import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mymanager/constants/app_constants.dart';
import 'package:mymanager/screen/create_task/create_task_controller.dart';
import 'package:mymanager/theme/app_colors.dart';
import 'package:mymanager/screen/create_task/widgets/priority_indicator.dart';
import 'package:mymanager/widgets/app_glass_field.dart';
import 'package:mymanager/widgets/app_glass_button.dart';
import 'package:mymanager/widgets/app_glass_toggle.dart';

class CreateTaskForm extends GetView<CreateTaskController> {
  const CreateTaskForm({super.key});

  Future<void> _pickDate(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: controller.selectedDate.value ?? now,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 5),
      builder: (c, child) => Theme(
        data: Theme.of(context).copyWith(dialogBackgroundColor: AppColors.darkBackground),
        child: child!,
      ),
    );
    if (picked != null) controller.selectedDate.value = picked;
  }

  Future<void> _pickEndDate(BuildContext context) async {
    final now = DateTime.now();
    final startDate = controller.selectedDate.value ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: controller.selectedEndDate.value ?? startDate,
      firstDate: startDate,
      lastDate: DateTime(now.year + 5),
      builder: (c, child) => Theme(
        data: Theme.of(context).copyWith(dialogBackgroundColor: AppColors.darkBackground),
        child: child!,
      ),
    );
    if (picked != null) controller.selectedEndDate.value = picked;
  }

  Future<void> _pickTime(BuildContext context) async {
    final now = TimeOfDay.now();
    final picked = await showTimePicker(
      context: context,
      initialTime: controller.selectedTime.value ?? now,
      builder: (c, child) => Theme(
        data: Theme.of(context).copyWith(dialogBackgroundColor: AppColors.darkBackground),
        child: child!,
      ),
    );
    if (picked != null) controller.selectedTime.value = picked;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Form(
              key: controller.formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Task Name
                  AppGlassField(
                    child: TextFormField(
                      controller: controller.nameController,
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
                      decoration: const InputDecoration(
                        labelText: 'Task Name *',
                        labelStyle: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                        border: InputBorder.none,
                      ),
                      validator: controller.validateName,
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Description
                  AppGlassField(
                    child: TextFormField(
                      controller: controller.descController,
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
                      onTap: () => _showProjectPicker(context),
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
                          onTap: () => _pickDate(context),
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
                          onTap: () => _pickTime(context),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

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

                  // End Date (shown only for recurring tasks) - Note: For reference/display only
                  // The app now creates ONE recurring task instead of multiple instances
                  Obx(() {
                    if (controller.frequency.value != 'Once') {
                      return Column(
                        children: [
                          AppGlassButton(
                            label: 'Repeat Until (optional)',
                            child: Obx(() {
                              final d = controller.selectedEndDate.value;
                              return Text(
                                d == null ? 'Repeats indefinitely' : '${d.day}/${d.month}/${d.year}',
                                style: const TextStyle(color: AppColors.textPrimary),
                              );
                            }),
                            onTap: () => _pickEndDate(context),
                          ),
                          const SizedBox(height: 6),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              'Set when this recurring task should stop repeating',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      );
                    }
                    return const SizedBox.shrink();
                  }),

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
                    onTap: () => _showEnergyPicker(context),
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
                      ...controller.subtasks.asMap().entries.map((entry) {
                        final index = entry.key;
                        final subtask = entry.value;
                        return Container(
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
                              Expanded(
                                child: Text(
                                  subtask,
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 20),
                                color: AppColors.error,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () => controller.removeSubtask(index),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      GestureDetector(
                        onTap: () => _showAddSubtaskDialog(context),
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
                  const SizedBox(height: 10),
                  AppGlassToggle(
                    label: 'Habit Building Task',
                    value: controller.isHabit,
                    onChanged: (v) => controller.isHabit.value = v,
                  ),

                  const SizedBox(height: 24),
                ],
              ),
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
                  Icon(Icons.add_task_rounded, size: 24),
                  SizedBox(width: 12),
                  Text(
                    'Create Task',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showProjectPicker(BuildContext context) {
    Get.bottomSheet(
      Container(
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Select Project',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ListTile(
              title: const Text('No Project', style: TextStyle(color: AppColors.textPrimary)),
              onTap: () {
                controller.selectedProject.value = null;
                Get.back();
              },
            ),
            Obx(() => Column(
              children: controller.projects.map((project) {
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
            )),
          ],
        ),
      ),
    );
  }

  void _showAddSubtaskDialog(BuildContext context) {
    final subtaskController = TextEditingController();
    Get.dialog(
      AlertDialog(
        backgroundColor: AppColors.cardDark,
        title: const Text('Add Subtask', style: TextStyle(color: AppColors.textPrimary)),
        content: TextField(
          controller: subtaskController,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: const InputDecoration(
            hintText: 'Enter subtask name',
            hintStyle: TextStyle(color: AppColors.textSecondary),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.textSecondary),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.primary),
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
              controller.addSubtask(subtaskController.text);
              Get.back();
            },
            child: const Text('Add', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  void _showFrequencyPicker(BuildContext context) {
    Get.bottomSheet(
      Container(
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Once', style: TextStyle(color: AppColors.textPrimary)),
              onTap: () {
                controller.frequency.value = AppConstants.frequencyOnce;
                Get.back();
              },
            ),
            ListTile(
              title: const Text('Daily', style: TextStyle(color: AppColors.textPrimary)),
              onTap: () {
                controller.frequency.value = AppConstants.frequencyDaily;
                Get.back();
              },
            ),
            ListTile(
              title: const Text('Weekly', style: TextStyle(color: AppColors.textPrimary)),
              onTap: () {
                controller.frequency.value = AppConstants.frequencyWeekly;
                Get.back();
              },
            ),
            ListTile(
              title: const Text('Monthly', style: TextStyle(color: AppColors.textPrimary)),
              onTap: () {
                controller.frequency.value = AppConstants.frequencyMonthly;
                Get.back();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showEnergyPicker(BuildContext context) {
    Get.bottomSheet(
      Container(
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('High', style: TextStyle(color: AppColors.textPrimary)),
              onTap: () {
                controller.energyLevel.value = AppConstants.energyHigh;
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
              title: const Text('Low', style: TextStyle(color: AppColors.textPrimary)),
              onTap: () {
                controller.energyLevel.value = AppConstants.energyLow;
                Get.back();
              },
            ),
          ],
        ),
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
