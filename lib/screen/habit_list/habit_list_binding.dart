import 'package:get/get.dart';
import 'package:mymanager/screen/habit_list/habit_list_controller.dart';

class HabitListBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<HabitListController>(() => HabitListController());
  }
}
