import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import 'formula_builder.dart';
import 'math_text.dart';

/// Matn maydoni + "Formula" tugmasi + jonli ko'rinish.
/// - "Formula qo'shish" tugmasi formula yaratish oynasini ochadi (LaTeX bilish shart emas).
/// - Tayyor formula kursor turgan joyga qo'shiladi.
/// - Matnda formula bo'lsa, tagida chiroyli ko'rinishi ko'rsatiladi.
class MathTextField extends StatefulWidget {
  const MathTextField({
    super.key,
    required this.controller,
    required this.label,
    this.helperText,
    this.minLines = 1,
    this.maxLines = 1,
    this.validator,
    this.alignLabelWithHint = false,
  });

  final TextEditingController controller;
  final String label;
  final String? helperText;
  final int minLines;
  final int maxLines;
  final FormFieldValidator<String>? validator;
  final bool alignLabelWithHint;

  @override
  State<MathTextField> createState() => _MathTextFieldState();
}

class _MathTextFieldState extends State<MathTextField> {
  final FocusNode _focus = FocusNode();

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  /// Kursor `$...$` ichidami? (oldidagi juftlanmagan `$` soni toq bo'lsa — ha)
  bool _insideMath(String before) {
    var open = false;
    var i = 0;
    while (i < before.length) {
      final ch = before[i];
      if (ch == '\\') {
        i += 2; // \$ va boshqa buyruqlarni o'tkazib yuboramiz
        continue;
      }
      if (ch == r'$') open = !open;
      i++;
    }
    return open;
  }

  Future<void> _addFormula() async {
    final tex = await showFormulaBuilder(context);
    if (tex == null || !mounted) return;

    final c = widget.controller;
    final text = c.text;
    var start = c.selection.start;
    var end = c.selection.end;
    if (start < 0 || end < 0 || start > text.length || end > text.length) {
      start = text.length;
      end = text.length;
    }
    if (start > end) {
      final t = start;
      start = end;
      end = t;
    }

    // Kursor allaqachon formula ichida bo'lsa, `$` belgilari qo'shilmaydi.
    final piece = _insideMath(text.substring(0, start)) ? tex : '\$$tex\$';

    c.value = TextEditingValue(
      text: text.replaceRange(start, end, piece),
      selection: TextSelection.collapsed(offset: start + piece.length),
    );
    _focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: widget.controller,
          focusNode: _focus,
          minLines: widget.minLines,
          maxLines: widget.maxLines,
          validator: widget.validator,
          decoration: InputDecoration(
            labelText: widget.label,
            helperText: widget.helperText,
            alignLabelWithHint: widget.alignLabelWithHint,
          ),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: _addFormula,
            icon: const Icon(Icons.functions_rounded, size: 20),
            label: const Text("Formula qo'shish"),
          ),
        ),
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: widget.controller,
          builder: (context, value, _) {
            if (!MathText.hasMath(value.text)) return const SizedBox.shrink();
            return Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 4),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.line),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Ko'rinishi",
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.muted,
                    ),
                  ),
                  const SizedBox(height: 6),
                  MathText(
                    value.text,
                    style: const TextStyle(fontSize: 16, height: 1.5),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}