import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:glass/glass.dart';
import 'package:mymanager/screen/create_task/create_task_controller.dart';
import 'package:mymanager/screen/create_task/widgets/create_task_form.dart';
import 'package:mymanager/theme/app_colors.dart';
import 'package:mymanager/theme/app_text_styles.dart';
import 'package:mymanager/theme/app_decorations.dart';

Future<void> showCreateTaskBottomSheet() async {
  if (!Get.isRegistered<CreateTaskController>()) {
    Get.put(CreateTaskController());
  }
  await Get.bottomSheet<void>(
    const CreateTaskView(),
    isScrollControlled: true,
    backgroundColor: AppColors.transparent,
    enableDrag: true,
  );
}

class CreateTaskView extends GetView<CreateTaskController> {
  const CreateTaskView({super.key});

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    return SafeArea(
      child: SizedBox(
        height: height < 760 ? height * 0.94 : height * 0.90,
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          child: Container(
            decoration: BoxDecoration(
              gradient: AppColors.modalGradient(0.95),
            ),
            child: Column(
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: AppDecorations.handleDecoration,
                ),

                // Header
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.white.withOpacity(0.08)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF5B8DEE), Color(0xFF3B6BBE)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.add_task_rounded, color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Create Task', style: AppTextStyles.headline2),
                            const SizedBox(height: 2),
                            Text(
                              'Capture work, set priority, and schedule reminders.',
                              style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close_rounded, color: AppColors.textPrimary),
                        onPressed: () => Get.back(),
                      ),
                    ],
                  ),
                ),

                // Form
                const Expanded(child: CreateTaskForm()),
              ],
            ),
          ).asGlass(
            tintColor: AppColors.transparent,
            clipBorderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
        ),
      ),
    );
  }
}
