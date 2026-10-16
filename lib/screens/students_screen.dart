import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../constants/app_colors.dart';
import '../models/app_user.dart';
import '../models/test_attempt.dart';
import '../utils/helpers.dart';
import '../widgets/app_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/page_header.dart';
import '../widgets/pill.dart';

class StudentsScreen extends StatefulWidget {
  const StudentsScreen({super.key});

  @override
  State<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends State<StudentsScreen> {
  String _query = '';
  late Future<List<TestAttempt>> _attempts = repo.recentAttempts(limit: 500);

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd.MM.yyyy');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHeader(
          title: 'Talabalar',
          subtitle: "Ro'yxatdan o'tgan talabalar va ularning natijalari",
          actions: [
            SizedBox(
              width: 260,
              child: TextField(
                onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
                decoration: const InputDecoration(
                  hintText: 'Qidirish…',
                  prefixIcon: Icon(Icons.search_rounded),
                  isDense: true,
                ),
              ),
            ),
            IconButton.filledTonal(
              tooltip: 'Natijalarni yangilash',
              onPressed: () =>
                  setState(() => _attempts = repo.recentAttempts(limit: 500)),
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
        Expanded(
          child: StreamBuilder<List<AppUser>>(
            stream: repo.watchStudents(),
            builder: (context, snap) {
              if (snap.hasError) return Center(child: Text('Xatolik: ${snap.error}'));
              if (!snap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final all = snap.data!;
              final list = _query.isEmpty
                  ? all
                  : all
                      .where((u) =>
                          u.name.toLowerCase().contains(_query) ||
                          u.email.toLowerCase().contains(_query))
                      .toList();
              if (list.isEmpty) {
                return const EmptyState(
                  icon: Icons.groups_rounded,
                  title: "Talabalar topilmadi",
                  subtitle: "Talabalar ilovadan ro'yxatdan o'tgach shu yerda ko'rinadi",
                );
              }
              return FutureBuilder<List<TestAttempt>>(
                future: _attempts,
                builder: (context, asnap) {
                  final byUser = <String, List<TestAttempt>>{};
                  for (final a in asnap.data ?? const <TestAttempt>[]) {
                    byUser.putIfAbsent(a.uid, () => []).add(a);
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.only(bottom: 32),
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      final u = list[i];
                      final attempts = byUser[u.uid] ?? const <TestAttempt>[];
                      final best = attempts
                          .map((a) => a.totalScore)
                          .whereType<int>()
                          .fold<int?>(null, (p, e) => p == null || e > p ? e : p);
                      return AppCard(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundColor: AppColors.skyLight,
                              child: Text(
                                (u.name.isEmpty ? u.email : u.name)
                                    .padRight(1, '?')
                                    .substring(0, 1)
                                    .toUpperCase(),
                                style: const TextStyle(
                                    color: AppColors.skyDark,
                                    fontWeight: FontWeight.w800),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(u.name.isEmpty ? '(ismsiz)' : u.name,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w800)),
                                  Text(u.email,
                                      style: const TextStyle(
                                          color: AppColors.muted, fontSize: 13)),
                                ],
                              ),
                            ),
                            Wrap(
                              spacing: 8,
                              children: [
                                if (u.createdAt != null)
                                  Pill(fmt.format(u.createdAt!),
                                      icon: Icons.event_rounded),
                                Pill('${attempts.length} ta test',
                                    color: AppColors.greenDark),
                                if (best != null)
                                  Pill('Eng yaxshi: $best',
                                      color: AppColors.skyDark,
                                      icon: Icons.emoji_events_rounded),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
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
