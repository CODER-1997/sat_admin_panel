import 'package:get/get.dart';

import '../services/auth_service.dart';

/// Login ekrani holati: yuklanmoqda va xatolik matni.
class AuthController extends GetxController {
  final _auth = Get.find<AuthService>();

  final isLoading = false.obs;
  final error = ''.obs; // bo'sh = xatolik yo'q

  Future<void> signIn(String email, String password) async {
    isLoading.value = true;
    error.value = '';
    try {
      await _auth.signIn(email, password);
      // Keyingi ekranga AuthGate o'zi o'tkazadi.
    } catch (e) {
      error.value = AuthService.message(e);
    } finally {
      isLoading.value = false;
    }
  }

  void signOut() => _auth.signOut();
}
