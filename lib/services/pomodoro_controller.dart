import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:mymanager/constants/app_constants.dart';
import 'package:mymanager/services/notification_service.dart';

class PomodoroController extends GetxController {
  final RxInt minutes = AppConstants.pomodoroWorkMinutes.obs;
  final RxInt seconds = 0.obs;
  final RxBool isRunning = false.obs;
  final RxBool isWorkSession = true.obs;
  final RxInt sessionsCompleted = 0.obs;
  
  Timer? _timer;
  String? currentTaskId;
  
  void startTimer({String? taskId}) {
    if (isRunning.value) return;
    
    currentTaskId = taskId;
    isRunning.value = true;
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (seconds.value > 0) {
        seconds.value--;
      } else if (minutes.value > 0) {
        minutes.value--;
        seconds.value = 59;
      } else {
        _onSessionComplete();
      }
    });
    
    if (kDebugMode) {
      developer.log('Pomodoro started for task: $taskId', name: 'PomodoroController');
    }
  }
  
  void pauseTimer() {
    isRunning.value = false;
    _timer?.cancel();
  }
  
  void resumeTimer() {
    if (!isRunning.value && (minutes.value > 0 || seconds.value > 0)) {
      startTimer(taskId: currentTaskId);
    }
  }
  
  void resetTimer() {
    _timer?.cancel();
    isRunning.value = false;
    minutes.value = isWorkSession.value
        ? AppConstants.pomodoroWorkMinutes
        : (sessionsCompleted.value % AppConstants.pomodoroSessionsBeforeLongBreak == 0
            ? AppConstants.pomodoroLongBreak
            : AppConstants.pomodoroShortBreak);
    seconds.value = 0;
  }
  
  void _onSessionComplete() {
    _timer?.cancel();
    isRunning.value = false;
    
    if (isWorkSession.value) {
      sessionsCompleted.value++;
      
      // Show completion notification
      NotificationService().showNotification(
        id: 999,
        title: 'Pomodoro Complete!',
        body: 'Great work! Time for a break.',
        channelId: AppConstants.channelIdFocus,
      );
      
      // Set break duration
      if (sessionsCompleted.value % AppConstants.pomodoroSessionsBeforeLongBreak == 0) {
        minutes.value = AppConstants.pomodoroLongBreak;
      } else {
        minutes.value = AppConstants.pomodoroShortBreak;
      }
    } else {
      // Show break complete notification
      NotificationService().showNotification(
        id: 999,
        title: 'Break Complete!',
        body: 'Ready to focus again?',
        channelId: AppConstants.channelIdFocus,
      );
      
      minutes.value = AppConstants.pomodoroWorkMinutes;
    }
    
    isWorkSession.value = !isWorkSession.value;
    seconds.value = 0;
    
    if (kDebugMode) {
      developer.log(
        'Session complete. Sessions: ${sessionsCompleted.value}',
        name: 'PomodoroController',
      );
    }
  }
  
  String get timeString {
    final m = minutes.value.toString().padLeft(2, '0');
    final s = seconds.value.toString().padLeft(2, '0');
    return '$m:$s';
  }
  
  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }
}
