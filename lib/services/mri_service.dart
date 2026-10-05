import 'package:agent_doctor/constants.dart';
import 'package:dio/dio.dart';

class MriService {
  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  static Future<Map<String, dynamic>> getLatestMriPhotos(String userId) async {
    try {
      final response = await _dio.get(
        '/api/photos/compare',
        queryParameters: {'user_id': userId},
      );

      if (response.statusCode == 200) {
        // response.data = { status: "success", data: { user_id, photos: [...] } }
        final body = response.data as Map<String, dynamic>;
        final innerData = body['data'] as Map<String, dynamic>? ?? {};
        // kembalikan langsung isi 'data', bukan seluruh body
        return {'status': 'success', 'data': innerData};
      }
      return {'status': 'error', 'message': 'Gagal mengambil data MRI'};
    } on DioException catch (e) {
      return {
        'status': 'error',
        'message': e.response?.data?['message']?.toString() ?? e.message,
      };
    } catch (e) {
      return {'status': 'error', 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> uploadMriPhoto(
    String userId,
    String base64Image,
  ) async {
    try {
      final response = await _dio.post(
        '/api/photos/',
        data: {'user_id': userId, 'foto_base64': base64Image},
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'status': 'success'};
      }
      return {'status': 'error', 'message': 'Gagal mengupload foto'};
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
