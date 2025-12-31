import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mymanager/screen/notifications/notifications_controller.dart';
import 'package:mymanager/database/tables/notifications/models/notification_model.dart';
import 'package:mymanager/utils/global_utils.dart';

class NotificationsView extends StatelessWidget {
  NotificationsView({super.key});
  
  final controller = Get.put(NotificationsController());

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'task':
        return Icons.task_alt;
      case 'project':
        return Icons.folder_outlined;
      case 'reminder':
        return Icons.alarm;
      case 'system':
        return Icons.settings;
      default:
        return Icons.notifications;
    }
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'task':
        return const Color(0xFF7C4DFF);
      case 'project':
        return const Color(0xFF4ECDC4);
      case 'reminder':
        return const Color(0xFFFFBE0B);
      case 'system':
        return const Color(0xFFFF6B6B);
      default:
        return const Color(0xFF7C4DFF);
    }
  }

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
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => Get.back(),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.arrow_back,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Text(
                            'Notifications',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Obx(() => controller.unreadCount.value > 0
                            ? GestureDetector(
                                onTap: () => controller.markAllAsRead(),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF7C4DFF),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text(
                                    'Mark all read',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              )
                            : const SizedBox.shrink()),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Filter chips
                    Row(
                      children: [
                        Obx(() => _buildFilterChip(
                              'All',
                              'all',
                              controller.filter.value == 'all',
                            )),
                        const SizedBox(width: 8),
                        Obx(() => _buildFilterChip(
                              'Unread',
                              'unread',
                              controller.filter.value == 'unread',
                            )),
                        const SizedBox(width: 8),
                        Obx(() => _buildFilterChip(
                              'Read',
                              'read',
                              controller.filter.value == 'read',
                            )),
                        const Spacer(),
                        if (controller.notifications.isNotEmpty)
                          GestureDetector(
                            onTap: () {
                              Get.dialog(
                                AlertDialog(
                                  backgroundColor: const Color(0xFF1A1A2E),
                                  title: const Text(
                                    'Delete All',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  content: const Text(
                                    'Are you sure you want to delete all notifications?',
                                    style: TextStyle(color: Colors.white70),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Get.back(),
                                      child: const Text('Cancel'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () {
                                        controller.deleteAllNotifications();
                                        Get.back();
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFFFF6B6B),
                                      ),
                                      child: const Text('Delete'),
                                    ),
                                  ],
                                ),
                              );
                            },
                            child: Icon(
                              Icons.delete_outline,
                              color: Colors.white.withOpacity(0.7),
                              size: 24,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // Notifications List
              Expanded(
                child: Obx(() {
                  if (controller.isLoading.value) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF7C4DFF),
                      ),
                    );
                  }

                  if (controller.notifications.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.notifications_off_outlined,
                            size: 80,
                            color: Colors.white.withOpacity(0.3),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No notifications',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: controller.loadNotifications,
                    color: const Color(0xFF7C4DFF),
                    backgroundColor: const Color(0xFF1A1A2E),
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: controller.notifications.length,
                      itemBuilder: (context, index) {
                        final notification = controller.notifications[index];
                        return _buildNotificationCard(notification);
                      },
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, bool isSelected) {
    return GestureDetector(
      onTap: () => controller.setFilter(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF7C4DFF)
              : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF7C4DFF)
                : Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white.withOpacity(0.7),
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationCard(NotificationModel notification) {
    final color = _getNotificationColor(notification.type);
    
    return Dismissible(
      key: Key(notification.notificationId),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFFF6B6B),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(
          Icons.delete,
          color: Colors.white,
          size: 24,
        ),
      ),
      onDismissed: (direction) {
        controller.deleteNotification(notification.notificationId);
      },
      child: GestureDetector(
        onTap: () {
          if (!notification.isRead) {
            controller.markAsRead(notification.notificationId);
          }
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: notification.isRead
                ? Colors.white.withOpacity(0.03)
                : Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: notification.isRead
                  ? Colors.white.withOpacity(0.05)
                  : color.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getNotificationIcon(notification.type),
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: notification.isRead
                                  ? FontWeight.normal
                                  : FontWeight.w600,
                            ),
                          ),
                        ),
                        if (!notification.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      notification.message,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      timeAgo(notification.createdAt),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
