import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mymanager/routes/app_bottom_nav_routes.dart';
import 'package:mymanager/screen/create_task/create_task_controller.dart';
import 'package:mymanager/screen/create_task/create_task_view.dart';
import 'package:mymanager/widgets/bottom_nav/bottom_nav_controller.dart';
import 'package:mymanager/widgets/bottom_nav/bottom_nav_view.dart';

class DashboardController extends GetxController {
  late final BottomNavController navController;
  late final List<NavItem> items;

  @override
  void onInit() {
    super.onInit();
    navController = Get.find<BottomNavController>();
    items = List<NavItem>.generate(appBottomNavRoutes.length, (index) {
      final routeData = appBottomNavRoutes[index];
      final icon = routeData['icon'] as IconData;
      final iconSelected = routeData['icon_selected'] as IconData;
      final label = routeData['label'] as String;
      onTap() {
        if (index == 2) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (Get.isRegistered<CreateTaskController>()) {
              Get.delete<CreateTaskController>();
            }
            showCreateTaskBottomSheet();
          });
        } else {
          navController.changeIndex(index);
        }
      }

      return NavItem(
        icon: icon,
        iconSelected: iconSelected,
        label: label,
        onTap: onTap,
      );
    });
  }
}
