import 'package:get/get.dart';
import 'package:mymanager/core/models/sub_task.dart';
import 'package:mymanager/core/models/task_model.dart';
import 'package:mymanager/services/tasks_services/task_storage_service.dart';

class TaskController extends GetxController {
  final TaskStorageService _service = Get.find<TaskStorageService>();

  RxList<Task> get tasks => _service.tasks;

  Future<void> addSample() async {
    await _service.createTaskFrom(
      taskName: 'New Task ${DateTime.now().millisecondsSinceEpoch}',
      taskDate: DateTime.now().toIso8601String().split('T').first,
      taskTime: '${DateTime.now().hour}:${DateTime.now().minute}',
      isTaskAlert: true,
      taskStatus: 'pending',
      subTasks: [
        SubTask(id: 's1', name: 'sub 1'),
        SubTask(id: 's2', name: 'sub 2'),
      ],
    );
  }

  Future<void> deleteTask(String id) => _service.deleteTask(id);
  Future<void> updateTask(String id, Task updated) =>
      _service.updateTask(id, updated);
}
