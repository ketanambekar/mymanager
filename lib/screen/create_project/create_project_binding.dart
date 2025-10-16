import 'package:get/get.dart';
import 'package:mymanager/screen/create_project/create_project_controller.dart';

class CreateProjectBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<CreateProjectController>(CreateProjectController());
  }
}
