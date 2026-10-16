import 'dart:convert';
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

/// Cloudflare R2 bilan Worker orqali ishlaydi (admin_panel/worker/ papkasiga qarang).
///
/// Kalit (key) qoidasi:
///   public/...  -> hamma ko'ra oladi (muqova rasmlari, savol rasmlari)
///   videos/...  -> faqat tizimga kirgan foydalanuvchilar
///   books/...   -> faqat tizimga kirgan foydalanuvchilar
class R2Storage {
  R2Storage({required String baseUrl, FirebaseAuth? auth})
      : baseUrl = baseUrl.endsWith('/')
            ? baseUrl.substring(0, baseUrl.length - 1)
            : baseUrl,
        _auth = auth ?? FirebaseAuth.instance;

  final String baseUrl;
  final FirebaseAuth _auth;

  /// R2 multipart: oxirgisidan boshqa har bir bo'lak kamida 5 MB bo'lishi shart.
  static const int partSize = 8 * 1024 * 1024;

  static bool isPublicKey(String key) => key.startsWith('public/');

  String url(String key) =>
      '$baseUrl/files/${key.split('/').map(Uri.encodeComponent).join('/')}';

  Future<Map<String, String>> authHeaders() async {
    final user = _auth.currentUser;
    if (user == null) return {};
    final token = await user.getIdToken();
    return {'Authorization': 'Bearer $token'};
  }

  Future<Map<String, String>> headersFor(String key) async =>
      isPublicKey(key) ? <String, String>{} : await authHeaders();

  static String guessContentType(String fileName) {
    final ext = fileName.contains('.')
        ? fileName.split('.').last.toLowerCase()
        : '';
    switch (ext) {
      case 'mp4':
      case 'm4v':
        return 'video/mp4';
      case 'mov':
        return 'video/quicktime';
      case 'webm':
        return 'video/webm';
      case 'mkv':
        return 'video/x-matroska';
      case 'pdf':
        return 'application/pdf';
      case 'png':
        return 'image/png';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'webp':
        return 'image/webp';
      case 'gif':
        return 'image/gif';
      case 'svg':
        return 'image/svg+xml';
      default:
        return 'application/octet-stream';
    }
  }

  static String _sanitize(String name) =>
      name.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');

  String _makeKey(String folder, String fileName) {
    final f = folder.endsWith('/') ? folder.substring(0, folder.length - 1) : folder;
    return '$f/${DateTime.now().millisecondsSinceEpoch}_${_sanitize(fileName)}';
  }

  void _check(http.Response r) {
    if (r.statusCode < 200 || r.statusCode >= 300) {
      var msg = r.body;
      try {
        final j = jsonDecode(r.body);
        if (j is Map && j['error'] != null) msg = j['error'].toString();
      } catch (_) {}
      throw Exception('Storage xatosi (${r.statusCode}): $msg');
    }
  }

  Future<Uint8List> _collect(Stream<List<int>> stream) async {
    final b = BytesBuilder();
    await for (final c in stream) {
      b.add(c);
    }
    return b.takeBytes();
  }

  /// Faylni R2 ga yuklaydi va kalitini qaytaradi.
  /// 8 MB dan katta fayllar avtomatik bo'laklab (multipart) yuklanadi.
  Future<String> upload({
    required Stream<List<int>> stream,
    required int size,
    required String folder,
    required String fileName,
    String? contentType,
    void Function(double progress)? onProgress,
  }) async {
    final key = _makeKey(folder, fileName);
    final type = contentType ?? guessContentType(fileName);
    final qKey = Uri.encodeQueryComponent(key);

    if (size <= partSize) {
      final bytes = await _collect(stream);
      final r = await http.put(
        Uri.parse('$baseUrl/upload?key=$qKey'),
        headers: {...await authHeaders(), 'Content-Type': type},
        body: bytes,
      );
      _check(r);
      onProgress?.call(1);
      return key;
    }

    // ---- multipart ----
    final create = await http.post(
      Uri.parse(
          '$baseUrl/multipart/create?key=$qKey&contentType=${Uri.encodeQueryComponent(type)}'),
      headers: await authHeaders(),
    );
    _check(create);
    final uploadId = (jsonDecode(create.body) as Map)['uploadId'] as String;

    final parts = <Map<String, dynamic>>[];
    var partNo = 1;
    var sent = 0;

    Future<void> sendPart(Uint8List data) async {
      Object? lastError;
      for (var attempt = 0; attempt < 3; attempt++) {
        try {
          final r = await http.put(
            Uri.parse(
                '$baseUrl/multipart/part?key=$qKey&uploadId=${Uri.encodeQueryComponent(uploadId)}&part=$partNo'),
            headers: await authHeaders(),
            body: data,
          );
          _check(r);
          final j = jsonDecode(r.body) as Map;
          parts.add({'partNumber': j['partNumber'], 'etag': j['etag']});
          partNo++;
          sent += data.length;
          onProgress?.call(size == 0 ? 1 : (sent / size).clamp(0.0, 0.99).toDouble());
          return;
        } catch (e) {
          lastError = e;
          await Future.delayed(Duration(seconds: 1 + attempt * 2));
        }
      }
      throw lastError ?? Exception('Bo\'lakni yuklab bo\'lmadi');
    }

    try {
      final buf = BytesBuilder();
      await for (final chunk in stream) {
        buf.add(chunk);
        while (buf.length >= partSize) {
          final all = buf.takeBytes();
          await sendPart(Uint8List.sublistView(all, 0, partSize));
          if (all.length > partSize) {
            buf.add(Uint8List.sublistView(all, partSize));
          }
        }
      }
      if (buf.length > 0) {
        await sendPart(buf.takeBytes());
      }
      final done = await http.post(
        Uri.parse(
            '$baseUrl/multipart/complete?key=$qKey&uploadId=${Uri.encodeQueryComponent(uploadId)}'),
        headers: {...await authHeaders(), 'Content-Type': 'application/json'},
        body: jsonEncode({'parts': parts}),
      );
      _check(done);
      onProgress?.call(1);
      return key;
    } catch (e) {
      try {
        await http.post(
          Uri.parse(
              '$baseUrl/multipart/abort?key=$qKey&uploadId=${Uri.encodeQueryComponent(uploadId)}'),
          headers: await authHeaders(),
        );
      } catch (_) {}
      rethrow;
    }
  }

  Future<void> delete(String key) async {
    final r = await http.delete(Uri.parse(url(key)), headers: await authHeaders());
    _check(r);
  }

  /// Xatolikni yutadi (tozalash ishlari uchun).
  Future<void> deleteQuiet(String? key) async {
    if (key == null || key.isEmpty) return;
    try {
      await delete(key);
    } catch (_) {}
  }

  /// Faylni to'liq yuklab oladi (PDF kitoblar uchun).
  Future<Uint8List> download(
    String key, {
    void Function(int received, int? total)? onProgress,
  }) async {
    final client = http.Client();
    try {
      final req = http.Request('GET', Uri.parse(url(key)));
      req.headers.addAll(await headersFor(key));
      final res = await client.send(req);
      if (res.statusCode != 200) {
        throw Exception('Faylni yuklab bo\'lmadi (${res.statusCode})');
      }
      final total = res.contentLength;
      final b = BytesBuilder();
      var got = 0;
      await for (final c in res.stream) {
        b.add(c);
        got += c.length;
        onProgress?.call(got, total);
      }
      return b.takeBytes();
    } finally {
      client.close();
    }
  }
}
