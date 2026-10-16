import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../constants/app_colors.dart';
import '../services/r2_storage.dart';
import '../services/repository.dart';

SatRepository get repo => Get.find<SatRepository>();
R2Storage get r2 => Get.find<R2Storage>();

void toast(String message, {bool error = false}) {
  Get.rawSnackbar(
    message: message,
    backgroundColor: error ? AppColors.danger : AppColors.ink,
    snackPosition: SnackPosition.BOTTOM,
    margin: const EdgeInsets.all(16),
    borderRadius: 14,
    maxWidth: 520,
    duration: Duration(seconds: error ? 5 : 3),
  );
}

Future<bool> confirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmText = "O'chirish",
}) async {
  final res = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Bekor qilish'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(confirmText),
        ),
      ],
    ),
  );
  return res ?? false;
}

String? requiredValidator(String? v) =>
    (v == null || v.trim().isEmpty) ? 'Majburiy maydon' : null;
