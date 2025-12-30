import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:mymanager/constants/app_constants.dart';
import 'package:mymanager/database/helper/database_helper.dart';
import 'package:mymanager/database/tables/tasks/models/task_model.dart';
import 'package:mymanager/utils/global_utils.dart';

class TaskApi {
  static String _generateId() => uuid.v4();
  static String _nowIso() => DateTime.now().toLocal().toIso8601String();

  /// Create a new task
  static Future<void> createTask(Task task) async {
    try {
      final db = await DatabaseHelper.database;
      final id = task.taskId.isNotEmpty ? task.taskId : _generateId();
      final now = _nowIso();

      final map = task.toMap();
      map['task_id'] = id;
      map['task_created_at'] = now;
      map['task_updated_at'] = now;

      await db.insert('tasks', map);
      if (kDebugMode) {
        developer.log('Created task: $id', name: 'TaskApi');
      }
    } catch (e, stack) {
      developer.log(
        'Error creating task: $e',
        error: e,
        stackTrace: stack,
        name: 'TaskApi',
      );
      rethrow;
    }
  }

  /// Get all tasks with optional filters
  static Future<List<Task>> getTasks({
    String? projectId,
    String? status,
    String? priority,
    bool includeCompleted = true,
    bool onlyParentTasks = false,
  }) async {
    try {
      final db = await DatabaseHelper.database;
      final whereClauses = <String>[];
      final whereArgs = <dynamic>[];

      if (projectId != null) {
        whereClauses.add('project_id = ?');
        whereArgs.add(projectId);
      }

      if (status != null) {
        whereClauses.add('task_status = ?');
        whereArgs.add(status);
      }

      if (!includeCompleted) {
        whereClauses.add('task_status != ?');
        whereArgs.add(AppConstants.taskStatusCompleted);
      }

      if (priority != null) {
        whereClauses.add('task_priority = ?');
        whereArgs.add(priority);
      }

      if (onlyParentTasks) {
        whereClauses.add('(parent_task_id IS NULL OR parent_task_id = \"\")');
      }

      final maps = await db.query(
        'tasks',
        where: whereClauses.isEmpty ? null : whereClauses.join(' AND '),
        whereArgs: whereArgs.isEmpty ? null : whereArgs,
        orderBy: 'task_order ASC, task_created_at DESC',
      );

      return maps.map((m) => Task.fromMap(m)).toList();
    } catch (e, stack) {
      developer.log(
        'Error getting tasks: $e',
        error: e,
        stackTrace: stack,
        name: 'TaskApi',
      );
      return [];
    }
  }

  /// Get subtasks for a parent task
  static Future<List<Task>> getSubTasks(String parentTaskId) async {
    try {
      final db = await DatabaseHelper.database;
      final maps = await db.query(
        'tasks',
        where: 'parent_task_id = ?',
        whereArgs: [parentTaskId],
        orderBy: 'task_order ASC',
      );
      return maps.map((m) => Task.fromMap(m)).toList();
    } catch (e, stack) {
      developer.log(
        'Error getting subtasks: $e',
        error: e,
        stackTrace: stack,
        name: 'TaskApi',
      );
      return [];
    }
  }

  /// Get tasks by Eisenhower Matrix quadrant
  static Future<List<Task>> getTasksByQuadrant({
    required bool urgent,
    required bool important,
  }) async {
    try {
      final db = await DatabaseHelper.database;
      final urgencyValue = urgent ? 'High' : 'Medium';
      final importanceValue = important ? 'High' : 'Medium';

      final maps = await db.query(
        'tasks',
        where: 'task_urgency = ? AND task_importance = ? AND task_status != ?',
        whereArgs: [urgencyValue, importanceValue, AppConstants.taskStatusCompleted],
        orderBy: 'task_due_date ASC',
      );

      return maps.map((m) => Task.fromMap(m)).toList();
    } catch (e, stack) {
      developer.log(
        'Error getting tasks by quadrant: $e',
        error: e,
        stackTrace: stack,
        name: 'TaskApi',
      );
      return [];
    }
  }

  /// Get task by ID
  static Future<Task?> getTaskById(String taskId) async {
    try {
      final db = await DatabaseHelper.database;
      final maps = await db.query(
        'tasks',
        where: 'task_id = ?',
        whereArgs: [taskId],
        limit: 1,
      );
      if (maps.isEmpty) return null;
      return Task.fromMap(maps.first);
    } catch (e, stack) {
      developer.log(
        'Error getting task by ID: $e',
        error: e,
        stackTrace: stack,
        name: 'TaskApi',
      );
      return null;
    }
  }

  /// Update task
  static Future<int> updateTask(String taskId, Task updated) async {
    try {
      final db = await DatabaseHelper.database;
      final now = _nowIso();

      final map = updated.toMap();
      map['task_updated_at'] = now;
      map.remove('task_id');
      map.remove('task_created_at');

      final count = await db.update(
        'tasks',
        map,
        where: 'task_id = ?',
        whereArgs: [taskId],
      );

      if (kDebugMode) {
        developer.log('Updated task $taskId, rows=$count', name: 'TaskApi');
      }
      return count;
    } catch (e, stack) {
      developer.log(
        'Error updating task: $e',
        error: e,
        stackTrace: stack,
        name: 'TaskApi',
      );
      return 0;
    }
  }

  /// Mark task as completed
  static Future<int> completeTask(String taskId) async {
    try {
      final db = await DatabaseHelper.database;
      final now = _nowIso();

      final count = await db.update(
        'tasks',
        {
          'task_status': AppConstants.taskStatusCompleted,
          'task_completed_date': now,
          'task_updated_at': now,
        },
        where: 'task_id = ?',
        whereArgs: [taskId],
      );

      if (kDebugMode) {
        developer.log('Completed task $taskId', name: 'TaskApi');
      }
      return count;
    } catch (e, stack) {
      developer.log(
        'Error completing task: $e',
        error: e,
        stackTrace: stack,
        name: 'TaskApi',
      );
      return 0;
    }
  }

  /// Delete task
  static Future<int> deleteTask(String taskId) async {
    try {
      final db = await DatabaseHelper.database;
      // Also delete all subtasks
      await db.delete('tasks', where: 'parent_task_id = ?', whereArgs: [taskId]);

      final count = await db.delete('tasks', where: 'task_id = ?', whereArgs: [taskId]);

      if (kDebugMode) {
        developer.log('Deleted task $taskId and its subtasks', name: 'TaskApi');
      }
      return count;
    } catch (e, stack) {
      developer.log(
        'Error deleting task: $e',
        error: e,
        stackTrace: stack,
        name: 'TaskApi',
      );
      return 0;
    }
  }

  /// Get tasks due today
  static Future<List<Task>> getTodayTasks() async {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day).toIso8601String();
      final tomorrow = DateTime(now.year, now.month, now.day + 1).toIso8601String();

      final db = await DatabaseHelper.database;
      final maps = await db.query(
        'tasks',
        where: 'task_due_date >= ? AND task_due_date < ? AND task_status != ?',
        whereArgs: [today, tomorrow, AppConstants.taskStatusCompleted],
        orderBy: 'task_urgency DESC, task_importance DESC',
      );

      return maps.map((m) => Task.fromMap(m)).toList();
    } catch (e, stack) {
      developer.log(
        'Error getting today tasks: $e',
        error: e,
        stackTrace: stack,
        name: 'TaskApi',
      );
      return [];
    }
  }

  /// Get overdue tasks
  static Future<List<Task>> getOverdueTasks() async {
    try {
      final now = DateTime.now().toIso8601String();
      final db = await DatabaseHelper.database;
      final maps = await db.query(
        'tasks',
        where: 'task_due_date < ? AND task_status != ?',
        whereArgs: [now, AppConstants.taskStatusCompleted],
        orderBy: 'task_due_date ASC',
      );

      return maps.map((m) => Task.fromMap(m)).toList();
    } catch (e, stack) {
      developer.log(
        'Error getting overdue tasks: $e',
        error: e,
        stackTrace: stack,
        name: 'TaskApi',
      );
      return [];
    }
  }

  /// Update task time spent
  static Future<int> updateTimeSpent(String taskId, int minutesToAdd) async {
    try {
      final task = await getTaskById(taskId);
      if (task == null) return 0;

      final db = await DatabaseHelper.database;
      final newTimeSpent = task.timeSpent + minutesToAdd;

      final count = await db.update(
        'tasks',
        {'time_spent': newTimeSpent, 'task_updated_at': _nowIso()},
        where: 'task_id = ?',
        whereArgs: [taskId],
      );

      return count;
    } catch (e, stack) {
      developer.log(
        'Error updating time spent: $e',
        error: e,
        stackTrace: stack,
        name: 'TaskApi',
      );
      return 0;
    }
  }
}
