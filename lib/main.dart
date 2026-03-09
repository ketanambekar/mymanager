import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:mymanager/app/app.dart';
import 'package:mymanager/routes/app_routes.dart';
import 'package:mymanager/services/backend_auth_service.dart';
import 'package:mymanager/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();
  final hasSession = await BackendAuthService.hasValidSession();
  await NotificationService().initialize();
  await NotificationService().requestPermissions();

  runApp(MyApp(initialRoute: hasSession ? AppRoutes.dashboard : AppRoutes.auth));
}
