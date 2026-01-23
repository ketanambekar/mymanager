import 'package:get/get.dart';
import 'package:mymanager/database/apis/task_api.dart';
import 'package:mymanager/database/apis/habit_api.dart';
import 'package:mymanager/database/tables/tasks/models/task_model.dart';
import 'package:mymanager/database/tables/tasks/models/habit_model.dart';
import 'dart:developer' as developer;

class CalenderController extends GetxController {
  final Rx<DateTime> selectedDay = DateTime
      .now()
      .obs;
  final Rx<DateTime> focusedDay = DateTime
      .now()
      .obs;
  final RxList<Task> allTasks = <Task>[].obs;
  final RxList<Habit> allHabits = <Habit>[].obs;
  final RxMap<String, List<String>> habitCompletions = <String, List<String>>{}
      .obs;

  @override
  void onInit() {
    super.onInit();
    loadTasks();
    loadHabits();
  }

  Future<void> loadTasks() async {
    try {
      final tasks = await TaskApi.getTasks();
      allTasks.value = tasks;
    } catch (e) {
      developer.log('Error loading tasks: $e', name: 'CalenderController');
    }
  }

  Future<void> loadHabits() async {
    try {
      final habits = await HabitApi.getHabits();
      allHabits.value = habits;

      // Load completion data for each habit
      for (var habit in habits) {
        final logs = await HabitApi.getHabitLogs(habit.habitId);
        habitCompletions[habit.habitId] = logs
            .map((log) => log['completed_date'] as String)
            .toList();
      }
    } catch (e) {
      developer.log('Error loading habits: $e', name: 'CalenderController');
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
      
      // Check if selected date matches due date
      if (dueDateOnly.isAtSameMomentAs(selected)) return true;
      
      // Check if task is recurring and applies to selected date
      if (task.isRecurring && task.taskFrequency != null && task.taskFrequency != 'Once') {
        return _isRecurringTaskOnDate(task, selected);
      }
      
      return false;
    }).toList();
  }

  /// Check if a recurring task occurs on a specific date
  bool _isRecurringTaskOnDate(Task task, DateTime date) {
    if (!task.isRecurring || task.taskDueDate == null) return false;
    
    final startDate = DateTime.parse(task.taskDueDate!);
    final startDateOnly = DateTime(startDate.year, startDate.month, startDate.day);
    final dateOnly = DateTime(date.year, date.month, date.day);
    
    // Date must be on or after start date
    if (dateOnly.isBefore(startDateOnly)) return false;
    
    // Check if date is before end date (if set)
    if (task.taskCompletedDate != null) {
      final endDate = DateTime.parse(task.taskCompletedDate!);
      final endDateOnly = DateTime(endDate.year, endDate.month, endDate.day);
      if (dateOnly.isAfter(endDateOnly)) return false;
    }
    
    switch (task.taskFrequency) {
      case 'Daily':
        return true; // Every day from start date
      case 'Weekly':
        final daysDiff = dateOnly.difference(startDateOnly).inDays;
        return daysDiff % 7 == 0; // Every 7 days
      case 'Monthly':
        return date.day == startDate.day; // Same day of month
      default:
        return false;
    }
  }

  /// Check if a date has any tasks
  bool hasTasksOnDate(DateTime date) {
    final dateOnly = DateTime(date.year, date.month, date.day);
    return allTasks.any((task) {
      if (task.taskDueDate == null) return false;
      
      final dueDate = DateTime.parse(task.taskDueDate!);
      final dueDateOnly = DateTime(dueDate.year, dueDate.month, dueDate.day);
      
      // Check direct match
      if (dueDateOnly.isAtSameMomentAs(dateOnly)) return true;
      
      // Check recurring tasks
      if (task.isRecurring && task.taskFrequency != null && task.taskFrequency != 'Once') {
        return _isRecurringTaskOnDate(task, dateOnly);
      }
      
      return false;
    });
  }

  /// Check if a date has any habit completions
  bool hasHabitCompletionOnDate(DateTime date) {
    final dateStr = date.toIso8601String().split('T')[0];
    return habitCompletions.values.any((completions) {
      return completions.any((c) => c.startsWith(dateStr));
    });
  }
}
