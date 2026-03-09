import 'package:get/get.dart';
import 'package:mymanager/database/apis/task_api.dart';
import 'package:mymanager/database/apis/task_status_api.dart';
import 'package:mymanager/database/models/task_status_option.dart';
import 'package:mymanager/database/tables/tasks/models/task_model.dart';
import 'package:mymanager/services/project_context_controller.dart';
import 'package:mymanager/services/xp_service.dart';
import 'dart:developer' as developer;

class TasksController extends GetxController {
  final RxList<Task> allTasks = <Task>[].obs;
  final RxList<Task> todayTasks = <Task>[].obs;
  final RxList<Task> upcomingTasks = <Task>[].obs;
  final RxList<Task> completedTasks = <Task>[].obs;
  
  final RxBool isLoading = false.obs;
  final RxString selectedFilter = 'All'.obs;
  final Rx<DateTime> selectedDate = DateTime.now().obs;
  final RxList<TaskStatusOption> taskStatuses = <TaskStatusOption>[].obs;
  final RxMap<String, List<Task>> subtasksMap = <String, List<Task>>{}.obs;
  final RxSet<String> expandedTasks = <String>{}.obs;
  late final ProjectContextController _projectContext;
  Worker? _projectSwitchWorker;
  
  @override
  void onInit() {
    super.onInit();
    _projectContext = Get.find<ProjectContextController>();
    _projectSwitchWorker = ever<String?>(_projectContext.selectedProjectId, (_) => loadTasks());
    loadTasks();
  }

  @override
  void onClose() {
    _projectSwitchWorker?.dispose();
    super.onClose();
  }
  
  void selectDate(DateTime date) {
    selectedDate.value = date;
    loadTasks();
  }
  
  void setFilter(String filter) {
    selectedFilter.value = filter;
  }

  List<String> get filterOptions {
    final names = taskStatuses.map((s) => s.name).toList();
    return ['All', ...names];
  }

  String get completedStatusName => TaskStatusApi.completedStatusName();

  bool isCompletedStatus(String status) => TaskStatusApi.isCompletedStatus(status);

  Future<void> loadTaskStatuses({bool forceRefresh = false}) async {
    taskStatuses.value = await TaskStatusApi.getTaskStatuses(forceRefresh: forceRefresh);
    if (selectedFilter.value != 'All' && !filterOptions.contains(selectedFilter.value)) {
      selectedFilter.value = 'All';
    }
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
      await loadTaskStatuses();
      
      // Load all tasks
      final tasks = await TaskApi.getTasks(projectId: _projectContext.selectedProjectId.value);
      
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
        !TaskStatusApi.isCompletedStatus(task.taskStatus)
      ).toList();
      
      completedTasks.value = expandedTasks.where((task) => TaskStatusApi.isCompletedStatus(task.taskStatus)).toList();
      
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
        final subs = await TaskApi.getSubTasks(
          task.taskId,
          projectId: _projectContext.selectedProjectId.value,
        );
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
      default:
        if (selectedFilter.value != 'All') {
          tasks = tasks.where((task) => task.taskStatus == selectedFilter.value).toList();
        }
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
            taskStatus: taskStatuses.isNotEmpty ? taskStatuses.first.name : 'Todo',
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

  Future<void> setTaskStatus(String taskId, String statusName) async {
    final task = allTasks.firstWhereOrNull((t) => t.taskId == taskId);
    if (task == null) return;

    final updated = task.copyWith(taskStatus: statusName);
    await TaskApi.updateTask(taskId, updated);
    await loadTasks();
  }

  Future<void> addCustomStatus(String name) async {
    await TaskStatusApi.createTaskStatus(name: name);
    await loadTaskStatuses(forceRefresh: true);
    await loadTasks();
  }

  Future<void> renameStatus(TaskStatusOption status, String newName) async {
    await TaskStatusApi.updateTaskStatus(id: status.id, name: newName);
    await loadTaskStatuses(forceRefresh: true);
    await loadTasks();
  }

  Future<void> deleteStatus(TaskStatusOption status) async {
    await TaskStatusApi.deleteTaskStatus(status.id);
    await loadTaskStatuses(forceRefresh: true);
    await loadTasks();
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
        
        // Award XP when task is completed
        if (newStatus == 'Completed' && currentStatus != 'Completed') {
          await XpService.awardXp(XpService.xpTaskComplete, reason: 'Task completed');
        }
        
        await loadTasks();
      }
    } catch (e) {
      developer.log('Error cycling task status: $e', name: 'TasksController');
    }
  }
}
