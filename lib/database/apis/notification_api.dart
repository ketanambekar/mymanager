import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:mymanager/database/tables/notifications/models/notification_model.dart';
import 'package:mymanager/services/api_client.dart';
import 'package:uuid/uuid.dart';

class NotificationApi {
  static const uuid = Uuid();
  static final ApiClient _client = ApiClient.instance;

  static Future<List<NotificationModel>> getAllNotifications() async {
    try {
      final response = await _client.get('/notifications?limit=100&page=1');
      if (response.statusCode < 200 || response.statusCode >= 300) return [];

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final rows = (body['data'] as List<dynamic>? ?? const []);
      return rows.cast<Map<String, dynamic>>().map(_mapNotification).toList();
    } catch (e, stack) {
      if (kDebugMode) {
        developer.log('Error in getAllNotifications: $e', stackTrace: stack, name: 'NotificationApi');
      }
      return [];
    }
  }

  static Future<List<NotificationModel>> getUnreadNotifications() async {
    final all = await getAllNotifications();
    return all.where((n) => !n.isRead).toList();
  }

  static Future<int> getUnreadCount() async {
    final unread = await getUnreadNotifications();
    return unread.length;
  }

  static Future<void> createNotification(NotificationModel notification) async {
    // Notifications are generated server-side based on app actions.
    if (kDebugMode) {
      developer.log('createNotification is server-driven; skipping direct create', name: 'NotificationApi');
    }
  }

  static Future<void> markAsRead(String notificationId) async {
    await _client.patch('/notifications/$notificationId/read', body: {});
  }

  static Future<void> markAllAsRead() async {
    final all = await getUnreadNotifications();
    for (final notification in all) {
      await markAsRead(notification.notificationId);
    }
  }

  static Future<void> deleteNotification(String notificationId) async {
    await _client.delete('/notifications/$notificationId');
  }

  static Future<void> deleteAllNotifications() async {
    await _client.delete('/notifications');
  }

  static NotificationModel _mapNotification(Map<String, dynamic> row) {
    final type = row['type']?.toString() ?? 'system';
    return NotificationModel.fromMap({
      'notificationId': row['id'].toString(),
      'title': _titleForType(type),
      'message': 'Notification: $type (#${row['reference_id'] ?? '-'}).',
      'type': type,
      'relatedId': row['reference_id']?.toString(),
      'isRead': (row['is_read'] == true) ? 1 : 0,
      'created_at': row['created_at']?.toString() ?? DateTime.now().toIso8601String(),
      'scheduled_for': null
    });
  }

  static String _titleForType(String type) {
    switch (type) {
      case 'task_assigned':
        return 'Task Assigned';
      case 'comment_mention':
        return 'Mentioned in Comment';
      case 'project_invite':
        return 'Project Invitation';
      default:
        return 'Notification';
    }
  }
}
