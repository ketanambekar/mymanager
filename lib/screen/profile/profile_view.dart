import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mymanager/screen/profile/profile_controller.dart';
import 'package:mymanager/screen/profile/widgets/add_update_bottomsheet.dart';
import 'package:mymanager/theme/app_theme.dart';
import 'package:mymanager/utils/global_utils.dart';

class ProfileView extends StatelessWidget {
  ProfileView({super.key});
  final controller = Get.put(ProfileController());
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      body: Container(
        margin: EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Column(
          children: [
            Center(
              child: ClipOval(
                child: Container(
                  width: 150,
                  height: 150,
                  color: Colors.white38,
                  child: Icon(
                    Icons.person_outline,
                    color: Colors.white,
                    size: 56,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 16),
              child: Obx(() {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () async {
                        await Get.bottomSheet<void>(
                          AddUpdateBottomSheet(
                            initialName: controller.userName.value,
                            onSave: (String name) {},
                          ),
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          enableDrag: true,
                        );
                      },
                      child: Text(
                        controller.userName.value.isEmpty
                            ? 'Click To Update Name'
                            : controller.userName.value,
                        style: AppTheme.headlineSmall,
                      ),
                    ),
                  ],
                );
              }),
            ),
            Obx(() {
              return Text(controller.id.value, style: AppTheme.caption);
            }),
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Active Since: ', style: AppTheme.caption),
                    Text(
                      formatDate(controller.activeSince.value),
                      style: AppTheme.caption,
                    ),
                  ],
                ),

                Obx(
                  () => Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Last Update: ', style: AppTheme.caption),
                      Text(
                        formatDate(controller.lastActive.value),
                        style: AppTheme.caption,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            Obx(() {
              return Text(
                "Active Since Version: v${controller.appVersion.value}",
                style: AppTheme.caption,
              );
            }),

            Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 16),
              child: Divider(color: Colors.white, thickness: 0.75),
            ),

            Container(
              padding: EdgeInsets.only(
                left: 16,
                right: 20,
                top: 20,
                bottom: 20,
              ),
              decoration: BoxDecoration(
                color: Colors.white30,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("About Me", style: AppTheme.body),
                  Icon(
                    Icons.arrow_forward_ios_sharp,
                    color: Colors.white,
                    size: 16,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
