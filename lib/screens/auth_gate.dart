import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/auth_controller.dart';
import '../models/app_user.dart';
import '../services/auth_service.dart';
import '../widgets/empty_state.dart';
import 'login_screen.dart';
import 'main_screen.dart';

/// Kirmagan bo'lsa -> Login; kirgan bo'lsa va role == admin -> panel.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthService>();
    return StreamBuilder<User?>(
      stream: auth.authChanges,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final user = snap.data;
        if (user == null) return const LoginScreen();
        return FutureBuilder<AppUser?>(
          key: ValueKey(user.uid),
          future: auth.fetchUser(user.uid),
          builder: (context, us) {
            if (us.connectionState != ConnectionState.done) {
              return const Scaffold(
                  body: Center(child: CircularProgressIndicator()));
            }
            final u = us.data;
            if (u != null && u.isAdmin) return MainScreen(user: u);
            return _NoAccess(email: user.email ?? '');
          },
        );
      },
    );
  }
}

class _NoAccess extends StatelessWidget {
  const _NoAccess({required this.email});

  final String email;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: EmptyState(
        icon: Icons.lock_outline,
        title: 'Bu akkaunt admin emas',
        subtitle:
            "$email uchun admin huquqi berilmagan.\nFirestore'da users/{uid} hujjatida role = \"admin\" qiling.",
        action: ElevatedButton(
          onPressed: () => Get.find<AuthController>().signOut(),
          child: const Text('Chiqish'),
        ),
      ),
    );
  }
}
