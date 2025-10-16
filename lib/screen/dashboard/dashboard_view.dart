import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mymanager/routes/app_routes.dart';
import 'package:mymanager/screen/dashboard/dashboard_controller.dart';
import 'package:mymanager/widgets/app_bar/app_bar.dart';
import 'package:mymanager/widgets/bottom_nav/bottom_nav_view.dart';

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});
  @override
  Widget build(BuildContext context) {
    final DashboardController controller = Get.find<DashboardController>();

    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      appBar: const AppHeader(),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.indigo.shade700, Colors.purple.shade700],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          Obx(() {
            controller.navController.ensurePage(
              controller.navController.selectedIndex.value,
            );
            final created = controller.navController.createdPages;
            if (created.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }
            return Stack(children: created);
          }),

          Align(
            alignment: Alignment.bottomCenter,
            child: FloatingGlassBottomNav(
              items: controller.items,
              showLabels: false,
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Container(
        width: 80,
        height: 80,
        padding: const EdgeInsets.only(bottom: 15),
        child: FloatingActionButton(
          shape: CircleBorder(),
          child: const Icon(Icons.add_sharp),
          onPressed: () async {
            final created = await Get.toNamed(AppRoutes.createProject);
            if (created == true) {
              controller.getAllProjects();
            }
          },
        ),
      ),
    );
  }
}
