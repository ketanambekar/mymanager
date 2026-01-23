import 'package:get/get.dart';
import 'package:mymanager/screen/create_edit_habit/create_edit_habit_controller.dart';

class CreateEditHabitBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CreateEditHabitController>(() => CreateEditHabitController());
  }
}
