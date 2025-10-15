import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:mymanager/database/constants/db_constants.dart';
import 'package:mymanager/database/tables/user_profile/user_tables.dart';
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
    final path = join(await getDatabasesPath(), DBConstants.dbName);
    if (kDebugMode) {
      developer.log('Database path: $path', name: 'DatabaseHelper');
    }
    final db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        if (kDebugMode) {
          developer.log('Creating tables...', name: 'DatabaseHelper');
        }
        await db.execute(UserTables.userProfile);
        if (kDebugMode) {
          developer.log('Table user_profile created ✅', name: 'DatabaseHelper');
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
