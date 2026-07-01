import 'package:flutter/material.dart';
import 'package:mymanger/app/app.dart';
import 'package:mymanger/services/auth_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AuthService.initialize();
  runApp(const MyApp());
}