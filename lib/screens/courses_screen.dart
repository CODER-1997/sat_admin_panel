import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../models/course.dart';
import '../utils/helpers.dart';
import '../widgets/app_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/form_dialog.dart';
import '../widgets/page_header.dart';
import '../widgets/pill.dart';
import '../widgets/r2_image.dart';
import '../widgets/switch_row.dart';
import '../widgets/upload_field.dart';
import 'lessons_screen.dart';

class CoursesScreen extends StatelessWidget {
  const CoursesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHeader(
          title: 'Kurslar va videolar',
          subtitle: "Kurs yarating, ichiga video darslarni yuklang",
          actions: [
            ElevatedButton.icon(
              onPressed: () => showCourseDialog(context),
              icon: const Icon(Icons.add_rounded),
              label: const Text("Kurs qo'shish"),
            ),
          ],
        ),
        Expanded(
          child: StreamBuilder<List<Course>>(
            stream: repo.watchCourses(),
            builder: (context, snap) {
              if (snap.hasError) {
                return Center(child: Text('Xatolik: ${snap.error}'));
              }
              if (!snap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final list = snap.data!;
              if (list.isEmpty) {
                return EmptyState(
                  icon: Icons.folder_copy_rounded,
                  title: "Hali kurs yo'q",
                  subtitle: "Birinchi kursni yarating, so'ng unga videolar qo'shing",
                  action: ElevatedButton.icon(
                    onPressed: () => showCourseDialog(context),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text("Kurs qo'shish"),
                  ),
                );
              }
              return LayoutBuilder(builder: (context, c) {
                final cols = c.maxWidth >= 1000 ? 3 : (c.maxWidth >= 640 ? 2 : 1);
                return GridView.builder(
                  padding: const EdgeInsets.only(bottom: 32),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: cols,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    mainAxisExtent: 330,
                  ),
                  itemCount: list.length,
                  itemBuilder: (_, i) => _CourseCard(course: list[i]),
                );
              });
            },
          ),
        ),
      ],
    );
  }
}

class _CourseCard extends StatelessWidget {
  const _CourseCard({required this.course});

  final Course course;

  Future<void> _delete(BuildContext context) async {
    final ok = await confirmDialog(
      context,
      title: "Kursni o'chirish",
      message:
          "\"${course.title}\" kursi va uning barcha darslari (videolari bilan) o'chiriladi. Davom etasizmi?",
    );
    if (!ok) return;
    try {
      final keys = await repo.deleteCourse(course.id);
      for (final k in keys) {
        await r2.deleteQuiet(k);
      }
      toast("Kurs o'chirildi");
    } catch (e) {
      toast('Xatolik: $e', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => LessonsScreen(course: course)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              R2Image(
                keyPath: course.coverKey,
                height: 150,
                width: double.infinity,
                icon: Icons.play_circle_outline_rounded,
              ),
              Positioned(
                left: 12,
                top: 12,
                child: course.published
                    ? const Pill("E'lon qilingan", color: AppColors.greenDark)
                    : const Pill('Qoralama', color: AppColors.warning),
              ),
            ],
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    course.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 17),
                  ),
                  const SizedBox(height: 4),
                  Expanded(
                    child: Text(
                      course.description.isEmpty
                          ? "Tavsif yo'q"
                          : course.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppColors.muted),
                    ),
                  ),
                  Row(
                    children: [
                      Text('Tartib: ${course.order}',
                          style: const TextStyle(
                              color: AppColors.muted, fontSize: 13)),
                      const Spacer(),
                      IconButton(
                        tooltip: 'Tahrirlash',
                        onPressed: () => showCourseDialog(context, course: course),
                        icon: const Icon(Icons.edit_rounded),
                      ),
                      IconButton(
                        tooltip: "O'chirish",
                        onPressed: () => _delete(context),
                        icon: const Icon(Icons.delete_outline_rounded,
                            color: AppColors.danger),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> showCourseDialog(BuildContext context, {Course? course}) =>
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _CourseDialog(course: course),
    );

class _CourseDialog extends StatefulWidget {
  const _CourseDialog({this.course});

  final Course? course;

  @override
  State<_CourseDialog> createState() => _CourseDialogState();
}

class _CourseDialogState extends State<_CourseDialog> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _title =
      TextEditingController(text: widget.course?.title);
  late final TextEditingController _desc =
      TextEditingController(text: widget.course?.description);
  late final TextEditingController _order =
      TextEditingController(text: '${widget.course?.order ?? 0}');
  late String? _cover = widget.course?.coverKey;
  late final String? _initialCover = widget.course?.coverKey;
  late bool _published = widget.course?.published ?? true;
  bool _saving = false;
  bool _uploading = false;

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    _order.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    if (_uploading) {
      toast('Rasm yuklanishi tugashini kuting');
      return;
    }
    setState(() => _saving = true);
    try {
      await repo.saveCourse(Course(
        id: widget.course?.id ?? '',
        title: _title.text.trim(),
        description: _desc.text.trim(),
        coverKey: _cover,
        published: _published,
        order: int.tryParse(_order.text.trim()) ?? 0,
      ));
      if (_initialCover != null && _initialCover != _cover) {
        await r2.deleteQuiet(_initialCover);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() => _saving = false);
      toast('Saqlab bo\'lmadi: $e', error: true);
    }
  }

  Future<void> _cancel() async {
    if (_cover != null && _cover != _initialCover) {
      await r2.deleteQuiet(_cover);
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return FormDialog(
      title: widget.course == null ? "Yangi kurs" : 'Kursni tahrirlash',
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
              decoration: const InputDecoration(labelText: 'Kurs nomi'),
              validator: requiredValidator,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _desc,
              minLines: 3,
              maxLines: 5,
              decoration: const InputDecoration(labelText: 'Tavsif'),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _order,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Tartib raqami',
                helperText: 'Kichik raqam ro\'yxatda yuqorida chiqadi',
              ),
            ),
            const SizedBox(height: 14),
            UploadField(
              label: 'Muqova rasmi',
              folder: 'public/covers',
              type: FileType.image,
              isImage: true,
              icon: Icons.image_outlined,
              initialKey: _cover,
              onChanged: (k) => setState(() => _cover = k),
              onBusyChanged: (b) {
                if (mounted) setState(() => _uploading = b);
              },
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
