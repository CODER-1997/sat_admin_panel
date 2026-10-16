import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../models/sat_module.dart';
import '../models/sat_question.dart';
import '../utils/helpers.dart';
import '../widgets/app_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/form_dialog.dart';
import '../widgets/math_text.dart';
import '../widgets/math_text_field.dart';
import '../widgets/pill.dart';
import '../widgets/sub_screen.dart';
import '../widgets/upload_field.dart';

/// Bitta modul (masalan "Math · 1-modul") ichidagi savollarni tahrirlash.
class ModuleEditorScreen extends StatefulWidget {
  const ModuleEditorScreen({super.key, required this.module});

  final SatModule module;

  @override
  State<ModuleEditorScreen> createState() => _ModuleEditorScreenState();
}

class _ModuleEditorScreenState extends State<ModuleEditorScreen> {
  late List<SatQuestion> _qs = List.of(widget.module.questions);
  late final TextEditingController _title =
  TextEditingController(text: widget.module.title);
  late final TextEditingController _duration =
  TextEditingController(text: '${widget.module.durationMin}');
  late Set<String> _knownImages =
  widget.module.questions.map((q) => q.imageKey).whereType<String>().toSet();
  bool _dirty = false;
  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    _duration.dispose();
    super.dispose();
  }

  void _touch() => setState(() => _dirty = true);

  Future<void> _add() async {
    final q = await showQuestionDialog(context, section: widget.module.section);
    if (q == null) return;
    if (q.imageKey != null) _knownImages.add(q.imageKey!);
    setState(() {
      _qs.add(q);
      _dirty = true;
    });
  }

  Future<void> _edit(int i) async {
    final q = await showQuestionDialog(
      context,
      section: widget.module.section,
      question: _qs[i],
    );
    if (q == null) return;
    if (q.imageKey != null) _knownImages.add(q.imageKey!);
    setState(() {
      _qs[i] = q;
      _dirty = true;
    });
  }

  void _move(int i, int delta) {
    final j = i + delta;
    if (j < 0 || j >= _qs.length) return;
    setState(() {
      final q = _qs.removeAt(i);
      _qs.insert(j, q);
      _dirty = true;
    });
  }

  Future<void> _remove(int i) async {
    final ok = await confirmDialog(
      context,
      title: "Savolni o'chirish",
      message: '${i + 1}-savol ro\'yxatdan olib tashlanadi (saqlagach o\'chadi).',
    );
    if (!ok) return;
    setState(() {
      _qs.removeAt(i);
      _dirty = true;
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final m = widget.module.copyWith(
        title: _title.text.trim(),
        durationMin: int.tryParse(_duration.text.trim()) ??
            SatModule.defaultMinutes(widget.module.section),
        questions: _qs,
      );
      await repo.saveModule(m);
      final current =
      _qs.map((q) => q.imageKey).whereType<String>().toSet();
      for (final k in _knownImages.difference(current)) {
        await r2.deleteQuiet(k);
      }
      _knownImages = current;
      if (mounted) {
        setState(() {
          _dirty = false;
          _saving = false;
        });
      }
      toast('Saqlandi ✓');
    } catch (e) {
      if (mounted) setState(() => _saving = false);
      toast("Saqlab bo'lmadi: $e", error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final target = SatModule.defaultQuestionCount(widget.module.section);
    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final leave = await confirmDialog(
          context,
          title: "Saqlanmagan o'zgarishlar",
          message: "Saqlamasdan chiqsangiz, o'zgarishlar yo'qoladi.",
          confirmText: 'Chiqish',
        );
        if (leave && mounted) Navigator.pop(context);
      },
      child: SubScreen(
        title: widget.module.label,
        subtitle:
        '${_qs.length} / $target savol${_dirty ? '  ·  saqlanmagan o\'zgarishlar' : ''}',
        actions: [
          OutlinedButton.icon(
            onPressed: _add,
            icon: const Icon(Icons.add_rounded),
            label: const Text("Savol qo'shish"),
          ),
          ElevatedButton.icon(
            onPressed: (_saving || !_dirty) ? null : _save,
            icon: _saving
                ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                  strokeWidth: 2.2, color: Colors.white),
            )
                : const Icon(Icons.save_rounded),
            label: const Text('Saqlash'),
          ),
        ],
        child: ListView(
          padding: const EdgeInsets.only(bottom: 40),
          children: [
            AppCard(
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextField(
                      controller: _title,
                      onChanged: (_) => _touch(),
                      decoration: const InputDecoration(
                        labelText: 'Modul sarlavhasi (ixtiyoriy)',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 1,
                    child: TextField(
                      controller: _duration,
                      keyboardType: TextInputType.number,
                      onChanged: (_) => _touch(),
                      decoration: const InputDecoration(labelText: 'Daqiqa'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (_qs.isEmpty)
              AppCard(
                child: EmptyState(
                  icon: Icons.help_outline_rounded,
                  title: "Bu modulda hali savol yo'q",
                  subtitle: "Birinchi savolni qo'shing",
                  action: ElevatedButton.icon(
                    onPressed: _add,
                    icon: const Icon(Icons.add_rounded),
                    label: const Text("Savol qo'shish"),
                  ),
                ),
              ),
            for (var i = 0; i < _qs.length; i++) ...[
              _QuestionTile(
                index: i,
                q: _qs[i],
                onEdit: () => _edit(i),
                onDelete: () => _remove(i),
                onUp: i == 0 ? null : () => _move(i, -1),
                onDown: i == _qs.length - 1 ? null : () => _move(i, 1),
              ),
              const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }
}

class _QuestionTile extends StatelessWidget {
  const _QuestionTile({
    required this.index,
    required this.q,
    required this.onEdit,
    required this.onDelete,
    this.onUp,
    this.onDown,
  });

  final int index;
  final SatQuestion q;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onUp;
  final VoidCallback? onDown;

  @override
  Widget build(BuildContext context) {
    final preview = q.prompt.trim().isEmpty ? '(savol matni yo\'q)' : q.prompt.trim();
    return AppCard(
      onTap: onEdit,
      padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.skyLight,
              shape: BoxShape.circle,
            ),
            child: Text('${index + 1}',
                style: const TextStyle(
                    fontWeight: FontWeight.w800, color: AppColors.skyDark)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MathText(preview,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    q.isMultipleChoice
                        ? const Pill('Test (A–D)')
                        : const Pill('Javob yoziladi', color: AppColors.warning),
                    Pill(
                        'Javob: ${q.isMultipleChoice ? String.fromCharCode(65 + q.correctIndex) : q.correctText}',
                        color: AppColors.greenDark,
                        icon: Icons.check_rounded),
                    if (q.imageKey != null)
                      const Pill('Rasm', icon: Icons.image_outlined),
                    if (q.explanation.trim().isNotEmpty)
                      const Pill('Izoh bor', icon: Icons.lightbulb_outline_rounded),
                  ],
                ),
              ],
            ),
          ),
          Column(
            children: [
              IconButton(
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Yuqoriga',
                  onPressed: onUp,
                  icon: const Icon(Icons.keyboard_arrow_up_rounded)),
              IconButton(
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Pastga',
                  onPressed: onDown,
                  icon: const Icon(Icons.keyboard_arrow_down_rounded)),
            ],
          ),
          IconButton(
            tooltip: "O'chirish",
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger),
          ),
        ],
      ),
    );
  }
}

// ======================================================================
// Savol dialogi
// ======================================================================

Future<SatQuestion?> showQuestionDialog(
    BuildContext context, {
      required String section,
      SatQuestion? question,
    }) =>
    showDialog<SatQuestion>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _QuestionDialog(section: section, question: question),
    );

class _QuestionDialog extends StatefulWidget {
  const _QuestionDialog({required this.section, this.question});

  final String section;
  final SatQuestion? question;

  @override
  State<_QuestionDialog> createState() => _QuestionDialogState();
}

class _QuestionDialogState extends State<_QuestionDialog> {
  final _form = GlobalKey<FormState>();

  late String _type = widget.question?.type ?? SatQuestion.mc;
  late int _correct = widget.question?.correctIndex ?? 0;
  late String? _image = widget.question?.imageKey;
  late final String? _initialImage = widget.question?.imageKey;
  bool _uploading = false;

  late final TextEditingController _passage =
  TextEditingController(text: widget.question?.passage);
  late final TextEditingController _prompt =
  TextEditingController(text: widget.question?.prompt);
  late final TextEditingController _explanation =
  TextEditingController(text: widget.question?.explanation);
  late final TextEditingController _accepted = TextEditingController(
      text: (widget.question?.acceptedAnswers ?? const <String>[]).join('; '));
  late final List<TextEditingController> _choices = List.generate(
    4,
        (i) => TextEditingController(
      text: (widget.question != null && i < widget.question!.choices.length)
          ? widget.question!.choices[i]
          : '',
    ),
  );

  bool get _isRw => widget.section == SatModule.rw;
  bool get _isMc => _type == SatQuestion.mc;

  @override
  void dispose() {
    _passage.dispose();
    _prompt.dispose();
    _explanation.dispose();
    _accepted.dispose();
    for (final c in _choices) {
      c.dispose();
    }
    super.dispose();
  }

  void _save() {
    if (!_form.currentState!.validate()) return;
    final accepted = _accepted.text
        .split(RegExp(r'[;\n]'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    final q = SatQuestion(
      id: widget.question?.id ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      type: _type,
      passage: _passage.text.trim(),
      prompt: _prompt.text.trim(),
      imageKey: _image,
      choices: _choices.map((c) => c.text.trim()).toList(),
      correctIndex: _correct,
      acceptedAnswers: _isMc ? const [] : accepted,
      explanation: _explanation.text.trim(),
    );
    Navigator.pop(context, q);
  }

  Future<void> _cancel() async {
    if (_image != null && _image != _initialImage) {
      await r2.deleteQuiet(_image);
    }
    if (mounted) Navigator.pop(context);
  }

  Widget _typeChip(String label, String value) {
    final selected = _type == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _type = value),
      selectedColor: AppColors.skyLight,
      labelStyle: TextStyle(
        fontWeight: FontWeight.w700,
        color: selected ? AppColors.skyDark : AppColors.ink,
      ),
      side: BorderSide(color: selected ? AppColors.sky : AppColors.line),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FormDialog(
      title: widget.question == null ? "Yangi savol" : 'Savolni tahrirlash',
      width: 680,
      saving: _uploading,
      saveText: 'Tayyor',
      onSave: _save,
      onCancel: _cancel,
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            if (!_isRw) ...[
              Wrap(
                spacing: 8,
                children: [
                  _typeChip('Test (A–D)', SatQuestion.mc),
                  _typeChip('Javob yoziladi (grid-in)', SatQuestion.spr),
                ],
              ),
              const SizedBox(height: 14),
            ],
            if (_isRw) ...[
              MathTextField(
                controller: _passage,
                label: 'Matn (passage)',
                minLines: 3,
                maxLines: 10,
                alignLabelWithHint: true,
              ),
              const SizedBox(height: 14),
            ],
            MathTextField(
              controller: _prompt,
              label: 'Savol',
              minLines: 2,
              maxLines: 8,
              alignLabelWithHint: true,
              helperText:
              "Formula kerak bo'lsa maydonni bosing: kasr, ildiz, daraja tugmalari chiqadi",
              validator: requiredValidator,
            ),
            const SizedBox(height: 14),
            UploadField(
              label: 'Rasm / grafik (ixtiyoriy)',
              folder: 'public/questions',
              type: FileType.image,
              isImage: true,
              icon: Icons.image_outlined,
              initialKey: _image,
              onChanged: (k) => setState(() => _image = k),
              onBusyChanged: (b) {
                if (mounted) setState(() => _uploading = b);
              },
            ),
            const SizedBox(height: 16),
            if (_isMc) ...[
              const Text('Variantlar (to\'g\'ri javobni belgilang)',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              for (var i = 0; i < 4; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      IconButton(
                        tooltip: "To'g'ri javob",
                        onPressed: () => setState(() => _correct = i),
                        icon: Icon(
                          _correct == i
                              ? Icons.check_circle_rounded
                              : Icons.radio_button_unchecked_rounded,
                          color: _correct == i ? AppColors.green : AppColors.muted,
                        ),
                      ),
                      Expanded(
                        child: MathTextField(
                          controller: _choices[i],
                          label: '${String.fromCharCode(65 + i)} variant',
                          maxLines: 3,
                          validator: requiredValidator,
                        ),
                      ),
                    ],
                  ),
                ),
            ] else ...[
              TextFormField(
                controller: _accepted,
                decoration: const InputDecoration(
                  labelText: "To'g'ri javob(lar)",
                  helperText:
                  "Bir nechta bo'lsa ';' bilan ajrating: 0.5; 1/2. Sonlar qiymati bo'yicha solishtiriladi",
                ),
                validator: requiredValidator,
              ),
            ],
            const SizedBox(height: 14),
            MathTextField(
              controller: _explanation,
              label: "Yechim / izoh (natijada ko'rsatiladi)",
              minLines: 2,
              maxLines: 8,
              alignLabelWithHint: true,
            ),
          ],
        ),
      ),
    );
  }
}