import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mymanager/database/apis/user_project_api.dart';
import 'package:mymanager/database/tables/user_projects/models/user_project_model.dart';
import 'package:mymanager/routes/app_bottom_nav_routes.dart';
import 'package:mymanager/screen/create_task/create_task_controller.dart';
import 'package:mymanager/screen/create_task/create_task_view.dart';
import 'package:mymanager/utils/global_utils.dart';
import 'package:mymanager/widgets/bottom_nav/bottom_nav_controller.dart';
import 'package:mymanager/widgets/bottom_nav/bottom_nav_view.dart';

class DashboardController extends GetxController {
  late final BottomNavController navController;
  late final List<NavItem> items;
  RxList<UserProjects> projects = <UserProjects>[].obs;
  bool isLoadingDashboard = false;
  @override
  void onInit() {
    super.onInit();
    loadDashboard();
    getAllProjects();
  }

  @override
  void onReady() {
    super.onReady();
  }

  Future<void> getAllProjects() async {
    projects.value = await UserProjectsApi.getProjects();
    for (var project in projects) {
      print(
        '${project.projectId}: ${project.projectName} ${project.projectStatus} (${project.projectUpdatedAt})',
      );
    }

    final allProjects = await UserProjectsApi.getProjects(includeDeleted: true);
  }



  void loadDashboard() {
    if (isLoadingDashboard) return;
    isLoadingDashboard = true;
    try {
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
    } catch (e, stack) {
      if(kDebugMode) {
        print("Dashboard LoadDashboard $e $stack");
      }
    } finally {
      isLoadingDashboard = false;
    }
  }
}
