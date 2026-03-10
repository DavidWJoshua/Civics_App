import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/utils/api_constants.dart';
import '../../../core/services/storage_service.dart';
import '../models/operator_analytics.dart';

class AdminService {
  final StorageService _storage = StorageService();

  Future<Map<String, dynamic>> getOverviewStats() async {
    final token = await _storage.getToken();
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/api/admin/overview'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      print("Admin Service Error: ${response.statusCode} - ${response.body}");
      throw Exception('Failed to load overview stats: ${response.statusCode} - ${response.body}');
    }
  }

  Future<Map<String, dynamic>> getComplaintAnalytics({int days = 30}) async {
    final token = await _storage.getToken();
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/api/admin/complaints?days=$days'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      print("Admin Service Analytics Error: ${response.statusCode} - ${response.body}");
      throw Exception('Failed to load analytics: ${response.statusCode} - ${response.body}');
    }
  }

  Future<Map<String, dynamic>> getSLAStats() async {
    final token = await _storage.getToken();
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/api/admin/sla'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load SLA stats');
    }
  }

  Future<Map<String, dynamic>> getOperatorStats() async {
    final token = await _storage.getToken();
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/api/admin/operator'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load operator stats');
    }
  }

  Future<void> downloadReport(String type, String format) async {
    final token = await _storage.getToken();
    // Implementation for downloading/saving file would go here
    // For now, just triggering the request
    await http.post(
      Uri.parse('${ApiConstants.baseUrl}/api/admin/reports'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'type': type,
        'format': format,
      }),
    );
    // Download logic to be handled by UI using url_launcher or similar with the response
  }

  Future<List<int>> downloadReportBytes(String type, String format, {DateTime? startDate, DateTime? endDate}) async {
    final token = await _storage.getToken();
    
    Map<String, dynamic> body = {
      'type': type,
      'format': format,
    };

    if (startDate != null) {
      body['start_date'] = startDate.toIso8601String().split('T')[0];
    }
    if (endDate != null) {
      body['end_date'] = endDate.toIso8601String().split('T')[0];
    }

    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/api/admin/reports'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      return response.bodyBytes;
    } else {
      throw Exception('Failed to download report: ${response.statusCode}');
    }
  }

  // --- New Operator Analytics Methods ---

  Future<LiftingStats> getLiftingStats({DateTime? startDate, DateTime? endDate}) async {
    final token = await _storage.getToken();
    String query = "";
    if (startDate != null && endDate != null) {
      String start = startDate.toIso8601String().split('T')[0];
      String end = endDate.toIso8601String().split('T')[0];
      query = "?start_date=$start&end_date=$end";
    }

    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/api/admin/lifting$query'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return LiftingStats.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load lifting stats');
    }
  }

  Future<PumpingStats> getPumpingStats({DateTime? startDate, DateTime? endDate}) async {
    final token = await _storage.getToken();
    String query = "";
    if (startDate != null && endDate != null) {
      String start = startDate.toIso8601String().split('T')[0];
      String end = endDate.toIso8601String().split('T')[0];
      query = "?start_date=$start&end_date=$end";
    }

    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/api/admin/pumping$query'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return PumpingStats.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load pumping stats');
    }
  }

  Future<STPStats> getSTPStats({DateTime? startDate, DateTime? endDate}) async {
    final token = await _storage.getToken();
    String query = "";
    if (startDate != null && endDate != null) {
      String start = startDate.toIso8601String().split('T')[0];
      String end = endDate.toIso8601String().split('T')[0];
      query = "?start_date=$start&end_date=$end";
    }

    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/api/admin/stp$query'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return STPStats.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load stp stats');
    }
  }

  Future<OperatorTaskMatrix> getOperatorTaskMatrix({String date = ''}) async {
    final token = await _storage.getToken();
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/api/admin/operator-matrix?date=$date'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return OperatorTaskMatrix.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load operator matrix');
    }
  }

  Future<List<dynamic>> getOperatorPeriodStats({DateTime? startDate, DateTime? endDate}) async {
    final token = await _storage.getToken();
    String query = '';
    if (startDate != null && endDate != null) {
      final start = startDate.toIso8601String().split('T')[0];
      final end = endDate.toIso8601String().split('T')[0];
      query = '?start_date=$start&end_date=$end';
    }
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/api/admin/operator-period-stats$query'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      return decoded ?? [];
    } else {
      throw Exception('Failed to load operator period stats: ${response.statusCode} - ${response.body}');
    }
  }
}
