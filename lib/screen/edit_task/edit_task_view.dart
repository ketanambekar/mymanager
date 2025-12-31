import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mymanager/screen/edit_task/edit_task_controller.dart';
import 'package:mymanager/screen/edit_task/widgets/edit_task_form.dart';
import 'package:mymanager/theme/app_colors.dart';
import 'package:mymanager/database/tables/tasks/models/task_model.dart';

class EditTaskView extends StatelessWidget {
  final Task task;

  const EditTaskView({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(EditTaskController(task: task));

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: SafeArea(
        child: Container(
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.darkBackground,
                AppColors.darkBackground.withOpacity(0.95),
              ],
            ),
          ),
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Get.back(),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.cardDark.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.textTertiary.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: const Icon(
                          Icons.arrow_back,
                          color: AppColors.textPrimary,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Text(
                        'Edit Task',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => controller.deleteTask(),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.error.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.error.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: const Icon(
                          Icons.delete_outline,
                          color: AppColors.error,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Form
              const Expanded(
                child: EditTaskForm(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
