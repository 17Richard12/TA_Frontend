import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lungs_assistant_agent/state/smoke_sync.dart';

class SecureSessionStorageException implements Exception {
  final String message;
  const SecureSessionStorageException(this.message);

  @override
  String toString() => message;
}

class SessionService {
  static const String _keyUid = 'uid';
  static const String _keyName = 'name';
  static const String _keyRole = 'role';
  static const String _keyToken = 'access_token';
  static const String _keyProfileCompleted = 'profile_completed';

  static FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  @visibleForTesting
  static void setSecureStorageForTesting(FlutterSecureStorage storage) {
    _secureStorage = storage;
  }

  @visibleForTesting
  static void resetSecureStorageForTesting() {
    _secureStorage = const FlutterSecureStorage();
  }

  /// Helper untuk memeriksa apakah data profil user sudah lengkap.
  static bool isProfileDataComplete(
    Map<String, dynamic>? userData, {
    String? roleFallback,
  }) {
    final role = (userData?['role']?.toString() ?? roleFallback ?? 'user')
        .trim()
        .toLowerCase();
    // Dokter / master / admin tidak wajib onboarding profil pasien
    if (role == 'dokter' ||
        role == 'doctor' ||
        role == 'master' ||
        role == 'admin') {
      return true;
    }
    if (userData == null) return false;
    if (userData['profile_completed'] == true ||
        userData['onboarding_completed'] == true) {
      return true;
    }
    final gender = (userData['gender'] ?? '').toString().trim();
    final bloodType = (userData['bloodType'] ?? '').toString().trim();
    final height = double.tryParse((userData['height'] ?? '0').toString()) ?? 0;
    final weight = double.tryParse((userData['weight'] ?? '0').toString()) ?? 0;
    return gender.isNotEmpty &&
        bloodType.isNotEmpty &&
        height > 0 &&
        weight > 0;
  }

  /// Menyimpan sesi pengguna.
  /// Wajib menyimpan JWT token secara aman terlebih dahulu ke FlutterSecureStorage.
  /// Apabila penyimpanan token gagal atau token kosong, melempar
  /// [SecureSessionStorageException] dan membatalkan penyimpanan sesi.
  static Future<void> saveSession(
    String uid,
    String name,
    String role, {
    bool? profileCompleted,
    String? token,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyToken);

    final cleanedToken = token?.trim() ?? '';
    if (cleanedToken.isEmpty) {
      await clearSession();
      throw const SecureSessionStorageException(
        'Sesi login tidak memiliki token autentikasi yang valid.',
      );
    }

    // Simpan & verifikasi token di secure storage terlebih dahulu.
    // Jika gagal, lempar exception dan jangan simpan sesi di SharedPreferences.
    await setToken(cleanedToken);

    await prefs.setString(_keyUid, uid);
    await prefs.setString(_keyName, name);
    await prefs.setString(_keyRole, role);
    if (profileCompleted != null) {
      await prefs.setBool(_keyProfileCompleted, profileCompleted);
    }
  }

  /// Membaca JWT token dari FlutterSecureStorage.
  /// Jika ditemukan token lama (legacy) di SharedPreferences, migrasikan ke
  /// FlutterSecureStorage dan hapus dari SharedPreferences.
  /// Apabila migrasi ke FlutterSecureStorage gagal, JANGAN pernah mengembalikan
  /// legacy token sebagai berhasil dimigrasikan.
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    String? secureToken;
    try {
      secureToken = await _secureStorage.read(key: _keyToken);
    } catch (_) {
      // Jangan pernah fallback ke pembacaan token plaintext jika secure storage gagal
      if (prefs.containsKey(_keyToken)) {
        await prefs.remove(_keyToken);
      }
      return null;
    }

    if (secureToken != null && secureToken.isNotEmpty) {
      if (prefs.containsKey(_keyToken)) {
        await prefs.remove(_keyToken);
      }
      return secureToken;
    }

    final legacyToken = prefs.getString(_keyToken);
    if (legacyToken != null && legacyToken.isNotEmpty) {
      // Hapus token plaintext dari SharedPreferences terlebih dahulu
      await prefs.remove(_keyToken);
      try {
        await _secureStorage.write(key: _keyToken, value: legacyToken);
        final verified = await _secureStorage.read(key: _keyToken);
        if (verified == legacyToken) {
          return legacyToken;
        }
      } catch (_) {
        // Migrasi gagal: bersihkan sesi dan jangan kembalikan legacyToken
      }
      await clearSession();
      return null;
    }

    return null;
  }

  /// Menyimpan JWT token ke FlutterSecureStorage dan memverifikasi bahwa token
  /// dapat dibaca kembali. Melempar [SecureSessionStorageException] jika gagal.
  static Future<void> setToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyToken);

    final cleaned = token.trim();
    if (cleaned.isEmpty) {
      throw const SecureSessionStorageException(
        'Token autentikasi tidak boleh kosong.',
      );
    }

    try {
      await _secureStorage.write(key: _keyToken, value: cleaned);
      final verified = await _secureStorage.read(key: _keyToken);
      if (verified != cleaned) {
        throw const SecureSessionStorageException(
          'Gagal memverifikasi penyimpanan token keamanan pada perangkat.',
        );
      }
    } on SecureSessionStorageException {
      rethrow;
    } catch (_) {
      throw const SecureSessionStorageException(
        'Gagal menyimpan sesi keamanan pada perangkat. Silakan coba lagi.',
      );
    }
  }

  static Future<Map<String, String>> getAuthHeaders({
    bool jsonContent = true,
  }) async {
    final headers = <String, String>{};
    if (jsonContent) {
      headers['Content-Type'] = 'application/json';
    }
    final token = await getToken();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  // Get Profile Completed
  static Future<bool?> getProfileCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyProfileCompleted);
  }

  // Set Profile Completed
  static Future<void> setProfileCompleted(bool completed) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyProfileCompleted, completed);
  }

  // Get UID
  static Future<String?> getUid() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUid);
  }

  // Get Name
  static Future<String?> getName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyName);
  }

  // Get Role
  static Future<String?> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyRole);
  }

  // Set Role secara terpisah
  static Future<void> setRole(String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyRole, role);
  }

  // Update Name
  static Future<void> updateName(String newName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyName, newName);
  }

  // App Tour / Walkthrough flag per user
  static Future<bool> hasSeenAppTour(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('has_seen_app_tour_$uid') ?? false;
  }

  static Future<void> setAppTourSeen(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_app_tour_$uid', true);
  }

  /// Menghapus seluruh data sesi di SharedPreferences dan FlutterSecureStorage.
  /// Mengembalikan `true` apabila penghapusan di FlutterSecureStorage berhasil,
  /// atau `false` apabila secure storage mengalami kegagalan platform (namun
  /// SharedPreferences dan state memori tetap dibersihkan).
  static Future<bool> clearSession() async {
    var secureDeleted = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyUid);
      await prefs.remove(_keyName);
      await prefs.remove(_keyRole);
      await prefs.remove(_keyToken);
      await prefs.remove(_keyProfileCompleted);
    } finally {
      SmokeSync.instance.reset();
    }

    try {
      await _secureStorage.delete(key: _keyToken);
    } catch (_) {
      try {
        await _secureStorage.deleteAll();
      } catch (_) {
        secureDeleted = false;
      }
    }
    return secureDeleted;
  }
}
