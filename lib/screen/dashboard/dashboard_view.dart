import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mymanager/routes/app_routes.dart';
import 'package:mymanager/screen/create_task/create_task_view.dart';
import 'package:mymanager/screen/dashboard/dashboard_controller.dart';
import 'package:mymanager/theme/app_theme.dart';
import 'package:mymanager/theme/app_colors.dart';
import 'package:mymanager/theme/app_text_styles.dart';
import 'package:mymanager/theme/app_decorations.dart';
import 'package:mymanager/widgets/app_bar/app_bar.dart';
import 'package:mymanager/widgets/bottom_nav/bottom_nav_view.dart';

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  void _showCreateMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.transparent,
      builder: (context) => Container(
        decoration: AppDecorations.modalDecoration,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            Container(
              width: 40,
              height: 4,
              decoration: AppDecorations.handleDecoration,
            ),
            const SizedBox(height: 24),
            Text(
              'Create New',
              style: AppTextStyles.headline3,
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: Container(
                padding: AppDecorations.paddingMedium,
                decoration: AppDecorations.iconContainerDecoration(AppColors.success),
                child: Icon(Icons.task_alt, color: AppColors.success),
              ),
              title: Text('Task', style: AppTextStyles.listTitle),
              subtitle: Text('Create a new task', style: AppTextStyles.listSubtitle),
              onTap: () async {
                Get.back();
                await showCreateTaskBottomSheet();
                Get.find<DashboardController>().getAllProjects();
              },
            ),
            ListTile(
              leading: Container(
                padding: AppDecorations.paddingMedium,
                decoration: AppDecorations.iconContainerDecoration(AppColors.info),
                child: Icon(Icons.folder_special, color: AppColors.info),
              ),
              title: Text('Project', style: AppTextStyles.listTitle),
              subtitle: Text('Create a new project', style: AppTextStyles.listSubtitle),
              onTap: () async {
                Get.back();
                final created = await Get.toNamed(AppRoutes.createProject);
                if (created == true) {
                  Get.find<DashboardController>().getAllProjects();
                }
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
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
              gradient: AppTheme.backgroundGradient,
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
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 70),
        child: FloatingActionButton(
          shape: AppDecorations.circleShape,
          backgroundColor: AppColors.primary,
          child: const Icon(Icons.add_sharp, size: 32),
          onPressed: () => _showCreateMenu(context),
        ),
      ),
    );
  }
}
