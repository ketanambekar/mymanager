import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mymanager/screen/trash/trash_controller.dart';
import 'package:mymanager/theme/app_colors.dart';

class TrashView extends StatelessWidget {
  const TrashView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(TrashController());

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textBlack),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'Trash',
          style: TextStyle(
            color: AppColors.textBlack,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          Obx(() {
            if (controller.deletedTasks.isEmpty) return const SizedBox();
            return PopupMenuButton(
              icon: const Icon(Icons.more_vert, color: AppColors.textBlack),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'restore_all',
                  child: Text('Restore All'),
                ),
                const PopupMenuItem(
                  value: 'delete_all',
                  child: Text('Delete All Permanently'),
                ),
              ],
              onSelected: (value) {
                if (value == 'restore_all') {
                  controller.restoreAll();
                } else if (value == 'delete_all') {
                  controller.deleteAllPermanently();
                }
              },
            );
          }),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        if (controller.deletedTasks.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.delete_outline,
                  size: 80,
                  color: AppColors.gray300,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Trash is empty',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textBlack,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Deleted tasks will appear here',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textBlackTertiary,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: controller.deletedTasks.length,
          itemBuilder: (context, index) {
            final task = controller.deletedTasks[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadowLight,
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          task.taskTitle,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textBlack,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.restore, color: AppColors.success),
                        onPressed: () => controller.restoreTask(task.taskId),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_forever, color: AppColors.error),
                        onPressed: () => controller.deletePermanently(task.taskId),
                      ),
                    ],
                  ),
                  if (task.taskDescription != null && task.taskDescription!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      task.taskDescription!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textBlackSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    'Deleted: ${_formatDate(task.taskUpdatedAt)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textBlackTertiary,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      }),
    );
  }

  String _formatDate(String? isoDate) {
    if (isoDate == null) return '';
    final date = DateTime.parse(isoDate);
    return '${date.day}/${date.month}/${date.year}';
  }
}
