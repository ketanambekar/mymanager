import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mymanager/screen/profile/profile_controller.dart';
import 'package:mymanager/screen/profile/widgets/add_update_bottomsheet.dart';
import 'package:mymanager/screen/profile/widgets/profile_tab_tiles.dart';
import 'package:mymanager/theme/app_theme.dart';
import 'package:mymanager/theme/app_text_styles.dart';
import 'package:mymanager/utils/global_utils.dart';

class ProfileView extends StatelessWidget {
  ProfileView({super.key});
  final controller = Get.put(ProfileController());
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Profile Header
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF7C4DFF), Color(0xFF536DFE)],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF7C4DFF).withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: const Color(0xFF7C4DFF),
                          child: const Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 48,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Obx(() => GestureDetector(
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
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              controller.userName.value.isEmpty
                                  ? 'Tap to set name'
                                  : controller.userName.value,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.edit,
                              color: Colors.white,
                              size: 18,
                            ),
                          ],
                        ),
                      )),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Profile',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Account Info Section
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Account Information',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                Obx(() => ProfileTabTiles(
                  title: 'User ID',
                  value: controller.id.value.isEmpty ? 'Not set' : controller.id.value,
                  icon: Icons.fingerprint,
                )),

                Obx(() => ProfileTabTiles(
                  title: 'Active Since',
                  value: controller.activeSince.value.isEmpty 
                      ? 'Not available' 
                      : formatDate(controller.activeSince.value),
                  icon: Icons.calendar_today,
                )),

                Obx(() => ProfileTabTiles(
                  title: 'Last Update',
                  value: controller.lastActive.value.isEmpty 
                      ? 'Not available' 
                      : formatDate(controller.lastActive.value),
                  icon: Icons.update,
                )),

                Obx(() => ProfileTabTiles(
                  title: 'App Version',
                  value: controller.appVersion.value.isEmpty 
                      ? 'v1.0.0' 
                      : "v${controller.appVersion.value}",
                  icon: Icons.info_outline,
                )),

                const SizedBox(height: 24),

                // Data Management Section
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Data Management',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Backup Database Button
                GestureDetector(
                  onTap: () => controller.backupDatabase(),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF4ECDC4).withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4ECDC4).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.backup,
                            color: Color(0xFF4ECDC4),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Backup Database',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Export all your data',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.6),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios,
                          color: Color(0xFF4ECDC4),
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),

                // Import Database Button
                GestureDetector(
                  onTap: () => controller.importDatabase(),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF7C4DFF).withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF7C4DFF).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.cloud_download,
                            color: Color(0xFF7C4DFF),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Import & Merge Database',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Restore from backup file',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.6),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios,
                          color: Color(0xFF7C4DFF),
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // About Section
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'About',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'About MyManager',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white.withOpacity(0.5),
                        size: 16,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
