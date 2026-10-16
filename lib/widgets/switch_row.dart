import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// Sozlama qatori: switch bilan.
class SwitchRow extends StatelessWidget {
  const SwitchRow({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.hint,
  });

  final String label;
  final String? hint;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
              if (hint != null)
                Text(hint!,
                    style:
                        const TextStyle(color: AppColors.muted, fontSize: 13)),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          thumbColor: const WidgetStatePropertyAll(Colors.white),
          trackColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? AppColors.green
                : AppColors.line,
          ),
          trackOutlineColor:
              const WidgetStatePropertyAll(Colors.transparent),
        ),
      ],
    );
  }
}
