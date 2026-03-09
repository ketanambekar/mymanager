import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mymanager/app/app_binding.dart';
import 'package:mymanager/routes/app_routes.dart';
import 'package:mymanager/theme/app_theme.dart';

class MyApp extends StatelessWidget {
  final String initialRoute;

  const MyApp({super.key, required this.initialRoute});
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'MyManager',
      debugShowCheckedModeBanner: false,
      initialRoute: initialRoute,
      getPages: AppPages.routes,
      initialBinding: AppBinding(),
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      builder: (context, child) {
        final brightness = Theme.of(context).brightness;
        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: AppTheme.backgroundGradientFor(brightness),
          ),
          child: SafeArea(child: child ?? const SizedBox.shrink()),
        );
      },
    );
  }
}
