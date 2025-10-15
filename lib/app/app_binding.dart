import 'package:get/get.dart';
import 'package:mymanager/app/app_controller.dart';

class AppBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<AppController>(AppController());
  }
}
