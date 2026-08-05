import 'package:shared_preferences/shared_preferences.dart';

class SessionService {
  static const String _keyUid = 'uid';
  static const String _keyName = 'name';

  // Save session
  static Future<void> saveSession(String uid, String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUid, uid);
    await prefs.setString(_keyName, name);
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

  // Update Name
  static Future<void> updateName(String newName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyName, newName);
  }

  // Clear session (Logout)
  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUid);
    await prefs.remove(_keyName);
  }
}
