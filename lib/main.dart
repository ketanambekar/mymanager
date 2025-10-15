import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:mymanager/app/app.dart';
import 'package:mymanager/database/helper/database_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();
  await DatabaseHelper.database;
  runApp(MyApp());
}
