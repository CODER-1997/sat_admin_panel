import 'dart:math' as math;

import 'package:flutter/material.dart';

// =====================================================================
// TexView — formulalarni chizadigan yengil vidjet (tashqi paketsiz).
//
// Qo'llab-quvvatlanadi:
//   \frac{a}{b}  kasr          \sqrt{x}  ildiz        \sqrt[n]{x}  n-darajali ildiz
//   x^{2}  daraja              x_{1}  indeks          \left| x \right|  modul
//   \left( x \right)  qavs     \pi \theta \le \ge \ne \pm \times \div \circ
//   \infty \angle \approx ...  \sin \cos \tan \log \ln  \text{matn}
// Boshqa hamma narsa oddiy belgi sifatida chiziladi.
// =====================================================================

class TexView extends StatelessWidget {
  const TexView(this.tex, {super.key, this.style});

  /// `$` belgilarisiz LaTeX matni, masalan: \frac{3}{4}
  final String tex;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final base = DefaultTextStyle.of(context).style.merge(style);
    final fontSize = base.fontSize ?? 16.0;
    final color = base.color ?? const Color(0xFF0B1B2B);
    final builder = _TexBuilder(base.copyWith(height: 1.2), color);
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: builder.row(TexParser.parse(tex), fontSize),
    );
  }
}

// ---------------------------------------------------------------------
// Formula daraxti
// ---------------------------------------------------------------------

abstract class TexNode {
  const TexNode();
}

/// Ketma-ket joylashgan bo'laklar.
class TexRow extends TexNode {
  const TexRow(this.items);

  final List<TexNode> items;
}

/// Oddiy matn bo'lagi (harf, raqam, belgi). Harflar qiya (italic) yoziladi.
class TexChar extends TexNode {
  const TexChar(this.text, {this.italic = false});

  final String text;
  final bool italic;
}

/// Bo'sh joy (shrift o'lchamiga nisbatan).
class TexSpace extends TexNode {
  const TexSpace(this.em);

  final double em;
}

class TexFrac extends TexNode {
  const TexFrac(this.num, this.den);

  final TexRow num;
  final TexRow den;
}

class TexSqrt extends TexNode {
  const TexSqrt(this.body, this.index);

  final TexRow body;
  final TexRow? index;
}

class TexScript extends TexNode {
  const TexScript(this.base, this.sup, this.sub);

  final TexNode base;
  final TexRow? sup;
  final TexRow? sub;
}

class TexFenced extends TexNode {
  const TexFenced(this.open, this.close, this.body);

  final String open;
  final String close;
  final TexRow body;
}

// ---------------------------------------------------------------------
// Tahlilchi (parser)
// ---------------------------------------------------------------------

class TexParser {
  TexParser._();

  static final Map<String, TexRow> _cache = {};

  /// LaTeX matnini daraxtga aylantiradi (natija eslab qolinadi).
  static TexRow parse(String tex) {
    final cached = _cache[tex];
    if (cached != null) return cached;

    TexRow row;
    try {
      row = _Parser(tex).parse();
    } catch (_) {
      row = TexRow([TexChar(tex)]);
    }
    if (_cache.length > 300) _cache.clear();
    _cache[tex] = row;
    return row;
  }
}

class _Parser {
  _Parser(this.s);

  final String s;
  int i = 0;

  static const Map<String, String> _greek = {
    'alpha': 'α',
    'beta': 'β',
    'gamma': 'γ',
    'delta': 'δ',
    'epsilon': 'ε',
    'varepsilon': 'ε',
    'zeta': 'ζ',
    'eta': 'η',
    'theta': 'θ',
    'lambda': 'λ',
    'mu': 'μ',
    'nu': 'ν',
    'xi': 'ξ',
    'pi': 'π',
    'rho': 'ρ',
    'sigma': 'σ',
    'tau': 'τ',
    'phi': 'φ',
    'varphi': 'φ',
    'chi': 'χ',
    'psi': 'ψ',
    'omega': 'ω',
  };

  static const Map<String, String> _greekUpper = {
    'Delta': 'Δ',
    'Theta': 'Θ',
    'Lambda': 'Λ',
    'Pi': 'Π',
    'Sigma': 'Σ',
    'Phi': 'Φ',
    'Psi': 'Ψ',
    'Omega': 'Ω',
  };

  /// Munosabat belgilari: ikki yonida kengroq bo'sh joy bilan.
  static const Map<String, String> _relations = {
    'le': '≤',
    'leq': '≤',
    'ge': '≥',
    'geq': '≥',
    'ne': '≠',
    'neq': '≠',
    'approx': '≈',
    'equiv': '≡',
    'sim': '∼',
    'll': '≪',
    'gg': '≫',
    'to': '→',
    'rightarrow': '→',
    'Rightarrow': '⇒',
    'Leftrightarrow': '⇔',
    'in': '∈',
    'notin': '∉',
    'subset': '⊂',
    'perp': '⊥',
    'parallel': '∥',
  };

  /// Amal belgilari (+, ×, ÷ kabi).
  static const Map<String, String> _binary = {
    'pm': '±',
    'mp': '∓',
    'times': '×',
    'div': '÷',
    'cdot': '·',
    'ast': '∗',
    'cup': '∪',
    'cap': '∩',
  };

  static const Map<String, String> _ordinary = {
    'infty': '∞',
    'angle': '∠',
    'circ': '°',
    'degree': '°',
    'triangle': '△',
    'prime': '′',
    'ldots': '…',
    'cdots': '⋯',
    'dots': '…',
    'therefore': '∴',
    'because': '∵',
    'partial': '∂',
    'nabla': '∇',
    'sum': '∑',
    'prod': '∏',
    'int': '∫',
  };

  static const Set<String> _functions = {
    'sin',
    'cos',
    'tan',
    'cot',
    'sec',
    'csc',
    'log',
    'ln',
    'exp',
    'lim',
    'min',
    'max',
    'det',
    'arcsin',
    'arccos',
    'arctan',
  };

  static const Set<String> _ignored = {
    'displaystyle',
    'textstyle',
    'scriptstyle',
    'big',
    'Big',
    'bigg',
    'Bigg',
    'bigl',
    'bigr',
    'Bigl',
    'Bigr',
    'limits',
    'nolimits',
  };

  static bool _isLetter(String c) {
    final u = c.codeUnitAt(0);
    return (u >= 65 && u <= 90) || (u >= 97 && u <= 122);
  }

  void _skipSpaces() {
    while (i < s.length && (s[i] == ' ' || s[i] == '\n' || s[i] == '\t')) {
      i++;
    }
  }

  bool _atRight() {
    if (!s.startsWith(r'\right', i)) return false;
    return i + 6 >= s.length || !_isLetter(s[i + 6]);
  }

  TexRow parse() => _row(braceEnd: false, rightEnd: false);

  /// Qatorni o'qiydi. `braceEnd` bo'lsa `}` da, `rightEnd` bo'lsa `\right` da
  /// to'xtaydi (to'xtatuvchi belgini chaqiruvchi o'zi o'qiydi).
  TexRow _row({required bool braceEnd, required bool rightEnd}) {
    final items = <TexNode>[];
    while (i < s.length) {
      final c = s[i];

      if (c == '}') {
        if (braceEnd) return TexRow(items);
        i++;
        continue;
      }
      if (c == ' ' || c == '\n' || c == '\t') {
        i++;
        continue;
      }
      if (c == '\\') {
        if (_atRight()) {
          if (rightEnd) return TexRow(items);
          i += 6;
          continue;
        }
        _command(items);
        continue;
      }
      if (c == '{') {
        i++;
        final inner = _row(braceEnd: true, rightEnd: false);
        if (i < s.length && s[i] == '}') i++;
        items.add(inner);
        continue;
      }
      if (c == '^' || c == '_') {
        i++;
        _attach(items, c == '^', _argument());
        continue;
      }
      i++;
      _char(items, c);
    }
    return TexRow(items);
  }

  /// Bitta argument: `{...}` guruhi yoki bitta belgi/buyruq.
  TexRow _argument() {
    _skipSpaces();
    if (i >= s.length) return const TexRow([]);
    final c = s[i];
    if (c == '{') {
      i++;
      final inner = _row(braceEnd: true, rightEnd: false);
      if (i < s.length && s[i] == '}') i++;
      return inner;
    }
    final tmp = <TexNode>[];
    if (c == '\\') {
      _command(tmp);
    } else {
      i++;
      _char(tmp, c);
    }
    return TexRow(tmp);
  }

  /// `^` yoki `_` ni oldingi bo'lakka biriktiradi.
  void _attach(List<TexNode> items, bool sup, TexRow arg) {
    while (items.isNotEmpty && items.last is TexSpace) {
      items.removeLast();
    }

    TexNode base = const TexRow([]);
    TexRow? supRow;
    TexRow? subRow;

    if (items.isNotEmpty) {
      final last = items.removeLast();
      if (last is TexScript &&
          ((sup && last.sup == null) || (!sup && last.sub == null))) {
        base = last.base;
        supRow = last.sup;
        subRow = last.sub;
      } else {
        base = last;
      }
    }

    if (sup) {
      supRow = arg;
    } else {
      subRow = arg;
    }
    items.add(TexScript(base, supRow, subRow));
  }

  /// Oldida operand (son, harf, qavs ...) bormi? Unda `-` amal, aks holda ishora.
  bool _operandBefore(List<TexNode> items) {
    if (items.isEmpty) return false;
    final last = items.last;
    if (last is TexSpace) return false;
    if (last is TexChar) {
      return !(last.text == '(' || last.text == '[');
    }
    return true;
  }

  void _relation(List<TexNode> items, String glyph) {
    items.add(const TexSpace(0.28));
    items.add(TexChar(glyph));
    items.add(const TexSpace(0.28));
  }

  void _binaryOp(List<TexNode> items, String glyph) {
    if (_operandBefore(items)) {
      items.add(const TexSpace(0.22));
      items.add(TexChar(glyph));
      items.add(const TexSpace(0.22));
    } else {
      items.add(TexChar(glyph));
    }
  }

  void _char(List<TexNode> items, String c) {
    if (_isLetter(c)) {
      items.add(TexChar(c, italic: true));
      return;
    }
    switch (c) {
      case '=':
      case '<':
      case '>':
        _relation(items, c);
        return;
      case '+':
        _binaryOp(items, '+');
        return;
      case '-':
        _binaryOp(items, '−');
        return;
      case '*':
        _binaryOp(items, '·');
        return;
      case ',':
        items.add(const TexChar(','));
        // 1,000 kabi sonlarda vergul keyin bo'sh joy qo'yilmaydi.
        if (!(_endsWithDigit(items) && i < s.length && _isDigit(s[i]))) {
          items.add(const TexSpace(0.17));
        }
        return;
      default:
        items.add(TexChar(c));
    }
  }

  static bool _isDigit(String c) {
    final u = c.codeUnitAt(0);
    return u >= 48 && u <= 57;
  }

  /// Vergul oldidagi bo'lak raqammi? (vergulning o'zidan oldingisi)
  bool _endsWithDigit(List<TexNode> items) {
    if (items.length < 2) return false;
    final prev = items[items.length - 2];
    return prev is TexChar && prev.text.isNotEmpty && _isDigit(prev.text[prev.text.length - 1]);
  }

  String _rawGroup() {
    _skipSpaces();
    if (i >= s.length) return '';
    if (s[i] != '{') {
      final c = s[i];
      i++;
      return c;
    }
    i++;
    var depth = 1;
    final b = StringBuffer();
    while (i < s.length) {
      final c = s[i];
      if (c == '{') depth++;
      if (c == '}') {
        depth--;
        if (depth == 0) {
          i++;
          break;
        }
      }
      b.write(c);
      i++;
    }
    return b.toString();
  }

  /// `\left` / `\right` dan keyingi belgi: ( ) [ ] | { } yoki `.` (yo'q).
  String _delimiter() {
    _skipSpaces();
    if (i >= s.length) return '';
    final c = s[i];
    if (c == '\\') {
      if (i + 1 < s.length && !_isLetter(s[i + 1])) {
        final n = s[i + 1];
        i += 2;
        return n;
      }
      // \langle kabi buyruqlar qo'llab-quvvatlanmaydi: o'tkazib yuboramiz.
      i++;
      while (i < s.length && _isLetter(s[i])) {
        i++;
      }
      return '';
    }
    i++;
    return c == '.' ? '' : c;
  }

  void _command(List<TexNode> items) {
    i++; // '\\'
    if (i >= s.length) return;

    final first = s[i];
    if (!_isLetter(first)) {
      i++;
      switch (first) {
        case ',':
          items.add(const TexSpace(0.17));
          return;
        case ';':
        case ' ':
          items.add(const TexSpace(0.28));
          return;
        case ':':
          items.add(const TexSpace(0.22));
          return;
        case '!':
        case '\\':
          return;
        default:
        // \% \# \& \$ \{ \} \_ \^ ... — belgining o'zi.
          items.add(TexChar(first));
          return;
      }
    }

    final start = i;
    while (i < s.length && _isLetter(s[i])) {
      i++;
    }
    final name = s.substring(start, i);

    switch (name) {
      case 'frac':
      case 'dfrac':
      case 'tfrac':
        {
          final num = _argument();
          final den = _argument();
          items.add(TexFrac(num, den));
          return;
        }
      case 'sqrt':
        {
          _skipSpaces();
          TexRow? index;
          if (i < s.length && s[i] == '[') {
            final end = s.indexOf(']', i);
            if (end > i) {
              index = _Parser(s.substring(i + 1, end)).parse();
              i = end + 1;
            }
          }
          items.add(TexSqrt(_argument(), index));
          return;
        }
      case 'left':
        {
          final open = _delimiter();
          final body = _row(braceEnd: false, rightEnd: true);
          var close = '';
          if (_atRight()) {
            i += 6;
            close = _delimiter();
          }
          items.add(TexFenced(open, close, body));
          return;
        }
      case 'right':
        return;
      case 'text':
      case 'mathrm':
      case 'mathbf':
      case 'textbf':
      case 'mbox':
      case 'operatorname':
        {
          final t = _rawGroup();
          if (t.isNotEmpty) items.add(TexChar(t));
          return;
        }
      case 'quad':
        items.add(const TexSpace(1.0));
        return;
      case 'qquad':
        items.add(const TexSpace(2.0));
        return;
    }

    if (_ignored.contains(name)) return;

    final greek = _greek[name];
    if (greek != null) {
      items.add(TexChar(greek, italic: true));
      return;
    }
    final upper = _greekUpper[name];
    if (upper != null) {
      items.add(TexChar(upper));
      return;
    }
    final rel = _relations[name];
    if (rel != null) {
      _relation(items, rel);
      return;
    }
    final bin = _binary[name];
    if (bin != null) {
      _binaryOp(items, bin);
      return;
    }
    final ord = _ordinary[name];
    if (ord != null) {
      items.add(TexChar(ord));
      return;
    }
    if (_functions.contains(name)) {
      items.add(TexChar(name));
      items.add(const TexSpace(0.17));
      return;
    }

    // Noma'lum buyruq: o'z holicha ko'rsatiladi.
    items.add(TexChar('\\$name'));
  }
}

// ---------------------------------------------------------------------
// Chizish
// ---------------------------------------------------------------------

class _TexBuilder {
  _TexBuilder(this.base, this.color);

  final TextStyle base;
  final Color color;

  /// Qatorni gorizontal Row qilib quradi.
  Widget row(TexRow r, double fs) {
    final children = <Widget>[];
    final run = StringBuffer();
    var runItalic = false;

    void flush() {
      if (run.isEmpty) return;
      children.add(
        Text(
          run.toString(),
          softWrap: false,
          style: base.copyWith(
            fontSize: fs,
            fontStyle: runItalic ? FontStyle.italic : FontStyle.normal,
          ),
        ),
      );
      run.clear();
    }

    for (final n in r.items) {
      if (n is TexChar) {
        if (run.isNotEmpty && runItalic != n.italic) flush();
        runItalic = n.italic;
        run.write(n.text);
      } else {
        flush();
        children.add(node(n, fs));
      }
    }
    flush();

    if (children.isEmpty) return const SizedBox.shrink();
    if (children.length == 1) return children.first;
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: children,
    );
  }

  Widget node(TexNode n, double fs) {
    if (n is TexRow) return row(n, fs);
    if (n is TexChar) return row(TexRow([n]), fs);
    if (n is TexSpace) return SizedBox(width: n.em * fs);
    if (n is TexFrac) return _frac(n, fs);
    if (n is TexSqrt) return _sqrt(n, fs);
    if (n is TexScript) return _script(n, fs);
    if (n is TexFenced) return _fenced(n, fs);
    return const SizedBox.shrink();
  }

  Widget _frac(TexFrac f, double fs) {
    final cfs = fs * 0.85;
    final bar = math.max(1.0, fs * 0.06);
    final pad = EdgeInsets.symmetric(horizontal: fs * 0.1);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: fs * 0.1),
      child: IntrinsicWidth(
        child: IntrinsicHeight(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Surat va maxraj teng balandlikda bo'ladi: chiziq aniq o'rtada.
              Expanded(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(padding: pad, child: row(f.num, cfs)),
                ),
              ),
              Container(
                height: bar,
                margin: EdgeInsets.symmetric(vertical: fs * 0.08),
                color: color,
              ),
              Expanded(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Padding(padding: pad, child: row(f.den, cfs)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sqrt(TexSqrt n, double fs) {
    final sign = fs * 0.6;
    final stroke = math.max(1.2, fs * 0.07);
    final radical = CustomPaint(
      painter: _RadicalPainter(color: color, stroke: stroke, sign: sign),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          sign + fs * 0.06,
          fs * 0.14,
          fs * 0.08,
          fs * 0.14,
        ),
        child: row(n.body, fs),
      ),
    );
    final idx = n.index;
    if (idx == null) return radical;
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(top: fs * 0.1),
          child: row(idx, fs * 0.55),
        ),
        radical,
      ],
    );
  }

  Widget _script(TexScript n, double fs) {
    final baseWidget = node(n.base, fs);
    final sfs = fs * 0.7;
    final sup = n.sup;
    final sub = n.sub;

    // 30° kabi: daraja belgisi ko'tarilmasdan, oddiy yoziladi.
    if (sup != null && sub == null && sup.items.length == 1) {
      final only = sup.items.first;
      if (only is TexChar && only.text == '°') {
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [baseWidget, row(sup, fs)],
        );
      }
    }

    // Ham yuqori, ham pastki indeks: yuqorisi tepaga, pastkisi pastga.
    if (sup != null && sub != null) {
      return IntrinsicHeight(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(child: baseWidget),
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [row(sup, sfs), row(sub, sfs)],
            ),
          ],
        ),
      );
    }

    final small = sup ?? sub;
    return Row(
      mainAxisSize: MainAxisSize.min,
      // Daraja tepaga, indeks pastga tekislanadi.
      crossAxisAlignment:
      sup != null ? CrossAxisAlignment.start : CrossAxisAlignment.end,
      children: [
        baseWidget,
        if (small != null) row(small, sfs),
      ],
    );
  }

  Widget _fenced(TexFenced n, double fs) {
    final w = fs * 0.3;
    final stroke = math.max(1.1, fs * 0.06);
    Widget delim(String ch) {
      if (ch.isEmpty) return SizedBox(width: fs * 0.05);
      return SizedBox(
        width: w,
        child: CustomPaint(painter: _DelimPainter(ch, color, stroke)),
      );
    }

    return IntrinsicHeight(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          delim(n.open),
          Center(child: row(n.body, fs)),
          delim(n.close),
        ],
      ),
    );
  }
}

/// Ildiz belgisi (√ va tepadagi chiziq). Ichidagi formulaga qarab cho'ziladi.
class _RadicalPainter extends CustomPainter {
  _RadicalPainter({
    required this.color,
    required this.stroke,
    required this.sign,
  });

  final Color color;
  final double stroke;
  final double sign;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeJoin = StrokeJoin.round;
    final h = size.height;
    final top = stroke / 2;
    final bottom = h - stroke / 2;

    final path = Path();
    path.moveTo(0, h * 0.58);
    path.lineTo(sign * 0.22, h * 0.52);
    path.lineTo(sign * 0.5, bottom);
    path.lineTo(sign * 0.92, top);
    path.lineTo(size.width, top);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_RadicalPainter old) =>
      old.color != color || old.stroke != stroke || old.sign != sign;
}

/// Qavs, kvadrat qavs va modul chiziqlari. Balandlikka qarab cho'ziladi.
class _DelimPainter extends CustomPainter {
  _DelimPainter(this.ch, this.color, this.stroke);

  final String ch;
  final Color color;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final w = size.width;
    final h = size.height;
    final path = Path();

    switch (ch) {
      case '(':
      case '{':
        path.moveTo(w * 0.8, h * 0.03);
        path.quadraticBezierTo(0, h * 0.5, w * 0.8, h * 0.97);
        break;
      case ')':
      case '}':
        path.moveTo(w * 0.2, h * 0.03);
        path.quadraticBezierTo(w, h * 0.5, w * 0.2, h * 0.97);
        break;
      case '[':
        path.moveTo(w * 0.8, h * 0.03);
        path.lineTo(w * 0.25, h * 0.03);
        path.lineTo(w * 0.25, h * 0.97);
        path.lineTo(w * 0.8, h * 0.97);
        break;
      case ']':
        path.moveTo(w * 0.2, h * 0.03);
        path.lineTo(w * 0.75, h * 0.03);
        path.lineTo(w * 0.75, h * 0.97);
        path.lineTo(w * 0.2, h * 0.97);
        break;
      default:
      // | va boshqa belgilar: tik chiziq.
        path.moveTo(w * 0.5, 0);
        path.lineTo(w * 0.5, h);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_DelimPainter old) =>
      old.ch != ch || old.color != color || old.stroke != stroke;
}