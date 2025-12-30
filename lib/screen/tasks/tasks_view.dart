import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mymanager/screen/tasks/tasks_controller.dart';
import 'package:mymanager/theme/app_colors.dart';
import 'package:mymanager/theme/app_text_styles.dart';
import 'package:mymanager/theme/app_decorations.dart';
import 'package:mymanager/database/tables/tasks/models/task_model.dart';

class TasksView extends StatelessWidget {
  const TasksView({super.key});

  @override
  Widget build(BuildContext context) {
    final TasksController controller = Get.put(TasksController());

    return Scaffold(
      body: Container(
        decoration: AppDecorations.backgroundDecoration,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: AppDecorations.paddingLarge,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('My Tasks', style: AppTextStyles.headline1),
                    const SizedBox(height: 8),
                    Obx(() => Text(
                      '${controller.allTasks.where((t) => t.taskStatus != 'completed').length} active tasks',
                      style: AppTextStyles.bodyMedium,
                    )),
                  ],
                ),
              ),
              
              // Filter Chips
              SizedBox(
                height: 50,
                child: Obx(() => ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _FilterChip(
                      label: 'All',
                      isSelected: controller.selectedFilter.value == 'all',
                      count: controller.allTasks.where((t) => t.taskStatus != 'completed').length,
                      onTap: () => controller.selectedFilter.value = 'all',
                    ),
                    _FilterChip(
                      label: 'Today',
                      isSelected: controller.selectedFilter.value == 'today',
                      count: controller.todayTasks.length,
                      onTap: () => controller.selectedFilter.value = 'today',
                    ),
                    _FilterChip(
                      label: 'Upcoming',
                      isSelected: controller.selectedFilter.value == 'upcoming',
                      count: controller.upcomingTasks.length,
                      onTap: () => controller.selectedFilter.value = 'upcoming',
                    ),
                    _FilterChip(
                      label: 'Completed',
                      isSelected: controller.selectedFilter.value == 'completed',
                      count: controller.completedTasks.length,
                      onTap: () => controller.selectedFilter.value = 'completed',
                    ),
                  ],
                )),
              ),
              
              const SizedBox(height: 16),
              
              // Tasks List
              Expanded(
                child: Obx(() {
                  if (controller.isLoading.value) {
                    return Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    );
                  }
                  
                  final tasks = controller.filteredTasks;
                  
                  if (tasks.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.task_alt,
                            size: 80,
                            color: AppColors.textTertiary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No tasks here',
                            style: AppTextStyles.headline3,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Create a task to get started',
                            style: AppTextStyles.bodyMedium,
                          ),
                        ],
                      ),
                    );
                  }
                  
                  return RefreshIndicator(
                    onRefresh: controller.loadTasks,
                    color: AppColors.primary,
                    backgroundColor: AppColors.backgroundDark,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: tasks.length,
                      itemBuilder: (context, index) {
                        final task = tasks[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _TaskCard(
                            task: task,
                            onTap: () {
                              // TODO: Navigate to task details
                            },
                            onComplete: (isComplete) {
                              controller.toggleTaskComplete(task.taskId, isComplete);
                            },
                            onDelete: () {
                              _showDeleteDialog(context, controller, task.taskId);
                            },
                          ),
                        );
                      },
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  void _showDeleteDialog(BuildContext context, TasksController controller, String taskId) {
    Get.dialog(
      AlertDialog(
        backgroundColor: AppColors.backgroundDark,
        shape: AppDecorations.roundedShape(16),
        title: Text('Delete Task', style: AppTextStyles.dialogTitle),
        content: Text(
          'Are you sure you want to delete this task?',
          style: AppTextStyles.dialogContent,
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancel', style: AppTextStyles.buttonMedium.copyWith(
              color: AppColors.textSecondary,
            )),
          ),
          TextButton(
            onPressed: () {
              controller.deleteTask(taskId);
              Get.back();
            },
            child: Text('Delete', style: AppTextStyles.buttonMedium.copyWith(
              color: AppColors.error,
            )),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final int count;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected 
              ? AppColors.primary 
              : AppColors.glassBackground,
            borderRadius: AppDecorations.radiusMedium,
            border: Border.all(
              color: isSelected 
                ? AppColors.primary 
                : AppColors.glassBorder,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Text(
                label,
                style: AppTextStyles.buttonMedium.copyWith(
                  color: isSelected 
                    ? AppColors.textPrimary 
                    : AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected 
                    ? AppColors.textPrimary.withOpacity(0.2)
                    : AppColors.overlayMedium,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  count.toString(),
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback onTap;
  final Function(bool) onComplete;
  final VoidCallback onDelete;

  const _TaskCard({
    required this.task,
    required this.onTap,
    required this.onComplete,
    required this.onDelete,
  });

  Color _getPriorityColor() {
    switch (task.taskPriority) {
      case 'urgent_important':
        return AppColors.urgentImportant;
      case 'urgent_not_important':
        return AppColors.urgentNotImportant;
      case 'not_urgent_important':
        return AppColors.notUrgentImportant;
      case 'not_urgent_not_important':
        return AppColors.notUrgentNotImportant;
      default:
        return AppColors.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: AppDecorations.cardDecoration,
        child: Padding(
          padding: AppDecorations.paddingMedium,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Priority indicator
                  Container(
                    width: 4,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _getPriorityColor(),
                      borderRadius: AppDecorations.radiusSmall,
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  // Task info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.taskTitle,
                          style: AppTextStyles.bodyLarge.copyWith(
                            fontWeight: FontWeight.w600,
                            decoration: task.taskStatus == 'completed' 
                              ? TextDecoration.lineThrough 
                              : null,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (task.taskDueDate != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Due: ${_formatDate(task.taskDueDate!)}',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: _isOverdue() ? AppColors.error : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  
                  // Complete checkbox
                  Checkbox(
                    value: task.taskStatus == 'completed',
                    onChanged: (value) => onComplete(value ?? false),
                    fillColor: WidgetStateProperty.all(
                      task.taskStatus == 'completed' ? AppColors.success : AppColors.transparent,
                    ),
                    side: BorderSide(color: AppColors.glassBorder),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(String isoDate) {
    final date = DateTime.parse(isoDate);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) return 'Today';
    if (dateOnly == tomorrow) return 'Tomorrow';
    return '${date.day}/${date.month}/${date.year}';
  }

  bool _isOverdue() {
    if (task.taskDueDate == null || task.taskStatus == 'completed') return false;
    final dueDate = DateTime.parse(task.taskDueDate!);
    return dueDate.isBefore(DateTime.now());
  }
}
