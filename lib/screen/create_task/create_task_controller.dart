import 'package:get/get.dart';
import 'package:flutter/material.dart';
// import 'package:mymanager/core/models/sub_task.dart';


class CreateTaskController extends GetxController {
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final descController = TextEditingController();
  final selectedDate = Rxn<DateTime>();
  final selectedTime = Rxn<TimeOfDay>();
  final isAlert = false.obs;
  final priority = 'Normal'.obs;
  final category = Rxn<String>();
  final taskAlerts = <String>[].obs; // e.g. '-10m'
  // final subTasks = <SubTask>[].obs;

  @override
  void onClose() {
    Get.focusScope?.unfocus();
    nameController.dispose();
    descController.dispose();


    super.onClose();
  }

  void addSubTask(String title) {
    // final id = '${DateTime.now().millisecondsSinceEpoch}${subTasks.length}';
    // subTasks.add(SubTask(id: id, name: title));
  }

  void removeSubTask(String id) {
    // subTasks.removeWhere((s) => s.id == id);
  }

  String? validateName(String? s) {
    if (s == null || s.trim().isEmpty) return 'Please enter a task name';
    return null;
  }

  String? get dateIso => selectedDate.value == null ? null : selectedDate.value!.toIso8601String().split('T').first;
  String? get timeIso => selectedTime.value == null ? null : '${selectedTime.value!.hour.toString().padLeft(2, '0')}:${selectedTime.value!.minute.toString().padLeft(2, '0')}';
}
