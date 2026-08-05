import 'dart:convert';
import 'package:agent_doctor/constants.dart';
import 'package:http/http.dart' as http;

class ActivityService {
  // TODO: Sesuaikan dengan URL backend kamu.
  // Jika menggunakan emulator Android, gunakan http://10.0.2.2:8000
  // Jika real device/hosting, gunakan IP/Domain yang sesuai.
  static const String baseUrl = '${AppConstants.baseUrl}/api/activities';

  /// Fetch data dari endpoint POST /activities/process
  /// Mengembalikan Map penuh agar kita bisa mendapatkan root 'id' (dailyActivityId)
  static Future<Map<String, dynamic>?> getDailyActivity(
    String userUid,
    String timestamp,
  ) async {
    final url = Uri.parse('$baseUrl/process');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_uid': userUid, 'timestamp': timestamp}),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['status'] == 'success') {
          // Mengembalikan objek data yang berisi {id, user_uid, timestamp, activities: [...]}
          return jsonResponse['data'];
        }
      }
      print('Gagal load activities: ${response.body}');
      return null;
    } catch (e) {
      print('Error getDailyActivity: $e');
      return null;
    }
  }

  /// Update status checklist via PATCH /activities/{daily_id}/items/{act_id}/check
  static Future<bool> updateActivityChecklist(
    String dailyActivityId,
    String activityId,
    bool isDone,
  ) async {
    final url = Uri.parse(
      '$baseUrl/$dailyActivityId/items/$activityId/check',
    );

    try {
      final response = await http.patch(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'done': isDone}),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        print(
          'Gagal update checklist: ${response.statusCode} - ${response.body}',
        );
        return false;
      }
    } catch (e) {
      print('Error update checklist: $e');
      return false;
    }
  }
}
