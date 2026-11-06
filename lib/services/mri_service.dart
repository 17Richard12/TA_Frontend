import 'package:lungs_assistant_agent/constants.dart';
import 'package:dio/dio.dart';

class MriService {
  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 90),
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
      final respData = e.response?.data;
      return {
        'status': 'error',
        'message':
            (respData is Map ? respData['message']?.toString() : null) ??
            e.message,
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
        final body = response.data;
        if (body is Map && body['status'] == 'error') {
          return {
            'status': 'error',
            'message':
                body['detail']?.toString() ??
                body['message']?.toString() ??
                'Gambar ditolak oleh sistem validasi.',
          };
        }
        return {'status': 'success'};
      }
      return {'status': 'error', 'message': 'Gagal mengupload foto'};
    } on DioException catch (e) {
      final data = e.response?.data;
      final serverMsg = data is Map
          ? (data['detail'] ?? data['message'])?.toString()
          : null;
      return {
        'status': 'error',
        'message': serverMsg ?? e.message ?? 'Gagal mengupload foto',
      };
    } catch (e) {
      return {'status': 'error', 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> startMriAnalysis(String userId) async {
    try {
      final response = await _dio.post(
        '/api/photos/analyze',
        data: {'user_id': userId},
      );
      if (response.statusCode == 200) {
        final body = response.data as Map<String, dynamic>;
        if (body['status'] == 'success') {
          final innerData = body['data'] as Map<String, dynamic>? ?? {};
          return {
            'status': 'success',
            'analysis': innerData['analysis']?.toString() ?? '',
          };
        }
        return {
          'status': 'error',
          'message':
              body['message']?.toString() ?? 'Gagal menganalisis CT Scan',
        };
      }
      return {'status': 'error', 'message': 'Gagal memulai analisis CT Scan'};
    } on DioException catch (e) {
      final data = e.response?.data;
      final serverMsg = data is Map
          ? (data['detail'] ?? data['message'])?.toString()
          : null;
      return {
        'status': 'error',
        'message': serverMsg ?? e.message ?? 'Gagal menganalisis CT Scan',
      };
    } catch (e) {
      return {'status': 'error', 'message': e.toString()};
    }
  }
}
