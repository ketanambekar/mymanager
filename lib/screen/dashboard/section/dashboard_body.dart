import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mymanager/database/apis/task_api.dart';
import 'package:mymanager/database/apis/user_project_api.dart';
import 'package:mymanager/database/apis/notification_api.dart';
import 'package:mymanager/database/apis/user_profile_api.dart';
import 'package:mymanager/database/tables/tasks/models/task_model.dart';
import 'package:mymanager/screen/dashboard/dashboard_controller.dart';
import 'package:mymanager/screen/task_group_detail/task_group_detail_view.dart';
import 'package:mymanager/screen/notifications/notifications_view.dart';
import 'package:mymanager/constants/app_constants.dart';
import 'package:get_storage/get_storage.dart';

class DashboardContent extends StatefulWidget {
  DashboardContent({super.key});

  @override
  State<DashboardContent> createState() => _DashboardContentState();
}

class _DashboardContentState extends State<DashboardContent> {
  final controller = Get.find<DashboardController>();
  List<Task> inProgressTasks = [];
  List<Task> todayTasks = [];
  bool isLoading = true;
  final RxInt unreadNotifications = 0.obs;
  final RxString userName = ''.obs;

  @override
  void initState() {
    super.initState();
    _loadTasks();
    _loadNotificationCount();
    _loadUserName();
    
    // Listen for refresh triggers
    ever(controller.isDashboardRefreshing, (isRefreshing) {
      if (!isRefreshing && mounted) {
        _loadTasks();
        _loadNotificationCount();
        _loadUserName();
      }
    });
  }

  Future<void> _loadNotificationCount() async {
    unreadNotifications.value = await NotificationApi.getUnreadCount();
  }

  Future<void> _loadUserName() async {
    final profileId = GetStorage().read(AppConstants.profileId);
    if (profileId != null) {
      final profile = await UserProfileApi.getProfile(profileId);
      if (profile != null && profile.name != null && profile.name!.isNotEmpty) {
        userName.value = profile.name!;
      } else {
        userName.value = controller.projects.isEmpty ? 'User' : 'Manager';
      }
    } else {
      userName.value = controller.projects.isEmpty ? 'User' : 'Manager';
    }
  }

  Future<void> _loadTasks() async {
    setState(() => isLoading = true);
    final today = await TaskApi.getTodayTasks();
    final all = await TaskApi.getTasks(includeCompleted: false);
    await controller.getAllProjects(); // Ensure projects are loaded
    await _loadNotificationCount(); // Refresh notification count
    
    setState(() {
      // Show both To do and In Progress tasks on dashboard
      todayTasks = today.where((t) => 
        t.taskStatus == 'Todo' || t.taskStatus == 'In Progress'
      ).toList();
      
      // Sort by due date (oldest first) and limit to 10
      final filteredTasks = all.where((t) => 
        t.taskStatus == 'Todo' || t.taskStatus == 'In Progress'
      ).toList();
      
      filteredTasks.sort((a, b) {
        if (a.taskDueDate == null && b.taskDueDate == null) return 0;
        if (a.taskDueDate == null) return 1;
        if (b.taskDueDate == null) return -1;
        return DateTime.parse(a.taskDueDate!).compareTo(DateTime.parse(b.taskDueDate!));
      });
      
      inProgressTasks = filteredTasks.take(10).toList();
      isLoading = false;
    });
  }

  Future<String> _getProjectLabel(Task task) async {
    if (task.projectId == null) return '';
    try {
      final project = await UserProjectsApi.getProjectById(task.projectId!);
      return project?.projectName ?? '';
    } catch (e) {
      return '';
    }
  }

  Color _getProjectColor(Task task) {
    // Use priority-based colors
    switch (task.taskPriority) {
      case 'High':
        return const Color(0xFFFF6B6B); // Red
      case 'Medium':
        return const Color(0xFFFFBE0B); // Orange
      case 'Low':
        return const Color(0xFF4ECDC4); // Teal/Green
      default:
        return const Color(0xFF7C4DFF); // Purple
    }
  }

  String _formatTaskTime(Task task) {
    if (task.taskDueDate == null) return '';
    final date = DateTime.parse(task.taskDueDate!);
    final now = DateTime.now();
    final difference = date.difference(now);
    
    // Check if task is overdue or upcoming
    if (difference.isNegative && task.taskStatus != 'Completed') {
      final hours = difference.inHours.abs();
      if (hours < 1) {
        return 'MISSED ${difference.inMinutes.abs()}m ago';
      } else if (hours < 24) {
        return 'MISSED ${hours}h ago';
      } else {
        return 'MISSED ${difference.inDays.abs()}d ago';
      }
    } else if (difference.inMinutes > 0 && difference.inHours < 24) {
      // Show upcoming within 24 hours
      if (difference.inHours < 1) {
        return 'In ${difference.inMinutes}m';
      } else {
        return 'In ${difference.inHours}h ${difference.inMinutes % 60}m';
      }
    }
    
    final hour = date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute ${date.hour >= 12 ? 'PM' : 'AM'}';
  }
  
  Color _getTimeColor(Task task) {
    if (task.taskDueDate == null) return Colors.white70;
    final date = DateTime.parse(task.taskDueDate!);
    final now = DateTime.now();
    final difference = date.difference(now);
    
    if (difference.isNegative && task.taskStatus != 'Completed') {
      return const Color(0xFFFF6B6B); // Red for missed
    } else if (difference.inMinutes > 0 && difference.inHours < 2) {
      return const Color(0xFFFFBE0B); // Orange for upcoming soon
    }
    
    return Colors.white70;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
        ),
      ),
      child: RefreshIndicator(
        onRefresh: _loadTasks,
        color: const Color(0xFF7C4DFF),
        backgroundColor: const Color(0xFF1A1A2E),
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20, top: 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Profile Card
              Container(
                padding: const EdgeInsets.all(20),
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
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const CircleAvatar(
                            radius: 24,
                            backgroundColor: Color(0xFF7C4DFF),
                            child: Icon(Icons.person, color: Colors.white, size: 28),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hey',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                              SizedBox(height: 2),
                              Obx(() => Text(
                                userName.value.isEmpty ? 'Manager' : userName.value,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              )),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "You have ${todayTasks.length} task${todayTasks.length != 1 ? 's' : ''}",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                "today",
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                              SizedBox(height: 12),
                              GestureDetector(
                                onTap: () {
                                  controller.navController.changeIndex(1); // Go to tasks tab
                                },
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    'View Task',
                                    style: TextStyle(
                                      color: Color(0xFF7C4DFF),
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                          ),
                          child: Center(
                            child: Text(
                              '${todayTasks.isEmpty ? 0 : (todayTasks.where((t) => t.taskStatus == 'Completed').length / todayTasks.length * 100).toInt()}%',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // In Progress Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Tasks',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Get.toNamed('/task-listing'),
                    child: Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              if (isLoading)
                const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                )
              else if (inProgressTasks.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: Text(
                      'No tasks in progress',
                      style: TextStyle(color: Colors.white54),
                    ),
                  ),
                )
              else
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: inProgressTasks.length,
                    itemBuilder: (context, index) {
                      final task = inProgressTasks[index];
                      final color = _getProjectColor(task);
                      
                      return Container(
                        width: 160,
                        margin: const EdgeInsets.only(right: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: color.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            FutureBuilder<String>(
                              future: _getProjectLabel(task),
                              builder: (context, snapshot) {
                                final projectName = snapshot.data ?? '';
                                if (projectName.isEmpty) return const SizedBox.shrink();
                                return Text(
                                  projectName,
                                  style: TextStyle(
                                    color: color,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 8),
                            Expanded(
                              child: Text(
                                task.taskTitle,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  Icons.access_time,
                                  size: 12,
                                  color: _getTimeColor(task),
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    _formatTaskTime(task),
                                    style: TextStyle(
                                      color: _getTimeColor(task),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

              const SizedBox(height: 24),

              // Task Groups Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Task Groups',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Get.toNamed('/task-group-listing'),
                    child: Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Task Group Cards - Dynamic from projects
              Obx(() {
                final projects = controller.projects;
                if (projects.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(
                      child: Text(
                        'No projects yet',
                        style: TextStyle(color: Colors.white54),
                      ),
                    ),
                  );
                }
                
                return Column(
                  children: projects.take(3).map((project) {
                    final colors = [
                      const Color(0xFFFF6B6B),
                      const Color(0xFF7C4DFF),
                      const Color(0xFFFFBE0B),
                      const Color(0xFF4ECDC4),
                      const Color(0xFF95E1D3),
                    ];
                    final color = colors[project.projectId.hashCode.abs() % colors.length];
                    
                    return FutureBuilder<List<Task>>(
                      future: TaskApi.getTasks(projectId: project.projectId),
                      builder: (context, snapshot) {
                        final taskCount = snapshot.data?.length ?? 0;
                        final completedCount = snapshot.data?.where((t) => t.taskStatus == 'Completed').length ?? 0;
                        
                        return _buildTaskGroup(
                          project.projectName ?? 'Unnamed Project',
                          '$taskCount Task${taskCount != 1 ? 's' : ''}',
                          color,
                          completedCount,
                        );
                      },
                    );
                  }).toList(),
                );
              }),

              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTaskGroup(String title, String subtitle, Color color, int progress) {
    return GestureDetector(
      onTap: () async {
        // Find the project by name
        final project = controller.projects.firstWhereOrNull(
          (p) => p.projectName == title,
        );
        if (project != null) {
          await Get.toNamed('/task-group-detail', arguments: {
            'projectId': project.projectId,
            'projectName': title,
            'projectColor': color,
          });
          // Refresh dashboard after returning
          _loadTasks();
        }
      },
      child: Container(
      margin: const EdgeInsets.only(bottom: 12),
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
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.folder_outlined, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$progress',
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    ),
    );
  }
}
