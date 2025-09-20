import 'package:get/get.dart';
import 'package:mymanager/widgets/bottom_nav/bottom_nav_controller.dart';

class BottomNavBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<BottomNavController>(() => BottomNavController());
  }
}
