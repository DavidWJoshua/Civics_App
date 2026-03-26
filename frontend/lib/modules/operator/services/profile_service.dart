import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/utils/api_constants.dart';
import '../../../core/utils/token_storage.dart';
import '../models/profile_model.dart';

class ProfileService {
  static Future<Map<String, String>> _headers() async {
    final token = await TokenStorage.getToken();
    return {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    };
  }

  static Future<OperatorProfile?> getProfile() async {
    final headers = await _headers();
    final response = await http.get(
      Uri.parse("${ApiConstants.baseUrl}/api/operator/profile"),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return OperatorProfile.fromJson(data);
    } else if (response.statusCode == 404) {
      // Profile not found
      return null;
    } else {
      throw Exception("Failed to load profile: ${response.body}");
    }
  }

  static Future<OperatorProfile> createProfile(Map<String, dynamic> profileData) async {
    final headers = await _headers();
    final response = await http.post(
      Uri.parse("${ApiConstants.baseUrl}/api/operator/profile"),
      headers: headers,
      body: jsonEncode(profileData),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return OperatorProfile.fromJson(data);
    } else {
      throw Exception("Failed to create profile: ${response.body}");
    }
  }

  static Future<OperatorProfile> updateProfile(Map<String, dynamic> profileData) async {
    final headers = await _headers();
    final response = await http.put(
      Uri.parse("${ApiConstants.baseUrl}/api/operator/profile"),
      headers: headers,
      body: jsonEncode(profileData),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return OperatorProfile.fromJson(data);
    } else {
      throw Exception("Failed to update profile: ${response.body}");
    }
  }
}
