import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:mymanager/database/helper/database_helper.dart';
import 'package:mymanager/database/tables/notifications/models/notification_model.dart';
import 'package:uuid/uuid.dart';

class NotificationApi {
  static const uuid = Uuid();

  static Future<List<NotificationModel>> getAllNotifications() async {
    try {
      final db = await DatabaseHelper.database;
      final maps = await db.query(
        'notifications',
        orderBy: 'created_at DESC',
      );
      return maps.map((m) => NotificationModel.fromMap(m)).toList();
    } catch (e, stack) {
      if (kDebugMode) {
        developer.log(
          'Error in getAllNotifications: $e',
          stackTrace: stack,
          name: 'NotificationApi',
        );
      }
      return [];
    }
  }

  static Future<List<NotificationModel>> getUnreadNotifications() async {
    try {
      final db = await DatabaseHelper.database;
      final maps = await db.query(
        'notifications',
        where: 'isRead = ?',
        whereArgs: [0],
        orderBy: 'created_at DESC',
      );
      return maps.map((m) => NotificationModel.fromMap(m)).toList();
    } catch (e, stack) {
      if (kDebugMode) {
        developer.log(
          'Error in getUnreadNotifications: $e',
          stackTrace: stack,
          name: 'NotificationApi',
        );
      }
      return [];
    }
  }

  static Future<int> getUnreadCount() async {
    try {
      final db = await DatabaseHelper.database;
      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM notifications WHERE isRead = 0',
      );
      return result.first['count'] as int;
    } catch (e, stack) {
      if (kDebugMode) {
        developer.log(
          'Error in getUnreadCount: $e',
          stackTrace: stack,
          name: 'NotificationApi',
        );
      }
      return 0;
    }
  }

  static Future<void> createNotification(NotificationModel notification) async {
    try {
      final db = await DatabaseHelper.database;
      await db.insert('notifications', notification.toMap());
      if (kDebugMode) {
        developer.log(
          'Created notification: ${notification.notificationId}',
          name: 'NotificationApi',
        );
      }
    } catch (e, stack) {
      if (kDebugMode) {
        developer.log(
          'Error in createNotification: $e',
          stackTrace: stack,
          name: 'NotificationApi',
        );
      }
      rethrow;
    }
  }

  static Future<void> markAsRead(String notificationId) async {
    try {
      final db = await DatabaseHelper.database;
      await db.update(
        'notifications',
        {'isRead': 1},
        where: 'notificationId = ?',
        whereArgs: [notificationId],
      );
      if (kDebugMode) {
        developer.log(
          'Marked notification as read: $notificationId',
          name: 'NotificationApi',
        );
      }
    } catch (e, stack) {
      if (kDebugMode) {
        developer.log(
          'Error in markAsRead: $e',
          stackTrace: stack,
          name: 'NotificationApi',
        );
      }
    }
  }

  static Future<void> markAllAsRead() async {
    try {
      final db = await DatabaseHelper.database;
      await db.update(
        'notifications',
        {'isRead': 1},
        where: 'isRead = ?',
        whereArgs: [0],
      );
      if (kDebugMode) {
        developer.log('Marked all notifications as read', name: 'NotificationApi');
      }
    } catch (e, stack) {
      if (kDebugMode) {
        developer.log(
          'Error in markAllAsRead: $e',
          stackTrace: stack,
          name: 'NotificationApi',
        );
      }
    }
  }

  static Future<void> deleteNotification(String notificationId) async {
    try {
      final db = await DatabaseHelper.database;
      await db.delete(
        'notifications',
        where: 'notificationId = ?',
        whereArgs: [notificationId],
      );
      if (kDebugMode) {
        developer.log(
          'Deleted notification: $notificationId',
          name: 'NotificationApi',
        );
      }
    } catch (e, stack) {
      if (kDebugMode) {
        developer.log(
          'Error in deleteNotification: $e',
          stackTrace: stack,
          name: 'NotificationApi',
        );
      }
    }
  }

  static Future<void> deleteAllNotifications() async {
    try {
      final db = await DatabaseHelper.database;
      await db.delete('notifications');
      if (kDebugMode) {
        developer.log('Deleted all notifications', name: 'NotificationApi');
      }
    } catch (e, stack) {
      if (kDebugMode) {
        developer.log(
          'Error in deleteAllNotifications: $e',
          stackTrace: stack,
          name: 'NotificationApi',
        );
      }
    }
  }
}
