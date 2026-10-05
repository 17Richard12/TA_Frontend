import 'package:shared_preferences/shared_preferences.dart';

class SessionService {
  static const String _keyUid = 'uid';
  static const String _keyName = 'name';
  static const String _keyRole = 'role';

  // 1. Tambahkan parameter role pada saveSession
  static Future<void> saveSession(String uid, String name, String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUid, uid);
    await prefs.setString(_keyName, name);
    await prefs.setString(_keyRole, role); // Simpan role
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

  // 2. Pastikan role ikut dihapus saat logout
  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUid);
    await prefs.remove(_keyName);
    await prefs.remove(_keyRole); // Hapus role
  }
}
