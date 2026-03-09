import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mymanager/routes/app_routes.dart';
import 'package:mymanager/screen/profile/profile_controller.dart';
import 'package:mymanager/screen/profile/widgets/add_update_bottomsheet.dart';
import 'package:mymanager/utils/global_utils.dart';
import 'package:mymanager/theme/theme_tokens.dart';
import 'package:mymanager/widgets/app_side_menu.dart';

class ProfileView extends StatelessWidget {
  ProfileView({super.key});

  final controller = Get.put(ProfileController());

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 980;

    final page = SafeArea(
      child: Obx(
        () => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (!isDesktop)
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: () => Scaffold.of(context).openDrawer(),
                  icon: Icon(Icons.menu_rounded, color: context.title),
                ),
              ),
            Text(
              'Profile',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: context.title,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)]),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 36,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, size: 42, color: Color(0xFF7C3AED)),
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () async {
                      await Get.bottomSheet<void>(
                        AddUpdateBottomSheet(
                          initialName: controller.userName.value,
                          onSave: (_) {},
                        ),
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                      );
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          controller.userName.value.isEmpty ? 'Tap to set name' : controller.userName.value,
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.edit, size: 16, color: Colors.white),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _InfoCard(title: 'User ID', value: controller.id.value.isEmpty ? 'Not set' : controller.id.value),
            _InfoCard(
              title: 'Active Since',
              value: controller.activeSince.value.isEmpty ? 'Not available' : formatDate(controller.activeSince.value),
            ),
            _InfoCard(
              title: 'Last Update',
              value: controller.lastActive.value.isEmpty ? 'Not available' : formatDate(controller.lastActive.value),
            ),
            _InfoCard(
              title: 'App Version',
              value: controller.appVersion.value.isEmpty ? 'v1.0.0' : 'v${controller.appVersion.value}',
            ),
            const SizedBox(height: 8),
            _ActionTile(
              icon: Icons.track_changes_rounded,
              title: 'My Habits',
              subtitle: 'Track and manage your habits',
              onTap: () => Get.toNamed(AppRoutes.habitList),
            ),
            _ActionTile(
              icon: Icons.download_rounded,
              title: 'Backup Database',
              subtitle: 'Save your data to a backup file',
              onTap: controller.backupDatabase,
            ),
            _ActionTile(
              icon: Icons.upload_file_rounded,
              title: 'Import Database',
              subtitle: 'Merge data from a backup file',
              onTap: controller.importDatabase,
            ),
            _ActionTile(
              icon: Icons.logout_rounded,
              title: 'Logout',
              subtitle: 'Sign out and go to login',
              onTap: controller.logout,
            ),
          ],
        ),
      ),
    );

    return Scaffold(
      backgroundColor: context.appBg,
      drawer: isDesktop ? null : const Drawer(child: AppSideMenu(activeRoute: AppRoutes.profile)),
      body: isDesktop
          ? Row(
              children: [
                const AppSideMenu(activeRoute: AppRoutes.profile),
                Expanded(child: page),
              ],
            )
          : page,
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.panel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.plusJakartaSans(color: context.subtitle, fontWeight: FontWeight.w600),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(color: context.title, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({required this.icon, required this.title, required this.subtitle, required this.onTap});

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.panel,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: context.border),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F3FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: const Color(0xFF7C3AED), size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, color: context.title)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: context.subtitle)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF9CA3AF)),
          ],
        ),
      ),
    );
  }
}
