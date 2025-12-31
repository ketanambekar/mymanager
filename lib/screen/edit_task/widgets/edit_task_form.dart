import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mymanager/constants/app_constants.dart';
import 'package:mymanager/screen/edit_task/edit_task_controller.dart';
import 'package:mymanager/theme/app_colors.dart';
import 'package:mymanager/widgets/app_glass_button.dart';
import 'package:mymanager/widgets/app_glass_field.dart';
import 'package:mymanager/widgets/app_glass_toggle.dart';

class EditTaskForm extends StatelessWidget {
  const EditTaskForm({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<EditTaskController>();

    return Form(
      key: controller.formKey,
      child: Column(
        children: [
          // Scrollable Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Task Name
                  AppGlassField(
                    child: TextFormField(
                      controller: controller.titleController,
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
                      decoration: const InputDecoration(
                        labelText: 'Task Name *',
                        labelStyle: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                        border: InputBorder.none,
                      ),
                      validator: (s) {
                        if (s == null || s.trim().isEmpty) return 'Please enter a task name';
                        return null;
                      },
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Description
                  AppGlassField(
                    child: TextFormField(
                      controller: controller.descriptionController,
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        labelStyle: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                        hintText: 'Add task description...',
                        hintStyle: TextStyle(color: AppColors.textTertiary, fontSize: 14),
                        border: InputBorder.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Project Selector
                  const Text(
                    'Project',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  Obx(() {
                    final selectedProject = controller.selectedProject.value;
                    return AppGlassButton(
                      label: '',
                      child: Text(
                        selectedProject?.projectName ?? 'No project selected',
                        style: TextStyle(
                          color: selectedProject != null 
                            ? AppColors.textPrimary 
                            : AppColors.textTertiary,
                          fontSize: 15,
                        ),
                      ),
                      onTap: () => _showProjectPicker(context, controller),
                    );
                  }),

                  const SizedBox(height: 20),

                  // Date and Time
                  const Text(
                    'Schedule',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: AppGlassButton(
                          label: 'Date',
                          child: Obx(() {
                            final d = controller.selectedDate.value;
                            return Text(
                              d == null ? 'Select date' : '${d.day}/${d.month}/${d.year}',
                              style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
                            );
                          }),
                          onTap: () => _pickDate(context, controller),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppGlassButton(
                          label: 'Time',
                          child: Obx(() {
                            final t = controller.selectedTime.value;
                            return Text(
                              t == null ? 'Select time' : t.format(context),
                              style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
                            );
                          }),
                          onTap: () => _pickTime(context, controller),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Priority with Flag Icons
                  const Text(
                    'Priority',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  Obx(() {
                    final urgency = controller.urgency.value;
                    final importance = controller.importance.value;
                    final isUrgentImportant = urgency == AppConstants.urgencyHigh && importance == AppConstants.importanceHigh;
                    final isUrgentNotImportant = urgency == AppConstants.urgencyHigh && importance == AppConstants.importanceLow;
                    final isNotUrgentImportant = urgency == AppConstants.urgencyLow && importance == AppConstants.importanceHigh;
                    final isNotUrgentNotImportant = urgency == AppConstants.urgencyLow && importance == AppConstants.importanceLow;
                    
                    return Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _PriorityFlag(
                                label: 'Urgent and Important',
                                icon: Icons.flag,
                                color: AppColors.error,
                                isSelected: isUrgentImportant,
                                onTap: () {
                                  controller.urgency.value = AppConstants.urgencyHigh;
                                  controller.importance.value = AppConstants.importanceHigh;
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _PriorityFlag(
                                label: 'Urgent but Not Important',
                                icon: Icons.flag_outlined,
                                color: AppColors.warning,
                                isSelected: isUrgentNotImportant,
                                onTap: () {
                                  controller.urgency.value = AppConstants.urgencyHigh;
                                  controller.importance.value = AppConstants.importanceLow;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: _PriorityFlag(
                                label: 'Not Urgent but Important',
                                icon: Icons.flag_outlined,
                                color: const Color(0xFF5B8DEE),
                                isSelected: isNotUrgentImportant,
                                onTap: () {
                                  controller.urgency.value = AppConstants.urgencyLow;
                                  controller.importance.value = AppConstants.importanceHigh;
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _PriorityFlag(
                                label: 'Not Urgent Not Important',
                                icon: Icons.outlined_flag,
                                color: AppColors.success,
                                isSelected: isNotUrgentNotImportant,
                                onTap: () {
                                  controller.urgency.value = AppConstants.urgencyLow;
                                  controller.importance.value = AppConstants.importanceLow;
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  }),

                  const SizedBox(height: 20),

                  // Status
                  const Text(
                    'Status',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  Obx(() {
                    final status = controller.selectedStatus.value;
                    return Row(
                      children: [
                        _StatusChip(
                          label: 'Todo',
                          icon: Icons.radio_button_unchecked,
                          isSelected: status == 'Todo',
                          onTap: () => controller.selectedStatus.value = 'Todo',
                        ),
                        const SizedBox(width: 8),
                        _StatusChip(
                          label: 'In Progress',
                          icon: Icons.pending_outlined,
                          isSelected: status == 'In Progress',
                          onTap: () => controller.selectedStatus.value = 'In Progress',
                        ),
                        const SizedBox(width: 8),
                        _StatusChip(
                          label: 'Completed',
                          icon: Icons.check_circle_outline,
                          isSelected: status == 'Completed',
                          onTap: () => controller.selectedStatus.value = 'Completed',
                        ),
                      ],
                    );
                  }),

                  const SizedBox(height: 20),

                  // Frequency - Inline Selection
                  const Text(
                    'Frequency',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  Obx(() {
                    final frequency = controller.frequency.value;
                    return Row(
                      children: [
                        _FrequencyChip(
                          label: 'Once',
                          icon: Icons.check_circle_outline,
                          isSelected: frequency == AppConstants.frequencyOnce,
                          onTap: () => controller.frequency.value = AppConstants.frequencyOnce,
                        ),
                        const SizedBox(width: 8),
                        _FrequencyChip(
                          label: 'Daily',
                          icon: Icons.today,
                          isSelected: frequency == AppConstants.frequencyDaily,
                          onTap: () => controller.frequency.value = AppConstants.frequencyDaily,
                        ),
                        const SizedBox(width: 8),
                        _FrequencyChip(
                          label: 'Weekly',
                          icon: Icons.date_range,
                          isSelected: frequency == AppConstants.frequencyWeekly,
                          onTap: () => controller.frequency.value = AppConstants.frequencyWeekly,
                        ),
                        const SizedBox(width: 8),
                        _FrequencyChip(
                          label: 'Monthly',
                          icon: Icons.calendar_month,
                          isSelected: frequency == AppConstants.frequencyMonthly,
                          onTap: () => controller.frequency.value = AppConstants.frequencyMonthly,
                        ),
                      ],
                    );
                  }),

                  const SizedBox(height: 20),

                  // Energy Level
                  const Text(
                    'Energy Level',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  AppGlassButton(
                    label: '',
                    child: Obx(() => Text(
                          controller.energyLevel.value,
                          style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
                        )),
                    onTap: () => _showEnergyPicker(context, controller),
                  ),

                  const SizedBox(height: 20),

                  // Time Estimate
                  const Text(
                    'Time Estimate',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  AppGlassField(
                    child: TextFormField(
                      initialValue: controller.timeEstimate.value?.toString() ?? '',
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        hintText: 'Enter time in minutes',
                        hintStyle: TextStyle(color: AppColors.textTertiary, fontSize: 14),
                        border: InputBorder.none,
                      ),
                      onChanged: (value) {
                        controller.timeEstimate.value = int.tryParse(value);
                      },
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Subtasks Section
                  const Text(
                    'Subtasks',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  Obx(() => Column(
                    children: [
                      ...controller.subtasks.map((subtask) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.cardDark.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.textTertiary.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              subtask.taskStatus == 'Completed'
                                  ? Icons.check_circle
                                  : Icons.circle_outlined,
                              color: subtask.taskStatus == 'Completed'
                                  ? AppColors.success
                                  : AppColors.textSecondary,
                              size: 22,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                subtask.taskTitle,
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 14,
                                  decoration: subtask.taskStatus == 'Completed'
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 20),
                              color: AppColors.error,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () => controller.deleteSubtask(subtask.taskId),
                            ),
                          ],
                        ),
                      )).toList(),
                      GestureDetector(
                        onTap: () => _showAddSubtaskDialog(context, controller),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: const Color(0xFF5B8DEE).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFF5B8DEE).withOpacity(0.3),
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.add, color: Color(0xFF5B8DEE), size: 20),
                              SizedBox(width: 6),
                              Text(
                                'Add Subtask',
                                style: TextStyle(
                                  color: Color(0xFF5B8DEE),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )),

                  const SizedBox(height: 20),

                  // Toggles
                  const Text(
                    'Additional Options',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  AppGlassToggle(
                    label: 'Enable Alerts',
                    value: controller.enableAlerts,
                    onChanged: (v) => controller.enableAlerts.value = v,
                  ),
                  const SizedBox(height: 10),
                  AppGlassToggle(
                    label: 'Requires Deep Focus',
                    value: controller.focusRequired,
                    onChanged: (v) => controller.focusRequired.value = v,
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          
          // Sticky Bottom Button
          Container(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom > 0 ? 8 : 20,
              top: 12,
            ),
            decoration: BoxDecoration(
              color: AppColors.darkBackground,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF5B8DEE), Color(0xFF3B6BBE)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: controller.saveTask,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.transparent,
                  shadowColor: AppColors.transparent,
                  foregroundColor: AppColors.textPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.save, size: 22),
                    SizedBox(width: 8),
                    Text(
                      'Save Changes',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate(BuildContext context, EditTaskController controller) async {
    final date = await showDatePicker(
      context: context,
      initialDate: controller.selectedDate.value ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF5B8DEE),
              surface: Color(0xFF2A2A2A),
            ),
          ),
          child: child!,
        );
      },
    );
    if (date != null) {
      controller.selectedDate.value = date;
    }
  }

  Future<void> _pickTime(BuildContext context, EditTaskController controller) async {
    final time = await showTimePicker(
      context: context,
      initialTime: controller.selectedTime.value ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF5B8DEE),
              surface: Color(0xFF2A2A2A),
            ),
          ),
          child: child!,
        );
      },
    );
    if (time != null) {
      controller.selectedTime.value = time;
    }
  }

  void _showProjectPicker(BuildContext context, EditTaskController controller) {
    Get.bottomSheet(
      Container(
        decoration: const BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('No Project', style: TextStyle(color: AppColors.textPrimary)),
              onTap: () {
                controller.selectedProject.value = null;
                Get.back();
              },
            ),
            ...controller.projects.map((project) {
              return ListTile(
                title: Text(
                  project.projectName ?? 'Unnamed Project',
                  style: const TextStyle(color: AppColors.textPrimary),
                ),
                onTap: () {
                  controller.selectedProject.value = project;
                  Get.back();
                },
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  void _showEnergyPicker(BuildContext context, EditTaskController controller) {
    Get.bottomSheet(
      Container(
        decoration: const BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Low', style: TextStyle(color: AppColors.textPrimary)),
              onTap: () {
                controller.energyLevel.value = AppConstants.energyLow;
                Get.back();
              },
            ),
            ListTile(
              title: const Text('Medium', style: TextStyle(color: AppColors.textPrimary)),
              onTap: () {
                controller.energyLevel.value = AppConstants.energyMedium;
                Get.back();
              },
            ),
            ListTile(
              title: const Text('High', style: TextStyle(color: AppColors.textPrimary)),
              onTap: () {
                controller.energyLevel.value = AppConstants.energyHigh;
                Get.back();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAddSubtaskDialog(BuildContext context, EditTaskController controller) {
    final subtaskController = TextEditingController();
    Get.dialog(
      AlertDialog(
        backgroundColor: AppColors.cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Add Subtask', style: TextStyle(color: AppColors.textPrimary)),
        content: TextField(
          controller: subtaskController,
          style: const TextStyle(color: AppColors.textPrimary),
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Enter subtask name',
            hintStyle: TextStyle(color: AppColors.textSecondary),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.textSecondary),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF5B8DEE)),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              if (subtaskController.text.trim().isNotEmpty) {
                controller.addSubtask(subtaskController.text.trim());
                Get.back();
              }
            },
            child: const Text('Add', style: TextStyle(color: Color(0xFF5B8DEE))),
          ),
        ],
      ),
    );
  }
}

class _PriorityFlag extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _PriorityFlag({
    required this.label,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.15) : AppColors.cardDark.withOpacity(0.5),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? color : AppColors.textTertiary.withOpacity(0.3),
              width: isSelected ? 2.5 : 1,
            ),
            boxShadow: isSelected ? [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ] : [],
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? color : AppColors.textSecondary,
                size: 28,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? color : AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _StatusChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.success.withOpacity(0.2) : AppColors.cardDark.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.success : AppColors.textTertiary.withOpacity(0.3),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected ? [
              BoxShadow(
                color: AppColors.success.withOpacity(0.2),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ] : [],
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? AppColors.success : AppColors.textSecondary,
                size: 20,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? AppColors.success : AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FrequencyChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _FrequencyChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF5B8DEE).withOpacity(0.2) : AppColors.cardDark.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? const Color(0xFF5B8DEE) : AppColors.textTertiary.withOpacity(0.3),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected ? [
              BoxShadow(
                color: const Color(0xFF5B8DEE).withOpacity(0.2),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ] : [],
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? const Color(0xFF5B8DEE) : AppColors.textSecondary,
                size: 20,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? const Color(0xFF5B8DEE) : AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
