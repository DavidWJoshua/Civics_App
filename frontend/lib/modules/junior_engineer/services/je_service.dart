import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/services/auth_service.dart';
import '../../../core/utils/api_constants.dart';
import '../../../../core/utils/token_storage.dart';


class JEService {
  static Future<Map<String, dynamic>> getDashboard() async {
    final headers = await AuthService.authHeaders();
    final res = await http.get(
      Uri.parse("${ApiConstants.baseUrl}/api/junior-engineer/dashboard"),
      headers: headers,
    );
    if (res.statusCode != 200) {
      throw Exception("Failed to load dashboard");
    }
    return jsonDecode(res.body);
  }

  static Future<List<dynamic>> getPendingBudgets() async {
    final headers = await AuthService.authHeaders();
    final res = await http.get(
      Uri.parse("${ApiConstants.baseUrl}/api/junior-engineer/budgets"),
      headers: headers,
    );
    if (res.statusCode != 200) {
      throw Exception("Failed to load budgets");
    }
    final data = jsonDecode(res.body);
    return (data as List?) ?? [];
  }

  static Future<void> approveBudget(String complaintId) async {
    final headers = await AuthService.authHeaders();
    final res = await http.post(
      Uri.parse("${ApiConstants.baseUrl}/api/junior-engineer/budgets/approve"),
      headers: headers,
      body: jsonEncode({"complaint_id": complaintId}),
    );
    if (res.statusCode != 200) {
      throw Exception("Approve failed");
    }
  }

  static Future<void> rejectBudget(String complaintId, String reason) async {
    final headers = await AuthService.authHeaders();
    final res = await http.post(
      Uri.parse("${ApiConstants.baseUrl}/api/junior-engineer/budgets/reject"),
      headers: headers,
      body: jsonEncode({
        "complaint_id": complaintId,
        "reason": reason,
      }),
    );
    if (res.statusCode != 200) {
      throw Exception("Reject failed");
    }
  }

  static Future<List<dynamic>> getEscalations() async {
    final headers = await AuthService.authHeaders();
    final res = await http.get(
      Uri.parse("${ApiConstants.baseUrl}/api/junior-engineer/escalations"),
      headers: headers,
    );
    if (res.statusCode != 200) {
      throw Exception("Failed to load escalations");
    }
    final data = jsonDecode(res.body);
    return (data as List?) ?? [];
  }

  static String fixImage(String path) {
    if (path.isEmpty) return "";
    if (path.contains("fe_uploads/")) {
      final cleanPath = path.substring(path.indexOf("fe_uploads/"));
      return "${ApiConstants.baseUrl}/$cleanPath";
    }
    if (path.contains("uploads/")) {
      final idx = path.indexOf("uploads/");
      if (idx == 0 || path[idx - 1] == '/') {
        final cleanPath = path.substring(idx);
        return "${ApiConstants.baseUrl}/$cleanPath";
      }
    }
    if (path.startsWith("http")) return path;
    if (!path.startsWith('/')) return "${ApiConstants.baseUrl}/$path";
    return "${ApiConstants.baseUrl}$path";
  }

  static Future<Map<String, dynamic>> getProfile() async {
    final headers = await AuthService.authHeaders();
    final res = await http.get(
      Uri.parse("${ApiConstants.baseUrl}/api/junior-engineer/profile"),
      headers: headers,
    );
    if (res.statusCode != 200) {
      throw Exception("Failed to load profile");
    }
    return jsonDecode(res.body);
  }

  static String _buildQuery(Map<String, dynamic>? filters) {
    if (filters == null || filters.isEmpty) return "";
    final query = filters.entries
        .where((e) => e.value != null && e.value.toString().isNotEmpty)
        .map((e) => "${e.key}=${Uri.encodeComponent(e.value.toString())}")
        .join("&");
    return query.isEmpty ? "" : "?$query";
  }

  static Future<List<dynamic>> getAllComplaints([Map<String, dynamic>? filters]) async {
    final headers = await AuthService.authHeaders();

    final response = await http.get(
      Uri.parse("${ApiConstants.baseUrl}/api/junior-engineer/complaints/all${_buildQuery(filters)}"),
      headers: headers,
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to load complaints");
    }

    final list = jsonDecode(response.body);
    if (list == null || list is! List) return []; // Safety check

    return list.map((c) {
      c['photo_url'] = fixImage(c['photo_url'] ?? "");
      c['completion_photo_url'] =
          fixImage(c['completion_photo_url'] ?? "");
      return c;
    }).toList();
  }

  // --------------------------------------------------
  // 🔄 COMPLAINT REASSIGNMENT
  // --------------------------------------------------

  static Future<List<dynamic>> getComplaintsForReassignment() async {
    final headers = await AuthService.authHeaders();
    final res = await http.get(
      Uri.parse("${ApiConstants.baseUrl}/api/junior-engineer/complaints/reassignment"),
      headers: headers,
    );
    if (res.statusCode != 200) {
      throw Exception("Failed to load reassignment complaints");
    }
    final data = jsonDecode(res.body);
    if (data == null || data is! List) return [];
    
    return data.map((c) {
      c['photo_url'] = fixImage(c['photo_url'] ?? "");
      c['completion_photo_url'] = fixImage(c['completion_photo_url'] ?? "");
      return c;
    }).toList();
  }

  static Future<List<dynamic>> getFieldOfficers() async {
    final headers = await AuthService.authHeaders();
    final res = await http.get(
      Uri.parse("${ApiConstants.baseUrl}/api/junior-engineer/officers"),
      headers: headers,
    );
    if (res.statusCode != 200) {
      throw Exception("Failed to load field officers");
    }
    final data = jsonDecode(res.body);
    return (data as List?) ?? [];
  }

  static Future<void> reassignComplaint(String complaintId, String newOfficerId) async {
    final headers = await AuthService.authHeaders();
    final res = await http.post(
      Uri.parse("${ApiConstants.baseUrl}/api/junior-engineer/complaints/reassign"),
      headers: headers,
      body: jsonEncode({
        "complaint_id": complaintId,
        "new_officer_id": newOfficerId,
      }),
    );
    if (res.statusCode != 200) {
      throw Exception("Reassignment failed");
    }
  }

}
