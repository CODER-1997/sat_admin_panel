import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// Gradient fonli quti (hero bloklar uchun).
class GradientBox extends StatelessWidget {
  const GradientBox({
    super.key,
    required this.child,
    this.gradient = AppColors.heroGradient,
    this.padding = const EdgeInsets.all(20),
    this.radius = 24,
  });

  final Widget child;
  final Gradient gradient;
  final EdgeInsetsGeometry padding;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: AppColors.sky.withAlpha(71),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: child,
    );
  }
}
