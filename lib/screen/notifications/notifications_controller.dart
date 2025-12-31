import 'package:get/get.dart';
import 'package:mymanager/database/apis/notification_api.dart';
import 'package:mymanager/database/tables/notifications/models/notification_model.dart';

class NotificationsController extends GetxController {
  final RxList<NotificationModel> notifications = <NotificationModel>[].obs;
  final RxInt unreadCount = 0.obs;
  final RxBool isLoading = false.obs;
  final RxString filter = 'all'.obs; // 'all', 'unread', 'read'

  @override
  void onInit() {
    super.onInit();
    loadNotifications();
  }

  Future<void> loadNotifications() async {
    isLoading.value = true;
    try {
      if (filter.value == 'unread') {
        notifications.value = await NotificationApi.getUnreadNotifications();
      } else {
        final allNotifications = await NotificationApi.getAllNotifications();
        if (filter.value == 'read') {
          notifications.value = allNotifications.where((n) => n.isRead).toList();
        } else {
          notifications.value = allNotifications;
        }
      }
      await updateUnreadCount();
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
    return notifications;
  }
}
