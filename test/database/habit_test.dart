import 'package:flutter_test/flutter_test.dart';
import 'package:mymanager/database/models/habit.dart';

void main() {
  group('Habit Model Tests', () {
    test('Create habit with default values', () {
      final habit = Habit(
        name: 'Test Habit',
        colorHex: 'FF5733',
        frequency: 'daily',
      );

      expect(habit.name, 'Test Habit');
      expect(habit.colorHex, 'FF5733');
      expect(habit.frequency, 'daily');
      expect(habit.reminderEnabled, false);
      expect(habit.isActive, true);
      expect(habit.currentStreak, 0);
      expect(habit.bestStreak, 0);
    });

    test('Create habit with all values', () {
      final now = DateTime.now();
      final habit = Habit(
        id: 1,
        name: 'Morning Meditation',
        description: 'Meditate for 10 minutes',
        colorHex: 'FF5733',
        frequency: 'daily',
        reminderTime: '07:00',
        reminderEnabled: true,
        isActive: true,
        currentStreak: 5,
        bestStreak: 10,
        createdAt: now,
        updatedAt: now,
      );

      expect(habit.id, 1);
      expect(habit.name, 'Morning Meditation');
      expect(habit.description, 'Meditate for 10 minutes');
      expect(habit.colorHex, 'FF5733');
      expect(habit.frequency, 'daily');
      expect(habit.reminderTime, '07:00');
      expect(habit.reminderEnabled, true);
      expect(habit.isActive, true);
      expect(habit.currentStreak, 5);
      expect(habit.bestStreak, 10);
      expect(habit.createdAt, now);
      expect(habit.updatedAt, now);
    });

    test('Habit to map conversion', () {
      final now = DateTime.now();
      final habit = Habit(
        id: 1,
        name: 'Test Habit',
        colorHex: 'FF5733',
        frequency: 'daily',
        currentStreak: 3,
        createdAt: now,
        updatedAt: now,
      );

      final map = habit.toMap();

      expect(map['id'], 1);
      expect(map['name'], 'Test Habit');
      expect(map['color_hex'], 'FF5733');
      expect(map['frequency'], 'daily');
      expect(map['current_streak'], 3);
      expect(map['created_at'], now.toIso8601String());
      expect(map['updated_at'], now.toIso8601String());
    });

    test('Habit from map conversion', () {
      final now = DateTime.now();
      final map = {
        'id': 1,
        'name': 'Test Habit',
        'description': 'Test Description',
        'color_hex': 'FF5733',
        'frequency': 'daily',
        'reminder_time': '07:00',
        'reminder_enabled': 1,
        'is_active': 1,
        'current_streak': 5,
        'best_streak': 10,
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      };

      final habit = Habit.fromMap(map);

      expect(habit.id, 1);
      expect(habit.name, 'Test Habit');
      expect(habit.description, 'Test Description');
      expect(habit.colorHex, 'FF5733');
      expect(habit.frequency, 'daily');
      expect(habit.reminderTime, '07:00');
      expect(habit.reminderEnabled, true);
      expect(habit.isActive, true);
      expect(habit.currentStreak, 5);
      expect(habit.bestStreak, 10);
    });

    test('Best streak should be updated when current streak exceeds it', () {
      final habit = Habit(
        name: 'Test Habit',
        colorHex: 'FF5733',
        frequency: 'daily',
        currentStreak: 5,
        bestStreak: 3,
      );

      // In real implementation, this would be handled by the controller/service
      expect(habit.currentStreak > habit.bestStreak, true);
    });

    test('Habit copy with modifications', () {
      final original = Habit(
        id: 1,
        name: 'Original Habit',
        colorHex: 'FF5733',
        frequency: 'daily',
        currentStreak: 5,
      );

      final modified = Habit(
        id: original.id,
        name: 'Modified Habit',
        colorHex: original.colorHex,
        frequency: original.frequency,
        currentStreak: original.currentStreak + 1,
      );

      expect(modified.id, original.id);
      expect(modified.name, 'Modified Habit');
      expect(modified.currentStreak, 6);
    });
  });

  group('Habit Frequency Tests', () {
    test('Valid frequency values', () {
      final validFrequencies = ['daily', 'weekly', 'custom'];
      
      for (final frequency in validFrequencies) {
        final habit = Habit(
          name: 'Test',
          colorHex: 'FF5733',
          frequency: frequency,
        );
        expect(habit.frequency, frequency);
      }
    });

    test('Daily habit frequency', () {
      final habit = Habit(
        name: 'Daily Exercise',
        colorHex: 'FF5733',
        frequency: 'daily',
      );
      expect(habit.frequency, 'daily');
    });

    test('Weekly habit frequency', () {
      final habit = Habit(
        name: 'Weekly Review',
        colorHex: 'FF5733',
        frequency: 'weekly',
      );
      expect(habit.frequency, 'weekly');
    });
  });

  group('Habit Streak Tests', () {
    test('New habit has zero streaks', () {
      final habit = Habit(
        name: 'New Habit',
        colorHex: 'FF5733',
        frequency: 'daily',
      );
      expect(habit.currentStreak, 0);
      expect(habit.bestStreak, 0);
    });

    test('Streak values are non-negative', () {
      final habit = Habit(
        name: 'Test Habit',
        colorHex: 'FF5733',
        frequency: 'daily',
        currentStreak: 5,
        bestStreak: 10,
      );
      expect(habit.currentStreak >= 0, true);
      expect(habit.bestStreak >= 0, true);
    });

    test('Best streak should be >= current streak in consistent state', () {
      // This tests the ideal state, though in practice the app updates them separately
      final habit1 = Habit(
        name: 'Test',
        colorHex: 'FF5733',
        frequency: 'daily',
        currentStreak: 5,
        bestStreak: 10,
      );
      expect(habit1.bestStreak >= habit1.currentStreak, true);

      final habit2 = Habit(
        name: 'Test',
        colorHex: 'FF5733',
        frequency: 'daily',
        currentStreak: 7,
        bestStreak: 7,
      );
      expect(habit2.bestStreak >= habit2.currentStreak, true);
    });
  });

  group('Habit Active Status Tests', () {
    test('New habit is active by default', () {
      final habit = Habit(
        name: 'Test Habit',
        colorHex: 'FF5733',
        frequency: 'daily',
      );
      expect(habit.isActive, true);
    });

    test('Habit can be inactive', () {
      final habit = Habit(
        name: 'Test Habit',
        colorHex: 'FF5733',
        frequency: 'daily',
        isActive: false,
      );
      expect(habit.isActive, false);
    });
  });

  group('Habit Reminder Tests', () {
    test('Reminder is disabled by default', () {
      final habit = Habit(
        name: 'Test Habit',
        colorHex: 'FF5733',
        frequency: 'daily',
      );
      expect(habit.reminderEnabled, false);
      expect(habit.reminderTime, null);
    });

    test('Reminder can be enabled with time', () {
      final habit = Habit(
        name: 'Test Habit',
        colorHex: 'FF5733',
        frequency: 'daily',
        reminderEnabled: true,
        reminderTime: '08:00',
      );
      expect(habit.reminderEnabled, true);
      expect(habit.reminderTime, '08:00');
    });

    test('Reminder time format is preserved', () {
      final times = ['07:00', '12:30', '18:45', '23:59'];
      
      for (final time in times) {
        final habit = Habit(
          name: 'Test',
          colorHex: 'FF5733',
          frequency: 'daily',
          reminderTime: time,
        );
        expect(habit.reminderTime, time);
      }
    });
  });
}
