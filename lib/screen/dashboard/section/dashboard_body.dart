import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mymanager/screen/dashboard/dashboard_controller.dart';
import 'package:mymanager/screen/dashboard/widgets/project_tiles.dart';
import 'package:mymanager/theme/app_text_styles.dart';
import 'package:mymanager/utils/global_utils.dart';

class DashboardContent extends StatelessWidget {
  DashboardContent({super.key});
  final controller = Get.find<DashboardController>();

  @override
  Widget build(BuildContext context) {
    Widget _viewMoreCard() {
      return Container(
        margin: const EdgeInsets.fromLTRB(0, 16, 16, 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white38,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Text('View More'),
            SizedBox(width: 8),
            Icon(Icons.arrow_forward_ios_sharp, color: Colors.white, size: 13),
          ],
        ),
      );
    }

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Obx(() {
          final projects = controller.projects;
          final count = projects.length;
          // show up to 5 items (index 0..4) and then a "View More" tile if there are more
          final visibleCount = count > 5 ? 5 : count;
          final children = <Widget>[
            // generate visible project cards
            ...List.generate(
              visibleCount,
              (i) => ProjectTiles(project: controller.projects[i]),
            ),
            // if more than 5 show a single "View More" card
            if (count > 5) _viewMoreCard(),
          ];

          return Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Active Projects ($count)',
                style: AppTextStyles.headline2.copyWith(
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(children: children),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}
