import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mymanager/screen/create_edit_habit/create_edit_habit_controller.dart';
import 'package:mymanager/theme/app_colors.dart';

class CreateEditHabitView extends StatelessWidget {
  const CreateEditHabitView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(CreateEditHabitController());
    final isEditing = controller.editingHabit != null;

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.cardDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.textPrimary),
          onPressed: () => Get.back(),
        ),
        title: Text(
          isEditing ? 'Edit Habit' : 'Create Habit',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Habit Name
            _SectionTitle(title: 'Habit Name'),
            const SizedBox(height: 8),
            TextField(
              controller: controller.nameController,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'e.g., Morning Meditation',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                filled: true,
                fillColor: AppColors.cardDark,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Description
            _SectionTitle(title: 'Description (Optional)'),
            const SizedBox(height: 8),
            TextField(
              controller: controller.descriptionController,
              style: const TextStyle(color: AppColors.textPrimary),
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Add notes about this habit...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                filled: true,
                fillColor: AppColors.cardDark,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Frequency
            _SectionTitle(title: 'Frequency'),
            const SizedBox(height: 8),
            Obx(() => Wrap(
              spacing: 8,
              children: controller.frequencies.map((freq) {
                final isSelected = controller.selectedFrequency.value == freq;
                return ChoiceChip(
                  label: Text(freq),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) controller.selectedFrequency.value = freq;
                  },
                  selectedColor: const Color(0xFF7C4DFF),
                  backgroundColor: AppColors.cardDark,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.white.withOpacity(0.6),
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                );
              }).toList(),
            )),
            
            const SizedBox(height: 24),
            
            // Color
            _SectionTitle(title: 'Color'),
            const SizedBox(height: 8),
            Obx(() => Wrap(
              spacing: 12,
              children: controller.colors.map((entry) {
                final isSelected = controller.selectedColor.value == entry.key;
                return GestureDetector(
                  onTap: () => controller.selectedColor.value = entry.key,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: entry.value,
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(color: Colors.white, width: 3)
                          : null,
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: entry.value.withOpacity(0.5),
                                blurRadius: 12,
                                spreadRadius: 2,
                              ),
                            ]
                          : null,
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, color: Colors.white)
                        : null,
                  ),
                );
              }).toList(),
            )),
            
            const SizedBox(height: 24),
            
            // Reminders
            Obx(() => SwitchListTile(
              title: const Text(
                'Enable Reminders',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                'Get notified to complete this habit',
                style: TextStyle(color: Colors.white.withOpacity(0.5)),
              ),
              value: controller.enableAlerts.value,
              onChanged: (value) => controller.enableAlerts.value = value,
              activeColor: const Color(0xFF7C4DFF),
              contentPadding: EdgeInsets.zero,
            )),
            
            // Time Picker (if reminders enabled)
            Obx(() {
              if (!controller.enableAlerts.value) return const SizedBox.shrink();
              
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: controller.alertTime.value ?? const TimeOfDay(hour: 9, minute: 0),
                        builder: (context, child) {
                          return Theme(
                            data: ThemeData.dark().copyWith(
                              colorScheme: const ColorScheme.dark(
                                primary: Color(0xFF7C4DFF),
                                surface: Color(0xFF1A1A2E),
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (time != null) {
                        controller.alertTime.value = time;
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.cardDark,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.access_time, color: Color(0xFF7C4DFF)),
                          const SizedBox(width: 12),
                          Text(
                            controller.alertTime.value != null
                                ? controller.alertTime.value!.format(context)
                                : 'Set reminder time',
                            style: TextStyle(
                              color: controller.alertTime.value != null
                                  ? AppColors.textPrimary
                                  : Colors.white.withOpacity(0.5),
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }),
            
            const SizedBox(height: 40),
            
            // Save Button
            Obx(() => SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: controller.isSaving.value
                    ? null
                    : controller.saveHabit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C4DFF),
                  disabledBackgroundColor: const Color(0xFF7C4DFF).withOpacity(0.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: controller.isSaving.value
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        isEditing ? 'Update Habit' : 'Create Habit',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
              ),
            )),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  
  const _SectionTitle({required this.title});
  
  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
