import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mymanager/database/apis/task_api.dart';
import 'package:mymanager/database/apis/task_status_api.dart';
import 'package:mymanager/database/models/task_status_option.dart';
import 'package:mymanager/database/tables/tasks/models/task_model.dart';
import 'package:mymanager/database/tables/user_projects/models/user_project_model.dart';
import 'package:mymanager/routes/app_routes.dart';
import 'package:mymanager/screen/create_task/create_task_controller.dart';
import 'package:mymanager/screen/create_task/create_task_view.dart';
import 'package:mymanager/services/api_client.dart';
import 'package:mymanager/services/project_context_controller.dart';
import 'package:mymanager/theme/theme_tokens.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  late Future<_DashboardData> _boardFuture;
  late final ProjectContextController _projectContext;
  Worker? _projectSwitchWorker;

  @override
  void initState() {
    super.initState();
    _projectContext = Get.find<ProjectContextController>();
    _projectSwitchWorker = ever<String?>(_projectContext.selectedProjectId, (_) => _refresh());
    _boardFuture = _loadDashboardData();
  }

  @override
  void dispose() {
    _projectSwitchWorker?.dispose();
    super.dispose();
  }

  Future<_DashboardData> _loadDashboardData() async {
    await _projectContext.loadProjects();
    final statusOptions = await TaskStatusApi.getTaskStatuses();
    final projects = _projectContext.projects.toList();
    final selectedProjectId = _projectContext.selectedProjectId.value;
    final selectedProject = _projectContext.selectedProject;
    final tasks = await TaskApi.getTasks(
      projectId: selectedProjectId,
      includeCompleted: true,
      onlyParentTasks: true,
    );

    String userName = 'User';
    String userSubtitle = 'Signed in';
    try {
      final meResp = await ApiClient.instance.get('/auth/me');
      if (meResp.statusCode >= 200 && meResp.statusCode < 300) {
        final body = jsonDecode(meResp.body) as Map<String, dynamic>;
        final data = body['data'] as Map<String, dynamic>?;
        final parsedName = data?['name']?.toString().trim();
        final parsedEmail = data?['email']?.toString().trim();
        if ((parsedName ?? '').isNotEmpty) {
          userName = parsedName!;
        }
        if ((parsedEmail ?? '').isNotEmpty) {
          userSubtitle = parsedEmail!;
        }
      }
    } catch (_) {
      // Keep safe fallback strings if profile fetch fails.
    }

    final todo = <Task>[];
    final progress = <Task>[];
    final done = <Task>[];

    for (final task in tasks) {
      final status = task.taskStatus.toLowerCase();
      if (status.contains('progress')) {
        progress.add(task);
      } else if (status.contains('done') || status.contains('complete')) {
        done.add(task);
      } else {
        todo.add(task);
      }
    }

    todo.sort((a, b) => _safeDateCompare(a.taskDueDate, b.taskDueDate));
    progress.sort((a, b) => _safeDateCompare(a.taskDueDate, b.taskDueDate));
    done.sort((a, b) => _safeDateCompare(a.taskCompletedDate, b.taskCompletedDate));

    final projectName = (selectedProject?.projectName?.isNotEmpty ?? false)
      ? selectedProject!.projectName!
      : (projects.isNotEmpty && (projects.first.projectName?.isNotEmpty ?? false))
        ? projects.first.projectName!
        : 'Mobile App';

    return _DashboardData(
      projectName: projectName,
      userName: userName,
      userSubtitle: userSubtitle,
      projects: projects,
      statusOptions: statusOptions,
      columns: [
        _KanbanColumn(title: 'To Do', color: const Color(0xFF8B5CF6), tasks: todo.take(8).map(_taskToCard).toList()),
        _KanbanColumn(
          title: 'On Progress',
          color: const Color(0xFFF97316),
          tasks: progress.take(8).map(_taskToCard).toList(),
        ),
        _KanbanColumn(title: 'Done', color: const Color(0xFF22C55E), tasks: done.take(8).map(_taskToCard).toList()),
      ],
    );
  }

  _Task _taskToCard(Task task) {
    final priority = (task.taskPriority ?? '').toLowerCase();
    final mappedPriority = priority.contains('high')
        ? _priorityHigh
        : (task.taskStatus.toLowerCase().contains('done') || task.taskStatus.toLowerCase().contains('complete'))
            ? _priorityDone
            : _priorityLow;

    return _Task(
      taskId: task.taskId,
      sourceTask: task,
      title: task.taskTitle,
      description: task.taskDescription,
      priority: mappedPriority,
      status: task.taskStatus,
      comments: 0,
      files: 0,
      assignees: _fallbackAvatars,
    );
  }

  Future<void> _changeTaskStatus(_Task task, String status) async {
    final updated = task.sourceTask.copyWith(taskStatus: status);
    await TaskApi.updateTask(task.taskId, updated);
    _refresh();
  }

  int _safeDateCompare(String? a, String? b) {
    try {
      if (a == null && b == null) return 0;
      if (a == null) return 1;
      if (b == null) return -1;
      return DateTime.parse(a).compareTo(DateTime.parse(b));
    } catch (_) {
      return 0;
    }
  }

  void _refresh() {
    setState(() {
      _boardFuture = _loadDashboardData();
    });
  }

  Future<void> _openCreateProject() async {
    final created = await Get.toNamed(AppRoutes.createProject);
    if (created == true && mounted) {
      _refresh();
    }
  }

  Future<void> _openCreateTask() async {
    if (Get.isRegistered<CreateTaskController>()) {
      Get.delete<CreateTaskController>();
    }
    await showCreateTaskBottomSheet();
    if (mounted) {
      _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appBg,
      drawer: FutureBuilder<_DashboardData>(
        future: _boardFuture,
        builder: (context, snapshot) => _Sidebar(
          projects: snapshot.data?.projects ?? const [],
          selectedProjectId: _projectContext.selectedProjectId.value,
          onSelectProject: (projectId) => _projectContext.selectProject(projectId),
          onCreateProject: _openCreateProject,
        ),
      ),
      body: SafeArea(
        child: FutureBuilder<_DashboardData>(
          future: _boardFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            final data = snapshot.data;
            if (data == null) {
              return const Center(child: Text('Unable to load dashboard'));
            }

            return LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = constraints.maxWidth < 900;
                return Row(
                  children: [
                    if (!isMobile)
                      _Sidebar(
                        projects: data.projects,
                        selectedProjectId: _projectContext.selectedProjectId.value,
                        onSelectProject: (projectId) => _projectContext.selectProject(projectId),
                        onCreateProject: _openCreateProject,
                      ),
                    Expanded(
                      child: Column(
                        children: [
                          _TopHeader(
                            isMobile: isMobile,
                            onMenuTap: () => Scaffold.of(context).openDrawer(),
                            onRefresh: _refresh,
                            userName: data.userName,
                            userSubtitle: data.userSubtitle,
                          ),
                          _ProjectHeader(projectName: data.projectName, onCreateTask: _openCreateTask),
                          Expanded(
                            child: _KanbanBoard(
                              isMobile: isMobile,
                              columns: data.columns,
                              statusOptions: data.statusOptions,
                              onStatusChanged: _changeTaskStatus,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.projects,
    required this.selectedProjectId,
    required this.onSelectProject,
    required this.onCreateProject,
  });

  final List<UserProjects> projects;
  final String? selectedProjectId;
  final Future<void> Function(String projectId) onSelectProject;
  final Future<void> Function() onCreateProject;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final labelStyle = GoogleFonts.plusJakartaSans(
      fontSize: 14,
      color: cs.onSurfaceVariant,
      fontWeight: FontWeight.w500,
    );

    return Container(
      width: 232,
      color: context.panel,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFF7C3AED),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.adjust_rounded, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 10),
                Text(
                  'Project M.',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: cs.onSurface,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _NavItem(
                  icon: Icons.home_rounded,
                  label: 'Home',
                  labelStyle: labelStyle,
                  onTap: () => Get.toNamed(AppRoutes.dashboard),
                ),
                _NavItem(
                  icon: Icons.task_alt_rounded,
                  label: 'Tasks',
                  labelStyle: labelStyle,
                  onTap: () => Get.toNamed(AppRoutes.tasks),
                ),
                _NavItem(
                  icon: Icons.calendar_month_rounded,
                  label: 'Calendar',
                  labelStyle: labelStyle,
                  onTap: () => Get.toNamed(AppRoutes.calender),
                ),
                _NavItem(
                  icon: Icons.bar_chart_rounded,
                  label: 'Reports',
                  labelStyle: labelStyle,
                  onTap: () => Get.toNamed(AppRoutes.reports),
                ),
                const SizedBox(height: 26),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'MY PROJECTS',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        letterSpacing: 0.8,
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    InkWell(
                      onTap: onCreateProject,
                      borderRadius: BorderRadius.circular(99),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(Icons.add, size: 16, color: cs.onSurfaceVariant),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (projects.isEmpty)
                  _ProjectItem(
                    name: 'No projects yet',
                    dotColor: const Color(0xFF9CA3AF),
                    onTap: () {},
                  )
                else
                  ..._buildHierarchicalProjectItems(),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFEFCE8), Color(0xFFFFF7ED)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Align(
                  alignment: Alignment.topRight,
                  child: Icon(Icons.lightbulb_rounded, color: Color(0xFFF59E0B), size: 18),
                ),
                Text(
                  'Thoughts Time',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "We don't have any notice for you, till then you can share your thoughts with your peers.",
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    height: 1.4,
                    color: cs.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      foregroundColor: cs.onSurface,
                      backgroundColor: context.panel,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {},
                    child: Text(
                      'Write a message',
                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildHierarchicalProjectItems() {
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
    var paletteIndex = 0;

    for (final parent in topLevel) {
      final parentColor = _parseProjectColor(parent.projectColor) ?? _projectPalette[paletteIndex % _projectPalette.length];
      widgets.add(
        _ProjectItem(
          onTap: () => onSelectProject(parent.projectId),
          name: parent.projectName ?? 'Untitled Project',
          dotColor: parentColor,
          active: parent.projectId == selectedProjectId,
        ),
      );

      final children = parentMap[parent.projectId] ?? const <UserProjects>[];
      for (final child in children) {
        widgets.add(
          _ProjectItem(
            onTap: () => onSelectProject(child.projectId),
            name: child.projectName ?? 'Untitled Sub-project',
            dotColor: _parseProjectColor(child.projectColor) ?? parentColor,
            active: child.projectId == selectedProjectId,
            indent: 14,
          ),
        );
      }

      paletteIndex++;
    }

    return widgets;
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.labelStyle,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final TextStyle labelStyle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: ListTile(
        dense: true,
        minLeadingWidth: 22,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10),
        leading: Icon(icon, size: 18, color: cs.onSurfaceVariant),
        title: Text(label, style: labelStyle),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        onTap: onTap,
      ),
    );
  }
}

class _ProjectItem extends StatelessWidget {
  const _ProjectItem({
    required this.name,
    required this.dotColor,
    required this.onTap,
    this.active = false,
    this.indent = 0,
  });

  final String name;
  final Color dotColor;
  final VoidCallback onTap;
  final bool active;
  final double indent;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding: EdgeInsets.fromLTRB(12 + indent, 10, 12, 10),
        decoration: BoxDecoration(
          color: active ? cs.primary.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                name,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: active ? cs.primary : cs.onSurface,
                ),
              ),
            ),
            if (active)
              const Icon(Icons.more_horiz_rounded, color: Color(0xFF9CA3AF), size: 18),
          ],
        ),
      ),
    );
  }
}

class _TopHeader extends StatelessWidget {
  const _TopHeader({
    required this.isMobile,
    required this.onMenuTap,
    required this.onRefresh,
    required this.userName,
    required this.userSubtitle,
  });

  final bool isMobile;
  final VoidCallback onMenuTap;
  final VoidCallback onRefresh;
  final String userName;
  final String userSubtitle;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      color: context.panel,
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 14 : 24, vertical: 12),
      child: isMobile
          ? Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: onMenuTap,
                      icon: Icon(Icons.menu_rounded, color: cs.onSurfaceVariant),
                    ),
                    Expanded(child: _SearchField(isMobile: true)),
                    IconButton(
                      onPressed: onRefresh,
                      icon: Icon(Icons.refresh_rounded, color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _HeaderIcon(icon: Icons.calendar_today_rounded),
                    SizedBox(width: 10),
                    _HeaderIcon(icon: Icons.chat_bubble_outline_rounded),
                    SizedBox(width: 10),
                    _HeaderIcon(icon: Icons.notifications_none_rounded),
                    SizedBox(width: 12),
                    _ProfileInfo(compact: true, name: userName, subtitle: userSubtitle),
                  ],
                ),
              ],
            )
          : Row(
              children: [
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: _SearchField(isMobile: false),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: onRefresh,
                  icon: Icon(Icons.refresh_rounded, color: cs.onSurfaceVariant),
                ),
                const _HeaderIcon(icon: Icons.calendar_today_rounded),
                const SizedBox(width: 10),
                const _HeaderIcon(icon: Icons.chat_bubble_outline_rounded),
                const SizedBox(width: 10),
                const _HeaderIcon(icon: Icons.notifications_none_rounded),
                const SizedBox(width: 14),
                Container(width: 1, height: 34, color: context.border),
                const SizedBox(width: 14),
                _ProfileInfo(compact: false, name: userName, subtitle: userSubtitle),
              ],
            ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.isMobile});

  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return TextField(
      decoration: InputDecoration(
        isDense: true,
        hintText: 'Search for anything...',
        hintStyle: GoogleFonts.plusJakartaSans(color: cs.onSurfaceVariant, fontSize: 13),
        prefixIcon: Icon(Icons.search_rounded, color: cs.onSurfaceVariant, size: 20),
        filled: true,
        fillColor: context.panelMuted,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: isMobile ? 10 : 12, vertical: 12),
      ),
    );
  }
}

class _HeaderIcon extends StatelessWidget {
  const _HeaderIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: context.panelMuted,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, size: 18, color: cs.onSurfaceVariant),
    );
  }
}

class _ProfileInfo extends StatelessWidget {
  const _ProfileInfo({required this.compact, required this.name, required this.subtitle});

  final bool compact;
  final String name;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => Get.toNamed(AppRoutes.profile),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!compact)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            if (!compact) const SizedBox(width: 10),
            Stack(
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  radius: compact ? 16 : 18,
                  backgroundColor: const Color(0xFF7C3AED),
                  child: const Icon(Icons.person, size: 18, color: Colors.white),
                ),
                Positioned(
                  right: -1,
                  bottom: -1,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: const Color(0xFF22C55E),
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ProjectHeader extends StatelessWidget {
  const _ProjectHeader({required this.projectName, required this.onCreateTask});

  final String projectName;
  final VoidCallback onCreateTask;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      color: context.panel,
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            runSpacing: 12,
            spacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            alignment: WrapAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    projectName,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const _TinyIcon(icon: Icons.link_rounded),
                  const SizedBox(width: 8),
                  const _TinyIcon(icon: Icons.remove_red_eye_outlined),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FilledButton.icon(
                    onPressed: onCreateTask,
                    icon: const Icon(Icons.add_task_rounded, size: 18),
                    label: Text(
                      'Add Task',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.add, color: Color(0xFF7C3AED), size: 18),
                    label: Text(
                      'Invite',
                      style: GoogleFonts.plusJakartaSans(
                        color: const Color(0xFF7C3AED),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const _AvatarStack(),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  _OutlineButton(icon: Icons.filter_list_rounded, label: 'Filter'),
                  SizedBox(width: 10),
                  _OutlineButton(icon: Icons.calendar_today_rounded, label: 'Today'),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  _OutlineButton(icon: Icons.share_outlined, label: 'Share', dropdown: false),
                  SizedBox(width: 10),
                  _SolidIcon(icon: Icons.grid_view_rounded),
                  SizedBox(width: 10),
                  _OutlineIcon(icon: Icons.grid_on_rounded),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TinyIcon extends StatelessWidget {
  const _TinyIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: const Color(0xFFF5F3FF),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, size: 16, color: const Color(0xFF7C3AED)),
    );
  }
}

class _AvatarStack extends StatelessWidget {
  const _AvatarStack();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 128,
      height: 32,
      child: Stack(
        children: [
          for (int i = 0; i < 4; i++)
            Positioned(
              left: i * 22,
              child: CircleAvatar(
                radius: 14,
                backgroundColor: Colors.white,
                child: CircleAvatar(
                  radius: 12.5,
                  backgroundColor: _projectPalette[i],
                  child: Text(
                    'U${i + 1}',
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          Positioned(
            left: 88,
            child: CircleAvatar(
              radius: 14,
              backgroundColor: Colors.white,
              child: CircleAvatar(
                radius: 12.5,
                backgroundColor: const Color(0xFF7C3AED),
                child: Text(
                  '+2',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OutlineButton extends StatelessWidget {
  const _OutlineButton({
    required this.icon,
    required this.label,
    this.dropdown = true,
  });

  final IconData icon;
  final String label;
  final bool dropdown;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        foregroundColor: cs.onSurface,
        side: BorderSide(color: cs.outlineVariant),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
      onPressed: () {},
      icon: Icon(icon, size: 16),
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          if (dropdown) ...[
            const SizedBox(width: 2),
            const Icon(Icons.keyboard_arrow_down_rounded, size: 16),
          ],
        ],
      ),
    );
  }
}

class _SolidIcon extends StatelessWidget {
  const _SolidIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: const Color(0xFF7C3AED),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, size: 18, color: Colors.white),
    );
  }
}

class _OutlineIcon extends StatelessWidget {
  const _OutlineIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        border: Border.all(color: cs.outlineVariant),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, size: 18, color: cs.onSurfaceVariant),
    );
  }
}

class _KanbanBoard extends StatelessWidget {
  const _KanbanBoard({
    required this.isMobile,
    required this.columns,
    required this.statusOptions,
    required this.onStatusChanged,
  });

  final bool isMobile;
  final List<_KanbanColumn> columns;
  final List<TaskStatusOption> statusOptions;
  final Future<void> Function(_Task task, String status) onStatusChanged;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final columnWidth = isMobile ? (width * 0.82).clamp(260.0, 340.0) : 320.0;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final column in columns) ...[
            SizedBox(
              width: columnWidth,
              child: _TaskColumn(
                column: column,
                statusOptions: statusOptions,
                onStatusChanged: onStatusChanged,
              ),
            ),
            const SizedBox(width: 20),
          ],
        ],
      ),
    );
  }
}

class _TaskColumn extends StatelessWidget {
  const _TaskColumn({
    required this.column,
    required this.statusOptions,
    required this.onStatusChanged,
  });

  final _KanbanColumn column;
  final List<TaskStatusOption> statusOptions;
  final Future<void> Function(_Task task, String status) onStatusChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: column.color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text(
              column.title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Center(
                child: Text(
                  column.tasks.length.toString(),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const Spacer(),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F3FF),
                borderRadius: BorderRadius.circular(7),
              ),
              child: const Icon(Icons.add, size: 16, color: Color(0xFF7C3AED)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(height: 2, color: column.color),
        const SizedBox(height: 14),
        if (column.tasks.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFF3F4F6)),
            ),
            child: Text(
              'No tasks yet',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: const Color(0xFF9CA3AF),
              ),
            ),
          ),
        for (final task in column.tasks) ...[
          _TaskCard(
            task: task,
            statusOptions: statusOptions,
            onStatusChanged: onStatusChanged,
          ),
          const SizedBox(height: 14),
        ],
      ],
    );
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({
    required this.task,
    required this.statusOptions,
    required this.onStatusChanged,
  });

  final _Task task;
  final List<TaskStatusOption> statusOptions;
  final Future<void> Function(_Task task, String status) onStatusChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: context.panel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x11000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: task.priority.background,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  task.priority.label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: task.priority.foreground,
                  ),
                ),
              ),
              const Spacer(),
                  PopupMenuButton<String>(
                    tooltip: 'Change status',
                    icon: const Icon(Icons.more_horiz_rounded, size: 18, color: Color(0xFF9CA3AF)),
                    onSelected: (value) {
                      onStatusChanged(task, value);
                    },
                    itemBuilder: (context) => statusOptions
                        .map(
                          (s) => PopupMenuItem<String>(
                            value: s.name,
                            child: Text('Move to ${s.name}'),
                          ),
                        )
                        .toList(),
                  ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            task.title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            ),
          ),
          if (task.description != null && task.description!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              task.description!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                height: 1.4,
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 10),
          Divider(height: 1, color: context.border),
          const SizedBox(height: 10),
          Row(
            children: [
              SizedBox(
                width: 70,
                height: 24,
                child: Stack(
                  children: [
                    for (int i = 0; i < task.assignees.length; i++)
                      Positioned(
                        left: i * 14,
                        child: CircleAvatar(
                          radius: 10,
                          backgroundColor: Colors.white,
                          child: CircleAvatar(
                            radius: 9,
                            backgroundColor: _projectPalette[i % _projectPalette.length],
                            child: Text(
                              '${i + 1}',
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const Spacer(),
              const Icon(Icons.mode_comment_outlined, size: 14, color: Color(0xFF9CA3AF)),
              const SizedBox(width: 4),
              Text(
                '${task.comments} comments',
                style: GoogleFonts.plusJakartaSans(fontSize: 11, color: cs.onSurfaceVariant),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.attach_file_rounded, size: 14, color: Color(0xFF9CA3AF)),
              const SizedBox(width: 2),
              Text(
                '${task.files} files',
                style: GoogleFonts.plusJakartaSans(fontSize: 11, color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DashboardData {
  const _DashboardData({
    required this.projectName,
    required this.userName,
    required this.userSubtitle,
    required this.projects,
    required this.statusOptions,
    required this.columns,
  });

  final String projectName;
  final String userName;
  final String userSubtitle;
  final List<UserProjects> projects;
  final List<TaskStatusOption> statusOptions;
  final List<_KanbanColumn> columns;
}

class _KanbanColumn {
  const _KanbanColumn({
    required this.title,
    required this.color,
    required this.tasks,
  });

  final String title;
  final Color color;
  final List<_Task> tasks;
}

class _Task {
  const _Task({
    required this.taskId,
    required this.sourceTask,
    required this.title,
    required this.priority,
    required this.status,
    required this.comments,
    required this.files,
    required this.assignees,
    this.description,
  });

  final String taskId;
  final Task sourceTask;
  final String title;
  final String? description;
  final _PriorityChip priority;
  final String status;
  final int comments;
  final int files;
  final List<String> assignees;
}

class _PriorityChip {
  const _PriorityChip(this.label, this.background, this.foreground);

  final String label;
  final Color background;
  final Color foreground;
}

const _priorityLow = _PriorityChip('Low', Color(0xFFFFEDD5), Color(0xFFEA580C));
const _priorityHigh = _PriorityChip('High', Color(0xFFFCE7F3), Color(0xFFDB2777));
const _priorityDone = _PriorityChip('Completed', Color(0xFFDCFCE7), Color(0xFF16A34A));

const _fallbackAvatars = [
  'A',
  'B',
  'C',
];

const _projectPalette = [
  Color(0xFF8B5CF6),
  Color(0xFFF97316),
  Color(0xFF3B82F6),
  Color(0xFF14B8A6),
  Color(0xFF9CA3AF),
];

Color? _parseProjectColor(String? rawColor) {
  if (rawColor == null || rawColor.isEmpty) return null;
  try {
    final cleaned = rawColor.replaceAll('#', '').trim();
    if (cleaned.length == 6) {
      return Color(int.parse('0xFF$cleaned'));
    }
    if (cleaned.length == 8) {
      return Color(int.parse('0x$cleaned'));
    }
  } catch (_) {
    return null;
  }
  return null;
}
