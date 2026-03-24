import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/utils/api_constants.dart';
import '../../../core/utils/token_storage.dart';

class LeaveRequest {
  final int? id;
  final String? officerId;
  final String fromDate;
  final String toDate;
  final String reason;
  final String status;
  final String createdAt;

  LeaveRequest({
    this.id,
    this.officerId,
    required this.fromDate,
    required this.toDate,
    required this.reason,
    required this.status,
    required this.createdAt,
  });

  factory LeaveRequest.fromJson(Map<String, dynamic> json) {
    return LeaveRequest(
      id: json['id'],
      officerId: json['officer_id'],
      fromDate: json['from_date'],
      toDate: json['to_date'],
      reason: json['reason'],
      status: json['status'],
      createdAt: json['created_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'from_date': fromDate,
      'to_date': toDate,
      'reason': reason,
    };
  }
}

class LeaveService {
  static Future<Map<String, String>> _headers() async {
    final token = await TokenStorage.getToken();
    return {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    };
  }

  static Future<void> applyLeave(Map<String, dynamic> leaveData) async {
    final headers = await _headers();
    final response = await http.post(
      Uri.parse("\${ApiConstants.baseUrl}/api/leave-management/leave/apply"),
      headers: headers,
      body: jsonEncode(leaveData),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception("Failed to apply for leave: \${response.body}");
    }
  }

  static Future<List<LeaveRequest>> getPendingLeaves() async {
    final headers = await _headers();
    final response = await http.get(
      Uri.parse("\${ApiConstants.baseUrl}/api/leave-management/leave/pending"),
      headers: headers,
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to fetch pending leaves: \${response.body}");
    }

    final List<dynamic> data = jsonDecode(response.body);
    return data.map((json) => LeaveRequest.fromJson(json)).toList();
  }

  static Future<void> approveRejectLeave(int leaveId, String status) async {
    final headers = await _headers();
    final response = await http.post(
      Uri.parse("\${ApiConstants.baseUrl}/api/leave-management/leave/$leaveId/approval"),
      headers: headers,
      body: jsonEncode({"status": status}),
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to update leave status: \${response.body}");
    }
  }
}
