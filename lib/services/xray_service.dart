import 'package:lungs_assistant_agent/constants.dart';
import 'package:dio/dio.dart';

class XrayService {
  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 90),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  static Future<Map<String, dynamic>> getLatestXrayPhotos(String userId) async {
    try {
      final response = await _dio.get(
        '/api/xrays/compare', // Disesuaikan dengan endpoint X-Ray
        queryParameters: {'user_id': userId},
      );

      if (response.statusCode == 200) {
        final body = response.data as Map<String, dynamic>;
        final innerData = body['data'] as Map<String, dynamic>? ?? {};
        return {'status': 'success', 'data': innerData};
      }
      return {'status': 'error', 'message': 'Gagal mengambil data X-Ray'};
    } on DioException catch (e) {
      return {
        'status': 'error',
        'message': e.response?.data?['message']?.toString() ?? e.message,
      };
    } catch (e) {
      return {'status': 'error', 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> uploadXrayPhoto(
    String userId,
    String base64Image,
  ) async {
    try {
      final response = await _dio.post(
        '/api/xrays/', // Disesuaikan dengan endpoint X-Ray
        data: {'user_id': userId, 'foto_base64': base64Image},
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'status': 'success'};
      }
      return {'status': 'error', 'message': 'Gagal mengupload foto X-Ray'};
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
