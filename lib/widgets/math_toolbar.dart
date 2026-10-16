import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';

import '../constants/app_colors.dart';

class _MathKey {
  const _MathKey(this.face, this.snippet, this.tooltip);

  final String face; // tugmadagi ko'rinish (LaTeX)
  final String snippet; // matnga qo'shiladigan LaTeX; ¦ = kursor qoladigan joy
  final String tooltip;
}

/// Formula tugmalari paneli: kasr, ildiz, daraja, belgilar ...
/// Tugma bosilganda LaTeX matn maydonga kursor turgan joyga qo'shiladi.
class MathToolbar extends StatelessWidget {
  const MathToolbar({super.key, required this.onPick});

  /// Tugma bosilganda snippet qaytariladi (uni [insertInto] bilan maydonga qo'shing).
  final ValueChanged<String> onPick;

  static const String caret = '¦';

  static const List<_MathKey> _keys = [
    _MathKey(r'f(x)', caret, 'Formula (bo\'sh)'),
    _MathKey(r'\frac{a}{b}', r'\frac{¦}{}', 'Kasr'),
    _MathKey(r'\sqrt{x}', r'\sqrt{¦}', 'Kvadrat ildiz'),
    _MathKey(r'\sqrt[n]{x}', r'\sqrt[¦]{}', 'n-darajali ildiz'),
    _MathKey(r'x^{n}', r'^{¦}', 'Daraja'),
    _MathKey(r'x_{n}', r'_{¦}', 'Pastki indeks'),
    _MathKey(r'\left|x\right|', r'\left|¦\right|', 'Modul'),
    _MathKey(r'\left(x\right)', r'\left(¦\right)', 'Katta qavs'),
    _MathKey(r'\pi', r'\pi', 'Pi'),
    _MathKey(r'\theta', r'\theta', 'Teta'),
    _MathKey(r'\le', r'\le', 'Kichik yoki teng'),
    _MathKey(r'\ge', r'\ge', 'Katta yoki teng'),
    _MathKey(r'\ne', r'\ne', 'Teng emas'),
    _MathKey(r'\pm', r'\pm', 'Plyus-minus'),
    _MathKey(r'\times', r'\times', "Ko'paytirish"),
    _MathKey(r'\div', r'\div', 'Bo\'lish'),
    _MathKey(r'^\circ', r'^\circ', 'Gradus'),
    _MathKey(r'\angle', r'\angle', 'Burchak'),
    _MathKey(r'\infty', r'\infty', 'Cheksizlik'),
  ];

  /// [snippet] ni [c] dagi kursor joyiga qo'shadi.
  /// Formula `$ ... $` ichida bo'lmasa, avtomatik `$` belgilari qo'yiladi.
  /// Matn belgilangan bo'lsa, u snippet ichiga (kursor joyiga) o'raladi.
  static void insertInto(TextEditingController c, String snippet) {
    final text = c.text;
    var start = c.selection.start;
    var end = c.selection.end;
    if (start < 0 || end < 0) {
      start = text.length;
      end = text.length;
    }
    if (start > end) {
      final t = start;
      start = end;
      end = t;
    }

    final at = snippet.indexOf(caret);
    // Kursorsiz snippet (masalan \pi) belgilangan matnni almashtirmaydi.
    if (at < 0) start = end;

    final selected = text.substring(start, end);
    final body = at < 0 ? snippet : snippet.replaceFirst(caret, selected);
    final caretInBody = at < 0 ? body.length : at + selected.length;
    final wrap = _insideMath(text.substring(0, start)) ? '' : r'$';

    c.value = TextEditingValue(
      text: text.replaceRange(start, end, '$wrap$body$wrap'),
      selection: TextSelection.collapsed(
        offset: start + wrap.length + caretInBody,
      ),
    );
  }

  static bool _insideMath(String before) {
    var open = false;
    for (var i = 0; i < before.length; i++) {
      final ch = before[i];
      if (ch == '\\') {
        i++; // keyingi belgi (masalan \$) e'tiborga olinmaydi
        continue;
      }
      if (ch == r'$') open = !open;
    }
    return open;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.skyLight.withAlpha(115),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.skySoft.withAlpha(153)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final k in _keys)
                _KeyButton(k, onTap: () => onPick(k.snippet)),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Tugma bosilsa formula avtomatik \$ ... \$ ichiga yoziladi. '
                'Haqiqiy dollar belgisi kerak bo\'lsa \\\$ deb yozing.',
            style: TextStyle(fontSize: 12, color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}

class _KeyButton extends StatelessWidget {
  const _KeyButton(this.k, {required this.onTap});

  final _MathKey k;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: k.tooltip,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          // Maydondan fokusni olib qo'ymasligi uchun.
          canRequestFocus: false,
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Align(
              widthFactor: 1,
              heightFactor: 1,
              child: Math.tex(
                k.face,
                mathStyle: MathStyle.text,
                textStyle:
                const TextStyle(fontSize: 17, color: AppColors.ink),
                onErrorFallback: (err) =>
                    Text(k.tooltip, style: const TextStyle(fontSize: 12)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}