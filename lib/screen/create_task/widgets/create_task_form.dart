import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mymanager/constants/app_constants.dart';
import 'package:mymanager/screen/create_task/create_task_controller.dart';
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
        data: Theme.of(context).copyWith(dialogBackgroundColor: Colors.black),
        child: child!,
      ),
    );
    if (picked != null) controller.selectedDate.value = picked;
  }

  Future<void> _pickTime(BuildContext context) async {
    final now = TimeOfDay.now();
    final picked = await showTimePicker(
      context: context,
      initialTime: controller.selectedTime.value ?? now,
      builder: (c, child) => Theme(
        data: Theme.of(context).copyWith(dialogBackgroundColor: Colors.black),
        child: child!,
      ),
    );
    if (picked != null) controller.selectedTime.value = picked;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
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
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Task Name *',
                  labelStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                ),
                validator: controller.validateName,
              ),
            ),

            const SizedBox(height: 16),

            // Description
            AppGlassField(
              child: TextFormField(
                controller: controller.descController,
                style: const TextStyle(color: Colors.white),
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  labelStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Date and Time
            Row(
              children: [
                Expanded(
                  child: AppGlassButton(
                    label: 'Date',
                    child: Obx(() {
                      final d = controller.selectedDate.value;
                      return Text(
                        d == null ? 'Select date' : '${d.day}/${d.month}/${d.year}',
                        style: const TextStyle(color: Colors.white),
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
                        style: const TextStyle(color: Colors.white),
                      );
                    }),
                    onTap: () => _pickTime(context),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Urgency and Importance
            const Text(
              'Priority (Eisenhower Matrix)',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: AppGlassButton(
                    label: 'Urgency',
                    child: Obx(() => Text(
                          controller.urgency.value,
                          style: const TextStyle(color: Colors.white),
                        )),
                    onTap: () => _showUrgencyPicker(context),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppGlassButton(
                    label: 'Importance',
                    child: Obx(() => Text(
                          controller.importance.value,
                          style: const TextStyle(color: Colors.white),
                        )),
                    onTap: () => _showImportancePicker(context),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),
            const PriorityIndicator(),

            const SizedBox(height: 16),

            // Frequency
            AppGlassButton(
              label: 'Frequency',
              child: Obx(() => Text(
                    controller.frequency.value,
                    style: const TextStyle(color: Colors.white),
                  )),
              onTap: () => _showFrequencyPicker(context),
            ),

            const SizedBox(height: 16),

            // Energy Level
            AppGlassButton(
              label: 'Energy Level',
              child: Obx(() => Text(
                    controller.energyLevel.value,
                    style: const TextStyle(color: Colors.white),
                  )),
              onTap: () => _showEnergyPicker(context),
            ),

            const SizedBox(height: 16),

            // Time Estimate
            AppGlassField(
              child: TextFormField(
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Time Estimate (minutes)',
                  labelStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                ),
                onChanged: (value) {
                  controller.timeEstimate.value = int.tryParse(value);
                },
              ),
            ),

            const SizedBox(height: 16),

            // Toggles
            AppGlassToggle(
              label: 'Enable Alerts',
              value: controller.enableAlerts,
              onChanged: (v) => controller.enableAlerts.value = v,
            ),
            const SizedBox(height: 8),
            AppGlassToggle(
              label: 'Requires Deep Focus',
              value: controller.focusRequired,
              onChanged: (v) => controller.focusRequired.value = v,
            ),

            const SizedBox(height: 24),

            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: controller.saveTask,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Create Task',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  void _showUrgencyPicker(BuildContext context) {
    Get.bottomSheet(
      Container(
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('High', style: TextStyle(color: Colors.white)),
              onTap: () {
                controller.urgency.value = AppConstants.urgencyHigh;
                Get.back();
              },
            ),
            ListTile(
              title: const Text('Medium', style: TextStyle(color: Colors.white)),
              onTap: () {
                controller.urgency.value = AppConstants.urgencyMedium;
                Get.back();
              },
            ),
            ListTile(
              title: const Text('Low', style: TextStyle(color: Colors.white)),
              onTap: () {
                controller.urgency.value = AppConstants.urgencyLow;
                Get.back();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showImportancePicker(BuildContext context) {
    Get.bottomSheet(
      Container(
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('High', style: TextStyle(color: Colors.white)),
              onTap: () {
                controller.importance.value = AppConstants.importanceHigh;
                Get.back();
              },
            ),
            ListTile(
              title: const Text('Medium', style: TextStyle(color: Colors.white)),
              onTap: () {
                controller.importance.value = AppConstants.importanceMedium;
                Get.back();
              },
            ),
            ListTile(
              title: const Text('Low', style: TextStyle(color: Colors.white)),
              onTap: () {
                controller.importance.value = AppConstants.importanceLow;
                Get.back();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showFrequencyPicker(BuildContext context) {
    Get.bottomSheet(
      Container(
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Once', style: TextStyle(color: Colors.white)),
              onTap: () {
                controller.frequency.value = AppConstants.frequencyOnce;
                Get.back();
              },
            ),
            ListTile(
              title: const Text('Daily', style: TextStyle(color: Colors.white)),
              onTap: () {
                controller.frequency.value = AppConstants.frequencyDaily;
                Get.back();
              },
            ),
            ListTile(
              title: const Text('Weekly', style: TextStyle(color: Colors.white)),
              onTap: () {
                controller.frequency.value = AppConstants.frequencyWeekly;
                Get.back();
              },
            ),
            ListTile(
              title: const Text('Monthly', style: TextStyle(color: Colors.white)),
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
          color: Colors.grey[900],
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('High', style: TextStyle(color: Colors.white)),
              onTap: () {
                controller.energyLevel.value = AppConstants.energyHigh;
                Get.back();
              },
            ),
            ListTile(
              title: const Text('Medium', style: TextStyle(color: Colors.white)),
              onTap: () {
                controller.energyLevel.value = AppConstants.energyMedium;
                Get.back();
              },
            ),
            ListTile(
              title: const Text('Low', style: TextStyle(color: Colors.white)),
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
