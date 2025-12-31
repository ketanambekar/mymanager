import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mymanager/database/apis/task_api.dart';
import 'package:mymanager/database/tables/tasks/models/task_model.dart';
import 'package:mymanager/screen/dashboard/dashboard_controller.dart';
import 'package:mymanager/screen/tasks/tasks_controller.dart';
import 'dart:developer' as developer;

class TrashController extends GetxController {
  final RxList<Task> deletedTasks = <Task>[].obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadDeletedTasks();
  }

  Future<void> loadDeletedTasks() async {
    try {
      isLoading.value = true;
      final tasks = await TaskApi.getDeletedTasks();
      deletedTasks.value = tasks;
    } catch (e) {
      developer.log('Error loading deleted tasks: $e', name: 'TrashController');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> restoreTask(String taskId) async {
    try {
      await TaskApi.restoreTask(taskId);
      await loadDeletedTasks();
      
      // Refresh other controllers
      try {
        Get.find<DashboardController>().refreshDashboard();
      } catch (e) {}
      try {
        Get.find<TasksController>().loadTasks();
      } catch (e) {}

      Get.snackbar(
        'Success',
        'Task restored successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.success,
        colorText: AppColors.textPrimary,
      );
    } catch (e) {
      developer.log('Error restoring task: $e', name: 'TrashController');
      Get.snackbar(
        'Error',
        'Failed to restore task',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error,
        colorText: AppColors.textPrimary,
      );
    }
  }

  Future<void> deletePermanently(String taskId) async {
    Get.dialog(
      AlertDialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Permanently', style: TextStyle(color: AppColors.textBlack)),
        content: const Text(
          'This action cannot be undone. Are you sure?',
          style: TextStyle(color: AppColors.textBlackSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textBlackSecondary)),
          ),
          TextButton(
            onPressed: () async {
              try {
                await TaskApi.permanentlyDeleteTask(taskId);
                await loadDeletedTasks();
                Get.back();
                Get.snackbar(
                  'Success',
                  'Task deleted permanently',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: AppColors.success,
                  colorText: AppColors.textPrimary,
                );
              } catch (e) {
                developer.log('Error deleting permanently: $e', name: 'TrashController');
                Get.back();
                Get.snackbar(
                  'Error',
                  'Failed to delete task',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: AppColors.error,
                  colorText: AppColors.textPrimary,
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  Future<void> restoreAll() async {
    if (deletedTasks.isEmpty) return;

    try {
      for (final task in deletedTasks) {
        await TaskApi.restoreTask(task.taskId);
      }
      await loadDeletedTasks();
      
      // Refresh other controllers
      try {
        Get.find<DashboardController>().refreshDashboard();
      } catch (e) {}
      try {
        Get.find<TasksController>().loadTasks();
      } catch (e) {}

      Get.snackbar(
        'Success',
        'All tasks restored',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.success,
        colorText: AppColors.textPrimary,
      );
    } catch (e) {
      developer.log('Error restoring all: $e', name: 'TrashController');
    }
  }

  Future<void> deleteAllPermanently() async {
    if (deletedTasks.isEmpty) return;

    Get.dialog(
      AlertDialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete All Permanently', style: TextStyle(color: AppColors.textBlack)),
        content: const Text(
          'This will permanently delete all tasks in trash. This action cannot be undone.',
          style: TextStyle(color: AppColors.textBlackSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textBlackSecondary)),
          ),
          TextButton(
            onPressed: () async {
              try {
                for (final task in deletedTasks) {
                  await TaskApi.permanentlyDeleteTask(task.taskId);
                }
                await loadDeletedTasks();
                Get.back();
                Get.snackbar(
                  'Success',
                  'All tasks deleted permanently',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: AppColors.success,
                  colorText: AppColors.textPrimary,
                );
              } catch (e) {
                developer.log('Error deleting all: $e', name: 'TrashController');
                Get.back();
              }
            },
            child: const Text('Delete All', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}
