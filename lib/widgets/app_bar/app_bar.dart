import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mymanager/screen/notifications/notifications_view.dart';
import 'package:mymanager/widgets/bottom_nav/bottom_nav_controller.dart';

import '../../database/apis/notification_api.dart';

class AppHeader extends GetView<BottomNavController>
    implements PreferredSizeWidget {
  final Widget? overrideTitle;

  const AppHeader({super.key, this.overrideTitle});

  // toolbar height
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  List<String> get _titles => const [
    'MyManager', // index 0 - Dashboard
    'Calendar', // index 1 - Calendar
    'Create', // index 2 - Create (or whatever you want)
    'Reports', // index 3 - Reports
    'Profile', // index 4 - Profile
  ];

  // Build actions depending on selected index
  List<Widget> _buildActions(int index, BuildContext context) {
    final List<Widget> actions = [];
    if (index == 0 || index == 4) {
      // final NotificationController? notifCtrl =
      // Get.isRegistered<NotificationController>() ? Get.find<NotificationController>() : null;

      actions.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: GestureDetector(
            onTap: () async {
              await Get.to(() => NotificationsView());
              // unreadNotifications.value = await NotificationApi.getUnreadCount();
            },
            child: Obx(() {
              final count = 2.obs; //notifCtrl?.unread.value ?? 0;
              final showBadge = count > 0;
              final display = (count > 99) ? '99+' : '$count';

              return Stack(
                clipBehavior: Clip.none,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Icon(
                      Icons.notifications_none,
                      size: 26,
                      color: Colors.white,
                    ),
                  ),
                  if (showBadge)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.25),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 20,
                          minHeight: 18,
                        ),
                        child: Center(
                          child: Text(
                            display,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            }),
          ),
        ),
      );
    }

    // Example: calendar filter on calendar tab
    if (index == 1) {
      actions.add(
        IconButton(
          tooltip: 'Filter',
          onPressed: () {
            // implement filter sheet
            showModalBottomSheet(
              context: context,
              builder: (_) => const SizedBox(
                height: 200,
                child: Center(
                  child: Text('Filter', style: TextStyle(color: Colors.white)),
                ),
              ),
            );
          },
          icon: const Icon(Icons.filter_list),
        ),
      );
    }

    // Example: profile/settings icon on profile tab
    // if (index == 4) {
    //   actions.add(
    //     IconButton(
    //       tooltip: 'Edit profile',
    //       onPressed: () {
    //         Get.toNamed('/profile/edit');
    //       },
    //       icon: const Icon(Icons.edit, color: Colors.white),
    //     ),
    //   );
    // }

    return actions;
  }

  @override
  Widget build(BuildContext context) {
    // Note: controller is obtained via GetView
    return Obx(() {
      final idx = controller.selectedIndex.value;
      final titleWidget =
          overrideTitle ??
          Text(
            _titles.elementAt(idx),
            style: GoogleFonts.poppins(
              textStyle: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          );

      return AppBar(
        title: titleWidget,
        elevation: 1,
        centerTitle: false,
        backgroundColor: Colors.transparent,
        actions: _buildActions(idx, context),
      );
    });
  }
}
