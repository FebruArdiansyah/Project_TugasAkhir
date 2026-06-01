import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'api_service.dart';

class AuthService {
  static const String _userKey = 'mobile_user';

  static Future<Map<String, dynamic>> login({
    required String login,
    required String password,
    String deviceName = 'flutter-mobile',
  }) async {
    final response = await ApiService.post(
      '/login',
      auth: false,
      body: {
        'login': login,
        'password': password,
        'device_name': deviceName,
      },
    );

    if (response is! Map<String, dynamic>) {
      throw ApiException(message: 'Response login tidak valid.');
    }

    final token = response['token']?.toString();

    if (token == null || token.isEmpty) {
      throw ApiException(message: 'Token login tidak ditemukan.');
    }

    await ApiService.saveToken(token);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _userKey,
      jsonEncode(response['user'] ?? {}),
    );

    return response;
  }

  static Future<void> logout() async {
    try {
      await ApiService.post('/logout');
    } finally {
      await ApiService.clearToken();

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userKey);
    }
  }

  static Future<bool> isLoggedIn() async {
    final token = await ApiService.getToken();
    return token != null && token.isNotEmpty;
  }

  static Future<Map<String, dynamic>?> getSavedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final rawUser = prefs.getString(_userKey);

    if (rawUser == null || rawUser.isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(rawUser);

      if (decoded is Map<String, dynamic>) {
        return decoded;
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<Map<String, dynamic>> getProfile() async {
    final response = await ApiService.get('/profile');

    if (response is! Map<String, dynamic>) {
      throw ApiException(message: 'Response profile tidak valid.');
    }

    return response;
  }
}