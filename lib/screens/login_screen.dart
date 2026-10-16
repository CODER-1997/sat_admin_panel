import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../constants/app_colors.dart';
import '../controllers/auth_controller.dart';
import '../widgets/error_box.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _auth = Get.find<AuthController>();
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_form.currentState!.validate()) return;
    _auth.signIn(_email.text, _password.text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, c) {
          final wide = c.maxWidth >= 900;
          return Row(
            children: [
              if (wide) const Expanded(child: _Hero()),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(28),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: Form(
                        key: _form,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!wide) ...[
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  gradient: AppColors.heroGradient,
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: const Icon(Icons.school_rounded,
                                    color: Colors.white, size: 30),
                              ),
                              const SizedBox(height: 20),
                            ],
                            Text(
                              'Xush kelibsiz 👋',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineMedium
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Admin panelga kirish uchun akkauntingizni kiriting',
                              style: TextStyle(color: AppColors.muted),
                            ),
                            const SizedBox(height: 28),
                            TextFormField(
                              controller: _email,
                              keyboardType: TextInputType.emailAddress,
                              autofillHints: const [AutofillHints.email],
                              decoration: const InputDecoration(
                                labelText: 'Email',
                                prefixIcon: Icon(Icons.alternate_email_rounded),
                              ),
                              validator: (v) =>
                                  (v == null || !v.contains('@')) ? "Email noto'g'ri" : null,
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _password,
                              obscureText: _obscure,
                              autofillHints: const [AutofillHints.password],
                              onFieldSubmitted: (_) => _submit(),
                              decoration: InputDecoration(
                                labelText: 'Parol',
                                prefixIcon: const Icon(Icons.lock_outline_rounded),
                                suffixIcon: IconButton(
                                  onPressed: () =>
                                      setState(() => _obscure = !_obscure),
                                  icon: Icon(_obscure
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined),
                                ),
                              ),
                              validator: (v) => (v == null || v.length < 6)
                                  ? 'Kamida 6 ta belgi'
                                  : null,
                            ),
                            Obx(() => _auth.error.value.isEmpty
                                ? const SizedBox.shrink()
                                : Padding(
                                    padding: const EdgeInsets.only(top: 14),
                                    child: ErrorBox(_auth.error.value),
                                  )),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              child: Obx(() => ElevatedButton(
                                    onPressed:
                                        _auth.isLoading.value ? null : _submit,
                                    child: _auth.isLoading.value
                                        ? const SizedBox(
                                            width: 22,
                                            height: 22,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.4,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Text('Kirish'),
                                  )),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.heroGradient),
      child: Stack(
        children: [
          Positioned(
            right: -80,
            top: -60,
            child: _Bubble(size: 260, alpha: 0.12),
          ),
          Positioned(
            left: -60,
            bottom: -80,
            child: _Bubble(size: 300, alpha: 0.10),
          ),
          Positioned(
            right: 70,
            bottom: 120,
            child: _Bubble(size: 90, alpha: 0.18, color: AppColors.green),
          ),
          Padding(
            padding: const EdgeInsets.all(56),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.school_rounded,
                      color: AppColors.sky, size: 36),
                ),
                const SizedBox(height: 28),
                const Text(
                  'SAT tayyorlov\nplatformasi',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 44,
                    height: 1.1,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  "Video darslar, kitoblar va haqiqiy SAT formatidagi testlarni bitta joydan boshqaring.",
                  style: TextStyle(color: Colors.white, fontSize: 17, height: 1.5),
                ),
                const SizedBox(height: 28),
                const Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _Chip(Icons.play_circle_rounded, 'Video darslar'),
                    _Chip(Icons.menu_book_rounded, 'PDF kitoblar'),
                    _Chip(Icons.quiz_rounded, 'SAT testlar'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.size, required this.alpha, this.color = Colors.white});

  final double size;
  final double alpha;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withAlpha((alpha * 255).round()),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(this.icon, this.text);

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(51),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 6),
          Text(text,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
