import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mymanager/database/apis/task_api.dart';
import 'package:mymanager/database/tables/tasks/models/task_model.dart';
import 'dart:developer' as developer;

class TasksController extends GetxController {
  final RxList<Task> allTasks = <Task>[].obs;
  final RxList<Task> todayTasks = <Task>[].obs;
  final RxList<Task> upcomingTasks = <Task>[].obs;
  final RxList<Task> completedTasks = <Task>[].obs;
  
  final RxBool isLoading = false.obs;
  final RxString selectedFilter = 'all'.obs; // all, today, upcoming, completed
  
  @override
  void onInit() {
    super.onInit();
    loadTasks();
  }
  
  Future<void> loadTasks() async {
    try {
      isLoading.value = true;
      
      // Load all tasks
      final tasks = await TaskApi.getTasks();
      allTasks.value = tasks;
      
      // Filter tasks
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final tomorrow = today.add(const Duration(days: 1));
      
      todayTasks.value = tasks.where((task) {
        if (task.taskDueDate == null) return false;
        final dueDate = DateTime.parse(task.taskDueDate!);
        return dueDate.isAfter(today.subtract(const Duration(seconds: 1))) && 
               dueDate.isBefore(tomorrow);
      }).toList();
      
      upcomingTasks.value = tasks.where((task) => 
        task.taskDueDate != null && 
        DateTime.parse(task.taskDueDate!).isAfter(tomorrow) &&
        task.taskStatus != 'completed'
      ).toList();
      
      completedTasks.value = tasks.where((task) => task.taskStatus == 'completed').toList();
      
      developer.log('Loaded ${tasks.length} tasks', name: 'TasksController');
    } catch (e) {
      developer.log('Error loading tasks: $e', name: 'TasksController');
    } finally {
      isLoading.value = false;
    }
  }
  
  List<Task> get filteredTasks {
    switch (selectedFilter.value) {
      case 'today':
        return todayTasks;
      case 'upcoming':
        return upcomingTasks;
      case 'completed':
        return completedTasks;
      default:
        return allTasks.where((task) => task.taskStatus != 'completed').toList();
    }
  }
  
  Future<void> toggleTaskComplete(String taskId, bool isComplete) async {
    try {
      if (isComplete) {
        await TaskApi.completeTask(taskId);
      } else {
        // Reopen task
        final task = await TaskApi.getTaskById(taskId);
        if (task != null) {
          final updated = Task(
            taskId: task.taskId,
            projectId: task.projectId,
            taskTitle: task.taskTitle,
            taskDescription: task.taskDescription,
            taskPriority: task.taskPriority,
            taskUrgency: task.taskUrgency,
            taskImportance: task.taskImportance,
            taskStatus: 'active',
            taskFrequency: task.taskFrequency,
            taskFrequencyValue: task.taskFrequencyValue,
            enableAlerts: task.enableAlerts,
            alertTime: task.alertTime,
            taskStartDate: task.taskStartDate,
            taskDueDate: task.taskDueDate,
            taskCompletedDate: null,
            timeEstimate: task.timeEstimate,
            timeSpent: task.timeSpent,
            taskColor: task.taskColor,
            taskOrder: task.taskOrder,
            isRecurring: task.isRecurring,
            parentTaskId: task.parentTaskId,
            energyLevel: task.energyLevel,
            focusRequired: task.focusRequired,
            taskCreatedAt: task.taskCreatedAt,
            taskUpdatedAt: DateTime.now().toIso8601String(),
          );
          await TaskApi.updateTask(taskId, updated);
        }
      }
      await loadTasks();
    } catch (e) {
      developer.log('Error toggling task: $e', name: 'TasksController');
    }
  }
  
  Future<void> deleteTask(String taskId) async {
    try {
      await TaskApi.deleteTask(taskId);
      await loadTasks();
    } catch (e) {
      developer.log('Error deleting task: $e', name: 'TasksController');
    }
  }
}
