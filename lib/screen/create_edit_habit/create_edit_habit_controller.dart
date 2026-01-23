import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mymanager/database/apis/habit_api.dart';
import 'package:mymanager/database/tables/tasks/models/habit_model.dart';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

class CreateEditHabitController extends GetxController {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  
  final RxString selectedFrequency = 'Daily'.obs;
  final RxString selectedColor = '0xFF7C4DFF'.obs;
  final RxBool enableAlerts = false.obs;
  final Rx<TimeOfDay?> alertTime = Rx<TimeOfDay?>(null);
  final RxBool isSaving = false.obs;
  
  Habit? editingHabit;
  
  final List<String> frequencies = [
    'Daily',
    'Weekly',
    'Monthly',
  ];
  
  final List<MapEntry<String, Color>> colors = [
    const MapEntry('0xFF7C4DFF', Color(0xFF7C4DFF)), // Purple
    const MapEntry('0xFFFF6B6B', Color(0xFFFF6B6B)), // Red
    const MapEntry('0xFF4ECDC4', Color(0xFF4ECDC4)), // Teal
    const MapEntry('0xFFFFBE0B', Color(0xFFFFBE0B)), // Orange
    const MapEntry('0xFF5B8DEE', Color(0xFF5B8DEE)), // Blue
    const MapEntry('0xFF95E1D3', Color(0xFF95E1D3)), // Mint
  ];
  
  @override
  void onInit() {
    super.onInit();
    // Check if editing existing habit
    if (Get.arguments != null && Get.arguments is Habit) {
      editingHabit = Get.arguments as Habit;
      _loadHabitData();
    }
  }
  
  void _loadHabitData() {
    if (editingHabit == null) return;
    
    nameController.text = editingHabit!.habitName;
    descriptionController.text = editingHabit!.habitDescription ?? '';
    selectedFrequency.value = editingHabit!.frequency;
    selectedColor.value = editingHabit!.habitColor ?? '0xFF7C4DFF';
    enableAlerts.value = editingHabit!.enableAlerts;
    
    if (editingHabit!.alertTime != null) {
      try {
        final parts = editingHabit!.alertTime!.split(':');
        alertTime.value = TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
      } catch (e) {
        alertTime.value = null;
      }
    }
  }
  
  Future<void> saveHabit() async {
    if (nameController.text.trim().isEmpty) {
      Get.snackbar(
        'Error',
        'Please enter a habit name',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    
    try {
      isSaving.value = true;
      
      final habit = Habit(
        habitId: editingHabit?.habitId ?? '',
        habitName: nameController.text.trim(),
        habitDescription: descriptionController.text.trim().isEmpty 
            ? null 
            : descriptionController.text.trim(),
        frequency: selectedFrequency.value,
        habitColor: '#${selectedColor.value.substring(4)}',
        enableAlerts: enableAlerts.value,
        alertTime: alertTime.value != null
            ? '${alertTime.value!.hour.toString().padLeft(2, '0')}:${alertTime.value!.minute.toString().padLeft(2, '0')}'
            : null,
        currentStreak: editingHabit?.currentStreak ?? 0,
        bestStreak: editingHabit?.bestStreak ?? 0,
        lastCompleted: editingHabit?.lastCompleted,
      );
      
      if (editingHabit != null) {
        await HabitApi.updateHabit(habit.habitId, habit);
        Get.snackbar(
          'Success',
          'Habit updated successfully',
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        await HabitApi.createHabit(habit);
        Get.snackbar(
          'Success',
          'Habit created successfully',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
      
      Get.back(result: true);
    } catch (e) {
      if (kDebugMode) {
        developer.log('Error saving habit: $e', name: 'CreateEditHabitController');
      }
      Get.snackbar(
        'Error',
        'Failed to save habit',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isSaving.value = false;
    }
  }
  
  @override
  void onClose() {
    nameController.dispose();
    descriptionController.dispose();
    super.onClose();
  }
}
