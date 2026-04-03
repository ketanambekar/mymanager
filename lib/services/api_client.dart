import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;

class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();
  static const _configuredBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: '');

  static const _accessTokenKey = 'api_access_token';
  static const _refreshTokenKey = 'api_refresh_token';

  final GetStorage _storage = GetStorage();
  String? _sessionAccessToken;
  String? _sessionRefreshToken;
  Future<bool>? _refreshInFlight;

  String get baseUrl {
    if (_configuredBaseUrl.isNotEmpty) return _configuredBaseUrl;
    if (kIsWeb) {
      final host = Uri.base.host.isEmpty ? 'localhost' : Uri.base.host;
      final scheme = Uri.base.scheme == 'https' ? 'https' : 'http';
      return '$scheme://$host:5000/api/v1';
    }
    try {
      if (Platform.isAndroid) return 'http://10.0.2.2:5000/api/v1';
    } catch (_) {
      // Fallback for platforms where dart:io is constrained.
    }
    return 'http://localhost:5000/api/v1';
  }

  String? get accessToken => _sessionAccessToken ?? _storage.read<String>(_accessTokenKey);
  String? get refreshToken => _sessionRefreshToken ?? _storage.read<String>(_refreshTokenKey);

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    bool persist = true,
  }) async {
    if (persist) {
      _sessionAccessToken = null;
      _sessionRefreshToken = null;
      await _storage.write(_accessTokenKey, accessToken);
      await _storage.write(_refreshTokenKey, refreshToken);
      return;
    }

    _sessionAccessToken = accessToken;
    _sessionRefreshToken = refreshToken;
    await _storage.remove(_accessTokenKey);
    await _storage.remove(_refreshTokenKey);
  }

  Future<void> clearTokens() async {
    _sessionAccessToken = null;
    _sessionRefreshToken = null;
    await _storage.remove(_accessTokenKey);
    await _storage.remove(_refreshTokenKey);
  }

  Future<http.Response> get(String path) => _send('GET', path);
  Future<http.Response> post(String path, {Map<String, dynamic>? body}) => _send('POST', path, body: body);
  Future<http.Response> put(String path, {Map<String, dynamic>? body}) => _send('PUT', path, body: body);
  Future<http.Response> patch(String path, {Map<String, dynamic>? body}) => _send('PATCH', path, body: body);
  Future<http.Response> delete(String path) => _send('DELETE', path);

  Future<http.Response> postMultipart(String path, {required String fieldName, required String filePath}) async {
    final uri = Uri.parse('$baseUrl$path');
    final request = http.MultipartRequest('POST', uri);
    final token = accessToken;

    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    request.files.add(await http.MultipartFile.fromPath(fieldName, filePath));
    final streamed = await request.send();
    return http.Response.fromStream(streamed);
  }

  Future<http.Response> _send(String method, String path, {Map<String, dynamic>? body, bool retryOnAuthFail = true}) async {
    final uri = Uri.parse('$baseUrl$path');
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json'
    };

    final token = accessToken;
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    late http.Response response;
    final encoded = body == null ? null : jsonEncode(body);

    switch (method) {
      case 'GET':
        response = await http.get(uri, headers: headers);
        break;
      case 'POST':
        response = await http.post(uri, headers: headers, body: encoded);
        break;
      case 'PUT':
        response = await http.put(uri, headers: headers, body: encoded);
        break;
      case 'PATCH':
        response = await http.patch(uri, headers: headers, body: encoded);
        break;
      case 'DELETE':
        response = await http.delete(uri, headers: headers);
        break;
      default:
        throw UnsupportedError('HTTP method not supported: $method');
    }

    if (response.statusCode == 401 && retryOnAuthFail && (refreshToken ?? '').isNotEmpty) {
      final refreshed = await _refreshAccessToken();
      if (refreshed) {
        return _send(method, path, body: body, retryOnAuthFail: false);
      }
    }

    return response;
  }

  Future<bool> _refreshAccessToken() async {
    final inFlight = _refreshInFlight;
    if (inFlight != null) return inFlight;

    final refreshFuture = _performRefreshAccessToken();
    _refreshInFlight = refreshFuture;

    try {
      return await refreshFuture;
    } finally {
      if (identical(_refreshInFlight, refreshFuture)) {
        _refreshInFlight = null;
      }
    }
  }

  Future<bool> _performRefreshAccessToken() async {
    final token = refreshToken;
    if (token == null || token.isEmpty) return false;

    final response = await http.post(
      Uri.parse('$baseUrl/auth/refresh'),
      headers: const {'Content-Type': 'application/json', 'Accept': 'application/json'},
      body: jsonEncode({'refresh_token': token}),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final payload = data['data'] as Map<String, dynamic>?;
      final newAccess = payload?['access_token']?.toString();
      final newRefresh = payload?['refresh_token']?.toString();
      if ((newAccess ?? '').isNotEmpty && (newRefresh ?? '').isNotEmpty) {
        final persist = _sessionAccessToken == null;
        await saveTokens(accessToken: newAccess!, refreshToken: newRefresh!, persist: persist);
        return true;
      }
    }

    await clearTokens();
    return false;
  }
}
