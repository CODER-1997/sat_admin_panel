import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../models/sat_module.dart';
import '../models/sat_test.dart';
import '../utils/helpers.dart';
import '../widgets/app_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/form_dialog.dart';
import '../widgets/page_header.dart';
import '../widgets/pill.dart';
import '../widgets/sub_screen.dart';
import '../widgets/switch_row.dart';
import 'module_editor_screen.dart';

class TestsScreen extends StatelessWidget {
  const TestsScreen({super.key});

  Future<void> _delete(BuildContext context, SatTest t) async {
    final ok = await confirmDialog(
      context,
      title: "Testni o'chirish",
      message:
          "\"${t.title}\" testi, uning barcha modullari va savollari o'chiriladi.",
    );
    if (!ok) return;
    try {
      final keys = await repo.deleteTest(t.id);
      for (final k in keys) {
        await r2.deleteQuiet(k);
      }
      toast("Test o'chirildi");
    } catch (e) {
      toast('Xatolik: $e', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHeader(
          title: 'SAT testlar',
          subtitle: 'Reading & Writing + Math modullaridan iborat testlar',
          actions: [
            ElevatedButton.icon(
              onPressed: () => showTestDialog(context),
              icon: const Icon(Icons.add_rounded),
              label: const Text("Test qo'shish"),
            ),
          ],
        ),
        Expanded(
          child: StreamBuilder<List<SatTest>>(
            stream: repo.watchTests(),
            builder: (context, snap) {
              if (snap.hasError) return Center(child: Text('Xatolik: ${snap.error}'));
              if (!snap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final list = snap.data!;
              if (list.isEmpty) {
                return EmptyState(
                  icon: Icons.quiz_rounded,
                  title: "Hali test yo'q",
                  subtitle: "Test yarating, so'ng modul va savollarni qo'shing",
                  action: ElevatedButton.icon(
                    onPressed: () => showTestDialog(context),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text("Test qo'shish"),
                  ),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.only(bottom: 32),
                itemCount: list.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, i) {
                  final t = list[i];
                  return AppCard(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => TestEditorScreen(testId: t.id)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            gradient: AppColors.greenGradient,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.quiz_rounded,
                              color: Colors.white),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(t.title,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16)),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 8,
                                runSpacing: 6,
                                children: [
                                  Pill('${t.moduleCount} modul',
                                      icon: Icons.view_module_rounded),
                                  Pill('${t.questionCount} savol',
                                      icon: Icons.help_outline_rounded),
                                  Pill('${t.durationMin} daqiqa',
                                      icon: Icons.schedule_rounded),
                                  t.published
                                      ? const Pill("E'lon qilingan",
                                          color: AppColors.greenDark)
                                      : const Pill('Qoralama',
                                          color: AppColors.warning),
                                ],
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Nomi va holatini tahrirlash',
                          onPressed: () => showTestDialog(context, test: t),
                          icon: const Icon(Icons.edit_rounded),
                        ),
                        IconButton(
                          tooltip: "O'chirish",
                          onPressed: () => _delete(context, t),
                          icon: const Icon(Icons.delete_outline_rounded,
                              color: AppColors.danger),
                        ),
                        const Icon(Icons.chevron_right_rounded,
                            color: AppColors.muted),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

Future<void> showTestDialog(BuildContext context, {SatTest? test}) =>
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _TestDialog(test: test),
    );

class _TestDialog extends StatefulWidget {
  const _TestDialog({this.test});

  final SatTest? test;

  @override
  State<_TestDialog> createState() => _TestDialogState();
}

class _TestDialogState extends State<_TestDialog> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _title =
      TextEditingController(text: widget.test?.title);
  late final TextEditingController _desc =
      TextEditingController(text: widget.test?.description);
  late bool _published = widget.test?.published ?? false;
  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await repo.saveTest(SatTest(
        id: widget.test?.id ?? '',
        title: _title.text.trim(),
        description: _desc.text.trim(),
        published: _published,
      ));
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() => _saving = false);
      toast("Saqlab bo'lmadi: $e", error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FormDialog(
      title: widget.test == null ? 'Yangi test' : 'Testni tahrirlash',
      saving: _saving,
      onSave: _save,
      onCancel: () => Navigator.pop(context),
      child: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            TextFormField(
              controller: _title,
              decoration: const InputDecoration(
                  labelText: 'Test nomi', hintText: 'Masalan: SAT Practice Test 1'),
              validator: requiredValidator,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _desc,
              minLines: 2,
              maxLines: 5,
              decoration: const InputDecoration(labelText: 'Tavsif'),
            ),
            const SizedBox(height: 14),
            SwitchRow(
              label: "E'lon qilish",
              hint: "Modullar tayyor bo'lgach yoqing",
              value: _published,
              onChanged: (v) => setState(() => _published = v),
            ),
          ],
        ),
      ),
    );
  }
}

// ======================================================================
// Test muharriri: modullar ro'yxati
// ======================================================================

class TestEditorScreen extends StatelessWidget {
  const TestEditorScreen({super.key, required this.testId});

  final String testId;

  Future<void> _createDefaults(BuildContext context, List<SatModule> existing) async {
    bool has(String s, int n) =>
        existing.any((m) => m.section == s && m.moduleNo == n);
    try {
      for (final s in [SatModule.rw, SatModule.math]) {
        for (final n in [1, 2]) {
          if (has(s, n)) continue;
          await repo.saveModule(SatModule(
            testId: testId,
            section: s,
            moduleNo: n,
            durationMin: SatModule.defaultMinutes(s),
          ));
        }
      }
      toast('Standart modullar yaratildi');
    } catch (e) {
      toast('Xatolik: $e', error: true);
    }
  }

  Future<void> _deleteModule(BuildContext context, SatModule m) async {
    final ok = await confirmDialog(
      context,
      title: "Modulni o'chirish",
      message: "${m.label} va undagi ${m.questions.length} ta savol o'chiriladi.",
    );
    if (!ok) return;
    try {
      await repo.deleteModule(testId, m.id);
      for (final q in m.questions) {
        await r2.deleteQuiet(q.imageKey);
      }
    } catch (e) {
      toast('Xatolik: $e', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<SatTest>>(
      stream: repo.watchTests(),
      builder: (context, testSnap) {
        SatTest? test;
        for (final t in testSnap.data ?? const <SatTest>[]) {
          if (t.id == testId) test = t;
        }
        return SubScreen(
          title: test?.title ?? 'Test',
          subtitle: test == null
              ? null
              : '${test.moduleCount} modul · ${test.questionCount} savol · ${test.durationMin} daqiqa',
          actions: [
            ElevatedButton.icon(
              onPressed: () => showModuleDialog(context, testId: testId),
              icon: const Icon(Icons.add_rounded),
              label: const Text("Modul qo'shish"),
            ),
          ],
          child: StreamBuilder<List<SatModule>>(
            stream: repo.watchModules(testId),
            builder: (context, snap) {
              if (snap.hasError) return Center(child: Text('Xatolik: ${snap.error}'));
              if (!snap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final modules = snap.data!;
              if (modules.isEmpty) {
                return EmptyState(
                  icon: Icons.view_module_rounded,
                  title: "Modullar yo'q",
                  subtitle:
                      "Digital SAT: Reading & Writing (2 modul, 32 daq) va Math (2 modul, 35 daq)",
                  action: ElevatedButton.icon(
                    onPressed: () => _createDefaults(context, modules),
                    icon: const Icon(Icons.auto_awesome_rounded),
                    label: const Text('Standart 4 modulni yaratish'),
                  ),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.only(bottom: 32),
                itemCount: modules.length + 1,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, i) {
                  if (i == modules.length) {
                    return Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () => _createDefaults(context, modules),
                        icon: const Icon(Icons.auto_awesome_rounded),
                        label: const Text("Yetishmayotgan standart modullarni qo'shish"),
                      ),
                    );
                  }
                  final m = modules[i];
                  final isRw = m.section == SatModule.rw;
                  final color = isRw ? AppColors.sky : AppColors.green;
                  final target = SatModule.defaultQuestionCount(m.section);
                  return AppCard(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => ModuleEditorScreen(module: m)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: color.withAlpha(36),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            isRw ? Icons.auto_stories_rounded : Icons.calculate_rounded,
                            color: color,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(m.label,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w800, fontSize: 16)),
                              if (m.title.isNotEmpty)
                                Text(m.title,
                                    style: const TextStyle(color: AppColors.muted)),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 8,
                                runSpacing: 6,
                                children: [
                                  Pill(
                                    '${m.questions.length} / $target savol',
                                    color: m.questions.length >= target
                                        ? AppColors.greenDark
                                        : AppColors.warning,
                                  ),
                                  Pill('${m.durationMin} daqiqa',
                                      icon: Icons.schedule_rounded),
                                ],
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: "O'chirish",
                          onPressed: () => _deleteModule(context, m),
                          icon: const Icon(Icons.delete_outline_rounded,
                              color: AppColors.danger),
                        ),
                        const Icon(Icons.chevron_right_rounded,
                            color: AppColors.muted),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}

Future<void> showModuleDialog(BuildContext context, {required String testId}) =>
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ModuleDialog(testId: testId),
    );

class _ModuleDialog extends StatefulWidget {
  const _ModuleDialog({required this.testId});

  final String testId;

  @override
  State<_ModuleDialog> createState() => _ModuleDialogState();
}

class _ModuleDialogState extends State<_ModuleDialog> {
  String _section = SatModule.rw;
  int _no = 1;
  late final TextEditingController _duration =
      TextEditingController(text: '${SatModule.defaultMinutes(SatModule.rw)}');
  bool _saving = false;

  @override
  void dispose() {
    _duration.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await repo.saveModule(SatModule(
        testId: widget.testId,
        section: _section,
        moduleNo: _no,
        durationMin: int.tryParse(_duration.text.trim()) ??
            SatModule.defaultMinutes(_section),
      ));
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() => _saving = false);
      toast("Saqlab bo'lmadi: $e", error: true);
    }
  }

  Widget _choice(String label, bool selected, VoidCallback onTap) => ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: AppColors.skyLight,
        labelStyle: TextStyle(
          fontWeight: FontWeight.w700,
          color: selected ? AppColors.skyDark : AppColors.ink,
        ),
        side: BorderSide(color: selected ? AppColors.sky : AppColors.line),
      );

  @override
  Widget build(BuildContext context) {
    return FormDialog(
      title: "Modul qo'shish",
      width: 460,
      saving: _saving,
      onSave: _save,
      onCancel: () => Navigator.pop(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          const Text('Bo\'lim', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              _choice('Reading & Writing', _section == SatModule.rw, () {
                setState(() {
                  _section = SatModule.rw;
                  _duration.text = '${SatModule.defaultMinutes(_section)}';
                });
              }),
              _choice('Math', _section == SatModule.math, () {
                setState(() {
                  _section = SatModule.math;
                  _duration.text = '${SatModule.defaultMinutes(_section)}';
                });
              }),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Modul raqami',
              style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              _choice('1-modul', _no == 1, () => setState(() => _no = 1)),
              _choice('2-modul', _no == 2, () => setState(() => _no = 2)),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _duration,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Davomiyligi (daqiqa)'),
          ),
        ],
      ),
    );
  }
}
