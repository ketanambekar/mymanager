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
import 'package:mymanager/services/notification_service.dart';
import 'package:mymanager/utils/global_utils.dart';

class CreateTaskController extends GetxController {
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final descController = TextEditingController();
  
  final selectedDate = Rxn<DateTime>();
  final selectedTime = Rxn<TimeOfDay>();
  final selectedEndDate = Rxn<DateTime>();
  final selectedProject = Rxn<UserProjects>();
  final parentTask = Rxn<Task>();
  
  final urgency = AppConstants.urgencyMedium.obs;
  final importance = AppConstants.importanceMedium.obs;
  final taskStatus = AppConstants.taskStatusTodo.obs;
  final frequency = AppConstants.frequencyOnce.obs;
  final energyLevel = AppConstants.energyMedium.obs;
  
  final enableAlerts = false.obs;
  final focusRequired = false.obs;
  final isRecurring = false.obs;
  final isHabit = false.obs;
  final timeEstimate = Rxn<int>();
  
  // Subtasks
  final RxList<String> subtasks = <String>[].obs;
  
  final RxList<UserProjects> projects = <UserProjects>[].obs;
  final RxList<Task> availableTasks = <Task>[].obs;

  @override
  void onInit() {
    super.onInit();
    _loadProjects();
    _loadTasks();
  }

  Future<void> _loadProjects() async {
    projects.value = await UserProjectsApi.getProjects();
  }

  Future<void> _loadTasks() async {
    availableTasks.value = await TaskApi.getTasks(onlyParentTasks: true);
  }

  String? validateName(String? s) {
    if (s == null || s.trim().isEmpty) return 'Please enter a task name';
    return null;
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

  // Add subtask
  void addSubtask(String subtask) {
    if (subtask.trim().isNotEmpty) {
      subtasks.add(subtask.trim());
    }
  }

  // Remove subtask
  void removeSubtask(int index) {
    if (index >= 0 && index < subtasks.length) {
      subtasks.removeAt(index);
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

      // Create task
      final taskId = uuid.v4();
      final task = Task(
        taskId: taskId,
        projectId: selectedProject.value?.projectId,
        taskTitle: nameController.text.trim(),
        taskDescription: descController.text.trim(),
        taskPriority: computedPriority,
        taskUrgency: urgency.value,
        taskImportance: importance.value,
        taskStatus: taskStatus.value,
        taskFrequency: frequency.value,
        enableAlerts: enableAlerts.value,
        alertTime: selectedTime.value != null
            ? '${selectedTime.value!.hour}:${selectedTime.value!.minute}'
            : null,
        taskDueDate: dueDate?.toIso8601String(),
        timeEstimate: timeEstimate.value,
        isRecurring: frequency.value != 'Once',
        energyLevel: energyLevel.value,
        focusRequired: focusRequired.value,
      );

      await TaskApi.createTask(task);
      
      // Create subtasks
      for (final subtaskTitle in subtasks) {
        final subtask = Task(
          taskId: '',
          projectId: selectedProject.value?.projectId,
          taskTitle: subtaskTitle,
          taskDescription: '',
          taskPriority: computedPriority,
          taskStatus: 'Todo',
          parentTaskId: taskId,
          taskDueDate: dueDate?.toIso8601String(),
        );
        await TaskApi.createTask(subtask);
      }

      // Schedule notification if enabled
      bool notificationScheduled = false;
      if (enableAlerts.value && dueDate != null) {
        final notificationTime = dueDate.subtract(const Duration(minutes: 15));
        
        if (notificationTime.isAfter(DateTime.now())) {
          notificationScheduled = await NotificationService().scheduleTaskNotification(
            id: taskId.hashCode,
            title: 'Task Due: ${task.taskTitle}',
            body: task.taskDescription ?? 'Time to work on this task',
            scheduledDate: notificationTime,
            payload: taskId,
          );
          
          if (!notificationScheduled && kDebugMode) {
            developer.log(
              'Failed to schedule notification - check permissions',
              name: 'CreateTaskController',
            );
          }
        }
      }

      Get.back(result: true);
      
      // Show success message
      String message = frequency.value != 'Once' 
          ? 'Recurring task created (${frequency.value})${selectedEndDate.value != null ? ' until ${selectedEndDate.value!.day}/${selectedEndDate.value!.month}/${selectedEndDate.value!.year}' : ''}'
          : 'Task created successfully';
      
      if (enableAlerts.value && !notificationScheduled && dueDate != null) {
        message += ' (Enable notification permissions for reminders)';
      }
      
      Get.snackbar(
        '✓ Success',
        message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF66BB6A),
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );

      if (kDebugMode) {
        developer.log('Task created: ${task.taskTitle} (${frequency.value})', name: 'CreateTaskController');
      }

      // Refresh dashboard if it exists
      try {
        final dashboardController = Get.find<DashboardController>();
        dashboardController.refreshDashboard();
      } catch (e) {
        // Dashboard controller not found, ignore
      }
    } catch (e, stack) {
      if (kDebugMode) {
        developer.log(
          'Error creating task: $e',
          error: e,
          stackTrace: stack,
          name: 'CreateTaskController',
        );
      }
      Get.snackbar(
        'Error',
        'Failed to create task',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
    }
  }

  @override
  void onClose() {
    nameController.dispose();
    descController.dispose();
    super.onClose();
  }
}
