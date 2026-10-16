import 'package:admin_panel/widgets/text_view.dart';
import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../utils/helpers.dart';
import 'form_dialog.dart';

// =====================================================================
// Formula yaratish oynasi (LaTeX bilmasdan).
//
// 1) Qutini bosib yozing (son, harf, + - = ...).
// 2) "Kasr", "Ildiz", "Daraja" ... tugmalarini bosing: kursor turgan joyga
//    tegishli shakl qo'shiladi, uning ichidagi qutilarni to'ldirasiz.
// 3) Pastdagi belgilar (π, ≤, ≥ ...) kursor joyiga yoziladi.
// 4) "Qo'shish" bosilsa, tayyor formula (LaTeX matn) qaytadi.
// =====================================================================

/// Oynani ochadi. Tayyor formulaning LaTeX matnini qaytaradi (bekor qilinsa null).
Future<String?> showFormulaBuilder(BuildContext context) => showDialog<String>(
  context: context,
  barrierDismissible: false,
  builder: (_) => const _FormulaBuilderDialog(),
);

// ---------------------------------------------------------------------
// Formula daraxti
// ---------------------------------------------------------------------

abstract class _Node {
  /// Shu shakl ichidagi ketma-ketliklar (masalan kasr: [surat, maxraj]).
  List<List<_Node>> get seqs => const [];

  /// Oldingi bo'lak turi ('' = hali hech narsa yo'q, 'sup', 'sub', 'other').
  String get kind => 'other';

  String tex(String last);

  void retire() {
    for (final s in seqs) {
      for (final n in s) {
        n.retire();
      }
    }
  }

  void dispose() {
    for (final s in seqs) {
      for (final n in s) {
        n.dispose();
      }
    }
  }
}

String _texOf(List<_Node> seq) {
  final b = StringBuffer();
  var last = '';
  for (final n in seq) {
    final piece = n.tex(last);
    if (piece.isEmpty) continue;
    b.write(piece);
    last = n.kind;
  }
  return b.toString();
}

/// Oddiy yoziladigan quti: sonlar, harflar, amallar, belgilar.
class _TextNode extends _Node {
  _TextNode(this.owner, {String text = '', this.hint = ''})
      : controller = TextEditingController(text: text),
        focus = FocusNode();

  final List<_Node> owner;
  final String hint;
  final TextEditingController controller;
  final FocusNode focus;
  bool retired = false;

  static const Map<String, String> _symbols = {
    'π': r'\pi ',
    'θ': r'\theta ',
    '≤': r'\le ',
    '≥': r'\ge ',
    '≠': r'\ne ',
    '±': r'\pm ',
    '×': r'\times ',
    '÷': r'\div ',
    '°': r'^\circ ',
    '∞': r'\infty ',
    '∠': r'\angle ',
    '≈': r'\approx ',
    '−': '-',
  };

  static const Set<String> _functions = {
    'sin', 'cos', 'tan', 'cot', 'sec', 'csc', 'log', 'ln', //
  };
  static final RegExp _word = RegExp(r'[A-Za-z]+');

  @override
  String tex(String last) {
    final s = controller.text.trim();
    if (s.isEmpty) return '';
    final b = StringBuffer();
    for (final r in s.runes) {
      final ch = String.fromCharCode(r);
      if ('{}\\\$'.contains(ch)) continue; // xavfli belgilar tashlab yuboriladi
      if (ch == '%' || ch == '#' || ch == '&' || ch == '_' || ch == '^') {
        b.write('\\');
        b.write(ch);
        continue;
      }
      b.write(_symbols[ch] ?? ch);
    }
    // sin, cos, log ... so'zlari to'g'ri (tik) yoziladi.
    return b.toString().replaceAllMapped(_word, (m) {
      final w = m[0]!;
      return _functions.contains(w) ? '\\$w ' : w;
    });
  }

  @override
  void retire() => retired = true;

  @override
  void dispose() {
    controller.dispose();
    focus.dispose();
  }
}

class _FracNode extends _Node {
  final List<_Node> top = [];
  final List<_Node> bottom = [];

  @override
  List<List<_Node>> get seqs => [top, bottom];

  @override
  String tex(String last) {
    final a = _texOf(top);
    final b = _texOf(bottom);
    if (a.isEmpty && b.isEmpty) return '';
    final aa = a.isEmpty ? r'\ ' : a;
    final bb = b.isEmpty ? r'\ ' : b;
    return '\\frac{$aa}{$bb}';
  }
}

class _SqrtNode extends _Node {
  final List<_Node> body = [];

  @override
  List<List<_Node>> get seqs => [body];

  @override
  String tex(String last) {
    final s = _texOf(body);
    return s.isEmpty ? '' : '\\sqrt{$s}';
  }
}

class _RootNode extends _Node {
  final List<_Node> index = [];
  final List<_Node> body = [];

  @override
  List<List<_Node>> get seqs => [index, body];

  @override
  String tex(String last) {
    final s = _texOf(body);
    if (s.isEmpty) return '';
    final i = _texOf(index);
    final ii = i.isEmpty ? 'n' : i;
    return '\\sqrt[$ii]{$s}';
  }
}

class _SupNode extends _Node {
  final List<_Node> body = [];

  @override
  String get kind => 'sup';

  @override
  List<List<_Node>> get seqs => [body];

  @override
  String tex(String last) {
    final s = _texOf(body);
    if (s.isEmpty) return '';
    // Asos yo'q yoki oldingisi ham daraja bo'lsa, bo'sh asos qo'yiladi.
    final needBase = last == '' || last == 'sup';
    return needBase ? '{}^{$s}' : '^{$s}';
  }
}

class _SubNode extends _Node {
  final List<_Node> body = [];

  @override
  String get kind => 'sub';

  @override
  List<List<_Node>> get seqs => [body];

  @override
  String tex(String last) {
    final s = _texOf(body);
    if (s.isEmpty) return '';
    final needBase = last == '' || last == 'sub';
    return needBase ? '{}_{$s}' : '_{$s}';
  }
}

class _AbsNode extends _Node {
  final List<_Node> body = [];

  @override
  List<List<_Node>> get seqs => [body];

  @override
  String tex(String last) {
    final s = _texOf(body);
    return s.isEmpty ? '' : '\\left|$s\\right|';
  }
}

class _ParenNode extends _Node {
  final List<_Node> body = [];

  @override
  List<List<_Node>> get seqs => [body];

  @override
  String tex(String last) {
    final s = _texOf(body);
    return s.isEmpty ? '' : '\\left($s\\right)';
  }
}

// ---------------------------------------------------------------------
// Oyna
// ---------------------------------------------------------------------

class _Tool {
  const _Tool(this.face, this.label, this.kind);

  final String face; // tugmadagi kichik formula
  final String label;
  final String kind;
}

class _FormulaBuilderDialog extends StatefulWidget {
  const _FormulaBuilderDialog();

  @override
  State<_FormulaBuilderDialog> createState() => _FormulaBuilderDialogState();
}

class _FormulaBuilderDialogState extends State<_FormulaBuilderDialog> {
  static const List<_Tool> _tools = [
    _Tool(r'\frac{a}{b}', 'Kasr', 'frac'),
    _Tool(r'\sqrt{x}', 'Ildiz', 'sqrt'),
    _Tool(r'\sqrt[n]{x}', 'n-ildiz', 'root'),
    _Tool(r'x^{n}', 'Daraja', 'sup'),
    _Tool(r'x_{n}', 'Indeks', 'sub'),
    _Tool(r'\left|x\right|', 'Modul', 'abs'),
    _Tool(r'\left(x\right)', 'Qavs', 'paren'),
  ];

  static const List<String> _symbols = [
    'π', 'θ', '≤', '≥', '≠', '±', '×', '÷', '°', '∞', '∠', '≈',
  ];

  final List<_Node> _root = [];
  _TextNode? _lastText;

  @override
  void initState() {
    super.initState();
    _root.add(_newText(_root, hint: 'Shu yerga yozing'));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) (_root.first as _TextNode).focus.requestFocus();
    });
  }

  @override
  void dispose() {
    for (final n in _root) {
      n.dispose();
    }
    super.dispose();
  }

  String get _tex => _texOf(_root);

  // ----- tugunlar yaratish / o'chirish -----

  _TextNode _newText(List<_Node> owner, {String text = '', String hint = ''}) {
    final node = _TextNode(owner, text: text, hint: hint);
    node.focus.addListener(() {
      if (node.focus.hasFocus) _lastText = node;
    });
    return node;
  }

  _Node _make(String kind) {
    if (kind == 'frac') {
      final n = _FracNode();
      n.top.add(_newText(n.top, hint: 'surat'));
      n.bottom.add(_newText(n.bottom, hint: 'maxraj'));
      return n;
    }
    if (kind == 'sqrt') {
      final n = _SqrtNode();
      n.body.add(_newText(n.body, hint: 'ildiz ostida'));
      return n;
    }
    if (kind == 'root') {
      final n = _RootNode();
      n.index.add(_newText(n.index, hint: 'n'));
      n.body.add(_newText(n.body, hint: 'ildiz ostida'));
      return n;
    }
    if (kind == 'sup') {
      final n = _SupNode();
      n.body.add(_newText(n.body, hint: 'daraja'));
      return n;
    }
    if (kind == 'sub') {
      final n = _SubNode();
      n.body.add(_newText(n.body, hint: 'indeks'));
      return n;
    }
    if (kind == 'abs') {
      final n = _AbsNode();
      n.body.add(_newText(n.body, hint: '...'));
      return n;
    }
    final n = _ParenNode();
    n.body.add(_newText(n.body, hint: '...'));
    return n;
  }

  _TextNode _firstText(_Node n) => n.seqs.first.first as _TextNode;

  /// Yozish uchun maqsad qutisi: oxirgi bosilgan quti yoki asosiy qatorning oxirgisi.
  _TextNode _target() {
    final t = _lastText;
    if (t != null && !t.retired) return t;
    return _root.last as _TextNode;
  }

  void _discard(_Node n) {
    n.retire();
    // Controllerlar widget olib tashlangandan keyin yo'q qilinadi.
    WidgetsBinding.instance.addPostFrameCallback((_) => n.dispose());
  }

  // ----- amallar -----

  void _add(String kind) {
    final t = _target();
    final owner = t.owner;
    final i = owner.indexOf(t);
    if (i < 0) return;

    // Matnni kursor joyidan ikkiga bo'lamiz: chap qismi shu qutida qoladi.
    final text = t.controller.text;
    var caret = t.controller.selection.baseOffset;
    if (caret < 0 || caret > text.length) caret = text.length;
    final left = text.substring(0, caret);
    final right = text.substring(caret);
    t.controller.value = TextEditingValue(
      text: left,
      selection: TextSelection.collapsed(offset: left.length),
    );

    final node = _make(kind);
    final tail = _newText(owner, text: right);
    owner.insertAll(i + 1, [node, tail]);

    final first = _firstText(node);
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !first.retired) first.focus.requestFocus();
    });
  }

  void _remove(List<_Node> owner, _Node n) {
    final i = owner.indexOf(n);
    if (i < 0) return;
    owner.removeAt(i);
    _discard(n);

    // Yonma-yon qolgan ikki matn qutisini birlashtiramiz.
    if (i > 0 && i < owner.length) {
      final a = owner[i - 1];
      final b = owner[i];
      if (a is _TextNode && b is _TextNode) {
        a.controller.text = a.controller.text + b.controller.text;
        owner.removeAt(i);
        _discard(b);
      }
    }
    setState(() {});
  }

  void _insertSymbol(String ch) {
    final t = _target();
    final c = t.controller;
    var start = c.selection.start;
    var end = c.selection.end;
    if (start < 0 || end < 0) {
      start = c.text.length;
      end = c.text.length;
    }
    if (start > end) {
      final x = start;
      start = end;
      end = x;
    }
    c.value = TextEditingValue(
      text: c.text.replaceRange(start, end, ch),
      selection: TextSelection.collapsed(offset: start + ch.length),
    );
    t.focus.requestFocus();
    setState(() {});
  }

  void _done() {
    final tex = _tex;
    if (tex.isEmpty) {
      toast('Avval formulani yozing', error: true);
      return;
    }
    Navigator.pop(context, tex);
  }

  // ----- ko'rinish -----

  @override
  Widget build(BuildContext context) {
    final tex = _tex;
    return FormDialog(
      title: 'Formula yaratish',
      width: 720,
      saveText: "Qo'shish",
      onSave: _done,
      onCancel: () => Navigator.pop(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Qutini bosib yozing. Kasr, ildiz kabi shakl kerak bo'lsa, pastdagi tugmani bosing.",
            style: TextStyle(color: AppColors.muted, fontSize: 13.5),
          ),
          const SizedBox(height: 12),
          _preview(tex),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.skyLight.withAlpha(90),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.skySoft.withAlpha(140)),
            ),
            child: _buildSeq(_root),
          ),
          const SizedBox(height: 14),
          // Tugmalarni bosganda yozish qutisi fokusni yo'qotmasligi uchun.
          TextFieldTapRegion(child: _palette()),
        ],
      ),
    );
  }

  Widget _preview(String tex) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 84),
      padding: const EdgeInsets.all(16),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
      ),
      child: tex.isEmpty
          ? const Text(
        "Tayyor formula shu yerda ko'rinadi",
        style: TextStyle(color: AppColors.muted),
      )
          : TexView(
        tex,
        style: const TextStyle(fontSize: 28, color: AppColors.ink),
      ),
    );
  }

  Widget _palette() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Shakl qo\'shish',
            style: TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [for (final t in _tools) _toolButton(t)],
        ),
        const SizedBox(height: 14),
        const Text('Belgilar', style: TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [for (final s in _symbols) _symbolButton(s)],
        ),
      ],
    );
  }

  ShapeBorder get _btnShape => RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
    side: const BorderSide(color: AppColors.line),
  );

  Widget _toolButton(_Tool t) {
    return Tooltip(
      message: t.label,
      child: Material(
        color: Colors.white,
        shape: _btnShape,
        child: InkWell(
          canRequestFocus: false,
          customBorder: _btnShape,
          onTap: () => _add(t.kind),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TexView(
                  t.face,
                  style: const TextStyle(fontSize: 17, color: AppColors.ink),
                ),
                const SizedBox(width: 8),
                Text(t.label,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _symbolButton(String ch) {
    return Material(
      color: Colors.white,
      shape: _btnShape,
      child: InkWell(
        canRequestFocus: false,
        customBorder: _btnShape,
        onTap: () => _insertSymbol(ch),
        child: Container(
          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          alignment: Alignment.center,
          child: Text(ch, style: const TextStyle(fontSize: 20)),
        ),
      ),
    );
  }

  // ----- daraxtni chizish -----

  Widget _buildSeq(List<_Node> seq) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 6,
      runSpacing: 8,
      children: [for (final n in seq) _buildNode(seq, n)],
    );
  }

  Widget _buildNode(List<_Node> owner, _Node n) {
    if (n is _TextNode) return _textBox(n);

    Widget inner;
    if (n is _FracNode) {
      inner = IntrinsicWidth(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(child: _buildSeq(n.top)),
            Container(
              height: 2,
              margin: const EdgeInsets.symmetric(vertical: 6),
              color: AppColors.ink,
            ),
            Center(child: _buildSeq(n.bottom)),
          ],
        ),
      );
    } else if (n is _SqrtNode) {
      inner = _radical(null, n.body);
    } else if (n is _RootNode) {
      inner = _radical(n.index, n.body);
    } else if (n is _SupNode) {
      inner = _buildSeq(n.body);
    } else if (n is _SubNode) {
      inner = _buildSeq(n.body);
    } else if (n is _AbsNode) {
      inner = _fenced('|', '|', n.body);
    } else if (n is _ParenNode) {
      inner = _fenced('(', ')', n.body);
    } else {
      inner = const SizedBox.shrink();
    }

    return KeyedSubtree(
      key: ObjectKey(n),
      child: _shell(owner, n, inner),
    );
  }

  Widget _radical(List<_Node>? index, List<_Node> body) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (index != null) ...[
          _buildSeq(index),
          const SizedBox(width: 2),
        ],
        const Text(
          '√',
          style: TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.w700,
            color: AppColors.sky,
          ),
        ),
        Container(
          padding: const EdgeInsets.only(top: 6, left: 4),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: AppColors.ink, width: 2)),
          ),
          child: _buildSeq(body),
        ),
      ],
    );
  }

  Widget _fenced(String open, String close, List<_Node> body) {
    const style = TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.w300,
      color: AppColors.ink,
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(open, style: style),
        const SizedBox(width: 4),
        _buildSeq(body),
        const SizedBox(width: 4),
        Text(close, style: style),
      ],
    );
  }

  /// Shakl atrofidagi ramka va o'chirish tugmasi.
  Widget _shell(List<_Node> owner, _Node n, Widget child) {
    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(10, 10, 24, 10),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(180),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.skySoft),
          ),
          child: child,
        ),
        Positioned(
          top: 2,
          right: 2,
          child: Tooltip(
            message: "Shaklni o'chirish",
            child: InkWell(
              canRequestFocus: false,
              customBorder: const CircleBorder(),
              onTap: () => _remove(owner, n),
              child: const Padding(
                padding: EdgeInsets.all(3),
                child: Icon(Icons.close_rounded,
                    size: 15, color: AppColors.muted),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _textBox(_TextNode n) {
    final width = (30.0 + n.controller.text.length * 11.0).clamp(54.0, 300.0);
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: AppColors.skySoft),
    );
    return SizedBox(
      key: ObjectKey(n),
      width: width.toDouble(),
      child: TextField(
        controller: n.controller,
        focusNode: n.focus,
        onChanged: (_) => setState(() {}),
        style: const TextStyle(fontSize: 17),
        decoration: InputDecoration(
          isDense: true,
          hintText: n.hint,
          hintStyle: const TextStyle(fontSize: 13, color: AppColors.muted),
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          filled: true,
          fillColor: Colors.white,
          border: border,
          enabledBorder: border,
          focusedBorder: border.copyWith(
            borderSide: const BorderSide(color: AppColors.sky, width: 2),
          ),
        ),
      ),
    );
  }
}