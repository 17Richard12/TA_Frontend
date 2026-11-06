import 'package:shared_preferences/shared_preferences.dart';
import 'package:lungs_assistant_agent/state/smoke_sync.dart';

class SessionService {
  static const String _keyUid = 'uid';
  static const String _keyName = 'name';
  static const String _keyRole = 'role';
  static const String _keyProfileCompleted = 'profile_completed';

  /// Helper untuk memeriksa apakah data profil user sudah lengkap.
  static bool isProfileDataComplete(
    Map<String, dynamic>? userData, {
    String? roleFallback,
  }) {
    final role = (userData?['role']?.toString() ?? roleFallback ?? 'user')
        .trim()
        .toLowerCase();
    // Dokter / master / admin tidak wajib onboarding profil pasien
    if (role == 'dokter' || role == 'doctor' || role == 'master' || role == 'admin') {
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

  // 1. Tambahkan parameter role & profileCompleted pada saveSession
  static Future<void> saveSession(
    String uid,
    String name,
    String role, {
    bool? profileCompleted,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUid, uid);
    await prefs.setString(_keyName, name);
    await prefs.setString(_keyRole, role); // Simpan role
    if (profileCompleted != null) {
      await prefs.setBool(_keyProfileCompleted, profileCompleted);
    }
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

  // Get Role (Gunakan konstanta _keyRole)
  static Future<String?> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyRole);
  }

  // Set Role secara terpisah (Opsional jika dibutuhkan)
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

  // 2. Pastikan role & status profil ikut dihapus saat logout
  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUid);
    await prefs.remove(_keyName);
    await prefs.remove(_keyRole); // Hapus role
    await prefs.remove(_keyProfileCompleted);
    SmokeSync.instance.reset();
  }
}
