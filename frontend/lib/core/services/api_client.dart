import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

import '../utils/api_constants.dart';
import '../utils/secure_token_storage.dart';

/// ApiClient — HTTP client with automatic token refresh and 401 handling.
/// Use this instead of raw http.get/post throughout the app.
class ApiClient {
  static String get _base => ApiConstants.baseUrl;

  // ─── Authenticated GET ────────────────────────────────────────────────────

  static Future<http.Response> get(String path) async {
    return _withRetry(() async {
      final token = await SecureTokenStorage.getAccessToken();
      return http.get(
        Uri.parse('$_base$path'),
        headers: _headers(token),
      );
    });
  }

  // ─── Authenticated POST ───────────────────────────────────────────────────

  static Future<http.Response> post(String path, Map<String, dynamic> body) async {
    return _withRetry(() async {
      final token = await SecureTokenStorage.getAccessToken();
      return http.post(
        Uri.parse('$_base$path'),
        headers: _headers(token),
        body: jsonEncode(body),
      );
    });
  }

  // ─── Authenticated PUT ────────────────────────────────────────────────────

  static Future<http.Response> put(String path, Map<String, dynamic> body) async {
    return _withRetry(() async {
      final token = await SecureTokenStorage.getAccessToken();
      return http.put(
        Uri.parse('$_base$path'),
        headers: _headers(token),
        body: jsonEncode(body),
      );
    });
  }

  // ─── Authenticated DELETE ─────────────────────────────────────────────────

  static Future<http.Response> delete(String path) async {
    return _withRetry(() async {
      final token = await SecureTokenStorage.getAccessToken();
      return http.delete(
        Uri.parse('$_base$path'),
        headers: _headers(token),
      );
    });
  }

  // ─── Multipart (file upload) ──────────────────────────────────────────────

  static Future<http.Response> multipart({
    required String path,
    required String method,
    required Map<String, String> fields,
    List<http.MultipartFile> files = const [],
  }) async {
    final token = await SecureTokenStorage.getAccessToken();
    final uri = Uri.parse('$_base$path');
    final request = http.MultipartRequest(method, uri);
    request.headers['Authorization'] = 'Bearer ${token ?? ""}';
    request.fields.addAll(fields);
    request.files.addAll(files);
    final streamed = await request.send();
    return http.Response.fromStream(streamed);
  }

  // ─── Unauthenticated POST (for login/OTP) ────────────────────────────────

  static Future<http.Response> publicPost(
    String path,
    Map<String, dynamic> body,
  ) async {
    return http.post(
      Uri.parse('$_base$path'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
  }

  // ─── Internal: retry once after refreshing token on 401 ──────────────────

  static Future<http.Response> _withRetry(
    Future<http.Response> Function() call,
  ) async {
    final response = await call();

    if (response.statusCode == 401) {
      // Try to refresh the access token
      final refreshed = await _tryRefreshToken();
      if (refreshed) {
        // Retry original call with new token
        return await call();
      } else {
        // Refresh failed — user must log in again
        await _handleSessionExpired();
        return response; // Return original 401 so caller can handle
      }
    }

    return response;
  }

  static bool _isRefreshing = false;

  static Future<bool> _tryRefreshToken() async {
    if (_isRefreshing) return false;
    _isRefreshing = true;

    try {
      final refreshToken = await SecureTokenStorage.getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) return false;

      final response = await http.post(
        Uri.parse('$_base/api/auth/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh_token': refreshToken}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await SecureTokenStorage.saveAuthData(
          accessToken: data['token'],
          refreshToken: data['refresh_token'],
          role: await SecureTokenStorage.getRole() ?? '',
        );
        return true;
      }
      return false;
    } catch (_) {
      return false;
    } finally {
      _isRefreshing = false;
    }
  }

  static Future<void> _handleSessionExpired() async {
    await SecureTokenStorage.clear();
    // Signal app to navigate to login — using a global flag
    SessionEvents.notifyExpired();
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────

  static Map<String, String> _headers(String? token) => {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };
}

/// SessionEvents — simple notifier that fires when the session expires.
/// Listen to this in your app root widget to redirect to login.
class SessionEvents {
  static final List<void Function()> _listeners = [];

  static void addListener(void Function() listener) {
    _listeners.add(listener);
  }

  static void removeListener(void Function() listener) {
    _listeners.remove(listener);
  }

  static void notifyExpired() {
    for (final l in _listeners) {
      l();
    }
  }
}
