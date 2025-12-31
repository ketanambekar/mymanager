import 'package:get/get.dart';
import 'package:mymanager/database/apis/task_api.dart';
import 'package:mymanager/database/tables/tasks/models/task_model.dart';
import 'dart:developer' as developer;

class CalenderController extends GetxController {
  final Rx<DateTime> selectedDay = DateTime.now().obs;
  final Rx<DateTime> focusedDay = DateTime.now().obs;
  final RxList<Task> allTasks = <Task>[].obs;
  
  @override
  void onInit() {
    super.onInit();
    loadTasks();
  }

  Future<void> loadTasks() async {
    try {
      final tasks = await TaskApi.getTasks();
      allTasks.value = tasks;
    } catch (e) {
      developer.log('Error loading tasks: \$e', name: 'CalenderController');
    }
  }

  void selectDay(DateTime selectedDay, DateTime focusedDay) {
    this.selectedDay.value = selectedDay;
    this.focusedDay.value = focusedDay;
  }

  List<Task> get tasksForSelectedDay {
    final selected = DateTime(
      selectedDay.value.year,
      selectedDay.value.month,
      selectedDay.value.day,
    );
    
    return allTasks.where((task) {
      if (task.taskDueDate == null) return false;
      final dueDate = DateTime.parse(task.taskDueDate!);
      final dueDateOnly = DateTime(dueDate.year, dueDate.month, dueDate.day);
      return dueDateOnly.isAtSameMomentAs(selected);
    }).toList();
  }
}
