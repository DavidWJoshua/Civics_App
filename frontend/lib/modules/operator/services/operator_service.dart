import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/utils/api_constants.dart';
import '../../../core/utils/token_storage.dart';
import '../models/operator_models.dart';

class OperatorService {
  static Future<Map<String, String>> _headers() async {
    final token = await TokenStorage.getToken();
    return {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    };
  }

  static Future<List<Station>> getStations() async {
    final headers = await _headers();
    final response = await http.get(
      Uri.parse("${ApiConstants.baseUrl}/api/operator/stations"),
      headers: headers,
    );

    if (response.statusCode != 200) throw Exception("Failed to load stations");

    final List<dynamic> data = jsonDecode(response.body);
    return data.map((json) => Station.fromJson(json)).toList();
  }

  // --- Lifting ---
  static Future<void> submitLiftingLog(Map<String, dynamic> log, String frequency) async {
    final endpoint = frequency.toLowerCase(); // daily, weekly, monthly, yearly
    // Map to specific endpoints or use a generic one if backend supported it. 
    // Assuming backend has /lifting/daily-log, /lifting/weekly-log etc.
    // For now, based on my backend implementation, I only have daily-log active.
    // I will use daily-log for daily, and just print/mock for others or I need to add them to backend.
    // The user didn't ask me to implement backend for weekly/monthly/yearly in the previous step, but I should probably add them to backend model/route if I want it to work fully.
    // However, for this step, I'll update the service to point to the likely endpoints.
    
    final headers = await _headers();
    final url = "${ApiConstants.baseUrl}/api/operator/lifting/$endpoint-log";
    
    final response = await http.post(
      Uri.parse(url),
      headers: headers,
      body: jsonEncode(log),
    );

    if (response.statusCode != 201 && response.statusCode != 200) {
       // If 404, maybe backend isn't ready, but we handle it gracefully?
       if (response.statusCode == 404) throw Exception("Endpoint $endpoint-log not implemented on backend");
       throw Exception("Failed to submit log: ${response.body}");
    }
  }

  // --- Pumping ---
  static Future<void> submitPumpingLog(Map<String, dynamic> log, String frequency) async {
    final endpoint = frequency.toLowerCase();
    final headers = await _headers();
    final url = "${ApiConstants.baseUrl}/api/operator/pumping/$endpoint-log";
    
    final response = await http.post(
      Uri.parse(url),
      headers: headers,
      body: jsonEncode(log),
    );

    if (response.statusCode != 201 && response.statusCode != 200) {
       if (response.statusCode == 404) throw Exception("Endpoint $endpoint-log not implemented on backend");
       throw Exception("Failed to submit log: ${response.body}");
    }
  }

  // --- STP ---
  static Future<void> submitStpLog(Map<String, dynamic> log, String frequency) async {
    final endpoint = frequency.toLowerCase();
    final headers = await _headers();
    final url = "${ApiConstants.baseUrl}/api/operator/stp/$endpoint-log";
    
    final response = await http.post(
      Uri.parse(url),
      headers: headers,
      body: jsonEncode(log),
    );

    if (response.statusCode != 201 && response.statusCode != 200) {
       if (response.statusCode == 404) throw Exception("Endpoint $endpoint-log not implemented on backend");
       throw Exception("Failed to submit log: ${response.body}");
    }
  }
}
