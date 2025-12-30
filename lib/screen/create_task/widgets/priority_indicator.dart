import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mymanager/constants/app_constants.dart';
import 'package:mymanager/screen/create_task/create_task_controller.dart';

class PriorityIndicator extends GetView<CreateTaskController> {
  const PriorityIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() => Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _getPriorityColor(controller.computedPriority).withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _getPriorityColor(controller.computedPriority).withOpacity(0.5),
            ),
          ),
          child: Row(
            children: [
              Icon(
                _getPriorityIcon(controller.computedPriority),
                color: _getPriorityColor(controller.computedPriority),
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  controller.computedPriority,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ));
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case AppConstants.priorityUrgentImportant:
        return Colors.red;
      case AppConstants.priorityUrgentNotImportant:
        return Colors.orange;
      case AppConstants.priorityNotUrgentImportant:
        return Colors.green;
      case AppConstants.priorityNotUrgentNotImportant:
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  IconData _getPriorityIcon(String priority) {
    switch (priority) {
      case AppConstants.priorityUrgentImportant:
        return Icons.priority_high;
      case AppConstants.priorityUrgentNotImportant:
        return Icons.people;
      case AppConstants.priorityNotUrgentImportant:
        return Icons.event_available;
      case AppConstants.priorityNotUrgentNotImportant:
        return Icons.delete_sweep;
      default:
        return Icons.task;
    }
  }
}
