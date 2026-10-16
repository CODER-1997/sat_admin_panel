import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'constants/app_config.dart';
import 'constants/app_theme.dart';
import 'controllers/auth_controller.dart';
import 'firebase_options.dart';
import 'screens/auth_gate.dart';
import 'services/auth_service.dart';
import 'services/r2_storage.dart';
import 'services/repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Servislar va umumiy controllerlar: butun ilova bo'yicha bitta nusxa.
  Get.put(AuthService(), permanent: true);
  Get.put(SatRepository(), permanent: true);
  Get.put(R2Storage(baseUrl: kStorageUrl), permanent: true);
  Get.put(AuthController(), permanent: true);

  runApp(const AdminApp());
}

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'SAT Admin',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const AuthGate(),
    );
  }
}
