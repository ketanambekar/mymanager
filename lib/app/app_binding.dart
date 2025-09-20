import 'package:get/get.dart';
import 'package:mymanager/app/app_controller.dart';
import 'package:mymanager/services/tasks_services/task_controller.dart';
import 'package:mymanager/services/tasks_services/task_storage_service.dart';

class AppBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AppController>(() => AppController());
    final svc = TaskStorageService();
    Get.putAsync<TaskStorageService>(() => svc.init());
    Get.lazyPut<TaskController>(() => TaskController());
  }
}
