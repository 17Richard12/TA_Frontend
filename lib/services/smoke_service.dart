import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:agent_doctor/constants.dart';

class SmokeService {
  // Mengambil data smoke count harian
  static Future<int> getSmokeCount(String userId, String timestamp) async {
    try {
      final response = await http.get(
        Uri.parse(
          '${AppConstants.baseUrl}/api/smoke-count/?user_id=$userId&timestamp=$timestamp',
        ),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['status'] == 'success') {
          return jsonResponse['data']['count'] ?? 0;
        }
      }
      return 0;
    } catch (e) {
      throw Exception('Error: $e');
      return 0;
    }
  }

  // Mengirim/Update data smoke count
  static Future<bool> postSmokeCount(
    String userId,
    String timestamp,
    int total,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/api/smoke-count/'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "user_id": userId,
          "timestamp": timestamp,
          "total": total,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      }
      return false;
    } catch (e) {
      throw Exception('Error: $e');
      return false;
    }
  }
}
