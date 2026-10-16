import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../constants/app_colors.dart';
import '../models/test_attempt.dart';
import '../utils/helpers.dart';
import '../widgets/app_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/page_header.dart';
import '../widgets/pill.dart';
import '../widgets/section_title.dart';
import '../widgets/stat_tile.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Future<List<int>> _counts;
  late Future<List<TestAttempt>> _attempts;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _counts = Future.wait([
      repo.count('users'),
      repo.count('courses'),
      repo.count('lessons'),
      repo.count('books'),
      repo.count('tests'),
    ]);
    _attempts = repo.recentAttempts(limit: 100);
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        PageHeader(
          title: 'Bosh sahifa',
          subtitle: "Platformadagi umumiy ko'rsatkichlar",
          actions: [
            OutlinedButton.icon(
              onPressed: () => setState(_load),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Yangilash'),
            ),
          ],
        ),
        FutureBuilder<List<int>>(
          future: _counts,
          builder: (context, snap) {
            final v = snap.data;
            String f(int i) => v == null ? '…' : '${v[i]}';
            final tiles = [
              StatTile(
                  icon: Icons.groups_rounded,
                  label: 'Foydalanuvchilar',
                  value: f(0)),
              StatTile(
                  icon: Icons.folder_copy_rounded,
                  label: 'Kurslar',
                  value: f(1),
                  color: AppColors.green),
              StatTile(
                  icon: Icons.play_circle_rounded,
                  label: 'Video darslar',
                  value: f(2)),
              StatTile(
                  icon: Icons.menu_book_rounded,
                  label: 'Kitoblar',
                  value: f(3),
                  color: AppColors.green),
              StatTile(
                  icon: Icons.quiz_rounded,
                  label: 'SAT testlar',
                  value: f(4)),
            ];
            return LayoutBuilder(builder: (context, c) {
              final cols = c.maxWidth >= 1000 ? 3 : (c.maxWidth >= 640 ? 2 : 1);
              final w = (c.maxWidth - (cols - 1) * 16) / cols;
              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [for (final t in tiles) SizedBox(width: w, child: t)],
              );
            });
          },
        ),
        const SizedBox(height: 28),
        const SectionTitle("So'nggi test natijalari"),
        const SizedBox(height: 12),
        FutureBuilder<List<TestAttempt>>(
          future: _attempts,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (snap.hasError) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Natijalarni yuklab bo\'lmadi: ${snap.error}',
                    style: const TextStyle(color: AppColors.danger)),
              );
            }
            final list = snap.data ?? [];
            if (list.isEmpty) {
              return const AppCard(
                child: EmptyState(
                  icon: Icons.insights_rounded,
                  title: "Hozircha natijalar yo'q",
                  subtitle: 'Talabalar test yechgach, shu yerda ko\'rinadi',
                ),
              );
            }
            final fmt = DateFormat('dd.MM.yyyy HH:mm');
            return AppCard(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: [
                  for (final a in list.take(12))
                    ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.skyLight,
                        child: Text(
                          (a.userName.isEmpty ? '?' : a.userName[0]).toUpperCase(),
                          style: const TextStyle(
                              color: AppColors.skyDark,
                              fontWeight: FontWeight.w800),
                        ),
                      ),
                      title: Text(
                        a.userName.isEmpty ? 'Talaba' : a.userName,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text('${a.testTitle} · ${fmt.format(a.finishedAt)}'),
                      trailing: a.totalScore != null
                          ? Pill('${a.totalScore} / 1600', color: AppColors.green)
                          : Pill('${a.correct}/${a.total}'),
                    ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}
