import 'dart:convert';

import 'package:get_storage/get_storage.dart';
import 'package:mymanager/constants/app_constants.dart';
import 'package:mymanager/services/api_client.dart';

class BackendAuthService {
  static final _client = ApiClient.instance;
  static final _storage = GetStorage();

  static Future<bool> hasValidSession() async {
    final keepLoggedIn = _storage.read<bool>(AppConstants.keepMeLoggedInKey) ?? true;
    if (!keepLoggedIn) {
      await _client.clearTokens();
      return false;
    }

    if ((_client.accessToken ?? '').isEmpty) return false;
    return _syncProfileFromMe();
  }

  static Future<Map<String, dynamic>> requestEmailOtp({required String email, String? name}) async {
    final response = await _client.post('/auth/email-otp/request', body: {
      'email': email,
      if ((name ?? '').trim().isNotEmpty) 'name': name!.trim()
    });

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(body['message']?.toString() ?? 'Failed to request OTP');
    }

    return (body['data'] as Map<String, dynamic>? ?? <String, dynamic>{});
  }

  static Future<void> verifyEmailOtp({
    required String email,
    required String otp,
    String? name,
    bool keepMeLoggedIn = true,
  }) async {
    final response = await _client.post('/auth/email-otp/verify', body: {
      'email': email,
      'otp': otp,
      if ((name ?? '').trim().isNotEmpty) 'name': name!.trim()
    });

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(body['message']?.toString() ?? 'OTP verification failed');
    }

    final data = body['data'] as Map<String, dynamic>?;
    final access = data?['access_token']?.toString();
    final refresh = data?['refresh_token']?.toString();
    if ((access ?? '').isEmpty || (refresh ?? '').isEmpty) {
      throw Exception('Session token missing from verify response');
    }

    await _client.saveTokens(
      accessToken: access!,
      refreshToken: refresh!,
      persist: keepMeLoggedIn,
    );
    await _storage.write(AppConstants.keepMeLoggedInKey, keepMeLoggedIn);

    final user = data?['user'] as Map<String, dynamic>?;
    final userId = user?['id']?.toString();
    if ((userId ?? '').isNotEmpty) {
      await _storage.write(AppConstants.profileId, userId);
    } else {
      await _syncProfileFromMe();
    }
  }

  static Future<void> logout() async {
    try {
      await _client.post('/auth/logout');
    } catch (_) {
      // Local cleanup still guarantees client-side logout.
    }
    await _client.clearTokens();
    await _storage.remove(AppConstants.profileId);
  }

  static Future<bool> _syncProfileFromMe() async {
    final meResp = await _client.get('/auth/me');
    if (meResp.statusCode < 200 || meResp.statusCode >= 300) {
      return false;
    }

    final body = jsonDecode(meResp.body) as Map<String, dynamic>;
    final data = body['data'] as Map<String, dynamic>?;
    final id = data?['id']?.toString();
    if ((id ?? '').isEmpty) {
      return false;
    }

    await _storage.write(AppConstants.profileId, id);
    return true;
  }
}
