import 'package:get/get.dart';
import 'package:mymanager/screen/habit_detail/habit_detail_controller.dart';

class HabitDetailBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<HabitDetailController>(() => HabitDetailController());
  }
}
