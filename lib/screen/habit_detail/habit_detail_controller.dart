import 'package:get/get.dart';
import 'package:mymanager/database/apis/habit_api.dart';
import 'package:mymanager/database/tables/tasks/models/habit_model.dart';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

class HabitDetailController extends GetxController {
  late Habit habit;
  final RxList<String> completionDates = <String>[].obs;
  final RxBool isLoading = true.obs;
  
  @override
  void onInit() {
    super.onInit();
    if (Get.arguments != null && Get.arguments is Habit) {
      habit = Get.arguments as Habit;
      loadCompletionHistory();
    }
  }
  
  Future<void> loadCompletionHistory() async {
    try {
      isLoading.value = true;
      final logs = await HabitApi.getHabitLogs(habit.habitId);
      completionDates.value = logs.map((log) => log['completed_date'] as String).toList();
      
      if (kDebugMode) {
        developer.log('Loaded ${completionDates.length} completion logs', name: 'HabitDetailController');
      }
    } catch (e) {
      if (kDebugMode) {
        developer.log('Error loading completion history: $e', name: 'HabitDetailController');
      }
    } finally {
      isLoading.value = false;
    }
  }
  
  /// Check if a date has a completion
  bool isDateCompleted(DateTime date) {
    final dateStr = date.toIso8601String().split('T')[0];
    return completionDates.any((d) => d.startsWith(dateStr));
  }
  
  /// Get completion count for current month
  int getMonthCompletions() {
    final now = DateTime.now();
    return completionDates.where((dateStr) {
      try {
        final date = DateTime.parse(dateStr);
        return date.year == now.year && date.month == now.month;
      } catch (e) {
        return false;
      }
    }).length;
  }
  
  /// Get total completions
  int getTotalCompletions() => completionDates.length;
}
