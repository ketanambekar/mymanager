import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mymanager/screen/task_group_detail/task_group_detail_controller.dart';
import 'package:mymanager/theme/app_colors.dart';
import 'package:mymanager/database/tables/tasks/models/task_model.dart';
import 'package:mymanager/screen/edit_task/edit_task_view.dart';
import 'package:intl/intl.dart';

class TaskGroupDetailView extends StatelessWidget {
  final String projectId;
  final String projectName;
  final Color projectColor;

  const TaskGroupDetailView({
    super.key,
    required this.projectId,
    required this.projectName,
    required this.projectColor,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(
      TaskGroupDetailController(projectId: projectId),
      tag: projectId,
    );

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF1A1A2E),
              const Color(0xFF16213E),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Get.back(),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            projectName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Obx(() => Text(
                            '${controller.tasks.length} Task${controller.tasks.length != 1 ? 's' : ''}',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 14,
                            ),
                          )),
                        ],
                      ),
                    ),
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: projectColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.folder_outlined,
                        color: projectColor,
                        size: 24,
                      ),
                    ),
                  ],
                ),
              ),

              // Stats
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: Obx(() {
                  final total = controller.tasks.length;
                  final completed = controller.tasks.where((t) => t.taskStatus == 'Completed').length;
                  final inProgress = controller.tasks.where((t) => t.taskStatus == 'In Progress').length;
                  final todo = controller.tasks.where((t) => t.taskStatus == 'Todo').length;
                  
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem('Total', total.toString(), projectColor),
                      _buildStatItem('To Do', todo.toString(), const Color(0xFF7C4DFF)),
                      _buildStatItem('In Progress', inProgress.toString(), const Color(0xFFFFBE0B)),
                      _buildStatItem('Done', completed.toString(), const Color(0xFF4ECDC4)),
                    ],
                  );
                }),
              ),

              const SizedBox(height: 20),

              // Tasks List
              Expanded(
                child: Obx(() {
                  if (controller.isLoading.value) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF7C4DFF),
                      ),
                    );
                  }

                  if (controller.tasks.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.task_outlined,
                            size: 64,
                            color: Colors.white.withOpacity(0.3),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No tasks in this project',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: controller.loadTasks,
                    color: const Color(0xFF7C4DFF),
                    backgroundColor: const Color(0xFF1A1A2E),
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: controller.tasks.length,
                      itemBuilder: (context, index) {
                        final task = controller.tasks[index];
                        return _buildTaskCard(task, projectColor);
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

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.6),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildTaskCard(Task task, Color color) {
    final bool isCompleted = task.taskStatus == 'Completed';
    final bool isOverdue = task.taskDueDate != null &&
        DateTime.parse(task.taskDueDate!).isBefore(DateTime.now()) &&
        !isCompleted;
    final controller = Get.find<TaskGroupDetailController>(tag: projectId);
    final hasSubtasks = controller.subtasksMap.containsKey(task.taskId);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isOverdue
              ? const Color(0xFFFF6B6B).withOpacity(0.5)
              : Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () async {
              await Get.to(() => EditTaskView(task: task));
              controller.loadTasks();
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 4,
                        height: 40,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              task.taskTitle,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                decoration: isCompleted
                                    ? TextDecoration.lineThrough
                                    : TextDecoration.none,
                              ),
                            ),
                            if (task.taskDescription != null &&
                                task.taskDescription!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  task.taskDescription!,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.6),
                                    fontSize: 13,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (hasSubtasks)
                        Obx(() => GestureDetector(
                          onTap: () => controller.toggleTaskExpansion(task.taskId),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              controller.isTaskExpanded(task.taskId)
                                  ? Icons.keyboard_arrow_up
                                  : Icons.keyboard_arrow_down,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        )),
                    ],
                  ),
                  if (task.taskDueDate != null) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 16,
                          color: isOverdue
                              ? const Color(0xFFFF6B6B)
                              : Colors.white.withOpacity(0.6),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _formatDueDate(task.taskDueDate!),
                          style: TextStyle(
                            color: isOverdue
                                ? const Color(0xFFFF6B6B)
                                : Colors.white.withOpacity(0.6),
                            fontSize: 13,
                            fontWeight: isOverdue ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                        if (task.taskFrequency != null && task.taskFrequency != 'Once') ...[
                          const SizedBox(width: 12),
                          Icon(
                            Icons.repeat,
                            size: 16,
                            color: Colors.white.withOpacity(0.6),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            task.taskFrequency!,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                  if (task.taskPriority != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.flag,
                          size: 16,
                          color: _getPriorityColor(task.taskPriority!),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          task.taskPriority!,
                          style: TextStyle(
                            color: _getPriorityColor(task.taskPriority!),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildStatusChip('Todo', task, controller),
                      const SizedBox(width: 8),
                      _buildStatusChip('In Progress', task, controller),
                      const SizedBox(width: 8),
                      _buildStatusChip('Completed', task, controller),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Subtasks section
          if (hasSubtasks)
            Obx(() {
              if (!controller.isTaskExpanded(task.taskId)) {
                return const SizedBox.shrink();
              }
              final subtasks = controller.subtasksMap[task.taskId] ?? [];
              return Container(
                padding: const EdgeInsets.only(left: 32, right: 16, bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Divider(color: Colors.white.withOpacity(0.1)),
                    const SizedBox(height: 8),
                    Text(
                      'Subtasks (${subtasks.length})',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...subtasks.map((subtask) => _buildSubtaskItem(subtask, controller)),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  String _formatDueDate(String dueDate) {
    final date = DateTime.parse(dueDate);
    final now = DateTime.now();
    final difference = date.difference(now);

    if (difference.isNegative) {
      final days = difference.inDays.abs();
      if (days == 0) {
        return 'Overdue today';
      } else if (days == 1) {
        return 'Overdue by 1 day';
      } else {
        return 'Overdue by $days days';
      }
    } else if (difference.inDays == 0) {
      return 'Due today at ${DateFormat('h:mm a').format(date)}';
    } else if (difference.inDays == 1) {
      return 'Due tomorrow';
    } else if (difference.inDays < 7) {
      return 'Due ${DateFormat('EEEE').format(date)}';
    } else {
      return 'Due ${DateFormat('MMM d, yyyy').format(date)}';
    }
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'Completed':
        return const Color(0xFF4ECDC4);
      case 'In Progress':
        return const Color(0xFFFFBE0B);
      case 'Todo':
      default:
        return const Color(0xFF7C4DFF);
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'High':
        return const Color(0xFFFF6B6B);
      case 'Medium':
        return const Color(0xFFFFBE0B);
      case 'Low':
        return const Color(0xFF4ECDC4);
      default:
        return const Color(0xFF7C4DFF);
    }
  }

  Widget _buildStatusChip(String status, Task task, TaskGroupDetailController controller) {
    final isSelected = task.taskStatus == status;
    final color = _getStatusColor(status);
    
    return GestureDetector(
      onTap: () => controller.changeTaskStatus(task, status),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.2) : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.white.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Text(
          status,
          style: TextStyle(
            color: isSelected ? color : Colors.white.withOpacity(0.6),
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildSubtaskItem(Task subtask, TaskGroupDetailController controller) {
    final isCompleted = subtask.taskStatus == 'Completed';
    
    return GestureDetector(
      onTap: () => controller.toggleSubtaskStatus(subtask),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isCompleted ? const Color(0xFF4ECDC4) : Colors.white.withOpacity(0.4),
                  width: 2,
                ),
                color: isCompleted ? const Color(0xFF4ECDC4) : Colors.transparent,
              ),
              child: isCompleted
                  ? const Icon(
                      Icons.check,
                      size: 14,
                      color: Colors.white,
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                subtask.taskTitle,
                style: TextStyle(
                  color: Colors.white.withOpacity(isCompleted ? 0.5 : 0.9),
                  fontSize: 14,
                  decoration: isCompleted ? TextDecoration.lineThrough : TextDecoration.none,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
