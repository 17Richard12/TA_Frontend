import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:agent_doctor/constants.dart';
import 'package:flutter/material.dart';

class ActivityService {
  // Menggunakan POST karena backend menerima payload (GenerateActivitySchema)
  static Future<List<dynamic>> getActivities(
    String userUid,
    String timestamp,
  ) async {
    try {
      final response = await http.post(
        Uri.parse(
          '${AppConstants.baseUrl}/api/activities/process',
        ), // Sesuaikan path jika berbeda
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"user_uid": userUid, "timestamp": timestamp}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['status'] == 'success') {
          // Mengambil array "activities" dari dalam "data"
          return jsonResponse['data']['activities'] ?? [];
        }
      }
      return [];
    } catch (e) {
      debugPrint("Error fetching activities: $e");
      return [];
    }
  }
}
