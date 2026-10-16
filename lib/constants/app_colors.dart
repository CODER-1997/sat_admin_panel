import 'package:flutter/material.dart';

/// SAT platformasining asosiy ranglari: sky blue (asosiy) + green (aksent).
class AppColors {
  AppColors._();

  static const sky = Color(0xFF0EA5E9);
  static const skyDark = Color(0xFF0284C7);
  static const skySoft = Color(0xFF7DD3FC);
  static const skyLight = Color(0xFFE0F2FE);

  static const green = Color(0xFF22C55E);
  static const greenDark = Color(0xFF16A34A);
  static const greenLight = Color(0xFFDCFCE7);

  static const background = Color(0xFFF4FAFF);
  static const ink = Color(0xFF0B1B2B);
  static const muted = Color(0xFF64748B);
  static const line = Color(0xFFE2EEF7);

  static const danger = Color(0xFFEF4444);
  static const dangerLight = Color(0xFFFEE2E2);
  static const warning = Color(0xFFF59E0B);
  static const warningLight = Color(0xFFFEF3C7);

  static const heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF38BDF8), Color(0xFF0EA5E9), Color(0xFF14B8A6)],
  );

  static const greenGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF4ADE80), Color(0xFF22C55E)],
  );

  static const skyGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF38BDF8), Color(0xFF0284C7)],
  );
}
