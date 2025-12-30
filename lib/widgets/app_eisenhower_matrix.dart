import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:mymanager/constants/app_constants.dart';
import 'package:mymanager/database/tables/tasks/models/task_model.dart';
import 'package:mymanager/theme/app_theme.dart';

/// Eisenhower Matrix visual quadrant view
class EisenhowerMatrix extends StatelessWidget {
  final List<Task> urgentImportant;
  final List<Task> urgentNotImportant;
  final List<Task> notUrgentImportant;
  final List<Task> notUrgentNotImportant;
  final Function(Task)? onTaskTap;

  const EisenhowerMatrix({
    super.key,
    required this.urgentImportant,
    required this.urgentNotImportant,
    required this.notUrgentImportant,
    required this.notUrgentNotImportant,
    this.onTaskTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            'Eisenhower Matrix',
            style: AppTheme.headlineSmall.copyWith(fontSize: 20),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Column(
              children: [
                // Top row: Urgent
                Expanded(
                  child: Row(
                    children: [
                      // Q1: Urgent & Important
                      Expanded(
                        child: _buildQuadrant(
                          title: 'Do First',
                          subtitle: 'Urgent & Important',
                          tasks: urgentImportant,
                          color: Colors.red,
                          icon: Icons.priority_high,
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Q2: Urgent but Not Important
                      Expanded(
                        child: _buildQuadrant(
                          title: 'Delegate',
                          subtitle: 'Urgent',
                          tasks: urgentNotImportant,
                          color: Colors.orange,
                          icon: Icons.people,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Bottom row: Not Urgent
                Expanded(
                  child: Row(
                    children: [
                      // Q3: Not Urgent but Important
                      Expanded(
                        child: _buildQuadrant(
                          title: 'Schedule',
                          subtitle: 'Important',
                          tasks: notUrgentImportant,
                          color: Colors.green,
                          icon: Icons.event_available,
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Q4: Not Urgent & Not Important
                      Expanded(
                        child: _buildQuadrant(
                          title: 'Eliminate',
                          subtitle: 'Low Priority',
                          tasks: notUrgentNotImportant,
                          color: Colors.grey,
                          icon: Icons.delete_sweep,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuadrant({
    required String title,
    required String subtitle,
    required List<Task> tasks,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${tasks.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Task list
          Expanded(
            child: tasks.isEmpty
                ? Center(
                    child: Text(
                      'No tasks',
                      style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: tasks.length,
                    itemBuilder: (context, index) {
                      final task = tasks[index];
                      return GestureDetector(
                        onTap: () => onTaskTap?.call(task),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  task.taskTitle,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    ).animate().scale(duration: 500.ms, curve: Curves.elasticOut);
  }
}
