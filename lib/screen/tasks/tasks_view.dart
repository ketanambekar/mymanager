import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:mymanager/database/models/task_status_option.dart';
import 'package:mymanager/screen/create_task/create_task_controller.dart';
import 'package:mymanager/screen/create_task/create_task_view.dart';
import 'package:mymanager/screen/edit_task/edit_task_view.dart';
import 'package:mymanager/screen/tasks/tasks_controller.dart';
import 'package:mymanager/routes/app_routes.dart';
import 'package:mymanager/theme/theme_tokens.dart';
import 'package:mymanager/widgets/app_side_menu.dart';

class TasksView extends StatelessWidget {
  const TasksView({super.key});

  Future<void> _openCreateTask(TasksController controller) async {
    if (Get.isRegistered<CreateTaskController>()) {
      Get.delete<CreateTaskController>();
    }
    await showCreateTaskBottomSheet();
    await controller.loadTasks();
  }

  Future<void> _showAddStatusDialog(BuildContext context, TasksController controller) async {
    final textController = TextEditingController();
    await Get.dialog(
      AlertDialog(
        title: const Text('Add Task Status'),
        content: TextField(
          controller: textController,
          decoration: const InputDecoration(hintText: 'e.g. On Hold, In Review'),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              final name = textController.text.trim();
              if (name.isEmpty) return;
              Get.back();
              try {
                await controller.addCustomStatus(name);
              } catch (e) {
                Get.snackbar('Error', e.toString().replaceFirst('Exception: ', ''));
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _showManageStatusesSheet(BuildContext context, TasksController controller) async {
    await Get.bottomSheet(
      Obx(
        () => Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
          decoration: BoxDecoration(
            color: context.panel,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text(
                    'Manage Statuses',
                    style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const Spacer(),
                  IconButton(onPressed: () => Get.back(), icon: const Icon(Icons.close_rounded)),
                ],
              ),
              const SizedBox(height: 8),
              ...controller.taskStatuses.map(
                (status) => ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(status.name),
                  subtitle: Text(status.code),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () => _showRenameStatusDialog(context, controller, status),
                        icon: const Icon(Icons.edit_outlined),
                      ),
                      IconButton(
                        onPressed: status.isSystem
                            ? null
                            : () async {
                                try {
                                  await controller.deleteStatus(status);
                                } catch (e) {
                                  Get.snackbar('Cannot Delete', e.toString().replaceFirst('Exception: ', ''));
                                }
                              },
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _showAddStatusDialog(context, controller),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Add Status'),
                ),
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  Future<void> _showRenameStatusDialog(BuildContext context, TasksController controller, TaskStatusOption status) async {
    final textController = TextEditingController(text: status.name);
    await Get.dialog(
      AlertDialog(
        title: const Text('Rename Status'),
        content: TextField(
          controller: textController,
          decoration: const InputDecoration(hintText: 'Status name'),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              final name = textController.text.trim();
              if (name.isEmpty) return;
              Get.back();
              try {
                await controller.renameStatus(status, name);
              } catch (e) {
                Get.snackbar('Error', e.toString().replaceFirst('Exception: ', ''));
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(TasksController());
    final isDesktop = MediaQuery.sizeOf(context).width >= 980;

    final body = SafeArea(
      child: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final dates = List.generate(21, (i) => DateTime.now().add(Duration(days: i - 7)));

        return RefreshIndicator(
          onRefresh: controller.loadTasks,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (!isDesktop)
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: () => Scaffold.of(context).openDrawer(),
                    icon: Icon(Icons.menu_rounded, color: context.title),
                  ),
                ),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Tasks',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: context.title,
                      ),
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: () => _openCreateTask(controller),
                    icon: const Icon(Icons.add_task_rounded),
                    label: const Text('Create Task'),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                DateFormat('EEEE, MMM d').format(controller.selectedDate.value),
                style: GoogleFonts.plusJakartaSans(fontSize: 13, color: context.subtitle),
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 78,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: dates.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final date = dates[index];
                    final selected = _isSameDate(controller.selectedDate.value, date);
                    return InkWell(
                      onTap: () => controller.selectDate(date),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        width: 62,
                        decoration: BoxDecoration(
                          color: selected ? context.accent : context.panel,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: selected ? context.accent : context.border),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              DateFormat('E').format(date),
                              style: GoogleFonts.plusJakartaSans(
                                color: selected ? Colors.white70 : context.subtitle,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              date.day.toString(),
                              style: GoogleFonts.plusJakartaSans(
                                color: selected ? Colors.white : context.title,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: controller.filterOptions
                    .map(
                      (f) => ChoiceChip(
                        selectedColor: context.accent,
                        labelStyle: GoogleFonts.plusJakartaSans(
                          color: controller.selectedFilter.value == f ? Colors.white : context.subtitle,
                          fontWeight: FontWeight.w600,
                        ),
                        backgroundColor: context.panel,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(color: context.border),
                        ),
                        selected: controller.selectedFilter.value == f,
                        label: Text(f),
                        onSelected: (_) => controller.setFilter(f),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: () => _showManageStatusesSheet(context, controller),
                  icon: const Icon(Icons.tune_rounded),
                  label: const Text('Manage Statuses'),
                ),
              ),
              const SizedBox(height: 14),
              if (controller.filteredTasks.isEmpty)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: context.panel,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: context.border),
                  ),
                  child: Text(
                    'No tasks for this date and filter.',
                    style: GoogleFonts.plusJakartaSans(color: context.subtitle),
                  ),
                ),
              ...controller.filteredTasks.map(
                (task) => _TaskTile(
                  task: task,
                  statusOptions: controller.taskStatuses.map((s) => s.name).toList(),
                  isDone: controller.isCompletedStatus(task.taskStatus),
                  onToggle: (value) => controller.toggleTaskComplete(task.taskId, value),
                  onStatusSelected: (status) => controller.setTaskStatus(task.taskId, status),
                ),
              ),
            ],
          ),
        );
      }),
    );

    return Scaffold(
      backgroundColor: context.appBg,
      drawer: isDesktop ? null : const Drawer(child: AppSideMenu(activeRoute: AppRoutes.tasks)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openCreateTask(controller),
        icon: const Icon(Icons.add_task_rounded),
        label: const Text('Create Task'),
      ),
      body: isDesktop
          ? Row(
              children: [
                const AppSideMenu(activeRoute: AppRoutes.tasks),
                Expanded(child: body),
              ],
            )
          : body,
    );
  }
}

class _TaskTile extends StatelessWidget {
  const _TaskTile({
    required this.task,
    required this.statusOptions,
    required this.isDone,
    required this.onToggle,
    required this.onStatusSelected,
  });

  final dynamic task;
  final List<String> statusOptions;
  final bool isDone;
  final ValueChanged<bool> onToggle;
  final ValueChanged<String> onStatusSelected;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Get.to(() => EditTaskView(task: task)),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.panel,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: context.border),
        ),
        child: Row(
          children: [
            Checkbox(
              value: isDone,
              activeColor: context.accent,
              onChanged: (v) => onToggle(v ?? false),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.taskTitle,
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700,
                      color: context.title,
                      decoration: isDone ? TextDecoration.lineThrough : TextDecoration.none,
                    ),
                  ),
                  if ((task.taskDescription ?? '').isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        task.taskDescription!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: context.subtitle,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              tooltip: 'Change status',
              onSelected: onStatusSelected,
              itemBuilder: (_) => statusOptions
                  .map((s) => PopupMenuItem<String>(value: s, child: Text(s)))
                  .toList(),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: context.panelMuted,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(task.taskStatus, style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700)),
                    const Icon(Icons.arrow_drop_down_rounded, size: 16),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            _PriorityTag(priority: task.taskPriority ?? 'Low'),
          ],
        ),
      ),
    );
  }
}

class _PriorityTag extends StatelessWidget {
  const _PriorityTag({required this.priority});

  final String priority;

  @override
  Widget build(BuildContext context) {
    final lower = priority.toLowerCase();
    final bg = lower.contains('high') ? const Color(0xFFFCE7F3) : const Color(0xFFFFEDD5);
    final fg = lower.contains('high') ? const Color(0xFFDB2777) : const Color(0xFFEA580C);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(
        priority,
        style: GoogleFonts.plusJakartaSans(fontSize: 11, color: fg, fontWeight: FontWeight.w700),
      ),
    );
  }
}

bool _isSameDate(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}
