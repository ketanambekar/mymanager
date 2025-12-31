import 'package:get/get.dart';
import 'package:mymanager/database/apis/task_api.dart';
import 'package:mymanager/database/tables/tasks/models/task_model.dart';
import 'dart:developer' as developer;

class TaskGroupDetailController extends GetxController {
  final String projectId;
  final RxList<Task> tasks = <Task>[].obs;
  final RxBool isLoading = false.obs;
  final RxMap<String, List<Task>> subtasksMap = <String, List<Task>>{}.obs;
  final RxSet<String> expandedTasks = <String>{}.obs;

  TaskGroupDetailController({required this.projectId});

  @override
  void onInit() {
    super.onInit();
    loadTasks();
  }

  Future<void> loadTasks() async {
    try {
      isLoading.value = true;
      final projectTasks = await TaskApi.getTasks(projectId: projectId);
      
      // Sort by due date (oldest first), then by status
      projectTasks.sort((a, b) {
        // Completed tasks go to bottom
        if (a.taskStatus == 'Completed' && b.taskStatus != 'Completed') return 1;
        if (a.taskStatus != 'Completed' && b.taskStatus == 'Completed') return -1;
        
        // Sort by due date
        if (a.taskDueDate == null && b.taskDueDate == null) return 0;
        if (a.taskDueDate == null) return 1;
        if (b.taskDueDate == null) return -1;
        return DateTime.parse(a.taskDueDate!).compareTo(DateTime.parse(b.taskDueDate!));
      });
      
      tasks.value = projectTasks;
      
      // Load subtasks for all tasks
      await _loadSubtasks(projectTasks);
      
      developer.log('Loaded ${projectTasks.length} tasks for project $projectId', 
          name: 'TaskGroupDetailController');
    } catch (e) {
      developer.log('Error loading tasks: $e', name: 'TaskGroupDetailController');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadSubtasks(List<Task> taskList) async {
    try {
      for (final task in taskList) {
        final subs = await TaskApi.getSubTasks(task.taskId);
        if (subs.isNotEmpty) {
          subtasksMap[task.taskId] = subs;
        }
      }
    } catch (e) {
      developer.log('Error loading subtasks: $e', name: 'TaskGroupDetailController');
    }
  }

  void toggleTaskExpansion(String taskId) {
    if (expandedTasks.contains(taskId)) {
      expandedTasks.remove(taskId);
    } else {
      expandedTasks.add(taskId);
    }
  }

  bool isTaskExpanded(String taskId) {
    return expandedTasks.contains(taskId);
  }

  Future<void> changeTaskStatus(Task task, String newStatus) async {
    try {
      final updatedTask = Task(
        taskId: task.taskId,
        taskTitle: task.taskTitle,
        taskDescription: task.taskDescription,
        taskDueDate: task.taskDueDate,
        taskStatus: newStatus,
        taskPriority: task.taskPriority,
        taskUrgency: task.taskUrgency,
        taskImportance: task.taskImportance,
        projectId: task.projectId,
        taskFrequency: task.taskFrequency,
        taskFrequencyValue: task.taskFrequencyValue,
        timeEstimate: task.timeEstimate,
        energyLevel: task.energyLevel,
        focusRequired: task.focusRequired,
        enableAlerts: task.enableAlerts,
        isRecurring: task.isRecurring,
      );
      
      await TaskApi.updateTask(task.taskId, updatedTask);
      await loadTasks();
      
      Get.snackbar(
        'Success',
        'Task status updated to $newStatus',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      developer.log('Error updating task status: $e', name: 'TaskGroupDetailController');
      Get.snackbar(
        'Error',
        'Failed to update task status',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> toggleSubtaskStatus(Task subtask) async {
    try {
      final newStatus = subtask.taskStatus == 'Completed' ? 'Todo' : 'Completed';
      final updatedSubtask = Task(
        taskId: subtask.taskId,
        taskTitle: subtask.taskTitle,
        taskDescription: subtask.taskDescription,
        taskDueDate: subtask.taskDueDate,
        taskStatus: newStatus,
        taskPriority: subtask.taskPriority,
        taskUrgency: subtask.taskUrgency,
        taskImportance: subtask.taskImportance,
        projectId: subtask.projectId,
        parentTaskId: subtask.parentTaskId,
      );
      
      await TaskApi.updateTask(subtask.taskId, updatedSubtask);
      await loadTasks();
    } catch (e) {
      developer.log('Error toggling subtask: $e', name: 'TaskGroupDetailController');
    }
  }
}
