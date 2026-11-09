import 'package:flutter/foundation.dart';
import 'package:lungs_assistant_agent/constants.dart';
import 'package:lungs_assistant_agent/services/session_service.dart';
import 'package:dio/dio.dart';

class DashboardService {
  static final Dio _dio = _createDio();

  static Dio _createDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 30),
        headers: {'Content-Type': 'application/json'},
      ),
    );
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await SessionService.getToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
      ),
    );
    return dio;
  }

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
      debugPrint('Error fetching dashboard: $e');
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
      final respData = e.response?.data;
      return {
        'status': 'error',
        'message':
            (respData is Map
                ? (respData['detail'] ?? respData['message'])?.toString()
                : null) ??
            e.message,
      };
    } catch (e) {
      return {'status': 'error', 'message': e.toString()};
    }
  }
}
