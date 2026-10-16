import 'package:get/get.dart';

/// Yon paneldagi tanlangan bo'lim (0 = Bosh sahifa, 1 = Kurslar, ...).
class NavController extends GetxController {
  final index = 0.obs;

  void go(int i) => index.value = i;
}
