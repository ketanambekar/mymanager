import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mymanager/theme/app_colors.dart';
import 'package:mymanager/screen/calander/calender_controller.dart';

class CalenderView extends StatelessWidget {
  const CalenderView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(CalenderController());

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.cardDark,
        elevation: 0,
        title: const Text(
          'Calendar',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cardDark,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadowDark,
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    'Calendar View',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Full calendar coming soon',
                    style: TextStyle(color: AppColors.textTertiary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Obx(() {
                final tasks = controller.tasksForSelectedDay;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tasks for Today',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (tasks.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: AppColors.cardDark,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Center(
                          child: Text(
                            'No tasks for this day',
                            style: TextStyle(color: AppColors.textTertiary),
                          ),
                        ),
                      )
                    else
                      ...tasks.map((task) => Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.cardDark,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.shadowDark,
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              task.taskTitle,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            if (task.taskDescription != null && task.taskDescription!.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                task.taskDescription!,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textSecondary,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      )),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
