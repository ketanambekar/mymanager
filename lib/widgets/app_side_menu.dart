import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mymanager/database/tables/user_projects/models/user_project_model.dart';
import 'package:mymanager/routes/app_routes.dart';
import 'package:mymanager/services/project_context_controller.dart';
import 'package:mymanager/theme/theme_tokens.dart';

class AppSideMenu extends StatelessWidget {
  const AppSideMenu({
    super.key,
    required this.activeRoute,
  });

  final String activeRoute;

  @override
  Widget build(BuildContext context) {
    final projectContext = Get.find<ProjectContextController>();

    void openCreateProject() {
      if (Scaffold.maybeOf(context)?.isDrawerOpen ?? false) {
        Navigator.of(context).pop();
      }
      Get.toNamed(AppRoutes.createProject);
    }

    final items = <_MenuItem>[
      const _MenuItem(label: 'Dashboard', icon: Icons.home_rounded, route: AppRoutes.dashboard),
      const _MenuItem(label: 'Tasks', icon: Icons.task_alt_rounded, route: AppRoutes.tasks),
      const _MenuItem(label: 'Calendar', icon: Icons.calendar_month_rounded, route: AppRoutes.calender),
      const _MenuItem(label: 'Reports', icon: Icons.bar_chart_rounded, route: AppRoutes.reports),
    ];

    return Container(
      width: 236,
      color: context.panel,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: context.accent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.dashboard_customize_rounded, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'MyManager',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: context.title,
                    ),
                  ),
                ],
              ),
            ),
            Divider(color: context.border, height: 1),
            const SizedBox(height: 8),
            for (final item in items)
              _MenuTile(
                item: item,
                selected: item.route == activeRoute,
                onTap: () {
                  if (Get.currentRoute != item.route) {
                    Get.offNamed(item.route);
                  } else if (Scaffold.maybeOf(context)?.isDrawerOpen ?? false) {
                    Navigator.of(context).pop();
                  }
                },
              ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'MY PROJECTS',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      letterSpacing: 0.8,
                      color: context.subtitle,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  InkWell(
                    onTap: openCreateProject,
                    borderRadius: BorderRadius.circular(99),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(Icons.add, size: 16, color: context.subtitle),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Obx(
              () {
                if (projectContext.projects.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    child: Text(
                      'No projects yet',
                      style: GoogleFonts.plusJakartaSans(fontSize: 12, color: context.subtitle),
                    ),
                  );
                }

                return Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    children: _buildProjectTiles(
                      context,
                      projectContext.projects,
                      projectContext.selectedProjectId.value,
                      onTap: (projectId) async {
                        await projectContext.selectProject(projectId);
                        if (Scaffold.maybeOf(context)?.isDrawerOpen ?? false) {
                          Navigator.of(context).pop();
                        }
                      },
                    ),
                  ),
                );
              },
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 14),
              child: FilledButton.icon(
                onPressed: openCreateProject,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Create Project'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  textStyle: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildProjectTiles(
    BuildContext context,
    List<UserProjects> projects,
    String? selectedProjectId, {
    required Future<void> Function(String projectId) onTap,
  }) {
    final parentMap = <String, List<UserProjects>>{};
    final topLevel = <UserProjects>[];

    for (final project in projects) {
      final parentId = project.parentProjectId;
      if (parentId == null || parentId.isEmpty) {
        topLevel.add(project);
      } else {
        parentMap.putIfAbsent(parentId, () => <UserProjects>[]).add(project);
      }
    }
    if (topLevel.isEmpty) {
      topLevel.addAll(projects);
    }

    final widgets = <Widget>[];
    for (final parent in topLevel) {
      widgets.add(
        _ProjectTile(
          name: parent.projectName ?? 'Untitled Project',
          selected: parent.projectId == selectedProjectId,
          indent: 0,
          onTap: () => onTap(parent.projectId),
        ),
      );
      final children = parentMap[parent.projectId] ?? const <UserProjects>[];
      for (final child in children) {
        widgets.add(
          _ProjectTile(
            name: child.projectName ?? 'Untitled Sub-project',
            selected: child.projectId == selectedProjectId,
            indent: 14,
            onTap: () => onTap(child.projectId),
          ),
        );
      }
    }

    return widgets;
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final _MenuItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      child: Material(
        color: selected ? context.accent.withValues(alpha: 0.14) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: Row(
              children: [
                Icon(
                  item.icon,
                  size: 19,
                  color: selected ? context.accent : context.subtitle,
                ),
                const SizedBox(width: 10),
                Text(
                  item.label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                    color: selected ? context.accent : context.title,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuItem {
  const _MenuItem({
    required this.label,
    required this.icon,
    required this.route,
  });

  final String label;
  final IconData icon;
  final String route;
}

class _ProjectTile extends StatelessWidget {
  const _ProjectTile({
    required this.name,
    required this.selected,
    required this.onTap,
    this.indent = 0,
  });

  final String name;
  final bool selected;
  final VoidCallback onTap;
  final double indent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(4 + indent, 2, 4, 2),
      child: Material(
        color: selected ? context.accent.withValues(alpha: 0.14) : Colors.transparent,
        borderRadius: BorderRadius.circular(9),
        child: InkWell(
          borderRadius: BorderRadius.circular(9),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Text(
              name,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                color: selected ? context.accent : context.subtitle,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
