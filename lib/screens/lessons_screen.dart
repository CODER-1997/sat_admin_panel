import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../models/course.dart';
import '../models/lesson.dart';
import '../utils/helpers.dart';
import '../widgets/app_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/form_dialog.dart';
import '../widgets/pill.dart';
import '../widgets/sub_screen.dart';
import '../widgets/switch_row.dart';
import '../widgets/upload_field.dart';

class LessonsScreen extends StatelessWidget {
  const LessonsScreen({super.key, required this.course});

  final Course course;

  Future<void> _delete(BuildContext context, Lesson l) async {
    final ok = await confirmDialog(
      context,
      title: "Darsni o'chirish",
      message: "\"${l.title}\" darsi va uning videosi o'chiriladi.",
    );
    if (!ok) return;
    try {
      final key = await repo.deleteLesson(l.id);
      await r2.deleteQuiet(key);
      toast("Dars o'chirildi");
    } catch (e) {
      toast('Xatolik: $e', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SubScreen(
      title: course.title,
      subtitle: 'Video darslar',
      actions: [
        ElevatedButton.icon(
          onPressed: () => showLessonDialog(context, courseId: course.id),
          icon: const Icon(Icons.add_rounded),
          label: const Text("Dars qo'shish"),
        ),
      ],
      child: StreamBuilder<List<Lesson>>(
        stream: repo.watchLessons(course.id),
        builder: (context, snap) {
          if (snap.hasError) return Center(child: Text('Xatolik: ${snap.error}'));
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final list = snap.data!;
          if (list.isEmpty) {
            return EmptyState(
              icon: Icons.play_circle_outline_rounded,
              title: "Bu kursda hali dars yo'q",
              subtitle: "Video faylni yuklab, birinchi darsni qo'shing",
              action: ElevatedButton.icon(
                onPressed: () => showLessonDialog(context, courseId: course.id),
                icon: const Icon(Icons.add_rounded),
                label: const Text("Dars qo'shish"),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.only(bottom: 32),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) {
              final l = list[i];
              return AppCard(
                child: Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        gradient: AppColors.skyGradient,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        '${i + 1}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 17),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l.title,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800, fontSize: 16)),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              if (l.durationMin > 0)
                                Pill('${l.durationMin} daqiqa',
                                    icon: Icons.schedule_rounded),
                              l.videoKey == null
                                  ? const Pill('Video yo\'q',
                                      color: AppColors.danger,
                                      icon: Icons.videocam_off_rounded)
                                  : const Pill('Video bor',
                                      color: AppColors.greenDark,
                                      icon: Icons.videocam_rounded),
                              l.published
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
                      tooltip: 'Tahrirlash',
                      onPressed: () => showLessonDialog(context,
                          courseId: course.id, lesson: l),
                      icon: const Icon(Icons.edit_rounded),
                    ),
                    IconButton(
                      tooltip: "O'chirish",
                      onPressed: () => _delete(context, l),
                      icon: const Icon(Icons.delete_outline_rounded,
                          color: AppColors.danger),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

Future<void> showLessonDialog(
  BuildContext context, {
  required String courseId,
  Lesson? lesson,
}) =>
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _LessonDialog(courseId: courseId, lesson: lesson),
    );

class _LessonDialog extends StatefulWidget {
  const _LessonDialog({required this.courseId, this.lesson});

  final String courseId;
  final Lesson? lesson;

  @override
  State<_LessonDialog> createState() => _LessonDialogState();
}

class _LessonDialogState extends State<_LessonDialog> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _title =
      TextEditingController(text: widget.lesson?.title);
  late final TextEditingController _desc =
      TextEditingController(text: widget.lesson?.description);
  late final TextEditingController _order =
      TextEditingController(text: '${widget.lesson?.order ?? 0}');
  late final TextEditingController _duration =
      TextEditingController(text: '${widget.lesson?.durationMin ?? 0}');
  late String? _video = widget.lesson?.videoKey;
  late final String? _initialVideo = widget.lesson?.videoKey;
  late bool _published = widget.lesson?.published ?? true;
  bool _saving = false;
  bool _uploading = false;

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    _order.dispose();
    _duration.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await repo.saveLesson(Lesson(
        id: widget.lesson?.id ?? '',
        courseId: widget.courseId,
        title: _title.text.trim(),
        description: _desc.text.trim(),
        videoKey: _video,
        durationMin: int.tryParse(_duration.text.trim()) ?? 0,
        order: int.tryParse(_order.text.trim()) ?? 0,
        published: _published,
      ));
      if (_initialVideo != null && _initialVideo != _video) {
        await r2.deleteQuiet(_initialVideo);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() => _saving = false);
      toast("Saqlab bo'lmadi: $e", error: true);
    }
  }

  Future<void> _cancel() async {
    if (_video != null && _video != _initialVideo) {
      await r2.deleteQuiet(_video);
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return FormDialog(
      title: widget.lesson == null ? 'Yangi dars' : 'Darsni tahrirlash',
      saving: _saving || _uploading,
      onSave: _save,
      onCancel: _cancel,
      child: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            TextFormField(
              controller: _title,
              decoration: const InputDecoration(labelText: 'Dars nomi'),
              validator: requiredValidator,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _desc,
              minLines: 3,
              maxLines: 6,
              decoration: const InputDecoration(labelText: 'Tavsif / izohlar'),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _order,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Tartib'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _duration,
                    keyboardType: TextInputType.number,
                    decoration:
                        const InputDecoration(labelText: 'Davomiyligi (daqiqa)'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            UploadField(
              label: 'Video fayl',
              folder: 'videos',
              type: FileType.video,
              icon: Icons.video_file_outlined,
              initialKey: _video,
              onChanged: (k) => setState(() => _video = k),
              onBusyChanged: (b) {
                if (mounted) setState(() => _uploading = b);
              },
            ),
            const SizedBox(height: 6),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "MP4 (H.264) tavsiya etiladi. Katta videolar bo'laklab yuklanadi — oynani yopmang.",
                style: TextStyle(color: AppColors.muted, fontSize: 12.5),
              ),
            ),
            const SizedBox(height: 14),
            SwitchRow(
              label: "E'lon qilish",
              hint: "O'chiq bo'lsa talabalar ko'rmaydi",
              value: _published,
              onChanged: (v) => setState(() => _published = v),
            ),
          ],
        ),
      ),
    );
  }
}
