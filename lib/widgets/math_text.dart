import 'package:admin_panel/widgets/text_view.dart';
import 'package:flutter/material.dart';


/// Matn ichidagi formulalarni chiroyli ko'rsatadi (kasr, ildiz, daraja ...).
///
/// Formula dollar belgilari orasida LaTeX bilan yoziladi:
///   Javob: $\frac{3}{4}$, ildiz: $\sqrt{x+1}$, daraja: $x^{2}$
/// Haqiqiy dollar belgisi kerak bo'lsa `\$` deb yoziladi (masalan: \$20).
/// Formulasiz oddiy matn o'zgarishsiz ko'rsatiladi.
class MathText extends StatelessWidget {
  const MathText(
      this.text, {
        super.key,
        this.style,
        this.maxLines,
        this.overflow,
        this.textAlign,
        this.selectable = false,
      });

  final String text;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextAlign? textAlign;

  /// Faqat formulasiz matn uchun: matnni belgilab nusxalash mumkin.
  final bool selectable;

  /// Matnda kamida bitta formula bormi?
  static bool hasMath(String text) => splitMath(text).any((p) => p.isMath);

  @override
  Widget build(BuildContext context) {
    final pieces = splitMath(text);

    if (!pieces.any((p) => p.isMath)) {
      final plain = pieces.map((p) => p.value).join();
      if (selectable) {
        return SelectableText(plain, style: style, textAlign: textAlign);
      }
      return Text(
        plain,
        style: style,
        maxLines: maxLines,
        overflow: overflow,
        textAlign: textAlign,
      );
    }

    final base = DefaultTextStyle.of(context).style.merge(style);
    final mathStyle = TextStyle(
      fontSize: base.fontSize,
      color: base.color,
      fontFamily: base.fontFamily,
      fontWeight: base.fontWeight,
    );

    return Text.rich(
      TextSpan(
        children: [
          for (final p in pieces)
            if (p.isMath)
              WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: TexView(p.value, style: mathStyle),
              )
            else
              TextSpan(text: p.value),
        ],
      ),
      style: style,
      maxLines: maxLines,
      overflow: overflow,
      textAlign: textAlign,
    );
  }
}

/// Matnning bir bo'lagi: oddiy matn yoki formula.
class MathPiece {
  const MathPiece(this.value, {required this.isMath});

  final String value;
  final bool isMath;
}

/// Matnni oddiy matn va `$...$` formulalariga ajratadi.
/// `\$` — oddiy dollar belgisi. Juftsiz `$` oddiy belgi sifatida qoladi.
List<MathPiece> splitMath(String s) {
  const dollar = r'$';
  const backslash = '\\';

  final pieces = <MathPiece>[];
  final buf = StringBuffer();

  void flushText() {
    if (buf.isEmpty) return;
    pieces.add(MathPiece(buf.toString(), isMath: false));
    buf.clear();
  }

  var i = 0;
  while (i < s.length) {
    final ch = s[i];

    if (ch == backslash && i + 1 < s.length && s[i + 1] == dollar) {
      buf.write(dollar);
      i += 2;
      continue;
    }

    if (ch == dollar) {
      var j = i + 1;
      var end = -1;
      while (j < s.length) {
        if (s[j] == backslash) {
          j += 2;
          continue;
        }
        if (s[j] == dollar) {
          end = j;
          break;
        }
        j++;
      }
      if (end > i + 1) {
        flushText();
        pieces.add(MathPiece(s.substring(i + 1, end), isMath: true));
        i = end + 1;
        continue;
      }
    }

    buf.write(ch);
    i++;
  }
  flushText();
  return pieces;
}