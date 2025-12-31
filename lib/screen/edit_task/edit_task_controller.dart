import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mymanager/constants/app_constants.dart';
import 'package:mymanager/database/apis/task_api.dart';
import 'package:mymanager/database/apis/user_project_api.dart';
import 'package:mymanager/database/tables/tasks/models/task_model.dart';
import 'package:mymanager/database/tables/user_projects/models/user_project_model.dart';
import 'package:mymanager/screen/dashboard/dashboard_controller.dart';
import 'package:mymanager/screen/tasks/tasks_controller.dart';
import 'package:mymanager/services/notification_service.dart';

class EditTaskController extends GetxController {
  final Task task;
  
  EditTaskController({required this.task});

  final formKey = GlobalKey<FormState>();
  late final TextEditingController titleController;
  late final TextEditingController descriptionController;
  
  final selectedDate = Rxn<DateTime>();
  final selectedTime = Rxn<TimeOfDay>();
  final selectedProject = Rxn<UserProjects>();
  
  final urgency = AppConstants.urgencyMedium.obs;
  final importance = AppConstants.importanceMedium.obs;
  final selectedStatus = AppConstants.taskStatusTodo.obs;
  final frequency = AppConstants.frequencyOnce.obs;
  final energyLevel = AppConstants.energyMedium.obs;
  
  final enableAlerts = false.obs;
  final focusRequired = false.obs;
  final timeEstimate = Rxn<int>();
  
  final RxList<Task> subtasks = <Task>[].obs;
  final RxList<UserProjects> projects = <UserProjects>[].obs;

  @override
  void onInit() {
    super.onInit();
    titleController = TextEditingController(text: task.taskTitle);
    descriptionController = TextEditingController(text: task.taskDescription ?? '');
    
    // Initialize fields from task
    selectedStatus.value = task.taskStatus;
    frequency.value = task.taskFrequency ?? AppConstants.frequencyOnce;
    energyLevel.value = task.energyLevel ?? AppConstants.energyMedium;
    enableAlerts.value = task.enableAlerts;
    focusRequired.value = task.focusRequired;
    timeEstimate.value = task.timeEstimate;
    
    // Parse priority to urgency/importance
    _parsePriority(task.taskPriority);
    
    // Parse date/time
    if (task.taskDueDate != null) {
      try {
        final dueDate = DateTime.parse(task.taskDueDate!);
        selectedDate.value = dueDate;
        selectedTime.value = TimeOfDay(hour: dueDate.hour, minute: dueDate.minute);
      } catch (e) {
        developer.log('Error parsing date: $e', name: 'EditTaskController');
      }
    }
    
    _loadProjects();
    _loadCurrentProject();
    loadSubtasks();
  }

  void _parsePriority(String? priority) {
    switch (priority) {
      case 'Urgent & Important':
        urgency.value = AppConstants.urgencyHigh;
        importance.value = AppConstants.importanceHigh;
        break;
      case 'Urgent Not Important':
        urgency.value = AppConstants.urgencyHigh;
        importance.value = AppConstants.importanceMedium;
        break;
      case 'Not Urgent Important':
        urgency.value = AppConstants.urgencyMedium;
        importance.value = AppConstants.importanceHigh;
        break;
      default:
        urgency.value = AppConstants.urgencyMedium;
        importance.value = AppConstants.importanceMedium;
    }
  }

  String get computedPriority {
    if (urgency.value == AppConstants.urgencyHigh && 
        importance.value == AppConstants.importanceHigh) {
      return AppConstants.priorityUrgentImportant;
    } else if (urgency.value == AppConstants.urgencyHigh) {
      return AppConstants.priorityUrgentNotImportant;
    } else if (importance.value == AppConstants.importanceHigh) {
      return AppConstants.priorityNotUrgentImportant;
    } else {
      return AppConstants.priorityNotUrgentNotImportant;
    }
  }

  @override
  void onClose() {
    titleController.dispose();
    descriptionController.dispose();
    super.onClose();
  }

  Future<void> _loadProjects() async {
    projects.value = await UserProjectsApi.getProjects();
  }

  Future<void> _loadCurrentProject() async {
    if (task.projectId != null) {
      try {
        final project = await UserProjectsApi.getProjectById(task.projectId!);
        selectedProject.value = project;
      } catch (e) {
        developer.log('Error loading project: $e', name: 'EditTaskController');
      }
    }
  }

  Future<void> loadSubtasks() async {
    try {
      final subs = await TaskApi.getSubTasks(task.taskId);
      subtasks.value = subs;
    } catch (e) {
      developer.log('Error loading subtasks: $e', name: 'EditTaskController');
    }
  }

  Future<void> addSubtask(String title) async {
    if (title.trim().isEmpty) return;

    try {
      final subtask = Task(
        taskId: '',
        projectId: task.projectId,
        taskTitle: title.trim(),
        taskStatus: 'Todo',
        parentTaskId: task.taskId,
      );

      await TaskApi.createTask(subtask);
      await loadSubtasks();
      
      Get.snackbar(
        '✓ Success',
        'Subtask added',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF66BB6A),
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
    } catch (e) {
      developer.log('Error creating subtask: $e', name: 'EditTaskController');
      Get.snackbar(
        'Error',
        'Failed to add subtask',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
    }
  }

  Future<void> deleteSubtask(String subtaskId) async {
    try {
      await TaskApi.deleteTask(subtaskId);
      await loadSubtasks();
      Get.snackbar(
        '✓ Success',
        'Subtask deleted',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF66BB6A),
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
    } catch (e) {
      developer.log('Error deleting subtask: $e', name: 'EditTaskController');
    }
  }

  Future<void> saveTask() async {
    if (!(formKey.currentState?.validate() ?? false)) return;

    try {
      final dueDate = selectedDate.value != null && selectedTime.value != null
          ? DateTime(
              selectedDate.value!.year,
              selectedDate.value!.month,
              selectedDate.value!.day,
              selectedTime.value!.hour,
              selectedTime.value!.minute,
            )
          : selectedDate.value;

      final updatedTask = task.copyWith(
        taskTitle: titleController.text.trim(),
        taskDescription: descriptionController.text.trim(),
        projectId: selectedProject.value?.projectId,
        taskPriority: computedPriority,
        taskUrgency: urgency.value,
        taskImportance: importance.value,
        taskStatus: selectedStatus.value,
        taskFrequency: frequency.value,
        energyLevel: energyLevel.value,
        enableAlerts: enableAlerts.value,
        alertTime: selectedTime.value != null
            ? '${selectedTime.value!.hour}:${selectedTime.value!.minute}'
            : null,
        taskDueDate: dueDate?.toIso8601String(),
        timeEstimate: timeEstimate.value,
        isRecurring: frequency.value != 'Once',
        focusRequired: focusRequired.value,
        taskUpdatedAt: DateTime.now().toIso8601String(),
      );

      await TaskApi.updateTask(task.taskId, updatedTask);

      // Schedule notification if enabled
      if (enableAlerts.value && dueDate != null) {
        final notificationTime = dueDate.subtract(const Duration(minutes: 15));
        
        if (notificationTime.isAfter(DateTime.now())) {
          await NotificationService().scheduleTaskNotification(
            id: task.taskId.hashCode,
            title: 'Task Due: ${updatedTask.taskTitle}',
            body: updatedTask.taskDescription ?? 'Time to work on this task',
            scheduledDate: notificationTime,
            payload: task.taskId,
          );
        }
      }

      // Refresh dashboard and tasks list
      try {
        final dashController = Get.find<DashboardController>();
        dashController.refreshDashboard();
      } catch (e) {
        // Dashboard controller not found, ignore
      }

      try {
        final tasksController = Get.find<TasksController>();
        await tasksController.loadTasks();
      } catch (e) {
        // Tasks controller not found, ignore
      }

      Get.back();
      Get.snackbar(
        '✓ Success',
        'Task updated successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF66BB6A),
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );

      if (kDebugMode) {
        developer.log('Task updated: ${updatedTask.taskTitle}', name: 'EditTaskController');
      }
    } catch (e, stack) {
      if (kDebugMode) {
        developer.log(
          'Error updating task: $e',
          error: e,
          stackTrace: stack,
          name: 'EditTaskController',
        );
      }
      Get.snackbar(
        'Error',
        'Failed to update task',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
    }
  }

  Future<void> deleteTask() async {
    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Task', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to delete this task? This will also delete all subtasks.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () async {
              try {
                await TaskApi.deleteTask(task.taskId);
                
                // Refresh dashboard and tasks list
                try {
                  final dashController = Get.find<DashboardController>();
                  dashController.refreshDashboard();
                } catch (e) {
                  // Dashboard controller not found, ignore
                }

                try {
                  final tasksController = Get.find<TasksController>();
                  await tasksController.loadTasks();
                } catch (e) {
                  // Tasks controller not found, ignore
                }

                Get.back(); // Close dialog
                Get.back(); // Close edit screen
                
                Get.snackbar(
                  '✓ Success',
                  'Task deleted successfully',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: const Color(0xFF66BB6A),
                  colorText: Colors.white,
                  duration: const Duration(seconds: 3),
                  margin: const EdgeInsets.all(16),
                  borderRadius: 12,
                );
              } catch (e) {
                developer.log('Error deleting task: $e', name: 'EditTaskController');
                Get.back();
                Get.snackbar(
                  'Error',
                  'Failed to delete task',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.red.withOpacity(0.8),
                  colorText: Colors.white,
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Color(0xFFFF6B6B))),
          ),
        ],
      ),
    );
  }
}
