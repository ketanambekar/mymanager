import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mymanager/app/app_binding.dart';
import 'package:mymanager/app/app_controller.dart';
import 'package:mymanager/routes/app_routes.dart';
import 'package:mymanager/theme/app_theme.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'MyManager',
      debugShowCheckedModeBanner: false,
      initialRoute: AppRoutes.dashboard,
      getPages: AppPages.routes,
      initialBinding: AppBinding(),
      theme: AppTheme.themeData,
      builder: (context, child) {
        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.indigo.shade700, Colors.purple.shade700],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(child: child ?? const SizedBox.shrink()),
        );
      },
    );
  }
}
