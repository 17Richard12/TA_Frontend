import 'package:lungs_assistant_agent/constants.dart';
import 'package:dio/dio.dart';

class AuthService {
  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  // ========================
  // REGISTER
  // POST /api/users/register
  // Body: { name, email, password }
  // Response: { status, message, data: { uid, name, email, ... } }
  // ========================
  Future<Map<String, dynamic>> register(
    String name,
    String email,
    String password,
  ) async {
    try {
      final response = await _dio.post(
        '/api/users/register',
        data: {'name': name, 'email': email, 'password': password},
      );

      final data = response.data;
      if (data['status'] == 'success') {
        return {
          'status': 'success',
          'uid': data['data']['uid'],
          'data': data['data'],
        };
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
  // LOGIN
  // POST /api/users/login
  // Body: { email, password }
  // Response: { status, message, data: { uid, name, email, ... } }
  // ========================
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _dio.post(
        '/api/users/login',
        data: {'email': email, 'password': password},
      );

      final data = response.data;
      if (data['status'] == 'success') {
        return {
          'status': 'success',
          'uid': data['data']['uid'],
          'data': data['data'],
        };
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
  // GET USER
  // GET /api/users/{uid}
  // Response: { status, data: { uid, name, email, ... } }
  // ========================
  Future<Map<String, dynamic>> getUser(String uid) async {
    try {
      final response = await _dio.get('/api/users/$uid');

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
  // EDIT ACCOUNT
  // PUT /api/users/{uid}/edit
  // Body: { name?, birth?, bloodType?, gender?, height?, weight?, phone?, history? }
  // Response: { status, message, data: { uid, ... } }
  // ========================
  Future<Map<String, dynamic>> editAccount(
    String uid,
    Map<String, dynamic> profileData,
  ) async {
    try {
      final response = await _dio.put(
        '/api/users/$uid/edit',
        data: profileData,
      );

      final data = response.data;
      if (data['status'] == 'success') {
        return {
          'status': 'success',
          'message': data['message'],
          'data': data['data'],
        };
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
  // CHANGE PASSWORD
  // PUT /api/users/{uid}/change-password
  // Body: { new_password }
  // Response: { status, message }
  // ========================
  Future<Map<String, dynamic>> changePassword(
    String uid,
    String newPassword,
  ) async {
    try {
      final response = await _dio.put(
        '/api/users/$uid/change-password',
        data: {'new_password': newPassword},
      );

      final data = response.data;
      if (data['status'] == 'success') {
        return {'status': 'success', 'message': data['message']};
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
  String _handleDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        return 'Connection timeout. Periksa koneksi kamu.';
      case DioExceptionType.receiveTimeout:
        return 'Server terlalu lama merespons.';
      case DioExceptionType.connectionError:
        return 'Tidak bisa terhubung ke server.';
      default:
        final statusCode = e.response?.statusCode;
        final message = e.response?.data?['detail'] ?? e.message;
        return 'Error $statusCode: $message';
    }
  }

  Future<Map<String, dynamic>> getAllUsers() async {
    try {
      final response = await _dio.get('/api/users/');

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

  Future<Map<String, dynamic>> getPatients() async {
    try {
      final response = await _dio.get('/api/users/patients');

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

  Future<Map<String, dynamic>> getPatientDailyReport(
    String uid,
    String date,
  ) async {
    try {
      final response = await _dio.get(
        '/api/users/$uid/daily-report',
        queryParameters: {'date': date},
      );

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

  Future<Map<String, dynamic>> addActivity(
    String uid,
    String date,
    String activity,
  ) async {
    try {
      final res = await _dio.post(
        '/api/users/$uid/activities',
        data: {'date': date, 'activity': activity},
      );
      return res.data;
    } catch (e) {
      return {'status': 'error'};
    }
  }

  Future<Map<String, dynamic>> editActivity(
    String uid,
    String activityId,
    String date,
    String activity,
  ) async {
    try {
      final res = await _dio.put(
        '/api/users/$uid/activities/$activityId',
        data: {'date': date, 'activity': activity},
      );
      return res.data;
    } catch (e) {
      return {'status': 'error'};
    }
  }

  Future<Map<String, dynamic>> deleteActivity(
    String uid,
    String activityId,
    String date,
  ) async {
    try {
      final res = await _dio.delete(
        '/api/users/$uid/activities/$activityId',
        queryParameters: {'date': date},
      );
      return res.data;
    } catch (e) {
      return {'status': 'error'};
    }
  }
}
