import 'dart:convert';
import 'package:http/http.dart' as http;

import '../utils/api_constants.dart';
import '../utils/secure_token_storage.dart';
import 'api_client.dart';

class AuthService {

  // ─── Send OTP ─────────────────────────────────────────────────────────────

  static Future<bool> sendOtp(
    String phone,
    String captchaId,
    String captchaValue, {
    String? role,
  }) async {
    final response = await http.post(
      Uri.parse("${ApiConstants.baseUrl}/api/auth/citizen/send-otp"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "phone_number": phone,
        "captcha_id": captchaId,
        "captcha_value": captchaValue,
        if (role != null) "role": role,
      }),
    );

    if (response.statusCode == 429) {
      final body = jsonDecode(response.body);
      throw Exception(body['error'] ?? "Too many requests. Try again later.");
    }

    if (response.statusCode != 200) {
      final body = jsonDecode(response.body);
      throw Exception(body['error'] ?? "Failed to send OTP");
    }

    final data = jsonDecode(response.body);
    return data['is_officer'] ?? false;
  }

  // ─── Get Captcha ──────────────────────────────────────────────────────────

  static Future<Map<String, String>> getCaptcha() async {
    final response = await http.get(
      Uri.parse("${ApiConstants.baseUrl}/api/auth/citizen/captcha"),
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to load captcha");
    }

    final data = jsonDecode(response.body);
    return {"captchaID": data["captcha_id"]};
  }

  // ─── Verify OTP & Login ───────────────────────────────────────────────────

  static Future<Map<String, dynamic>> verifyOtp(
    String phone,
    String otp, {
    String role = "CITIZEN",
  }) async {
    final response = await http.post(
      Uri.parse("${ApiConstants.baseUrl}/api/auth/citizen/verify-otp"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "phone_number": phone,
        "code": otp,
        "role": role,
      }),
    );

    if (response.statusCode == 429) {
      final body = jsonDecode(response.body);
      throw Exception(body['error'] ?? "Account locked. Try again later.");
    }

    if (response.statusCode != 200) {
      final body = jsonDecode(response.body);
      throw Exception(body['error'] ?? "Invalid OTP");
    }

    final data = jsonDecode(response.body);

    // Store tokens securely after successful login
    await SecureTokenStorage.saveAuthData(
      accessToken: data['token'],
      refreshToken: data['refresh_token'] ?? '',
      role: data['role'] ?? role,
    );

    return data;
  }

  // ─── Refresh Access Token ─────────────────────────────────────────────────

  static Future<bool> refreshToken() async {
    final refreshToken = await SecureTokenStorage.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) return false;

    final response = await http.post(
      Uri.parse("${ApiConstants.baseUrl}/api/auth/refresh"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"refresh_token": refreshToken}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      await SecureTokenStorage.saveAuthData(
        accessToken: data['token'],
        refreshToken: data['refresh_token'] ?? '',
        role: await SecureTokenStorage.getRole() ?? '',
      );
      return true;
    }

    return false;
  }

  // ─── Logout ───────────────────────────────────────────────────────────────

  static Future<void> logout() async {
    final refreshToken = await SecureTokenStorage.getRefreshToken();

    try {
      // Tell server to blacklist both tokens
      await ApiClient.post('/api/auth/logout', {
        if (refreshToken != null) 'refresh_token': refreshToken,
      });
    } catch (_) {
      // Swallow errors — always clear local storage
    }

    await SecureTokenStorage.clear();
  }

  // ─── Get Citizen Home (legacy helper) ─────────────────────────────────────

  static Future<Map<String, dynamic>> getCitizenHome(String token) async {
    final res = await http.get(
      Uri.parse("${ApiConstants.baseUrl}/api/citizen/home"),
      headers: {
        "Authorization": "Bearer $token",
      },
    );

    if (res.statusCode != 200) {
      throw Exception("Failed to load dashboard");
    }

    return jsonDecode(res.body);
  }

  // ─── Convenience: build auth headers ─────────────────────────────────────

  static Future<Map<String, String>> authHeaders() async {
    final token = await SecureTokenStorage.getAccessToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${token ?? ""}',
    };
  }

  // ─── Check if user is logged in ──────────────────────────────────────────

  static Future<bool> isLoggedIn() async {
    return SecureTokenStorage.isLoggedIn();
  }
}
