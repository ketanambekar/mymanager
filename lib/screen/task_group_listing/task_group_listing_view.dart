import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mymanager/screen/task_group_listing/task_group_listing_controller.dart';
import 'package:mymanager/database/tables/user_projects/models/user_project_model.dart';
import 'package:mymanager/database/apis/task_api.dart';

class TaskGroupListingView extends StatelessWidget {
  const TaskGroupListingView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(TaskGroupListingController());

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'Task Groups',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(
              color: Color(0xFF7C4DFF),
            ),
          );
        }

        if (controller.projects.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.folder_outlined,
                  size: 80,
                  color: Colors.white.withOpacity(0.3),
                ),
                const SizedBox(height: 16),
                Text(
                  'No projects yet',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Create a project to organize your tasks',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: controller.loadProjects,
          color: const Color(0xFF7C4DFF),
          backgroundColor: const Color(0xFF1A1A2E),
          child: ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: controller.projects.length,
            itemBuilder: (context, index) {
              final project = controller.projects[index];
              return _ProjectCard(
                project: project,
                controller: controller,
              );
            },
          ),
        );
      }),
    );
  }
}

class _ProjectCard extends StatelessWidget {
  final UserProjects project;
  final TaskGroupListingController controller;

  const _ProjectCard({
    required this.project,
    required this.controller,
  });

  Color _getProjectColor() {
    final colors = [
      const Color(0xFFFF6B6B),
      const Color(0xFF7C4DFF),
      const Color(0xFFFFBE0B),
      const Color(0xFF4ECDC4),
      const Color(0xFF95E1D3),
      const Color(0xFFFF6B9D),
      const Color(0xFF5F27CD),
    ];
    return colors[project.projectId.hashCode.abs() % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final color = _getProjectColor();

    return GestureDetector(
      onTap: () {
        Get.toNamed('/task-group-detail', arguments: {
          'projectId': project.projectId,
          'projectName': project.projectName ?? 'Unnamed Project',
          'projectColor': color,
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withOpacity(0.3),
              color.withOpacity(0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: color.withOpacity(0.5),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.folder_outlined,
                    color: color,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        project.projectName ?? 'Unnamed Project',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Obx(() {
                        final taskCount = controller.getTaskCount(project.projectId);
                        return Text(
                          '$taskCount Task${taskCount != 1 ? 's' : ''}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 14,
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white.withOpacity(0.6),
                  size: 20,
                ),
              ],
            ),
            if (project.projectDescription != null && project.projectDescription!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                project.projectDescription!,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 14,
                  height: 1.5,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 16),
            FutureBuilder<Map<String, int>>(
              future: _getTaskStats(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const SizedBox.shrink();
                }
                final stats = snapshot.data!;
                return Row(
                  children: [
                    _StatBadge(
                      label: 'To Do',
                      count: stats['todo'] ?? 0,
                      color: const Color(0xFF7C4DFF),
                    ),
                    const SizedBox(width: 8),
                    _StatBadge(
                      label: 'In Progress',
                      count: stats['inProgress'] ?? 0,
                      color: const Color(0xFFFFBE0B),
                    ),
                    const SizedBox(width: 8),
                    _StatBadge(
                      label: 'Done',
                      count: stats['completed'] ?? 0,
                      color: const Color(0xFF4ECDC4),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<Map<String, int>> _getTaskStats() async {
    try {
      final tasks = await TaskApi.getTasks(projectId: project.projectId);
      return {
        'todo': tasks.where((t) => t.taskStatus == 'Todo').length,
        'inProgress': tasks.where((t) => t.taskStatus == 'In Progress').length,
        'completed': tasks.where((t) => t.taskStatus == 'Completed').length,
      };
    } catch (e) {
      return {'todo': 0, 'inProgress': 0, 'completed': 0};
    }
  }
}

class _StatBadge extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _StatBadge({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 10,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
