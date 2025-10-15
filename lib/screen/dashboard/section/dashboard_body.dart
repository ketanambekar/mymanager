import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mymanager/core/models/task_model.dart';
import 'package:mymanager/screen/dashboard/widgets/summary.dart';
import 'package:mymanager/screen/dashboard/widgets/task_cards.dart';
import 'package:mymanager/services/tasks_services/task_storage_service.dart';

class DashboardContent extends StatelessWidget {
  const DashboardContent({super.key});

  // Try to parse date + time in common formats. Returns null on failure.
  DateTime? _parseDateTime(String? dateStr, String? timeStr) {
    if (dateStr == null || dateStr.isEmpty) return null;

    try {
      // If dateStr already contains a time part (ISO), parse directly
      if (dateStr.contains('T')) {
        return DateTime.parse(dateStr);
      }

      // If we have both date and time (time like "HH:mm")
      if (timeStr != null && timeStr.isNotEmpty) {
        final time = timeStr.length == 5
            ? '${timeStr}:00'
            : timeStr; // make HH:mm -> HH:mm:ss
        return DateTime.parse('${dateStr}T$time');
      }

      // Last resort: parse date-only (YYYY-MM-DD)
      return DateTime.parse(dateStr);
    } catch (_) {
      // parsing failed, return null
      return null;
    }
  }

  // Convert a DateTime to a local date-only key: year-month-day
  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  // Format the header e.g. "20 Sep 2025"
  String _formatDateHeader(DateTime d) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final TaskStorageService svc = Get.put(TaskStorageService());

    return SafeArea(
      child: Obx(() {
        final List<Task> tasks = svc.tasks;

        // Summary values
        final total = tasks.length;
        final completed = tasks
            .where((t) => (t.taskStatus ?? '') == 'completed')
            .length;
        final pending = total - completed;

        // Group tasks by date-only key. Use `null` key for tasks without a date.
        final Map<DateTime?, List<Task>> groups = {};
        for (final t in tasks) {
          final dt = _parseDateTime(t.taskStartDate ?? t.taskDate, t.taskTime);
          final key = dt != null ? _dateOnly(dt) : null;
          groups.putIfAbsent(key, () => []).add(t);
        }

        // Sort group keys: non-null dates descending (newest first), null at the end
        final keys = groups.keys.toList()
          ..sort((a, b) {
            if (a == null && b == null) return 0;
            if (a == null) return 1; // a after b
            if (b == null) return -1;
            return b.compareTo(a); // newest first
          });

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Task summary at top
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              child: TaskSummary(
                total: total,
                completed: completed,
                pending: pending,
                onTotalTap: () => print('Total tapped'),
                onCompletedTap: () => print('Completed tapped'),
                onPendingTap: () => print('Pending tapped'),
              ),
            ),

            const SizedBox(height: 16),

            // If no tasks show placeholder
            if (tasks.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.inbox, size: 56, color: Colors.white24),
                      SizedBox(height: 12),
                      Text(
                        'No tasks yet',
                        style: TextStyle(color: Colors.white54),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Tap + to create your first task',
                        style: TextStyle(color: Colors.white38),
                      ),
                    ],
                  ),
                ),
              )
            else
              // Sectioned list by date
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.only(bottom: 80),
                  itemCount: keys.length,
                  itemBuilder: (context, sectionIndex) {
                    final DateTime? dateKey = keys[sectionIndex];
                    final groupTasks = groups[dateKey] ?? [];

                    // sort tasks inside the date:
                    // 1) incomplete first, completed last
                    // 2) then by time ascending (earliest first) if available
                    groupTasks.sort((a, b) {
                      final aDone = (a.taskStatus ?? '') == 'completed';
                      final bDone = (b.taskStatus ?? '') == 'completed';
                      if (aDone != bDone)
                        return aDone ? 1 : -1; // completed go down

                      final aDt = _parseDateTime(
                        a.taskStartDate ?? a.taskDate,
                        a.taskTime,
                      );
                      final bDt = _parseDateTime(
                        b.taskStartDate ?? b.taskDate,
                        b.taskTime,
                      );
                      if (aDt == null && bDt == null) return 0;
                      if (aDt == null) return 1;
                      if (bDt == null) return -1;
                      return aDt.compareTo(bDt); // earliest first
                    });

                    // Build a column: date header + tasks for that date
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // date header
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
                          child: Text(
                            dateKey == null
                                ? 'No date'
                                : _formatDateHeader(dateKey),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),

                        // tasks of the day
                        ...groupTasks.map((task) {
                          final dt = _parseDateTime(
                            task.taskStartDate ?? task.taskDate,
                            task.taskTime,
                          );

                          return TaskCard(
                            id: task.id,
                            title: task.taskName,
                            subtitle: task.taskDescription ?? '',
                            time: dt,
                            done: (task.taskStatus ?? '') == 'completed',
                            onTap: () {
                              print('open task ${task.id}');
                            },
                            onToggleDone: (v) async {
                              final newStatus = v ? 'completed' : 'pending';
                              await svc.patchTask(task.id, {
                                'taskStatus': newStatus,
                              });
                            },
                            onEdit: () {
                              print('edit ${task.id}');
                            },
                            onDelete: () async {
                              final removed = await svc.deleteTask(task.id);
                              if (removed) {
                                Get.snackbar(
                                  'Deleted',
                                  'Task removed',
                                  snackPosition: SnackPosition.BOTTOM,
                                  backgroundColor: Colors.black87,
                                  colorText: Colors.white,
                                );
                              } else {
                                Get.snackbar(
                                  'Error',
                                  'Could not remove task',
                                  snackPosition: SnackPosition.BOTTOM,
                                );
                              }
                            },
                          );
                        }).toList(),
                      ],
                    );
                  },
                ),
              ),
          ],
        );
      }),
    );
  }
}
