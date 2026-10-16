import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../constants/app_colors.dart';
import '../services/r2_storage.dart';
import '../utils/helpers.dart';

/// R2 dagi rasmni ko'rsatadi. `public/` kalitlari tokensiz, qolganlari
/// foydalanuvchi tokeni bilan yuklanadi.
class R2Image extends StatelessWidget {
  const R2Image({
    super.key,
    required this.keyPath,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.radius = 0,
    this.icon = Icons.image_outlined,
  });

  final String? keyPath;
  final double? width;
  final double? height;
  final BoxFit fit;
  final double radius;
  final IconData icon;

  Widget _placeholder() => Container(
        width: width,
        height: height,
        color: AppColors.skyLight,
        alignment: Alignment.center,
        child: Icon(icon, color: AppColors.skySoft, size: 32),
      );

  Widget _image(String url, Map<String, String> headers) => CachedNetworkImage(
        imageUrl: url,
        httpHeaders: headers,
        width: width,
        height: height,
        fit: fit,
        placeholder: (_, __) => _placeholder(),
        errorWidget: (_, __, ___) => _placeholder(),
      );

  @override
  Widget build(BuildContext context) {
    final k = keyPath;
    Widget child;
    if (k == null || k.isEmpty) {
      child = _placeholder();
    } else {
      final r2 = Get.find<R2Storage>();
      final url = r2.url(k);
      if (R2Storage.isPublicKey(k)) {
        child = _image(url, const {});
      } else {
        child = FutureBuilder<Map<String, String>>(
          future: r2.headersFor(k),
          builder: (_, snap) =>
              snap.hasData ? _image(url, snap.data!) : _placeholder(),
        );
      }
    }
    if (radius <= 0) return child;
    return ClipRRect(borderRadius: BorderRadius.circular(radius), child: child);
  }
}
