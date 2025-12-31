import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mymanager/screen/task_listing/task_listing_controller.dart';
import 'package:mymanager/database/tables/tasks/models/task_model.dart';
import 'package:mymanager/database/apis/user_project_api.dart';

class TaskListingView extends StatelessWidget {
  const TaskListingView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(TaskListingController());

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'All Tasks',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          // Filter chips
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Obx(() {
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _FilterChip(
                      label: 'All',
                      isSelected: controller.selectedFilter.value == 'All',
                      onTap: () => controller.setFilter('All'),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Todo',
                      isSelected: controller.selectedFilter.value == 'Todo',
                      onTap: () => controller.setFilter('Todo'),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'In Progress',
                      isSelected: controller.selectedFilter.value == 'In Progress',
                      onTap: () => controller.setFilter('In Progress'),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Completed',
                      isSelected: controller.selectedFilter.value == 'Completed',
                      onTap: () => controller.setFilter('Completed'),
                    ),
                  ],
                ),
              );
            }),
          ),

          // Task list
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF7C4DFF),
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
                        Icons.task_outlined,
                        size: 80,
                        color: Colors.white.withOpacity(0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No tasks found',
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
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    return _TaskCard(task: task);
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF7C4DFF)
              : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF7C4DFF)
                : Colors.white.withOpacity(0.2),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  final Task task;

  const _TaskCard({required this.task});

  Color _getPriorityColor() {
    switch (task.taskPriority) {
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

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final difference = date.difference(now);

      if (difference.isNegative && task.taskStatus != 'Completed') {
        return 'Overdue';
      } else if (difference.inDays == 0) {
        return 'Today';
      } else if (difference.inDays == 1) {
        return 'Tomorrow';
      } else if (difference.inDays > 1 && difference.inDays < 7) {
        return '${difference.inDays} days';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final priorityColor = _getPriorityColor();
    final isOverdue = task.taskDueDate != null &&
        DateTime.parse(task.taskDueDate!).isBefore(DateTime.now()) &&
        task.taskStatus != 'Completed';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: priorityColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 40,
                decoration: BoxDecoration(
                  color: priorityColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FutureBuilder<String>(
                      future: _getProjectName(),
                      builder: (context, snapshot) {
                        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                          return Text(
                            snapshot.data!,
                            style: TextStyle(
                              color: priorityColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                    const SizedBox(height: 4),
                    Text(
                      task.taskTitle,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (task.taskDescription != null &&
                        task.taskDescription!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        task.taskDescription!,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 13,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getStatusColor().withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  task.taskStatus ?? 'Todo',
                  style: TextStyle(
                    color: _getStatusColor(),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.access_time,
                size: 14,
                color: isOverdue ? const Color(0xFFFF6B6B) : Colors.white70,
              ),
              const SizedBox(width: 4),
              Text(
                _formatDate(task.taskDueDate),
                style: TextStyle(
                  color: isOverdue ? const Color(0xFFFF6B6B) : Colors.white70,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 16),
              Icon(
                Icons.flag_outlined,
                size: 14,
                color: priorityColor,
              ),
              const SizedBox(width: 4),
              Text(
                task.taskPriority ?? 'Normal',
                style: TextStyle(
                  color: priorityColor,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getStatusColor() {
    switch (task.taskStatus) {
      case 'Completed':
        return const Color(0xFF4ECDC4);
      case 'In Progress':
        return const Color(0xFFFFBE0B);
      default:
        return const Color(0xFF7C4DFF);
    }
  }

  Future<String> _getProjectName() async {
    if (task.projectId == null) return '';
    try {
      final project = await UserProjectsApi.getProjectById(task.projectId!);
      return project?.projectName ?? '';
    } catch (e) {
      return '';
    }
  }
}
