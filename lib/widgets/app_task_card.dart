import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:mymanager/constants/app_constants.dart';
import 'package:mymanager/database/tables/tasks/models/task_model.dart';
import 'package:mymanager/theme/app_theme.dart';
import 'package:mymanager/utils/global_utils.dart';

/// Natural-looking task card with organic feel
class TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback? onTap;
  final VoidCallback? onComplete;
  final VoidCallback? onDelete;
  final bool showProject;

  const TaskCard({
    super.key,
    required this.task,
    this.onTap,
    this.onComplete,
    this.onDelete,
    this.showProject = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title and priority indicator
                Row(
                  children: [
                    // Priority dot
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: _getPriorityColor(),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: _getPriorityColor().withOpacity(0.4),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        task.taskTitle,
                        style: AppTextStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: Colors.white,
                          decoration: task.taskStatus == AppConstants.taskStatusCompleted
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                    ),
                    if (task.focusRequired)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.psychology, size: 14, color: Colors.orange),
                            SizedBox(width: 4),
                            Text('Focus', style: TextStyle(fontSize: 10, color: Colors.white)),
                          ],
                        ),
                      ),
                  ],
                ),

                if (task.taskDescription != null && task.taskDescription!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    task.taskDescription!,
                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],

                const SizedBox(height: 12),

                // Metadata row
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    if (task.taskDueDate != null)
                      _buildMetaChip(
                        icon: task.isOverdue
                            ? Icons.warning_amber_rounded
                            : Icons.calendar_today,
                        label: timeAgo(task.taskDueDate!),
                        color: task.isOverdue ? Colors.red : Colors.blue,
                      ),
                    if (task.timeEstimate != null)
                      _buildMetaChip(
                        icon: Icons.access_time,
                        label: '${task.timeEstimate}m',
                        color: Colors.purple,
                      ),
                    if (task.energyLevel != null)
                      _buildMetaChip(
                        icon: Icons.battery_charging_full,
                        label: task.energyLevel!,
                        color: _getEnergyColor(),
                      ),
                    if (task.taskFrequency != null &&
                        task.taskFrequency != AppConstants.frequencyOnce)
                      _buildMetaChip(
                        icon: Icons.repeat,
                        label: task.taskFrequency!,
                        color: Colors.teal,
                      ),
                  ],
                ),

                // Action buttons
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (onComplete != null && task.taskStatus != AppConstants.taskStatusCompleted)
                      _buildActionButton(
                        icon: Icons.check_circle_outline,
                        label: 'Complete',
                        color: Colors.green,
                        onTap: onComplete!,
                      ),
                    const Spacer(),
                    if (onDelete != null)
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20),
                        color: Colors.red.withOpacity(0.7),
                        onPressed: onDelete,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms, curve: Curves.easeOut)
        .slideY(begin: 0.2, end: 0, curve: Curves.easeOutCubic);
  }

  Widget _buildMetaChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getPriorityColor() {
    if (task.isUrgentAndImportant) return Colors.red;
    if (task.isUrgentNotImportant) return Colors.orange;
    if (task.isNotUrgentButImportant) return Colors.green;
    return Colors.grey;
  }

  Color _getEnergyColor() {
    switch (task.energyLevel) {
      case AppConstants.energyHigh:
        return Colors.red;
      case AppConstants.energyMedium:
        return Colors.yellow;
      case AppConstants.energyLow:
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}
