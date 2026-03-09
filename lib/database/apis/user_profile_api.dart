import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:get_storage/get_storage.dart';
import 'package:mymanager/database/tables/user_profile/models/user_profile_model.dart';
import 'package:mymanager/services/api_client.dart';

class UserProfileApi {
  static final ApiClient _client = ApiClient.instance;
  static final GetStorage _storage = GetStorage();

  static String _profileKey(String id) => 'profile_meta_$id';

  static Future<UserProfile?> getProfile(String profileId) async {
    try {
      final resp = await _client.get('/auth/me');
      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        final body = jsonDecode(resp.body) as Map<String, dynamic>;
        final data = body['data'] as Map<String, dynamic>?;
        if (data != null) {
          final metadata = (_storage.read<Map>(_profileKey(data['id'].toString())) ?? {}).cast<String, dynamic>();
          final createdAt = data['created_at']?.toString();
          final lastActive = data['last_active_at']?.toString();
          return UserProfile.fromMap({
            'profileId': data['id'].toString(),
            'name': data['name'],
            'appVersion': metadata['appVersion'],
            'xp_points': metadata['xp_points'] ?? 0,
            'level': metadata['level'] ?? 1,
            'created_at': (createdAt ?? '').isNotEmpty
                ? createdAt
                : (metadata['created_at'] ?? DateTime.now().toIso8601String()),
            'updated_at': (lastActive ?? '').isNotEmpty
                ? lastActive
                : (metadata['updated_at'] ?? DateTime.now().toIso8601String())
          });
        }
      }

      final local = (_storage.read<Map>(_profileKey(profileId)) ?? {}).cast<String, dynamic>();
      if (local.isEmpty) return null;
      return UserProfile.fromMap(local);
    } catch (e, stack) {
      if (kDebugMode) {
        developer.log('Error in getProfile: $e', stackTrace: stack, name: 'UserProfileApi');
      }
      return null;
    }
  }

  static Future<List<UserProfile>> getAllProfiles() async {
    final me = await _client.get('/auth/me');
    if (me.statusCode < 200 || me.statusCode >= 300) return [];
    final body = jsonDecode(me.body) as Map<String, dynamic>;
    final data = body['data'] as Map<String, dynamic>?;
    if (data == null) return [];
    final profile = await getProfile(data['id'].toString());
    return profile == null ? [] : [profile];
  }

  static Future<void> createProfile(UserProfile profile) async {
    final now = DateTime.now().toIso8601String();
    await _storage.write(_profileKey(profile.profileId), {
      'profileId': profile.profileId,
      'name': profile.name,
      'appVersion': profile.appVersion,
      'xp_points': profile.xpPoints,
      'level': profile.level,
      'created_at': profile.createdAt ?? now,
      'updated_at': profile.updatedAt ?? now
    });
  }

  static Future<int> updateProfile(UserProfile profile) async {
    final current = (_storage.read<Map>(_profileKey(profile.profileId)) ?? {}).cast<String, dynamic>();
    final merged = {
      ...current,
      ...profile.toMap(),
      'updated_at': DateTime.now().toIso8601String()
    };
    await _storage.write(_profileKey(profile.profileId), merged);
    return 1;
  }

  static Future<int> deleteProfile(String profileId) async {
    await _storage.remove(_profileKey(profileId));
    return 1;
  }
}
