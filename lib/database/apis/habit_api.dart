import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:mymanager/database/helper/database_helper.dart';
import 'package:mymanager/database/tables/tasks/models/habit_model.dart';
import 'package:mymanager/utils/global_utils.dart';

class HabitApi {
  static String _generateId() => uuid.v4();
  static String _nowIso() => DateTime.now().toLocal().toIso8601String();

  /// Create a new habit
  static Future<void> createHabit(Habit habit) async {
    try {
      final db = await DatabaseHelper.database;
      final id = habit.habitId.isNotEmpty ? habit.habitId : _generateId();
      final now = _nowIso();

      final map = habit.toMap();
      map['habit_id'] = id;
      map['habit_created_at'] = now;
      map['habit_updated_at'] = now;

      await db.insert('habits', map);
      if (kDebugMode) {
        developer.log('Created habit: $id', name: 'HabitApi');
      }
    } catch (e, stack) {
      developer.log(
        'Error creating habit: $e',
        error: e,
        stackTrace: stack,
        name: 'HabitApi',
      );
      rethrow;
    }
  }

  /// Get all habits
  static Future<List<Habit>> getHabits() async {
    try {
      final db = await DatabaseHelper.database;
      final maps = await db.query('habits', orderBy: 'habit_created_at DESC');
      return maps.map((m) => Habit.fromMap(m)).toList();
    } catch (e, stack) {
      developer.log(
        'Error getting habits: $e',
        error: e,
        stackTrace: stack,
        name: 'HabitApi',
      );
      return [];
    }
  }

  /// Get habit by ID
  static Future<Habit?> getHabitById(String habitId) async {
    try {
      final db = await DatabaseHelper.database;
      final maps = await db.query(
        'habits',
        where: 'habit_id = ?',
        whereArgs: [habitId],
        limit: 1,
      );
      if (maps.isEmpty) return null;
      return Habit.fromMap(maps.first);
    } catch (e, stack) {
      developer.log(
        'Error getting habit by ID: $e',
        error: e,
        stackTrace: stack,
        name: 'HabitApi',
      );
      return null;
    }
  }

  /// Update habit
  static Future<int> updateHabit(String habitId, Habit updated) async {
    try {
      final db = await DatabaseHelper.database;
      final map = updated.toMap();
      map['habit_updated_at'] = _nowIso();
      map.remove('habit_id');
      map.remove('habit_created_at');

      final count = await db.update(
        'habits',
        map,
        where: 'habit_id = ?',
        whereArgs: [habitId],
      );

      if (kDebugMode) {
        developer.log('Updated habit $habitId', name: 'HabitApi');
      }
      return count;
    } catch (e, stack) {
      developer.log(
        'Error updating habit: $e',
        error: e,
        stackTrace: stack,
        name: 'HabitApi',
      );
      return 0;
    }
  }

  /// Complete habit for today
  static Future<void> completeHabit(String habitId, {String? notes}) async {
    try {
      final db = await DatabaseHelper.database;
      final now = _nowIso();
      final habit = await getHabitById(habitId);
      if (habit == null) return;

      // Log completion
      await db.insert('habit_logs', {
        'log_id': _generateId(),
        'habit_id': habitId,
        'completed_date': now,
        'notes': notes,
      });

      // Update streak
      int newStreak = habit.currentStreak + 1;
      int newBest = newStreak > habit.bestStreak ? newStreak : habit.bestStreak;

      await db.update(
        'habits',
        {
          'current_streak': newStreak,
          'best_streak': newBest,
          'last_completed': now,
          'habit_updated_at': now,
        },
        where: 'habit_id = ?',
        whereArgs: [habitId],
      );

      if (kDebugMode) {
        developer.log('Completed habit $habitId, streak: $newStreak', name: 'HabitApi');
      }
    } catch (e, stack) {
      developer.log(
        'Error completing habit: $e',
        error: e,
        stackTrace: stack,
        name: 'HabitApi',
      );
      rethrow;
    }
  }

  /// Delete habit
  static Future<int> deleteHabit(String habitId) async {
    try {
      final db = await DatabaseHelper.database;
      await db.delete('habit_logs', where: 'habit_id = ?', whereArgs: [habitId]);
      final count = await db.delete('habits', where: 'habit_id = ?', whereArgs: [habitId]);

      if (kDebugMode) {
        developer.log('Deleted habit $habitId', name: 'HabitApi');
      }
      return count;
    } catch (e, stack) {
      developer.log(
        'Error deleting habit: $e',
        error: e,
        stackTrace: stack,
        name: 'HabitApi',
      );
      return 0;
    }
  }

  /// Get habit logs
  static Future<List<Map<String, dynamic>>> getHabitLogs(String habitId, {int days = 30}) async {
    try {
      final db = await DatabaseHelper.database;
      final cutoffDate = DateTime.now().subtract(Duration(days: days)).toIso8601String();

      final maps = await db.query(
        'habit_logs',
        where: 'habit_id = ? AND completed_date >= ?',
        whereArgs: [habitId, cutoffDate],
        orderBy: 'completed_date DESC',
      );

      return maps;
    } catch (e, stack) {
      developer.log(
        'Error getting habit logs: $e',
        error: e,
        stackTrace: stack,
        name: 'HabitApi',
      );
      return [];
    }
  }
}
