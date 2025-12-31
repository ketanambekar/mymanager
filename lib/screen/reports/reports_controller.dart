import 'package:get/get.dart';
import 'package:mymanager/database/apis/task_api.dart';
import 'package:mymanager/database/apis/user_project_api.dart';
import 'package:mymanager/database/tables/tasks/models/task_model.dart';
import 'package:mymanager/database/tables/user_projects/models/user_project_model.dart';
import 'dart:developer' as developer;

class ReportsController extends GetxController {
  final RxList<Task> allTasks = <Task>[].obs;
  final RxList<UserProjects> allProjects = <UserProjects>[].obs;
  final RxBool isLoading = false.obs;

  // Task Statistics
  final RxInt totalTasks = 0.obs;
  final RxInt completedTasks = 0.obs;
  final RxInt inProgressTasks = 0.obs;
  final RxInt todoTasks = 0.obs;
  final RxInt overdueTasks = 0.obs;

  // Priority Statistics
  final RxInt urgentImportant = 0.obs;
  final RxInt urgentNotImportant = 0.obs;
  final RxInt notUrgentImportant = 0.obs;
  final RxInt notUrgentNotImportant = 0.obs;

  // Frequency Statistics
  final RxInt onceTasks = 0.obs;
  final RxInt dailyTasks = 0.obs;
  final RxInt weeklyTasks = 0.obs;
  final RxInt monthlyTasks = 0.obs;

  // Time Statistics
  final RxInt todayTasks = 0.obs;
  final RxInt thisWeekTasks = 0.obs;
  final RxInt thisMonthTasks = 0.obs;

  // Completion Rate
  final RxDouble completionRate = 0.0.obs;

  @override
  void onInit() {
    super.onInit();
    loadReportData();
  }

  Future<void> loadReportData() async {
    try {
      isLoading.value = true;

      // Load all data
      final tasks = await TaskApi.getTasks();
      final projects = await UserProjectsApi.getProjects();

      allTasks.value = tasks;
      allProjects.value = projects;

      // Calculate statistics
      _calculateTaskStatistics(tasks);
      _calculatePriorityStatistics(tasks);
      _calculateFrequencyStatistics(tasks);
      _calculateTimeStatistics(tasks);
      _calculateCompletionRate(tasks);

      developer.log('Report data loaded: ${tasks.length} tasks, ${projects.length} projects',
          name: 'ReportsController');
    } catch (e) {
      developer.log('Error loading report data: $e', name: 'ReportsController');
    } finally {
      isLoading.value = false;
    }
  }

  void _calculateTaskStatistics(List<Task> tasks) {
    totalTasks.value = tasks.length;
    completedTasks.value = tasks.where((t) => t.taskStatus == 'Completed').length;
    inProgressTasks.value = tasks.where((t) => t.taskStatus == 'In Progress').length;
    todoTasks.value = tasks.where((t) => t.taskStatus == 'Todo').length;

    final now = DateTime.now();
    overdueTasks.value = tasks.where((t) {
      if (t.taskDueDate == null || t.taskStatus == 'Completed') return false;
      return DateTime.parse(t.taskDueDate!).isBefore(now);
    }).length;
  }

  void _calculatePriorityStatistics(List<Task> tasks) {
    urgentImportant.value = tasks.where((t) =>
        t.taskUrgency == 'High' && t.taskImportance == 'High').length;
    urgentNotImportant.value = tasks.where((t) =>
        t.taskUrgency == 'High' && t.taskImportance == 'Low').length;
    notUrgentImportant.value = tasks.where((t) =>
        t.taskUrgency == 'Low' && t.taskImportance == 'High').length;
    notUrgentNotImportant.value = tasks.where((t) =>
        t.taskUrgency == 'Low' && t.taskImportance == 'Low').length;
  }

  void _calculateFrequencyStatistics(List<Task> tasks) {
    onceTasks.value = tasks.where((t) => t.taskFrequency == 'Once' || t.taskFrequency == null).length;
    dailyTasks.value = tasks.where((t) => t.taskFrequency == 'Daily').length;
    weeklyTasks.value = tasks.where((t) => t.taskFrequency == 'Weekly').length;
    monthlyTasks.value = tasks.where((t) => t.taskFrequency == 'Monthly').length;
  }

  void _calculateTimeStatistics(List<Task> tasks) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekStart = today.subtract(Duration(days: today.weekday - 1));
    final monthStart = DateTime(now.year, now.month, 1);

    todayTasks.value = tasks.where((t) {
      if (t.taskDueDate == null) return false;
      final dueDate = DateTime.parse(t.taskDueDate!);
      final dueDateOnly = DateTime(dueDate.year, dueDate.month, dueDate.day);
      return dueDateOnly.isAtSameMomentAs(today);
    }).length;

    thisWeekTasks.value = tasks.where((t) {
      if (t.taskDueDate == null) return false;
      final dueDate = DateTime.parse(t.taskDueDate!);
      return dueDate.isAfter(weekStart) && dueDate.isBefore(today.add(const Duration(days: 7)));
    }).length;

    thisMonthTasks.value = tasks.where((t) {
      if (t.taskDueDate == null) return false;
      final dueDate = DateTime.parse(t.taskDueDate!);
      return dueDate.isAfter(monthStart) && dueDate.month == now.month;
    }).length;
  }

  void _calculateCompletionRate(List<Task> tasks) {
    if (tasks.isEmpty) {
      completionRate.value = 0.0;
      return;
    }
    completionRate.value = (completedTasks.value / tasks.length) * 100;
  }
}