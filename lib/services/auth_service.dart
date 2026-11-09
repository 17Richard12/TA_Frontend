import 'package:lungs_assistant_agent/constants.dart';
import 'package:lungs_assistant_agent/services/session_service.dart';
import 'package:dio/dio.dart';

class AuthService {
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

  // ========================
  // REGISTER
  // POST /api/users/register
  // Body: { name, email, password }
  // Response: { status, message, data: { uid, name, email, access_token, ... } }
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
        final userData = data['data'] as Map<String, dynamic>? ?? {};
        final token = userData['access_token']?.toString();
        if (token != null && token.isNotEmpty) {
          await SessionService.setToken(token);
        }
        return {'status': 'success', 'uid': userData['uid'], 'data': userData};
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
  // Response: { status, message, data: { uid, name, email, access_token, ... } }
  // ========================
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _dio.post(
        '/api/users/login',
        data: {'email': email, 'password': password},
      );

      final data = response.data;
      if (data['status'] == 'success') {
        final userData = data['data'] as Map<String, dynamic>? ?? {};
        final token = userData['access_token']?.toString();
        if (token != null && token.isNotEmpty) {
          await SessionService.setToken(token);
        }
        return {'status': 'success', 'uid': userData['uid'], 'data': userData};
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
      final isUnauthorized = e.response?.statusCode == 401;
      return {
        'status': 'error',
        'unauthorized': isUnauthorized,
        'message': _handleDioError(e),
      };
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
  // Body: { current_password, new_password }
  // Response: { status, message }
  // ========================
  Future<Map<String, dynamic>> changePassword(
    String uid,
    String currentPassword,
    String newPassword,
  ) async {
    try {
      final response = await _dio.put(
        '/api/users/$uid/change-password',
        data: {
          'current_password': currentPassword,
          'new_password': newPassword,
        },
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
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Koneksi internetmu lambat. Pastikan sinyal stabil dan coba lagi ya.';

      case DioExceptionType.connectionError:
        return 'Gagal terhubung ke sistem. Periksa koneksi internetmu.';

      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;

        final respData = e.response?.data;
        String? backendMessage;
        if (respData is Map) {
          final detail = respData['detail'];
          if (detail is List && detail.isNotEmpty) {
            final first = detail.first;
            backendMessage = first is Map
                ? first['msg']?.toString()
                : first.toString();
          } else {
            backendMessage = (detail ?? respData['message'])?.toString();
          }
        }

        if (statusCode == 400 || statusCode == 422) {
          return backendMessage ??
              'Data yang kamu masukkan kurang tepat. Coba periksa lagi ya.';
        } else if (statusCode == 401) {
          return backendMessage ??
              'Email atau kata sandi tidak sesuai. Silakan periksa kembali.';
        } else if (statusCode == 403) {
          return backendMessage ??
              'Maaf, kamu tidak memiliki akses untuk tindakan ini.';
        } else if (statusCode == 404) {
          return backendMessage ?? 'Data yang kamu cari tidak ditemukan.';
        } else if (statusCode != null && statusCode >= 500) {
          return 'Maaf, server kami sedang sibuk atau ada gangguan. Coba beberapa saat lagi ya.';
        }

        return 'Ups, terjadi gangguan sistem. Silakan coba beberapa saat lagi.';

      default:
        return 'Terjadi kesalahan yang tidak terduga. Silakan coba lagi.';
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

  Future<Map<String, dynamic>> submitOnboarding(
    String uid,
    Map<String, dynamic> onboardingData,
  ) async {
    try {
      final response = await _dio.post(
        '/api/users/$uid/onboarding',
        data: onboardingData,
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
}
