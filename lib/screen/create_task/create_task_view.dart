import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:glass/glass.dart';
import 'package:mymanager/screen/create_task/create_task_controller.dart';
// import 'package:mymanager/services/tasks_services/task_storage_service.dart';

showCreateTaskBottomSheet() async {
  if (!Get.isRegistered<CreateTaskController>()) {
    Get.put(CreateTaskController());
  }
  await Get.bottomSheet<void>(
    _CreateTaskSheetView(),
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    enableDrag: true,
  );


}

class _CreateTaskSheetView extends GetView<CreateTaskController> {
  @override
  final controller = Get.find<CreateTaskController>();
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

  Future<void> _saveTask() async {
    if (!(controller.formKey.currentState?.validate() ?? false)) {
      return;
    }

    // final svc = Get.find<TaskStorageService>();

    // create task from fields
    // await svc.createTaskFrom(
    //   taskName: controller.nameController.text.trim(),
    //   taskDate: controller.dateIso,
    //   taskTime: controller.timeIso,
    //   taskAlerts: controller.taskAlerts.isEmpty
    //       ? null
    //       : controller.taskAlerts.toList(),
    //   taskSlot: null,
    //   subTasks: controller.subTasks.toList(),
    //   taskDuration: null,
    //   taskEndTime: null,
    //   taskStartDate: controller.dateIso,
    //   taskFrequency: null,
    //   isTaskAlert: controller.isAlert.value,
    //   taskStatus: 'pending',
    //   taskDescription: controller.descController.text.trim(),
    //   taskCategory: controller.category.value,
    //   taskPriority: controller.priority.value,
    // );

    // close sheet
    Get.back();
    // optional: show confirmation
    Get.snackbar(
      'Saved',
      'Task created',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.black87,
      colorText: Colors.white,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Use viewInsets to handle keyboard (sheet moves up)
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(

      child: Container(
        // keep sheet height compact but allow scrolling
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.86,
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 14.0,
              vertical: 12,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Container(
                // outer glass container
                color: Colors.black.withOpacity(0.35),
                child:
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // top drag handle
                          Container(
                            width: 48,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.white24,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // header
                          Row(
                            children: [
                              const Icon(
                                Icons.add_box_outlined,
                                color: Colors.white70,
                              ),
                              const SizedBox(width: 10),
                              const Expanded(
                                child: Text(
                                  'Create Task',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: () => Get.back(),
                                icon: const Icon(
                                  Icons.close,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          // The actual form area — frosted panel
                          Form(
                            key: controller.formKey,
                            child: Column(
                              children: [
                                // Task name
                                _glassField(
                                  child: TextFormField(
                                    controller: controller.nameController,
                                    style: const TextStyle(
                                      color: Colors.white,
                                    ),
                                    decoration: const InputDecoration(
                                      hintText: 'Task name',
                                      hintStyle: TextStyle(
                                        color: Colors.white54,
                                      ),
                                      border: InputBorder.none,
                                    ),
                                    validator: controller.validateName,
                                    textInputAction: TextInputAction.next,
                                  ),
                                ),

                                const SizedBox(height: 8),

                                // date/time row
                                Row(
                                  children: [
                                    Expanded(
                                      child: _glassButton(
                                        label: 'Date',
                                        child: Obx(() {
                                          final d =
                                              controller.selectedDate.value;
                                          return Text(
                                            d == null
                                                ? 'Select date'
                                                : '${d.day}/${d.month}/${d.year}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                            ),
                                          );
                                        }),
                                        onTap: () => _pickDate(context),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: _glassButton(
                                        label: 'Time',
                                        child: Obx(() {
                                          final t =
                                              controller.selectedTime.value;
                                          return Text(
                                            t == null
                                                ? 'Select time'
                                                : t.format(context),
                                            style: const TextStyle(
                                              color: Colors.white,
                                            ),
                                          );
                                        }),
                                        onTap: () => _pickTime(context),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 8),

                                // Priority & Alert toggle row
                                Row(
                                  children: [
                                    Expanded(
                                      child: _glassButton(
                                        label: 'Priority',
                                        child: Obx(
                                          () => Text(
                                            controller.priority.value,
                                            style: const TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                        onTap: () =>
                                            _showPriorityPicker(context),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: _glassToggle(
                                        label: 'Alerts',
                                        value: controller.isAlert,
                                        onChanged: (v) =>
                                            controller.isAlert.value = v,
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 8),

                                // Subtasks input (compact)
                                _subTasksEditor(),

                                const SizedBox(height: 8),

                                // Description
                                _glassField(
                                  child: TextFormField(
                                    controller: controller.descController,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                    ),
                                    maxLines: 3,
                                    decoration: const InputDecoration(
                                      hintText:
                                          'Add a short description (optional)',
                                      hintStyle: TextStyle(
                                        color: Colors.white54,
                                      ),
                                      border: InputBorder.none,
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 12),

                                // save button
                                Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: _saveTask,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              Colors.greenAccent.shade400,
                                          foregroundColor: Colors.black,
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 14,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                        ),
                                        child: const Text(
                                          'Save Task',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 8),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ).asGlass(
                      tintColor: Colors.white,
                      blurX: 8,
                      blurY: 8,
                      clipBorderRadius: BorderRadius.circular(18),
                    ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // small helper: frosted input field container
  Widget _glassField({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child:
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: child,
          ).asGlass(
            tintColor: Colors.white,
            blurX: 8,
            blurY: 8,
            clipBorderRadius: BorderRadius.circular(12),
          ),
    );
  }

  // frosted button
  Widget _glassButton({
    required String label,
    required Widget child,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child:
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  child,
                ],
              ),
            ).asGlass(
              tintColor: Colors.white,
              blurX: 8,
              blurY: 8,
              clipBorderRadius: BorderRadius.circular(12),
            ),
      ),
    );
  }

  // toggle widget with label
  Widget _glassToggle({
    required String label,
    required RxBool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child:
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                Obx(
                  () =>
                      Switch.adaptive(value: value.value, onChanged: onChanged),
                ),
              ],
            ),
          ).asGlass(
            tintColor: Colors.white,
            blurX: 8,
            blurY: 8,
            clipBorderRadius: BorderRadius.circular(12),
          ),
    );
  }

  // subtasks editor segment
  Widget _subTasksEditor() {
    final newSubController = TextEditingController();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Subtasks',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        // Obx(() {
        //   // final subs = controller.subTasks;
        //   return Column(
        //     children: [
        //       // list existing subtasks
        //       if (subs.isNotEmpty)
        //         Column(
        //           children: subs.map((s) {
        //             return Padding(
        //               padding: const EdgeInsets.symmetric(vertical: 4),
        //               child: Row(
        //                 children: [
        //                   Expanded(
        //                     child: Text(
        //                       s.name,
        //                       style: const TextStyle(color: Colors.white),
        //                     ),
        //                   ),
        //                   IconButton(
        //                     onPressed: () => controller.removeSubTask(s.id),
        //                     icon: const Icon(
        //                       Icons.close,
        //                       color: Colors.white54,
        //                     ),
        //                   ),
        //                 ],
        //               ),
        //             );
        //           }).toList(),
        //         ),
        //       // input to add new subtask
        //       Row(
        //         children: [
        //           Expanded(
        //             child: ClipRRect(
        //               borderRadius: BorderRadius.circular(10),
        //               child:
        //                   Container(
        //                     padding: const EdgeInsets.symmetric(horizontal: 8),
        //                     child: TextField(
        //                       controller: newSubController,
        //                       style: const TextStyle(color: Colors.white),
        //                       decoration: const InputDecoration(
        //                         hintText: 'Add subtask',
        //                         hintStyle: TextStyle(color: Colors.white54),
        //                         border: InputBorder.none,
        //                       ),
        //                       textInputAction: TextInputAction.done,
        //                       onSubmitted: (v) {
        //                         final trimmed = v.trim();
        //                         if (trimmed.isNotEmpty) {
        //                           controller.addSubTask(trimmed);
        //                           newSubController.clear();
        //                         }
        //                       },
        //                     ),
        //                   ).asGlass(
        //                     tintColor: Colors.white,
        //                     blurX: 8,
        //                     blurY: 8,
        //                     clipBorderRadius: BorderRadius.circular(10),
        //                   ),
        //             ),
        //           ),
        //           const SizedBox(width: 8),
        //           ElevatedButton(
        //             onPressed: () {
        //               final v = newSubController.text.trim();
        //               if (v.isNotEmpty) {
        //                 controller.addSubTask(v);
        //                 newSubController.clear();
        //               }
        //             },
        //             style: ElevatedButton.styleFrom(
        //               backgroundColor: Colors.white12,
        //               foregroundColor: Colors.white,
        //               shape: RoundedRectangleBorder(
        //                 borderRadius: BorderRadius.circular(10),
        //               ),
        //             ),
        //             child: const Text('Add'),
        //           ),
        //         ],
        //       ),
        //     ],
        //   );
        // }),
      ],
    );
  }

  // priority picker sheet
  void _showPriorityPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            color: Colors.black.withOpacity(0.6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: const Text(
                    'Low',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () => _selectPriority('Low'),
                ),
                ListTile(
                  title: const Text(
                    'Normal',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () => _selectPriority('Normal'),
                ),
                ListTile(
                  title: const Text(
                    'High',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () => _selectPriority('High'),
                ),
                ListTile(
                  title: const Text(
                    'Urgent',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () => _selectPriority('Urgent'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _selectPriority(String p) {
    controller.priority.value = p;
    Get.back();
  }
}
