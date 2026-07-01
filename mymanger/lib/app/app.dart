import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mymanger/features/dashboard/dashboard_view.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MyManger',
      theme: ThemeData(primaryColor: Colors.blue),
      initialRoute: '/',
      getPages: [
        GetPage(name: '/', page: () => const DashboardView()),
      ],
    );
  }
}
