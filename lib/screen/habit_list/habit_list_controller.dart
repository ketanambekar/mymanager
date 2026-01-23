import 'package:get/get.dart';
import 'package:mymanager/database/apis/habit_api.dart';
import 'package:mymanager/database/tables/tasks/models/habit_model.dart';
import 'package:mymanager/services/xp_service.dart';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

class HabitListController extends GetxController {
  final RxList<Habit> habits = <Habit>[].obs;
  final RxBool isLoading = false.obs;
  
  @override
  void onInit() {
    super.onInit();
    loadHabits();
  }
  
  Future<void> loadHabits() async {
    try {
      isLoading.value = true;
      habits.value = await HabitApi.getHabits();
      if (kDebugMode) {
        developer.log('Loaded ${habits.length} habits', name: 'HabitListController');
      }
    } catch (e) {
      if (kDebugMode) {
        developer.log('Error loading habits: $e', name: 'HabitListController');
      }
    } finally {
      isLoading.value = false;
    }
  }
  
  Future<void> toggleHabitCompletion(Habit habit) async {
    try {
      if (habit.isDueToday) {
        await HabitApi.completeHabit(habit.habitId);
        await XpService.awardXp(XpService.xpHabitComplete, reason: 'Habit completed');
        await loadHabits(); // Refresh to show updated streak
        
        Get.snackbar(
          'Habit Completed! 🎉',
          '+${XpService.xpHabitComplete} XP | Streak: ${habit.currentStreak + 1} days',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 2),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        developer.log('Error completing habit: $e', name: 'HabitListController');
      }
      Get.snackbar(
        'Error',
        'Failed to complete habit',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
  
  Future<void> deleteHabit(String habitId) async {
    try {
      await HabitApi.deleteHabit(habitId);
      await loadHabits();
      Get.snackbar(
        'Habit Deleted',
        'Habit has been removed',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      if (kDebugMode) {
        developer.log('Error deleting habit: $e', name: 'HabitListController');
      }
    }
  }
}
