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
  final RxString selectedFilter = 'All'.obs;
  final Rx<DateTime> selectedDate = DateTime.now().obs;
  final RxMap<String, List<Task>> subtasksMap = <String, List<Task>>{}.obs;
  final RxSet<String> expandedTasks = <String>{}.obs;
  
  @override
  void onInit() {
    super.onInit();
    loadTasks();
  }
  
  void selectDate(DateTime date) {
    selectedDate.value = date;
    loadTasks();
  }
  
  void setFilter(String filter) {
    selectedFilter.value = filter;
  }
  
  // Expand recurring tasks into virtual instances
  List<Task> _expandRecurringTasks(List<Task> tasks) {
    final List<Task> expandedTasks = [];
    final now = DateTime.now();
    final pastLimit = now.subtract(const Duration(days: 30)); // Show past 30 days
    final futureLimit = now.add(const Duration(days: 90)); // Show next 90 days
    
    for (final task in tasks) {
      if (task.isRecurring && task.taskFrequency != null && task.taskFrequency != 'Once') {
        // Generate instances for recurring task
        if (task.taskDueDate != null) {
          final startDate = DateTime.parse(task.taskDueDate!);
          DateTime currentDate = startDate;
          
          // Start from past limit if task started before that
          while (currentDate.isBefore(pastLimit)) {
            switch (task.taskFrequency) {
              case 'Daily':
                currentDate = currentDate.add(const Duration(days: 1));
                break;
              case 'Weekly':
                currentDate = currentDate.add(const Duration(days: 7));
                break;
              case 'Monthly':
                currentDate = DateTime(currentDate.year, currentDate.month + 1, currentDate.day);
                break;
              default:
                currentDate = futureLimit;
            }
          }
          
          // Generate instances from past limit to future limit
          while (currentDate.isBefore(futureLimit)) {
            // Create a copy with the current occurrence date
            final instanceDate = currentDate.toIso8601String();
            expandedTasks.add(Task(
              taskId: '${task.taskId}_${currentDate.millisecondsSinceEpoch}',
              taskTitle: task.taskTitle,
              taskDescription: task.taskDescription,
              taskDueDate: instanceDate,
              taskStatus: task.taskStatus,
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
            ));
            
            // Move to next occurrence
            switch (task.taskFrequency) {
              case 'Daily':
                currentDate = currentDate.add(const Duration(days: 1));
                break;
              case 'Weekly':
                currentDate = currentDate.add(const Duration(days: 7));
                break;
              case 'Monthly':
                currentDate = DateTime(currentDate.year, currentDate.month + 1, currentDate.day);
                break;
              default:
                currentDate = futureLimit;
            }
          }
        }
      } else {
        // Non-recurring task, add as-is
        expandedTasks.add(task);
      }
    }
    
    return expandedTasks;
  }
  
  Future<void> loadTasks() async {
    try {
      isLoading.value = true;
      
      // Load all tasks
      final tasks = await TaskApi.getTasks();
      
      // Expand recurring tasks
      final expandedTasks = _expandRecurringTasks(tasks);
      allTasks.value = expandedTasks;
      
      // Filter tasks by selected date
      final selected = DateTime(
        selectedDate.value.year,
        selectedDate.value.month,
        selectedDate.value.day,
      );
      final nextDay = selected.add(const Duration(days: 1));
      
      todayTasks.value = expandedTasks.where((task) {
        if (task.taskDueDate == null) return false;
        final dueDate = DateTime.parse(task.taskDueDate!);
        final dueDateOnly = DateTime(dueDate.year, dueDate.month, dueDate.day);
        return dueDateOnly.isAtSameMomentAs(selected);
      }).toList();
      
      upcomingTasks.value = expandedTasks.where((task) => 
        task.taskDueDate != null && 
        DateTime.parse(task.taskDueDate!).isAfter(nextDay) &&
        task.taskStatus != 'Completed'
      ).toList();
      
      completedTasks.value = expandedTasks.where((task) => task.taskStatus == 'Completed').toList();
      
      developer.log('Loaded ${expandedTasks.length} tasks (${tasks.length} unique) for ${selectedDate.value}', name: 'TasksController');
      
      // Load subtasks for all tasks
      await loadSubtasksForTasks(todayTasks);
    } catch (e) {
      developer.log('Error loading tasks: \$e', name: 'TasksController');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadSubtasksForTasks(List<Task> tasks) async {
    try {
      for (final task in tasks) {
        final subs = await TaskApi.getSubTasks(task.taskId);
        if (subs.isNotEmpty) {
          subtasksMap[task.taskId] = subs;
        }
      }
    } catch (e) {
      developer.log('Error loading subtasks: \$e', name: 'TasksController');
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

  List<Task> getSubtasks(String taskId) {
    return subtasksMap[taskId] ?? [];
  }

  int getSubtaskCount(String taskId) {
    return subtasksMap[taskId]?.length ?? 0;
  }
  
  List<Task> get filteredTasks {
    List<Task> tasks = todayTasks.toList();
    
    switch (selectedFilter.value) {
      case 'To do':
        tasks = tasks.where((task) => task.taskStatus == 'Todo').toList();
        break;
      case 'In Progress':
        tasks = tasks.where((task) => task.taskStatus == 'In Progress').toList();
        break;
      case 'Completed':
        tasks = tasks.where((task) => task.taskStatus == 'Completed').toList();
        break;
      default:
        // All tasks
        break;
    }
    
    // Sort by priority (High > Medium > Low) and then by due time
    tasks.sort((a, b) {
      // First sort by priority
      final priorityOrder = {'High': 0, 'Medium': 1, 'Low': 2};
      final aPriority = priorityOrder[a.taskPriority] ?? 3;
      final bPriority = priorityOrder[b.taskPriority] ?? 3;
      
      if (aPriority != bPriority) {
        return aPriority.compareTo(bPriority);
      }
      
      // Then sort by due date/time
      if (a.taskDueDate != null && b.taskDueDate != null) {
        return DateTime.parse(a.taskDueDate!).compareTo(DateTime.parse(b.taskDueDate!));
      }
      
      return 0;
    });
    
    return tasks;
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

  Future<void> cycleTaskStatus(String taskId, String currentStatus) async {
    try {
      String newStatus;
      if (currentStatus == 'Todo') {
        newStatus = 'In Progress';
      } else if (currentStatus == 'In Progress') {
        newStatus = 'Completed';
      } else {
        newStatus = 'Todo';
      }

      final task = allTasks.firstWhereOrNull((t) => t.taskId == taskId);
      if (task != null) {
        final updated = task.copyWith(taskStatus: newStatus);
        await TaskApi.updateTask(taskId, updated);
        await loadTasks();
      }
    } catch (e) {
      developer.log('Error cycling task status: $e', name: 'TasksController');
    }
  }
}
