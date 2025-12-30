import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:glass/glass.dart';
import 'package:mymanager/constants/app_constants.dart';
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
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(
      child: Container(
        height: MediaQuery.of(context).size.height * 0.85,
        margin: EdgeInsets.only(bottom: bottomInset),
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
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Text(
                        'Create Task',
                        style: AppTextStyles.headline2,
                      ),
                      const Spacer(),
                      IconButton(
                        icon: Icon(Icons.close, color: AppColors.textPrimary),
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
