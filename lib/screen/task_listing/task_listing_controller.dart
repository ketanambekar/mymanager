import 'package:get/get.dart';
import 'package:mymanager/database/apis/task_api.dart';
import 'package:mymanager/database/tables/tasks/models/task_model.dart';

class TaskListingController extends GetxController {
  final RxList<Task> tasks = <Task>[].obs;
  final RxBool isLoading = false.obs;
  final RxString selectedFilter = 'All'.obs;

  @override
  void onInit() {
    super.onInit();
    loadTasks();
  }

  Future<void> loadTasks() async {
    isLoading.value = true;
    try {
      final allTasks = await TaskApi.getTasks(includeCompleted: true);
      tasks.value = allTasks;
    } catch (e) {
      print('Error loading tasks: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void setFilter(String filter) {
    selectedFilter.value = filter;
  }

  List<Task> get filteredTasks {
    if (selectedFilter.value == 'All') {
      return tasks;
    }
    return tasks.where((task) => task.taskStatus == selectedFilter.value).toList();
  }
}
