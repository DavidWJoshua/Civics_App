import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/services/auth_service.dart';
import '../../../core/utils/api_constants.dart';

class CommissionerService {

  static Future<Map<String, dynamic>> getDashboard() async {
    final headers = await AuthService.authHeaders();
    final res = await http.get(
      Uri.parse("${ApiConstants.baseUrl}/api/commissioner/dashboard"),
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
      Uri.parse("${ApiConstants.baseUrl}/api/commissioner/budgets"),
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
      Uri.parse("${ApiConstants.baseUrl}/api/commissioner/budgets/approve"),
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
      Uri.parse("${ApiConstants.baseUrl}/api/commissioner/budgets/reject"),
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
      Uri.parse("${ApiConstants.baseUrl}/api/commissioner/escalations"),
      headers: headers,
    );

    if (res.statusCode != 200) {
      throw Exception("Failed to load escalations");
    }

    final data = jsonDecode(res.body);
    return (data as List?) ?? [];
  }
  static Future<Map<String, dynamic>> getComplaintDetails(String id) async {
  final headers = await AuthService.authHeaders();
  final res = await http.get(
    Uri.parse("${ApiConstants.baseUrl}/api/commissioner/complaints/$id"),
    headers: headers,
  );

  if (res.statusCode != 200) {
    throw Exception("Failed to load details");
  }

  return jsonDecode(res.body);
}
  static Future<Map<String, dynamic>> getProfile() async {
    final headers = await AuthService.authHeaders();
    final res = await http.get(
      Uri.parse("${ApiConstants.baseUrl}/api/commissioner/profile"),
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
    final res = await http.get(
      Uri.parse("${ApiConstants.baseUrl}/api/commissioner/complaints/all${_buildQuery(filters)}"),
      headers: headers,
    );

    if (res.statusCode != 200) {
      throw Exception("Failed to load complaints");
    }

    final data = jsonDecode(res.body);
    return (data as List?) ?? [];
  }

}
