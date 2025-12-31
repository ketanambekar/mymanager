import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:mymanager/constants/app_constants.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  /// Initialize notification service
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      tz.initializeTimeZones();

      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const settings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notifications.initialize(
        settings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // Create notification channels for Android
      await _createNotificationChannels();

      _initialized = true;
      if (kDebugMode) {
        developer.log('Notification service initialized', name: 'NotificationService');
      }
    } catch (e, stack) {
      developer.log(
        'Error initializing notifications: $e',
        error: e,
        stackTrace: stack,
        name: 'NotificationService',
      );
    }
  }

  /// Create Android notification channels
  Future<void> _createNotificationChannels() async {
    try {
      const tasksChannel = AndroidNotificationChannel(
        AppConstants.channelIdTasks,
        AppConstants.channelNameTasks,
        description: 'Notifications for task reminders',
        importance: Importance.high,
        enableVibration: true,
      );

      const habitsChannel = AndroidNotificationChannel(
        AppConstants.channelIdHabits,
        AppConstants.channelNameHabits,
        description: 'Notifications for habit reminders',
        importance: Importance.high,
        enableVibration: true,
      );

      const focusChannel = AndroidNotificationChannel(
        AppConstants.channelIdFocus,
        AppConstants.channelNameFocus,
        description: 'Notifications for focus sessions',
        importance: Importance.high,
        sound: RawResourceAndroidNotificationSound('focus_complete'),
      );

      await _notifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(tasksChannel);

      await _notifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(habitsChannel);

      await _notifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(focusChannel);
    } catch (e, stack) {
      developer.log(
        'Error creating channels: $e',
        error: e,
        stackTrace: stack,
        name: 'NotificationService',
      );
    }
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    if (kDebugMode) {
      developer.log(
        'Notification tapped: ${response.payload}',
        name: 'NotificationService',
      );
    }
    // TODO: Navigate to specific task/habit based on payload
  }

  /// Request notification permissions (Android 13+)
  Future<bool> requestPermissions() async {
    try {
      final androidImpl = _notifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      
      if (androidImpl != null) {
        // Request exact alarm permission for Android 13+
        final exactAlarmGranted = await androidImpl.requestExactAlarmsPermission();
        
        // Request notification permission
        final notificationGranted = await androidImpl.requestNotificationsPermission();
        
        if (kDebugMode) {
          developer.log(
            'Notification permissions - Exact alarms: $exactAlarmGranted, Notifications: $notificationGranted',
            name: 'NotificationService',
          );
        }
        
        return exactAlarmGranted == true && notificationGranted == true;
      }
      
      return true; // iOS handles permissions differently
    } catch (e, stack) {
      developer.log(
        'Error requesting permissions: $e',
        error: e,
        stackTrace: stack,
        name: 'NotificationService',
      );
      return false;
    }
  }

  /// Schedule task notification
  Future<bool> scheduleTaskNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    try {
      // Check and request permissions if needed
      final hasPermission = await requestPermissions();
      
      if (!hasPermission) {
        if (kDebugMode) {
          developer.log(
            'Notification permissions not granted, skipping scheduling',
            name: 'NotificationService',
          );
        }
        return false;
      }

      const androidDetails = AndroidNotificationDetails(
        AppConstants.channelIdTasks,
        AppConstants.channelNameTasks,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );

      const iosDetails = DarwinNotificationDetails();

      const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

      await _notifications.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(scheduledDate, tz.local),
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: payload,
      );

      if (kDebugMode) {
        developer.log('Scheduled notification $id for $scheduledDate', name: 'NotificationService');
      }
      return true;
    } catch (e, stack) {
      // Only log the error, don't throw - task creation should succeed even if notification fails
      if (kDebugMode) {
        developer.log(
          'Could not schedule notification: ${e.toString()}',
          error: e,
          stackTrace: stack,
          name: 'NotificationService',
        );
      }
      return false;
    }
  }

  /// Schedule recurring notification
  Future<void> scheduleRecurringNotification({
    required int id,
    required String title,
    required String body,
    required String frequency,
    required DateTime startTime,
    String? payload,
  }) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        AppConstants.channelIdTasks,
        AppConstants.channelNameTasks,
        importance: Importance.high,
        priority: Priority.high,
      );

      const iosDetails = DarwinNotificationDetails();
      const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

      // Schedule based on frequency
      switch (frequency) {
        case AppConstants.frequencyDaily:
          await _notifications.zonedSchedule(
            id,
            title,
            body,
            _nextInstanceOfTime(startTime),
            details,
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            matchDateTimeComponents: DateTimeComponents.time,
            payload: payload,
          );
          break;

        case AppConstants.frequencyWeekly:
          await _notifications.zonedSchedule(
            id,
            title,
            body,
            _nextInstanceOfTime(startTime),
            details,
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
            payload: payload,
          );
          break;

        default:
          // For other frequencies, schedule single notification
          await scheduleTaskNotification(
            id: id,
            title: title,
            body: body,
            scheduledDate: startTime,
            payload: payload,
          );
      }

      if (kDebugMode) {
        developer.log('Scheduled $frequency notification $id', name: 'NotificationService');
      }
    } catch (e, stack) {
      developer.log(
        'Error scheduling recurring notification: $e',
        error: e,
        stackTrace: stack,
        name: 'NotificationService',
      );
    }
  }

  /// Show immediate notification
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String channelId = AppConstants.channelIdTasks,
    String? payload,
  }) async {
    try {
      final androidDetails = AndroidNotificationDetails(
        channelId,
        channelId == AppConstants.channelIdTasks
            ? AppConstants.channelNameTasks
            : AppConstants.channelNameFocus,
        importance: Importance.high,
        priority: Priority.high,
      );

      const iosDetails = DarwinNotificationDetails();
      final details = NotificationDetails(android: androidDetails, iOS: iosDetails);

      await _notifications.show(id, title, body, details, payload: payload);
    } catch (e, stack) {
      developer.log(
        'Error showing notification: $e',
        error: e,
        stackTrace: stack,
        name: 'NotificationService',
      );
    }
  }

  /// Cancel notification
  Future<void> cancelNotification(int id) async {
    try {
      await _notifications.cancel(id);
      if (kDebugMode) {
        developer.log('Cancelled notification $id', name: 'NotificationService');
      }
    } catch (e, stack) {
      developer.log(
        'Error cancelling notification: $e',
        error: e,
        stackTrace: stack,
        name: 'NotificationService',
      );
    }
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    try {
      await _notifications.cancelAll();
      if (kDebugMode) {
        developer.log('Cancelled all notifications', name: 'NotificationService');
      }
    } catch (e, stack) {
      developer.log(
        'Error cancelling all notifications: $e',
        error: e,
        stackTrace: stack,
        name: 'NotificationService',
      );
    }
  }

  /// Helper to get next instance of time
  tz.TZDateTime _nextInstanceOfTime(DateTime time) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }
}
