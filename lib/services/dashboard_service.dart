import 'package:lungs_assistant_agent/constants.dart';
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

  static Future<Map<String, dynamic>?> getDashboardData(
    String userId,
    String date,
  ) async {
    try {
      final response = await _dio.get(
        '/api/dashboard/',
        queryParameters: {'user_id': userId, 'date': date},
      );

      if (response.statusCode == 200) {
        return response.data;
      }
      return null;
    } catch (e) {
      print('Error fetching dashboard: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>> getMonthlyReport(
    String userId,
    int year,
    int month,
  ) async {
    try {
      final response = await _dio.get(
        '/api/dashboard/monthly',
        queryParameters: {'user_id': userId, 'year': year, 'month': month},
      );

      if (response.statusCode == 200) {
        final body = response.data as Map<String, dynamic>;
        final innerData = body['data'] as Map<String, dynamic>? ?? {};
        return {'status': 'success', 'data': innerData};
      }
      return {'status': 'error', 'message': 'Gagal mengambil laporan bulanan'};
    } on DioException catch (e) {
      return {
        'status': 'error',
        'message': e.response?.data?['message']?.toString() ?? e.message,
      };
    } catch (e) {
      return {'status': 'error', 'message': e.toString()};
    }
  }
}
