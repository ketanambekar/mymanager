import 'package:get/get.dart';
import 'package:mymanager/database/apis/notification_api.dart';
import 'package:mymanager/database/tables/notifications/models/notification_model.dart';
import 'package:mymanager/database/apis/task_api.dart';
import 'package:mymanager/database/apis/habit_api.dart';
import 'dart:developer' as developer;

class NotificationsController extends GetxController {
  final RxList<NotificationModel> notifications = <NotificationModel>[].obs;
  final RxList<ScheduledNotificationInfo> scheduledNotifications = <ScheduledNotificationInfo>[].obs;
  final RxInt unreadCount = 0.obs;
  final RxInt pendingCount = 0.obs;
  final RxBool isLoading = false.obs;
  final RxString filter = 'all'.obs; // 'all', 'unread', 'read'

  @override
  void onInit() {
    super.onInit();
    loadNotifications();
    loadScheduledNotifications();
  }

  Future<void> loadScheduledNotifications() async {
    try {
      final List<ScheduledNotificationInfo> upcoming = [];
      
      // Get tasks with notifications enabled
      final tasks = await TaskApi.getTasks();
      final now = DateTime.now();
      
      for (final task in tasks) {
        if (task.enableAlerts && task.alertTime != null && task.alertTime!.isNotEmpty) {
          try {
            // alertTime is in format "HH:mm", convert to DateTime
            final timeParts = task.alertTime!.split(':');
            if (timeParts.length == 2) {
              final hour = int.tryParse(timeParts[0]) ?? 0;
              final minute = int.tryParse(timeParts[1]) ?? 0;
              
              // Check if task has a due date to use, otherwise use today
              DateTime baseDate;
              if (task.taskDueDate != null && task.taskDueDate!.isNotEmpty) {
                baseDate = DateTime.parse(task.taskDueDate!);
              } else {
                baseDate = now;
              }
              
              var notificationTime = DateTime(
                baseDate.year,
                baseDate.month,
                baseDate.day,
                hour,
                minute,
              );
              
              // If notification time is in the past, skip it
              if (notificationTime.isAfter(now)) {
                upcoming.add(ScheduledNotificationInfo(
                  id: task.taskId.hashCode,
                  title: task.taskTitle,
                  body: 'Task Reminder: ${task.taskTitle}',
                  scheduledTime: notificationTime,
                  type: 'task',
                ));
              }
            }
          } catch (e) {
            developer.log('Error parsing task alert time: ${task.alertTime} - $e', name: 'NotificationsController');
          }
        }
      }

      // Get habits with reminders enabled
      final habits = await HabitApi.getHabits();
      for (final habit in habits) {
        if (habit.enableAlerts && habit.alertTime != null && habit.alertTime!.isNotEmpty) {
          try {
            final timeParts = habit.alertTime!.split(':');
            if (timeParts.length == 2) {
              final hour = int.tryParse(timeParts[0]) ?? 0;
              final minute = int.tryParse(timeParts[1]) ?? 0;
              
              var nextReminder = DateTime(now.year, now.month, now.day, hour, minute);
              if (nextReminder.isBefore(now)) {
                nextReminder = nextReminder.add(const Duration(days: 1));
              }
              
              upcoming.add(ScheduledNotificationInfo(
                id: habit.habitId.hashCode,
                title: habit.habitName,
                body: 'Habit Reminder: ${habit.habitName}',
                scheduledTime: nextReminder,
                type: 'habit',
              ));
            }
          } catch (e) {
            developer.log('Error parsing habit alert time: ${habit.alertTime} - $e', name: 'NotificationsController');
          }
        }
      }

      // Sort by scheduled time
      upcoming.sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
      scheduledNotifications.value = upcoming;
      pendingCount.value = upcoming.length;
    } catch (e) {
      developer.log('Error loading scheduled notifications: $e', name: 'NotificationsController');
    }
  }

  Future<void> loadNotifications() async {
    isLoading.value = true;
    try {
      final allNotifications = await NotificationApi.getAllNotifications();
      
      // Apply filter
      if (filter.value == 'unread') {
        notifications.value = allNotifications.where((n) => !n.isRead).toList();
      } else if (filter.value == 'read') {
        notifications.value = allNotifications.where((n) => n.isRead).toList();
      } else {
        notifications.value = allNotifications;
      }
      
      await updateUnreadCount();
      await loadScheduledNotifications(); // Refresh scheduled notifications too
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateUnreadCount() async {
    unreadCount.value = await NotificationApi.getUnreadCount();
  }

  Future<void> markAsRead(String notificationId) async {
    await NotificationApi.markAsRead(notificationId);
    await loadNotifications();
  }

  Future<void> markAllAsRead() async {
    await NotificationApi.markAllAsRead();
    await loadNotifications();
  }

  Future<void> deleteNotification(String notificationId) async {
    await NotificationApi.deleteNotification(notificationId);
    await loadNotifications();
  }

  Future<void> deleteAllNotifications() async {
    await NotificationApi.deleteAllNotifications();
    await loadNotifications();
  }

  void setFilter(String newFilter) {
    filter.value = newFilter;
    loadNotifications();
  }

  List<NotificationModel> get filteredNotifications {
    // Already filtered in loadNotifications, just return
    return notifications;
  }
  
  Future<void> refreshAll() async {
    await loadNotifications();
    await loadScheduledNotifications();
  }
}
