import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mymanager/screen/tasks/tasks_controller.dart';
import 'package:mymanager/screen/edit_task/edit_task_view.dart';
import 'package:mymanager/theme/app_colors.dart';
import 'package:mymanager/database/tables/tasks/models/task_model.dart';
import 'package:mymanager/database/apis/user_project_api.dart';
import 'package:intl/intl.dart';

class TasksView extends StatelessWidget {
  const TasksView({super.key});

  @override
  Widget build(BuildContext context) {
    final TasksController controller = Get.put(TasksController());

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Calendar date selector
            Container(
              height: 90,
              color: AppColors.darkBackground,
              child: Obx(() {
                final selectedDate = controller.selectedDate.value;
                final today = DateTime.now();
                final dates = List.generate(30, (index) {
                  return today.add(Duration(days: index - 7));
                });
                
                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: dates.length,
                  itemBuilder: (context, index) {
                    final date = dates[index];
                    final isSelected = date.day == selectedDate.day &&
                        date.month == selectedDate.month &&
                        date.year == selectedDate.year;
                    
                    return GestureDetector(
                      onTap: () => controller.selectDate(date),
                      child: Container(
                        width: 60,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary : AppColors.cardDark,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.shadowDark,
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              DateFormat('MMM').format(date),
                              style: TextStyle(
                                color: isSelected ? AppColors.textPrimary : AppColors.textBlackTertiary,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              date.day.toString(),
                              style: TextStyle(
                                color: isSelected ? AppColors.textPrimary : AppColors.textBlack,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              DateFormat('E').format(date),
                              style: TextStyle(
                                color: isSelected ? AppColors.textPrimary : AppColors.textBlackTertiary,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              }),
            ),
            
            // Filter tabs
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Obx(() {
                return Row(
                  children: [
                    _FilterTab(
                      label: 'All',
                      isSelected: controller.selectedFilter.value == 'All',
                      onTap: () => controller.setFilter('All'),
                    ),
                    const SizedBox(width: 8),
                    _FilterTab(
                      label: 'To do',
                      isSelected: controller.selectedFilter.value == 'To do',
                      onTap: () => controller.setFilter('To do'),
                    ),
                    const SizedBox(width: 8),
                    _FilterTab(
                      label: 'In Progress',
                      isSelected: controller.selectedFilter.value == 'In Progress',
                      onTap: () => controller.setFilter('In Progress'),
                    ),
                    const SizedBox(width: 8),
                    _FilterTab(
                      label: 'Completed',
                      isSelected: controller.selectedFilter.value == 'Completed',
                      onTap: () => controller.setFilter('Completed'),
                    ),
                  ],
                );
              }),
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
                          color: AppColors.gray300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No tasks here',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Create a task to get started',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                
                return RefreshIndicator(
                  onRefresh: controller.loadTasks,
                  color: AppColors.primary,
                  backgroundColor: AppColors.cardDark,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: tasks.length,
                    itemBuilder: (context, index) {
                      final task = tasks[index];
                      return _TaskCard(
                        task: task,
                        controller: controller,
                        onTap: () {
                          Get.to(() => EditTaskView(task: task));
                        },
                      );
                    },
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterTab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterTab({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.cardDark,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowDark,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  final Task task;
  final TasksController controller;
  final VoidCallback onTap;

  const _TaskCard({
    required this.task,
    required this.controller,
    required this.onTap,
  });

  Color _getProjectColor() {
    // Use priority-based colors
    switch (task.taskPriority) {
      case 'High':
        return AppColors.error; // Red for high priority
      case 'Medium':
        return AppColors.warning; // Orange for medium priority
      case 'Low':
        return AppColors.success; // Green for low priority
      default:
        return AppColors.info; // Blue for no priority
    }
  }

  String _getStatusLabel() {
    switch (task.taskStatus) {
      case 'Completed':
        return 'Done';
      case 'In Progress':
        return 'In Progress';
      case 'Todo':
        return 'To do';
      default:
        return 'To do';
    }
  }

  Color _getStatusColor() {
    switch (task.taskStatus) {
      case 'Completed':
        return AppColors.completedStatus;
      case 'In Progress':
        return AppColors.inProgressStatus;
      case 'Todo':
        return AppColors.todoStatus;
      default:
        return AppColors.todoStatus;
    }
  }

  String _formatTime(String? isoDate) {
    if (isoDate == null) return '';
    final date = DateTime.parse(isoDate);
    final now = DateTime.now();
    final difference = date.difference(now);
    
    // Check if task is overdue or upcoming
    if (difference.isNegative && task.taskStatus != 'Completed') {
      final hours = difference.inHours.abs();
      if (hours < 1) {
        return 'MISSED (${difference.inMinutes.abs()}m ago)';
      } else if (hours < 24) {
        return 'MISSED (${hours}h ago)';
      } else {
        return 'MISSED (${difference.inDays.abs()}d ago)';
      }
    } else if (difference.inMinutes > 0 && difference.inHours < 24) {
      // Show upcoming within 24 hours
      if (difference.inHours < 1) {
        return 'In ${difference.inMinutes}m';
      } else {
        return 'In ${difference.inHours}h ${difference.inMinutes % 60}m';
      }
    }
    
    final hour = date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute ${date.hour >= 12 ? 'PM' : 'AM'}';
  }
  
  Color _getTimeColor(String? isoDate) {
    if (isoDate == null) return AppColors.textTertiary;
    final date = DateTime.parse(isoDate);
    final now = DateTime.now();
    final difference = date.difference(now);
    
    if (difference.isNegative && task.taskStatus != 'Completed') {
      return AppColors.error; // Red for missed
    } else if (difference.inMinutes > 0 && difference.inHours < 2) {
      return AppColors.warning; // Orange for upcoming soon
    }
    
    return AppColors.textTertiary;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: task.projectId != null 
        ? UserProjectsApi.getProjectById(task.projectId!)
        : Future.value(null),
      builder: (context, snapshot) {
        final projectName = snapshot.data?.projectName;
        final projectColor = _getProjectColor();
        final subtaskCount = controller.getSubtaskCount(task.taskId);
        final hasSubtasks = subtaskCount > 0;
        final timeText = _formatTime(task.taskDueDate);
        final timeColor = _getTimeColor(task.taskDueDate);
        
        return Obx(() {
          final isExpanded = controller.isTaskExpanded(task.taskId);
          final subtasks = controller.getSubtasks(task.taskId);
          
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
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
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // Status toggle button
                      GestureDetector(
                        onTap: () => controller.cycleTaskStatus(task.taskId, task.taskStatus),
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: _getStatusColor().withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _getStatusColor(),
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            task.taskStatus == 'Completed'
                                ? Icons.check
                                : task.taskStatus == 'In Progress'
                                    ? Icons.more_horiz
                                    : Icons.circle_outlined,
                            size: 16,
                            color: _getStatusColor(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: onTap,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  if (projectName != null) ...[
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: projectColor.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        projectName,
                                        style: TextStyle(
                                          color: projectColor,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                  ],
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: projectColor.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: projectColor, width: 1.5),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          task.taskPriority == 'High' 
                                            ? Icons.priority_high 
                                            : task.taskPriority == 'Medium'
                                              ? Icons.drag_handle
                                              : Icons.low_priority,
                                          size: 12,
                                          color: projectColor,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          task.taskPriority ?? 'Low',
                                          style: TextStyle(
                                            color: projectColor,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (hasSubtasks) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.subdirectory_arrow_right,
                                            size: 14,
                                            color: AppColors.primary,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '$subtaskCount',
                                            style: TextStyle(
                                              color: AppColors.primary,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                task.taskTitle,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Icon(
                                    Icons.access_time,
                                    size: 16,
                                    color: timeColor,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    timeText,
                                    style: TextStyle(
                                      color: timeColor,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor().withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Text(
                                      _getStatusLabel(),
                                      style: TextStyle(
                                        color: _getStatusColor(),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Subtasks accordion
                if (hasSubtasks)
                  Column(
                    children: [
                      Divider(height: 1, color: AppColors.gray600),
                      InkWell(
                        onTap: () => controller.toggleTaskExpansion(task.taskId),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Row(
                            children: [
                              Icon(
                                isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                                color: AppColors.primary,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                isExpanded ? 'Hide subtasks' : 'Show subtasks ($subtaskCount)',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (isExpanded)
                        Container(
                          padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
                          child: Column(
                            children: subtasks.map((subtask) {
                              final subtaskColor = _getStatusColorForStatus(subtask.taskStatus);
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.darkBackground,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppColors.gray600,
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      subtask.taskStatus == 'Completed'
                                          ? Icons.check_circle
                                          : Icons.circle_outlined,
                                      color: subtaskColor,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        subtask.taskTitle,
                                        style: TextStyle(
                                          color: AppColors.textPrimary,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          decoration: subtask.taskStatus == 'Completed'
                                              ? TextDecoration.lineThrough
                                              : null,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: subtaskColor.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        _getStatusLabelForStatus(subtask.taskStatus),
                                        style: TextStyle(
                                          color: subtaskColor,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                    ],
                  ),
              ],
            ),
          );
        });
      },
    );
  }

  String _getStatusLabelForStatus(String status) {
    switch (status) {
      case 'Completed':
        return 'Done';
      case 'In Progress':
        return 'In Progress';
      case 'Todo':
        return 'To do';
      default:
        return 'To do';
    }
  }

  Color _getStatusColorForStatus(String status) {
    switch (status) {
      case 'Completed':
        return AppColors.completedStatus;
      case 'In Progress':
        return AppColors.inProgressStatus;
      case 'Todo':
        return AppColors.todoStatus;
      default:
        return AppColors.todoStatus;
    }
  }
}
