import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lungs_assistant_agent/state/smoke_sync.dart';

class SessionService {
  static const String _keyUid = 'uid';
  static const String _keyName = 'name';
  static const String _keyRole = 'role';
  static const String _keyToken = 'access_token';
  static const String _keyProfileCompleted = 'profile_completed';

  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();

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

  static Future<void> saveSession(
    String uid,
    String name,
    String role, {
    bool? profileCompleted,
    String? token,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUid, uid);
    await prefs.setString(_keyName, name);
    await prefs.setString(_keyRole, role);
    if (profileCompleted != null) {
      await prefs.setBool(_keyProfileCompleted, profileCompleted);
    }
    // Pastikan token sensitif tidak pernah tersimpan di SharedPreferences
    await prefs.remove(_keyToken);
    if (token != null && token.isNotEmpty) {
      await setToken(token);
    }
  }

  /// Membaca JWT token dari FlutterSecureStorage.
  /// Jika ditemukan token lama (legacy) di SharedPreferences, migrasikan secara
  /// aman ke FlutterSecureStorage lalu hapus dari SharedPreferences.
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    String? secureToken;
    try {
      secureToken = await _secureStorage.read(key: _keyToken);
    } catch (_) {
      secureToken = null;
    }

    if (secureToken != null && secureToken.isNotEmpty) {
      if (prefs.containsKey(_keyToken)) {
        await prefs.remove(_keyToken);
      }
      return secureToken;
    }

    final legacyToken = prefs.getString(_keyToken);
    if (legacyToken != null && legacyToken.isNotEmpty) {
      try {
        await _secureStorage.write(key: _keyToken, value: legacyToken);
      } catch (_) {}
      await prefs.remove(_keyToken);
      return legacyToken;
    }

    return null;
  }

  static Future<void> setToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyToken);
    try {
      await _secureStorage.write(key: _keyToken, value: token);
    } catch (_) {}
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

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUid);
    await prefs.remove(_keyName);
    await prefs.remove(_keyRole);
    await prefs.remove(_keyToken);
    await prefs.remove(_keyProfileCompleted);
    try {
      await _secureStorage.delete(key: _keyToken);
    } catch (_) {}
    SmokeSync.instance.reset();
  }
}
