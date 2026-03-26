import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/api_constants.dart';
import '../../../core/utils/token_storage.dart';

class AuthService {

  static Future<bool> sendOtp(String phone, String captchaId, String captchaValue, {String? role}) async {
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

    if (response.statusCode != 200) {
      final body = jsonDecode(response.body);
      throw Exception(body['error'] ?? "Failed to send OTP");
    }

    final data = jsonDecode(response.body);
    return data['is_officer'] ?? false;
  }

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


  static Future<Map<String, dynamic>> verifyOtp(String phone, String otp, {String role = "CITIZEN"}) async {
    final response = await http.post(
      Uri.parse("${ApiConstants.baseUrl}/api/auth/citizen/verify-otp"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "phone_number": phone,
        "code": otp,
        "role": role,
      }),
    );

    if (response.statusCode != 200) {
      final body = jsonDecode(response.body);
      throw Exception(body['error'] ?? "Invalid OTP");
    }

    return jsonDecode(response.body);
  }
  static Future<Map<String, String>> authHeaders() async {
    final token = await TokenStorage.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  static Future<void> logout() async {
    final token = await TokenStorage.getToken();
    if (token == null) return;

    try {
      await http.post(
        Uri.parse("${ApiConstants.baseUrl}/api/auth/logout"),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
    } catch (e) {
      // Ignore errors on logout network call, we still want to clear local storage
    } finally {
      await TokenStorage.clear();
    }
  }
}
