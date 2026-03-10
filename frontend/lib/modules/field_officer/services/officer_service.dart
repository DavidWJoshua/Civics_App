import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/services/auth_service.dart';
import '../../../core/utils/api_constants.dart';
import 'package:http_parser/http_parser.dart';
import 'dart:io';
import '../../../core/utils/token_storage.dart';

class OfficerService {
  static String fixImage(String path) {
    if (path.isEmpty) return "";
    
    // Check for `fe_uploads` first so it doesn't get caught by `uploads`
    if (path.contains("fe_uploads/")) {
      final cleanPath = path.substring(path.indexOf("fe_uploads/"));
      return "${ApiConstants.baseUrl}/$cleanPath";
    }

    if (path.contains("uploads/")) {
      // Ensure we don't accidentally match part of another word
      final idx = path.indexOf("uploads/");
      if (idx == 0 || path[idx - 1] == '/') {
        final cleanPath = path.substring(idx);
        return "${ApiConstants.baseUrl}/$cleanPath";
      }
    }
    
    if (path.startsWith('http')) return path;
    if (!path.startsWith('/')) return "\${ApiConstants.baseUrl}/\$path";
    return "\${ApiConstants.baseUrl}\$path";
  }

  static Future<Map<String, dynamic>> getProfile() async {
    final headers = await AuthService.authHeaders();
    final res = await http.get(
      Uri.parse("${ApiConstants.baseUrl}/api/field-officer/profile"),
      headers: headers,
    );

    if (res.statusCode != 200 || res.body.isEmpty) {
      throw Exception("Failed to load profile");
    }

    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> getStats() async {
    final headers = await AuthService.authHeaders();
    final res = await http.get(
      Uri.parse("${ApiConstants.baseUrl}/api/field-officer/dashboard-stats"),
      headers: headers,
    );

    if (res.statusCode != 200 || res.body.isEmpty) {
      return {
        "raised": 0,
        "completed": 0,
        "rejected": 0,
        "not_completed": 0,
      };
    }

    return jsonDecode(res.body);
  }

  static Future<List<dynamic>> _fetchList(String endpoint) async {
    final headers = await AuthService.authHeaders();
    final res = await http.get(
      Uri.parse("${ApiConstants.baseUrl}$endpoint"),
      headers: headers,
    );

    if (res.statusCode != 200 || res.body.isEmpty) {
      return [];
    }

    final decoded = jsonDecode(res.body);
    if (decoded == null || decoded is! List) return [];

    return decoded.map((c) {
      c['photo_url'] = fixImage(c['photo_url'] ?? "");
      c['completion_photo_url'] = fixImage(c['completion_photo_url'] ?? "");
      return c;
    }).toList();
  }

  static String _buildQuery(Map<String, dynamic>? filters) {
    if (filters == null || filters.isEmpty) return "";
    final query = filters.entries
        .where((e) => e.value != null && e.value.toString().isNotEmpty)
        .map((e) => "${e.key}=${Uri.encodeComponent(e.value.toString())}")
        .join("&");
    return query.isEmpty ? "" : "?$query";
  }

  static Future<List<dynamic>> getRaisedComplaints([Map<String, dynamic>? filters]) =>
      _fetchList("/api/field-officer/complaints/raised${_buildQuery(filters)}");

  static Future<List<dynamic>> getToDoComplaints([Map<String, dynamic>? filters]) =>
      _fetchList("/api/field-officer/complaints/todo${_buildQuery(filters)}");

  static Future<List<dynamic>> getCompletedComplaints([Map<String, dynamic>? filters]) =>
      _fetchList("/api/field-officer/complaints/completed${_buildQuery(filters)}");

  static Future<List<dynamic>> getRejectedComplaints([Map<String, dynamic>? filters]) =>
      _fetchList("/api/field-officer/complaints/rejected${_buildQuery(filters)}");

  static Future<void> acceptComplaint(
      String id, double cost, int days) async {
    final headers = await AuthService.authHeaders();
    final res = await http.post(
      Uri.parse("${ApiConstants.baseUrl}/api/field-officer/complaints/accept"),
      headers: headers,
      body: jsonEncode({
        "complaint_id": id,
        "estimated_cost": cost,
        "estimated_days": days,
      }),
    );

    if (res.statusCode != 200) {
      throw Exception("Failed to accept complaint");
    }
  }

  static Future<void> rejectComplaint(String id, String reason) async {
    final headers = await AuthService.authHeaders();
    final res = await http.post(
      Uri.parse("${ApiConstants.baseUrl}/api/field-officer/complaints/reject"),
      headers: headers,
      body: jsonEncode({
        "complaint_id": id,
        "reason": reason,
      }),
    );

    if (res.statusCode != 200) {
      throw Exception("Failed to reject complaint");
    }
  }

  static Future<void> completeComplaint(
    String id,
    String imagePath,
    double lat,
    double lng,
) async {
  final token = await TokenStorage.getToken();

  final uri = Uri.parse(
      "${ApiConstants.baseUrl}/api/field-officer/complaints/complete");

  final request = http.MultipartRequest("POST", uri);

  request.headers['Authorization'] = 'Bearer $token';

  request.fields['complaint_id'] = id;
  request.fields['latitude'] = lat.toString();
  request.fields['longitude'] = lng.toString();

  request.files.add(
    await http.MultipartFile.fromPath(
      'image',
      imagePath,
    ),
  );

  final response = await request.send();

  if (response.statusCode != 200) {
    throw Exception("Failed to complete complaint");
  }
}

  static Future<void> applyLeave(String fromDate, String toDate, String reason) async {
    final token = await TokenStorage.getToken();
    final response = await http.post(
      Uri.parse("${ApiConstants.baseUrl}/api/leave-management/leave/apply"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "from_date": fromDate,
        "to_date": toDate,
        "reason": reason,
      }),
    );

    if (response.statusCode != 201) {
      throw Exception("Failed to apply leave: ${response.body}");
    }
  }

  static Future<List<dynamic>> getLeaveHistory() async {
    final token = await TokenStorage.getToken();
    final response = await http.get(
      Uri.parse("${ApiConstants.baseUrl}/api/leave-management/leave/history"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      return decoded ?? [];
    }
    throw Exception("Failed to load leave history");
  }

  static Future<List<dynamic>> jeGetPendingLeaves() async {
    final token = await TokenStorage.getToken();
    final response = await http.get(
      Uri.parse("${ApiConstants.baseUrl}/api/leave-management/leave/pending"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception("Failed to load pending leaves");
  }

  static Future<void> jeUpdateLeaveStatus(String leaveID, String status) async {
    final token = await TokenStorage.getToken();
    final response = await http.post(
      Uri.parse("${ApiConstants.baseUrl}/api/leave-management/leave/$leaveID/approval"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode({"status": status}),
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to update leave status: ${response.body}");
    }
  }
}
