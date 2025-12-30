import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mymanager/constants/app_constants.dart';
import 'package:mymanager/database/apis/task_api.dart';
import 'package:mymanager/database/apis/user_project_api.dart';
import 'package:mymanager/database/tables/tasks/models/task_model.dart';
import 'package:mymanager/database/tables/user_projects/models/user_project_model.dart';
import 'package:mymanager/services/notification_service.dart';

class CreateTaskController extends GetxController {
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final descController = TextEditingController();
  
  final selectedDate = Rxn<DateTime>();
  final selectedTime = Rxn<TimeOfDay>();
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
  final timeEstimate = Rxn<int>();
  
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

      final task = Task(
        taskId: '',
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
        isRecurring: isRecurring.value,
        parentTaskId: parentTask.value?.taskId,
        energyLevel: energyLevel.value,
        focusRequired: focusRequired.value,
      );

      await TaskApi.createTask(task);

      // Schedule notification if enabled
      if (enableAlerts.value && dueDate != null) {
        await NotificationService().scheduleTaskNotification(
          id: task.taskId.hashCode,
          title: 'Task Due: ${task.taskTitle}',
          body: task.taskDescription ?? 'Time to work on this task',
          scheduledDate: dueDate.subtract(const Duration(minutes: 15)),
          payload: task.taskId,
        );
      }

      Get.back(result: true);
      Get.snackbar(
        'Success',
        'Task created successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.withOpacity(0.8),
        colorText: Colors.white,
      );

      if (kDebugMode) {
        developer.log('Task created: ${task.taskTitle}', name: 'CreateTaskController');
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
