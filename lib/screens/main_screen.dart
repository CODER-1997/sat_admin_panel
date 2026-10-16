import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../constants/app_colors.dart';
import '../controllers/auth_controller.dart';
import '../controllers/nav_controller.dart';
import '../models/app_user.dart';
import 'books_screen.dart';
import 'courses_screen.dart';
import 'dashboard_screen.dart';
import 'students_screen.dart';
import 'tests_screen.dart';

class _NavItem {
  const _NavItem(this.label, this.icon, this.builder);

  final String label;
  final IconData icon;
  final Widget Function() builder;
}

/// Chap tomonda yon panel, o'ngda sahifa. Tor ekranlarda drawer.
class MainScreen extends StatefulWidget {
  const MainScreen({super.key, required this.user});

  final AppUser user;

  static final List<_NavItem> _items = [
    _NavItem('Bosh sahifa', Icons.space_dashboard_rounded,
            () => const DashboardScreen()),
    _NavItem('Kurslar va videolar', Icons.play_circle_rounded,
            () => const CoursesScreen()),
    _NavItem('Kitoblar', Icons.menu_book_rounded, () => const BooksScreen()),
    _NavItem('SAT testlar', Icons.quiz_rounded, () => const TestsScreen()),
    _NavItem('Talabalar', Icons.groups_rounded, () => const StudentsScreen()),
  ];

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late final NavController _nav;

  @override
  void initState() {
    super.initState();
    _nav = Get.put(NavController());
  }

  @override
  void dispose() {
    Get.delete<NavController>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final wide = c.maxWidth >= 960;
        final sidebar = _Sidebar(
          user: widget.user,
          nav: _nav,
          onSelect: (i) {
            _nav.go(i);
            if (!wide) Navigator.of(context).maybePop();
          },
        );
        final content = Obx(() => Padding(
          padding: EdgeInsets.fromLTRB(wide ? 32 : 16, 24, wide ? 32 : 16, 0),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1180),
              child: KeyedSubtree(
                key: ValueKey(_nav.index.value),
                child: MainScreen._items[_nav.index.value].builder(),
              ),
            ),
          ),
        ));

        if (wide) {
          return Scaffold(
            body: Row(
              children: [
                SizedBox(width: 280, child: sidebar),
                Expanded(child: content),
              ],
            ),
          );
        }
        return Scaffold(
          appBar: AppBar(
            title: Obx(() => Text(MainScreen._items[_nav.index.value].label)),
          ),
          drawer: Drawer(child: sidebar),
          body: content,
        );
      },
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.user,
    required this.nav,
    required this.onSelect,
  });

  final AppUser user;
  final NavController nav;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0EA5E9), Color(0xFF0284C7)],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.school_rounded,
                        color: AppColors.sky, size: 26),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('SAT Platform',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 17)),
                      Text('Admin panel',
                          style: TextStyle(color: Colors.white70, fontSize: 13)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Expanded(
                // Tanlangan bo'lim Obx ichida (itemBuilder dan tashqarida) o'qiladi,
                // aks holda GetX "improper use of GetX" xatosini beradi.
                child: Obx(() {
                  final current = nav.index.value;
                  return ListView.separated(
                    itemCount: MainScreen._items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 6),
                    itemBuilder: (_, i) {
                      final it = MainScreen._items[i];
                      final selected = current == i;
                      return Material(
                        color: selected
                            ? Colors.white
                            : Colors.white.withAlpha(0),
                        borderRadius: BorderRadius.circular(14),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () => onSelect(i),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 13),
                            child: Row(
                              children: [
                                Icon(it.icon,
                                    color: selected
                                        ? AppColors.sky
                                        : Colors.white),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    it.label,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: selected
                                          ? AppColors.skyDark
                                          : Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                }),
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(41),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppColors.green,
                      child: Text(
                        (user.name.isNotEmpty ? user.name : user.email)
                            .padRight(1, 'A')
                            .substring(0, 1)
                            .toUpperCase(),
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w800),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        user.name.isNotEmpty ? user.name : user.email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w700),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Chiqish',
                      onPressed: () => Get.find<AuthController>().signOut(),
                      icon: const Icon(Icons.logout_rounded, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}