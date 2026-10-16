import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../models/book.dart';
import '../utils/helpers.dart';
import '../widgets/app_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/form_dialog.dart';
import '../widgets/page_header.dart';
import '../widgets/pill.dart';
import '../widgets/r2_image.dart';
import '../widgets/switch_row.dart';
import '../widgets/upload_field.dart';

class BooksScreen extends StatelessWidget {
  const BooksScreen({super.key});

  Future<void> _delete(BuildContext context, Book b) async {
    final ok = await confirmDialog(
      context,
      title: "Kitobni o'chirish",
      message: "\"${b.title}\" kitobi va PDF fayli o'chiriladi.",
    );
    if (!ok) return;
    try {
      final keys = await repo.deleteBook(b.id);
      for (final k in keys) {
        await r2.deleteQuiet(k);
      }
      toast("Kitob o'chirildi");
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
          title: 'Kitoblar',
          subtitle: "PDF kitoblarni yuklang — talabalar ilovada o'qiydi",
          actions: [
            ElevatedButton.icon(
              onPressed: () => showBookDialog(context),
              icon: const Icon(Icons.add_rounded),
              label: const Text("Kitob qo'shish"),
            ),
          ],
        ),
        Expanded(
          child: StreamBuilder<List<Book>>(
            stream: repo.watchBooks(),
            builder: (context, snap) {
              if (snap.hasError) return Center(child: Text('Xatolik: ${snap.error}'));
              if (!snap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final list = snap.data!;
              if (list.isEmpty) {
                return EmptyState(
                  icon: Icons.menu_book_rounded,
                  title: "Hali kitob yo'q",
                  subtitle: 'Birinchi PDF kitobni yuklang',
                  action: ElevatedButton.icon(
                    onPressed: () => showBookDialog(context),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text("Kitob qo'shish"),
                  ),
                );
              }
              return LayoutBuilder(builder: (context, c) {
                final cols = c.maxWidth >= 1000 ? 4 : (c.maxWidth >= 700 ? 3 : 2);
                return GridView.builder(
                  padding: const EdgeInsets.only(bottom: 32),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: cols,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    mainAxisExtent: 400,
                  ),
                  itemCount: list.length,
                  itemBuilder: (_, i) {
                    final b = list[i];
                    return AppCard(
                      padding: EdgeInsets.zero,
                      onTap: () => showBookDialog(context, book: b),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Stack(
                            children: [
                              R2Image(
                                keyPath: b.coverKey,
                                height: 240,
                                width: double.infinity,
                                icon: Icons.menu_book_rounded,
                              ),
                              Positioned(
                                left: 10,
                                top: 10,
                                child: b.published
                                    ? const Pill("E'lon qilingan",
                                        color: AppColors.greenDark)
                                    : const Pill('Qoralama',
                                        color: AppColors.warning),
                              ),
                            ],
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(b.title,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w800)),
                                  Text(b.author.isEmpty ? '—' : b.author,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          color: AppColors.muted, fontSize: 13)),
                                  const Spacer(),
                                  Row(
                                    children: [
                                      b.pdfKey == null
                                          ? const Pill('PDF yo\'q',
                                              color: AppColors.danger)
                                          : const Pill('PDF bor',
                                              color: AppColors.greenDark,
                                              icon: Icons.picture_as_pdf_rounded),
                                      const Spacer(),
                                      IconButton(
                                        tooltip: "O'chirish",
                                        visualDensity: VisualDensity.compact,
                                        onPressed: () => _delete(context, b),
                                        icon: const Icon(
                                            Icons.delete_outline_rounded,
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
                  },
                );
              });
            },
          ),
        ),
      ],
    );
  }
}

Future<void> showBookDialog(BuildContext context, {Book? book}) =>
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _BookDialog(book: book),
    );

class _BookDialog extends StatefulWidget {
  const _BookDialog({this.book});

  final Book? book;

  @override
  State<_BookDialog> createState() => _BookDialogState();
}

class _BookDialogState extends State<_BookDialog> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _title =
      TextEditingController(text: widget.book?.title);
  late final TextEditingController _author =
      TextEditingController(text: widget.book?.author);
  late final TextEditingController _desc =
      TextEditingController(text: widget.book?.description);
  late String? _cover = widget.book?.coverKey;
  late String? _pdf = widget.book?.pdfKey;
  late final String? _initialCover = widget.book?.coverKey;
  late final String? _initialPdf = widget.book?.pdfKey;
  late bool _published = widget.book?.published ?? true;
  bool _saving = false;
  int _busyCount = 0;

  @override
  void dispose() {
    _title.dispose();
    _author.dispose();
    _desc.dispose();
    super.dispose();
  }

  void _busy(bool b) {
    if (!mounted) return;
    setState(() => _busyCount += b ? 1 : -1);
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    if (_pdf == null) {
      toast('PDF faylni yuklang', error: true);
      return;
    }
    setState(() => _saving = true);
    try {
      await repo.saveBook(Book(
        id: widget.book?.id ?? '',
        title: _title.text.trim(),
        author: _author.text.trim(),
        description: _desc.text.trim(),
        coverKey: _cover,
        pdfKey: _pdf,
        published: _published,
      ));
      if (_initialCover != null && _initialCover != _cover) {
        await r2.deleteQuiet(_initialCover);
      }
      if (_initialPdf != null && _initialPdf != _pdf) {
        await r2.deleteQuiet(_initialPdf);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() => _saving = false);
      toast("Saqlab bo'lmadi: $e", error: true);
    }
  }

  Future<void> _cancel() async {
    if (_cover != null && _cover != _initialCover) await r2.deleteQuiet(_cover);
    if (_pdf != null && _pdf != _initialPdf) await r2.deleteQuiet(_pdf);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return FormDialog(
      title: widget.book == null ? 'Yangi kitob' : 'Kitobni tahrirlash',
      saving: _saving || _busyCount > 0,
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
              decoration: const InputDecoration(labelText: 'Kitob nomi'),
              validator: requiredValidator,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _author,
              decoration: const InputDecoration(labelText: 'Muallif'),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _desc,
              minLines: 2,
              maxLines: 5,
              decoration: const InputDecoration(labelText: 'Tavsif'),
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
              onBusyChanged: _busy,
            ),
            const SizedBox(height: 12),
            UploadField(
              label: 'PDF fayl',
              folder: 'books',
              type: FileType.custom,
              extensions: const ['pdf'],
              icon: Icons.picture_as_pdf_outlined,
              initialKey: _pdf,
              onChanged: (k) => setState(() => _pdf = k),
              onBusyChanged: _busy,
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
