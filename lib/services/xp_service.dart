import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:get_storage/get_storage.dart';
import 'package:mymanager/constants/app_constants.dart';
import 'package:mymanager/database/apis/user_profile_api.dart';

/// XP Service - Awards experience points and handles leveling
class XpService {
  // XP rewards
  static const int xpHabitComplete = 10;
  static const int xpTaskComplete = 15;
  static const int xpPomodoroComplete = 5;
  
  // Level calculation
  static int calculateLevel(int totalXp) => (totalXp / 100).floor() + 1;
  
  /// Award XP to the user profile
  static Future<void> awardXp(int xpAmount, {String? reason}) async {
    try {
      final profileId = GetStorage().read(AppConstants.profileId);
      if (profileId == null) return;
      
      final profile = await UserProfileApi.getProfile(profileId);
      if (profile == null) return;
      
      final newXp = profile.xpPoints + xpAmount;
      final newLevel = calculateLevel(newXp);
      final leveledUp = newLevel > profile.level;
      
      final updatedProfile = profile.copyWith(
        xpPoints: newXp,
        level: newLevel,
      );
      
      await UserProfileApi.updateProfile(updatedProfile);
      
      if (kDebugMode) {
        developer.log(
          'XP awarded: +$xpAmount${reason != null ? " ($reason)" : ""} | Total: $newXp | Level: $newLevel${leveledUp ? " 🎉 LEVEL UP!" : ""}',
          name: 'XpService',
        );
      }
    } catch (e, stack) {
      if (kDebugMode) {
        developer.log(
          'Error awarding XP: $e',
          error: e,
          stackTrace: stack,
          name: 'XpService',
        );
      }
    }
  }
  
  /// Get XP progress to next level (0.0 to 1.0)
  static double getProgressToNextLevel(int currentXp) {
    final currentLevel = calculateLevel(currentXp);
    final xpForCurrentLevel = (currentLevel - 1) * 100;
    final xpForNextLevel = currentLevel * 100;
    final progress = (currentXp - xpForCurrentLevel) / (xpForNextLevel - xpForCurrentLevel);
    return progress.clamp(0.0, 1.0);
  }
  
  /// Get XP needed for next level
  static int getXpToNextLevel(int currentXp) {
    final currentLevel = calculateLevel(currentXp);
    final xpForNextLevel = currentLevel * 100;
    return xpForNextLevel - currentXp;
  }
}
