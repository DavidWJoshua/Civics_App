import 'package:http/http.dart' as http;
import 'dart:convert';

void main() async {
  // First login to get a token
  final loginResponse = await http.post(
    Uri.parse('http://localhost:8080/api/auth/login'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'phone_number': '+919999999999', 
      'password': 'password123'
    }),
  );

  if (loginResponse.statusCode != 200) {
    print("Login failed: ${loginResponse.body}");
    return;
  }

  final token = jsonDecode(loginResponse.body)['token'];
  print("Got token: $token");

  final response = await http.get(
    Uri.parse('http://localhost:8080/api/admin/operator-matrix?date=2026-02-24'),
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
  );

  print("Matrix Status: ${response.statusCode}");
  
  try {
    final parsed = jsonDecode(response.body);
    // Mimic the factory code
    Map<String, String> safeCastMap(dynamic mapObj) {
      if (mapObj == null || mapObj is! Map) return {};
      return mapObj.map<String, String>((key, value) => MapEntry(key.toString(), value.toString()));
    }

    print("Total Operators field: ${parsed['total_operators']}");
    final tasksList = parsed['tasks'] as List?;
    if (tasksList == null) {
      print("Tasks list is null");
    } else {
      print("Tasks list length: ${tasksList.length}");
      for (var t in tasksList) {
        final stType = t['station_type'] ?? '';
        final daily = safeCastMap(t['daily']);
        final weekly = safeCastMap(t['weekly']);
        print("Op: ${t['operator_name']}, Type: $stType, DailyKeys: ${daily.keys.length}, WeeklyKeys: ${weekly.keys.length}");
      }
    }

  } catch (e, stack) {
    print("Failed to decode or parse: $e");
    print(stack);
  }
}
