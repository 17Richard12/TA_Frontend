import 'package:agent_doctor/constants.dart';
import 'package:dio/dio.dart';

class DashboardService {
  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  static Future<Map<String, dynamic>?> getDashboardData(String userId, String date) async {
    try {
      final response = await _dio.get('/api/dashboard/', queryParameters: {
        'user_id': userId,
        'date': date,
      });

      if (response.statusCode == 200) {
        return response.data;
      }
      return null;
    } catch (e) {
      print('Error fetching dashboard: $e');
      return null;
    }
  }
}
