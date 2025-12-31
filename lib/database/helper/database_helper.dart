import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:mymanager/constants/app_constants.dart';
import 'package:mymanager/database/tables/tasks/tasks_table.dart';
import 'package:mymanager/database/tables/user_profile/user_tables.dart';
import 'package:mymanager/database/tables/user_projects/user_projects_table.dart';
import 'package:mymanager/database/tables/notifications/notification_tables.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static Database? _db;

  static Future<Database> get database async {
    if (_db != null) {
      if (kDebugMode) {
        developer.log('Database already initialized ✅', name: 'DatabaseHelper');
      }
      return _db!;
    }

    _db = await _initDB();
    return _db!;
  }

  static Future<Database> _initDB() async {
    final path = join(await getDatabasesPath(), AppConstants.dbName);
    if (kDebugMode) {
      developer.log('Database path: $path', name: 'DatabaseHelper');
    }
    final db = await openDatabase(
      path,
      version: 3,
      onCreate: (db, version) async {
        if (kDebugMode) {
          developer.log('Creating tables...', name: 'DatabaseHelper');
        }
        await db.execute(UserTables.userProfile);
        await db.execute(UserProjectsTables.userProjects);
        await db.execute(TasksTables.tasks);
        await db.execute(TasksTables.taskHistory);
        await db.execute(TasksTables.habits);
        await db.execute(TasksTables.habitLogs);
        await db.execute(NotificationTables.notifications);

        if (kDebugMode) {
          developer.log('All tables created ✅', name: 'DatabaseHelper');
        }
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(TasksTables.tasks);
          await db.execute(TasksTables.taskHistory);
          await db.execute(TasksTables.habits);
          await db.execute(TasksTables.habitLogs);
          if (kDebugMode) {
            developer.log('Database upgraded to v2 ✅', name: 'DatabaseHelper');
          }
        }
        if (oldVersion < 3) {
          await db.execute(NotificationTables.notifications);
          if (kDebugMode) {
            developer.log('Database upgraded to v3 (notifications) ✅', name: 'DatabaseHelper');
          }
        }
      },
    );
    if (kDebugMode) {
      developer.log('Database opened successfully ✅', name: 'DatabaseHelper');
    }
    return db;
  }

  static Future<void> close() async {
    if (_db != null) {
      await _db!.close();
      _db = null;
      if (kDebugMode) developer.log('Database closed', name: 'DatabaseHelper');
    }
  }
}
