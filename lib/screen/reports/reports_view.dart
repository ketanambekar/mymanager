import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:mymanager/routes/app_routes.dart';
import 'package:mymanager/screen/reports/reports_controller.dart';
import 'package:mymanager/theme/theme_tokens.dart';
import 'package:mymanager/widgets/app_side_menu.dart';

class ReportsView extends StatelessWidget {
  const ReportsView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ReportsController());
    final isDesktop = MediaQuery.sizeOf(context).width >= 980;

    final page = SafeArea(
      child: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return RefreshIndicator(
          onRefresh: controller.loadReportData,
          child: ListView(
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
                'Reports & Analytics',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: context.title,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                DateFormat('MMMM d, yyyy').format(DateTime.now()),
                style: GoogleFonts.plusJakartaSans(color: context.subtitle, fontSize: 13),
              ),
              const SizedBox(height: 14),
              _HighlightCard(
                title: 'Overall Progress',
                value: '${controller.completionRate.value.toStringAsFixed(1)}%',
                subtitle: '${controller.completedTasks.value} of ${controller.totalTasks.value} tasks completed',
              ),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  final twoCols = constraints.maxWidth > 700;
                  if (twoCols) {
                    return Row(
                      children: [
                        Expanded(
                          child: _StatCard(label: 'Total Tasks', value: controller.totalTasks.value.toString(), icon: Icons.task_alt_rounded),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _StatCard(label: 'Projects', value: controller.allProjects.length.toString(), icon: Icons.folder_rounded),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _StatCard(label: 'Habits', value: controller.totalHabits.value.toString(), icon: Icons.track_changes_rounded),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _StatCard(label: 'Overdue', value: controller.overdueTasks.value.toString(), icon: Icons.warning_amber_rounded),
                        ),
                      ],
                    );
                  }
                  return Column(
                    children: [
                      _StatCard(label: 'Total Tasks', value: controller.totalTasks.value.toString(), icon: Icons.task_alt_rounded),
                      const SizedBox(height: 10),
                      _StatCard(label: 'Projects', value: controller.allProjects.length.toString(), icon: Icons.folder_rounded),
                      const SizedBox(height: 10),
                      _StatCard(label: 'Habits', value: controller.totalHabits.value.toString(), icon: Icons.track_changes_rounded),
                      const SizedBox(height: 10),
                      _StatCard(label: 'Overdue', value: controller.overdueTasks.value.toString(), icon: Icons.warning_amber_rounded),
                    ],
                  );
                },
              ),
              const SizedBox(height: 12),
              _StatCard(
                label: 'XP Level',
                value: 'Level ${controller.currentLevel.value}',
                icon: Icons.stars_rounded,
                detail: '${controller.totalXP.value} XP total • ${controller.xpToNextLevel.value} XP to next level',
              ),
            ],
          ),
        );
      }),
    );

    return Scaffold(
      backgroundColor: context.appBg,
      drawer: isDesktop ? null : const Drawer(child: AppSideMenu(activeRoute: AppRoutes.reports)),
      body: isDesktop
          ? Row(
              children: [
                const AppSideMenu(activeRoute: AppRoutes.reports),
                Expanded(child: page),
              ],
            )
          : page,
    );
  }
}

class _HighlightCard extends StatelessWidget {
  const _HighlightCard({required this.title, required this.value, required this.subtitle});

  final String title;
  final String value;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
                const SizedBox(height: 6),
                Text(subtitle, style: GoogleFonts.plusJakartaSans(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(value, style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value, required this.icon, this.detail});

  final String label;
  final String value;
  final IconData icon;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: const Color(0xFFF5F3FF), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: const Color(0xFF7C3AED), size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFF6B7280))),
                const SizedBox(height: 2),
                Text(value, style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800, color: const Color(0xFF111827))),
                if (detail != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(detail!, style: GoogleFonts.plusJakartaSans(fontSize: 11, color: const Color(0xFF9CA3AF))),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
