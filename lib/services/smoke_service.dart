import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:lungs_assistant_agent/constants.dart';
import 'package:lungs_assistant_agent/services/session_service.dart';

class SmokeService {
  // Mengambil data smoke count harian
  static Future<int> getSmokeCount(String userId, String timestamp) async {
    try {
      final headers = await SessionService.getAuthHeaders(jsonContent: false);
      final response = await http.get(
        Uri.parse(
          '${AppConstants.baseUrl}/api/smoke-count/?user_id=$userId&timestamp=$timestamp',
        ),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['status'] == 'success') {
          return jsonResponse['data']['count'] ?? 0;
        }
      }
      return 0;
    } catch (e) {
      debugPrint('Error getSmokeCount: $e');
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
      final headers = await SessionService.getAuthHeaders();
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/api/smoke-count/'),
        headers: headers,
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
      debugPrint('Error postSmokeCount: $e');
      return false;
    }
  }

  static Future<List<dynamic>> getWeeklyReport(
    String userId,
    String timestamp,
  ) async {
    try {
      final headers = await SessionService.getAuthHeaders(jsonContent: false);
      final response = await http.get(
        Uri.parse(
          '${AppConstants.baseUrl}/api/smoke-count/report?user_id=$userId&timestamp=$timestamp',
        ),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['status'] == 'success') {
          return jsonResponse['data'] ?? [];
        }
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching report: $e');
      return [];
    }
  }
}
