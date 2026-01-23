import 'package:flutter_test/flutter_test.dart';
import 'package:mymanager/services/xp_service.dart';

void main() {
  group('XP Service Tests', () {
    test('Calculate level correctly', () {
      expect(XpService.calculateLevel(0), 1);
      expect(XpService.calculateLevel(50), 1);
      expect(XpService.calculateLevel(100), 2);
      expect(XpService.calculateLevel(150), 2);
      expect(XpService.calculateLevel(200), 3);
      expect(XpService.calculateLevel(450), 5);
      expect(XpService.calculateLevel(999), 10);
    });

    test('Calculate XP to next level correctly', () {
      expect(XpService.getXpToNextLevel(0), 100);
      expect(XpService.getXpToNextLevel(50), 50);
      expect(XpService.getXpToNextLevel(100), 100);
      expect(XpService.getXpToNextLevel(150), 50);
      expect(XpService.getXpToNextLevel(450), 50);
    });

    test('Calculate progress to next level correctly', () {
      expect(XpService.getProgressToNextLevel(0), 0.0);
      expect(XpService.getProgressToNextLevel(50), 0.5);
      expect(XpService.getProgressToNextLevel(100), 0.0);
      expect(XpService.getProgressToNextLevel(150), 0.5);
      expect(XpService.getProgressToNextLevel(175), 0.75);
      expect(XpService.getProgressToNextLevel(199), 0.99);
      expect(XpService.getProgressToNextLevel(200), 0.0);
    });

    test('XP rewards are consistent', () {
      expect(XpService.xpHabitComplete, 10);
      expect(XpService.xpTaskComplete, 15);
      expect(XpService.xpPomodoroComplete, 5);
    });

    test('Progress is clamped between 0 and 1', () {
      final progress1 = XpService.getProgressToNextLevel(0);
      final progress2 = XpService.getProgressToNextLevel(99);
      final progress3 = XpService.getProgressToNextLevel(100);
      
      expect(progress1 >= 0.0 && progress1 <= 1.0, true);
      expect(progress2 >= 0.0 && progress2 <= 1.0, true);
      expect(progress3 >= 0.0 && progress3 <= 1.0, true);
    });
  });

  group('XP Level Progression Tests', () {
    test('Leveling up requires exactly 100 XP per level', () {
      for (int level = 1; level <= 10; level++) {
        final minXp = (level - 1) * 100;
        final maxXp = level * 100 - 1;
        
        expect(XpService.calculateLevel(minXp), level);
        expect(XpService.calculateLevel(maxXp), level);
      }
    });

    test('Level increases at correct thresholds', () {
      expect(XpService.calculateLevel(99), 1);
      expect(XpService.calculateLevel(100), 2);
      expect(XpService.calculateLevel(199), 2);
      expect(XpService.calculateLevel(200), 3);
      expect(XpService.calculateLevel(299), 3);
      expect(XpService.calculateLevel(300), 4);
    });
  });

  group('XP Rewards Simulation Tests', () {
    test('Completing 10 habits equals level 2', () {
      final totalXp = XpService.xpHabitComplete * 10;
      expect(totalXp, 100);
      expect(XpService.calculateLevel(totalXp), 2);
    });

    test('Completing 7 tasks (rounded) equals level 2', () {
      final totalXp = XpService.xpTaskComplete * 7;
      expect(totalXp, 105);
      expect(XpService.calculateLevel(totalXp), 2);
    });

    test('Completing 20 pomodoros equals level 2', () {
      final totalXp = XpService.xpPomodoroComplete * 20;
      expect(totalXp, 100);
      expect(XpService.calculateLevel(totalXp), 2);
    });

    test('Mixed activities XP calculation', () {
      int totalXp = 0;
      
      // Day 1: 1 habit, 2 tasks, 4 pomodoros
      totalXp += XpService.xpHabitComplete;
      totalXp += XpService.xpTaskComplete * 2;
      totalXp += XpService.xpPomodoroComplete * 4;
      expect(totalXp, 60); // 10 + 30 + 20 = 60
      
      // Day 2: 1 habit, 1 task, 2 pomodoros
      totalXp += XpService.xpHabitComplete;
      totalXp += XpService.xpTaskComplete;
      totalXp += XpService.xpPomodoroComplete * 2;
      expect(totalXp, 95); // Previous 60 + 35 = 95
      
      expect(XpService.calculateLevel(totalXp), 1);
      
      // Day 3: 1 habit (push to level 2)
      totalXp += XpService.xpHabitComplete;
      expect(totalXp, 105);
      expect(XpService.calculateLevel(totalXp), 2);
    });
  });
}
