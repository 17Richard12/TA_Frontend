import 'package:lungs_assistant_agent/constants.dart';
import 'package:lungs_assistant_agent/services/session_service.dart';
import 'package:dio/dio.dart';

class XrayService {
  static final Dio _dio = _createDio();

  static Dio _createDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 90),
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

  static Future<Map<String, dynamic>> getLatestXrayPhotos(String userId) async {
    try {
      final response = await _dio.get(
        '/api/xrays/compare',
        queryParameters: {'user_id': userId},
      );

      if (response.statusCode == 200) {
        final body = response.data as Map<String, dynamic>;
        final innerData = body['data'] as Map<String, dynamic>? ?? {};
        return {'status': 'success', 'data': innerData};
      }
      return {'status': 'error', 'message': 'Gagal mengambil data X-Ray'};
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

  static Future<Map<String, dynamic>> uploadXrayPhoto(
    String userId,
    String base64Image,
  ) async {
    try {
      final response = await _dio.post(
        '/api/xrays/',
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
      return {'status': 'error', 'message': 'Gagal mengupload foto X-Ray'};
    } on DioException catch (e) {
      final data = e.response?.data;
      final serverMsg = data is Map
          ? (data['detail'] ?? data['message'])?.toString()
          : null;
      return {
        'status': 'error',
        'message': serverMsg ?? e.message ?? 'Gagal mengupload foto X-Ray',
      };
    } catch (e) {
      return {'status': 'error', 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> startXrayAnalysis(String userId) async {
    try {
      final response = await _dio.post(
        '/api/xrays/analyze',
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
          'message': body['message']?.toString() ?? 'Gagal menganalisis X-Ray',
        };
      }
      return {'status': 'error', 'message': 'Gagal memulai analisis X-Ray'};
    } on DioException catch (e) {
      final data = e.response?.data;
      final serverMsg = data is Map
          ? (data['detail'] ?? data['message'])?.toString()
          : null;
      return {
        'status': 'error',
        'message': serverMsg ?? e.message ?? 'Gagal menganalisis X-Ray',
      };
    } catch (e) {
      return {'status': 'error', 'message': e.toString()};
    }
  }
}
