import 'package:flutter/material.dart';

/// Dialog uchun yagona ko'rinish (sarlavha, forma, tugmalar).
class FormDialog extends StatelessWidget {
  const FormDialog({
    super.key,
    required this.title,
    required this.child,
    required this.onSave,
    required this.onCancel,
    this.saving = false,
    this.width = 540,
    this.saveText = 'Saqlash',
  });

  final String title;
  final Widget child;
  final VoidCallback onSave;
  final VoidCallback onCancel;
  final bool saving;
  final double width;
  final String saveText;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      content: SizedBox(
        width: width,
        child: SingleChildScrollView(child: child),
      ),
      actions: [
        TextButton(
          onPressed: saving ? null : onCancel,
          child: const Text('Bekor qilish'),
        ),
        ElevatedButton(
          onPressed: saving ? null : onSave,
          child: saving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color: Colors.white,
                  ),
                )
              : Text(saveText),
        ),
      ],
    );
  }
}
