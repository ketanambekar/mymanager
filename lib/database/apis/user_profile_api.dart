import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:mymanager/database/helper/database_helper.dart';
import 'package:mymanager/database/tables/user_profile/models/user_profile_model.dart';
import 'package:mymanager/utils/global_utils.dart';
import 'package:uuid/uuid.dart';

class UserProfileApi {
  static Future<UserProfile?> getProfile(String profileId) async {
    try {
      final db = await DatabaseHelper.database;
      final maps = await db.query(
        'user_profile',
        where: 'profileId = ?',
        whereArgs: [profileId],
        limit: 1,
      );
      if (maps.isEmpty) return null;
      if (kDebugMode) {
        developer.log(
          'getProfile: found ${maps.length} rows',
          name: 'UserProfileApi',
        );
      }
      return UserProfile.fromMap(maps.first);
    } catch (e, stack) {
      developer.log(
        'Error in getProfile: $e',
        stackTrace: stack,
        name: 'UserProfileApi',
      );
      rethrow;
    }
  }

  static Future<List<UserProfile>> getAllProfiles() async {
    try {
      final db = await DatabaseHelper.database;
      final maps = await db.query('user_profile', orderBy: 'created_at DESC');
      return maps.map((m) => UserProfile.fromMap(m)).toList();
    } catch (e, stack) {
      developer.log(
        'Error in getAllProfiles: $e',
        stackTrace: stack,
        name: 'UserProfileApi',
      );
      return [];
    }
  }

  static Future<void> createProfile(UserProfile profile) async {
    try {
      final db = await DatabaseHelper.database;
      final id = (profile.profileId.isNotEmpty) ? profile.profileId : uuid.v4();

      final map = <String, dynamic>{
        'profileId': id,
        'name': profile.name,
        'appVersion': profile.appVersion,
      };

      await db.insert('user_profile', map);
      if (kDebugMode) {
        developer.log('Inserted profile $id', name: 'UserProfileApi');
      }
    } catch (e, stack) {
      developer.log(
        'Error in createProfile: $e',
        stackTrace: stack,
        name: 'UserProfileApi',
      );
      rethrow;
    }
  }

  static Future<int> updateProfile(UserProfile profile) async {
    try {
      final db = await DatabaseHelper.database;
      final now = DateTime.now().toLocal().toIso8601String();
      final map = {
        'name': profile.name,
        'appVersion': profile.appVersion,
        'updated_at': now,
      };

      final count = await db.update(
        'user_profile',
        map,
        where: 'profileId = ?',
        whereArgs: [profile.profileId],
      );

      if (kDebugMode) {
        developer.log(
          'Updated profile ${profile.profileId}, rows=$count',
          name: 'UserProfileApi',
        );
      }
      return count;
    } catch (e, stack) {
      developer.log(
        'Error in updateProfile: $e',
        stackTrace: stack,
        name: 'UserProfileApi',
      );
      return 0;
    }
  }

  static Future<int> deleteProfile(String profileId) async {
    try {
      final db = await DatabaseHelper.database;
      final count = await db.delete(
        'user_profile',
        where: 'profileId = ?',
        whereArgs: [profileId],
      );
      if (kDebugMode) {
        developer.log(
          'Deleted profile $profileId, rows=$count',
          name: 'UserProfileApi',
        );
      }
      return count;
    } catch (e, stack) {
      developer.log(
        'Error in deleteProfile: $e',
        stackTrace: stack,
        name: 'UserProfileApi',
      );
      return 0;
    }
  }
}
