import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mymanager/app/app.dart';
import 'package:mymanager/services/tasks_services/task_storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final svc = TaskStorageService();
  await svc.init();
  Get.put<TaskStorageService>(svc);
  runApp(const MyApp());
}
