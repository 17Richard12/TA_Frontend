import 'package:agent_doctor/constants.dart';
import 'package:dio/dio.dart';

class ChatService {
  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 120),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  // ========================
  // POST CHAT
  // POST /api/chats/
  // Body: { user_uid, session_id (nullable), message }
  // Response: { status, data: { session_id, user_message, ai_response } }
  // ========================
  static Future<Map<String, dynamic>> sendMessage({
    required String userUid,
    required String message,
    String? sessionId,
  }) async {
    try {
      final response = await _dio.post(
        '/api/chats/',
        data: {
          'user_uid': userUid,
          'session_id': sessionId, // null = buat session baru
          'message': message,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['status'] == 'success') {
          return {
            'status': 'success',
            'session_id': data['data']['session_id'],
            'ai_response': data['data']['ai_response'],
          };
        } else {
          return {'status': 'error', 'message': data['message']};
        }
      } else {
        return {
          'status': 'error',
          'message': 'Server error: ${response.statusCode}',
        };
      }
    } on DioException catch (e) {
      return {'status': 'error', 'message': _handleDioError(e)};
    } catch (e) {
      return {'status': 'error', 'message': 'Unexpected error: $e'};
    }
  }

  // ========================
  // GET CHAT BY SESSION
  // GET /api/chats/session/{session_id}
  // Response: { status, data: { session_id, user, chats } }
  // ========================
  static Future<Map<String, dynamic>> getChatBySession(String sessionId) async {
    try {
      final response = await _dio.get('/api/chats/session/$sessionId');

      final data = response.data;
      if (data['status'] == 'success') {
        return {'status': 'success', 'data': data['data']};
      } else {
        return {'status': 'error', 'message': data['message']};
      }
    } on DioException catch (e) {
      return {'status': 'error', 'message': _handleDioError(e)};
    } catch (e) {
      return {'status': 'error', 'message': 'Unexpected error: $e'};
    }
  }

  // ========================
  // GET CHAT HISTORY
  // GET /api/chats/history/{user_uid}
  // Response: { status, data: [ { session_id, preview }, ... ] }
  // ========================
  static Future<Map<String, dynamic>> getChatHistory(String userUid) async {
    try {
      final response = await _dio.get('/api/chats/history/$userUid');

      final data = response.data;
      if (data['status'] == 'success') {
        return {'status': 'success', 'data': data['data']};
      } else {
        return {'status': 'error', 'message': data['message']};
      }
    } on DioException catch (e) {
      return {'status': 'error', 'message': _handleDioError(e)};
    } catch (e) {
      return {'status': 'error', 'message': 'Unexpected error: $e'};
    }
  }

  // ========================
  // ERROR HANDLER
  // ========================
  static String _handleDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        return 'Connection timeout. Periksa koneksi kamu.';
      case DioExceptionType.receiveTimeout:
        return 'Server terlalu lama merespons. Coba lagi.';
      case DioExceptionType.connectionError:
        return 'Tidak bisa terhubung ke server. Pastikan backend berjalan.';
      default:
        final statusCode = e.response?.statusCode;
        final message = e.response?.data?['detail'] ?? e.message;
        return 'Error $statusCode: $message';
    }
  }
}
