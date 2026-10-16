import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../utils/helpers.dart';
import 'r2_image.dart';

/// Fayl tanlash + R2 ga yuklash (progress bilan).
class UploadField extends StatefulWidget {
  const UploadField({
    super.key,
    required this.label,
    required this.folder,
    required this.onChanged,
    this.initialKey,
    this.type = FileType.any,
    this.extensions,
    this.isImage = false,
    this.icon = Icons.cloud_upload_outlined,
    this.onBusyChanged,
  });

  final String label;
  final String folder; // masalan: public/covers, videos, books
  final String? initialKey;
  final ValueChanged<String?> onChanged;
  final ValueChanged<bool>? onBusyChanged;
  final FileType type;
  final List<String>? extensions;
  final bool isImage;
  final IconData icon;

  @override
  State<UploadField> createState() => _UploadFieldState();
}

class _UploadFieldState extends State<UploadField> {
  String? _key;
  String? _fileName;
  double? _progress;
  String? _error;

  @override
  void initState() {
    super.initState();
    _key = widget.initialKey;
  }

  bool get _busy => _progress != null;

  Future<void> _pick() async {
    final res = await FilePicker.platform.pickFiles(
      type: widget.type,
      allowedExtensions: widget.extensions,
      withData: widget.isImage,
      withReadStream: !widget.isImage,
    );
    if (res == null || res.files.isEmpty) return;
    final f = res.files.first;

    Stream<List<int>>? stream = f.readStream;
    if (stream == null && f.bytes != null) stream = Stream.value(f.bytes!);
    if (stream == null) {
      setState(() => _error = "Faylni o'qib bo'lmadi");
      return;
    }

    setState(() {
      _progress = 0;
      _error = null;
      _fileName = f.name;
    });
    widget.onBusyChanged?.call(true);
    try {
      final key = await r2.upload(
        stream: stream,
        size: f.size,
        folder: widget.folder,
        fileName: f.name,
        onProgress: (p) {
          if (mounted) setState(() => _progress = p);
        },
      );
      if (!mounted) return;
      setState(() {
        _key = key;
        _progress = null;
      });
      widget.onChanged(key);
    } catch (e) {
      if (mounted) {
        setState(() {
          _progress = null;
          _error = "Yuklashda xatolik: $e";
        });
      }
    } finally {
      widget.onBusyChanged?.call(false);
    }
  }

  void _clear() {
    setState(() {
      _key = null;
      _fileName = null;
    });
    widget.onChanged(null);
  }

  @override
  Widget build(BuildContext context) {
    final hasFile = _key != null;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.skyLight.withAlpha(115),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.skySoft.withAlpha(153)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (widget.isImage && hasFile)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: R2Image(
                    keyPath: _key,
                    width: 64,
                    height: 64,
                    radius: 12,
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Icon(
                    hasFile ? Icons.check_circle_rounded : widget.icon,
                    color: hasFile ? AppColors.green : AppColors.sky,
                    size: 32,
                  ),
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.label,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      _busy
                          ? 'Yuklanmoqda… ${((_progress ?? 0) * 100).round()}%'
                          : hasFile
                              ? (_fileName ?? 'Yuklangan fayl mavjud')
                              : 'Fayl tanlanmagan',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              if (hasFile && !_busy)
                IconButton(
                  tooltip: 'Olib tashlash',
                  onPressed: _clear,
                  icon: const Icon(Icons.close_rounded),
                ),
              OutlinedButton(
                style: OutlinedButton.styleFrom(minimumSize: const Size(0, 42)),
                onPressed: _busy ? null : _pick,
                child: Text(hasFile ? "Almashtirish" : 'Tanlash'),
              ),
            ],
          ),
          if (_busy) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: (_progress ?? 0) > 0 ? _progress : null,
                minHeight: 8,
              ),
            ),
          ],
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _error!,
                style: const TextStyle(color: AppColors.danger, fontSize: 13),
              ),
            ),
        ],
      ),
    );
  }
}
