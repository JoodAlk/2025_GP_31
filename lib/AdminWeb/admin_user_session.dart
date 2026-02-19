import 'package:shared_preferences/shared_preferences.dart';

class AdminUserSession {
  // Save data to session
  static Future<void> saveSession({
    required String dbKey,
    required String id,
    required String name,
    required String email,
    required String phone,
    String? permissionKey,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('admin_db_key', dbKey);
    await prefs.setString('admin_id', id);
    await prefs.setString('admin_name', name);
    await prefs.setString('admin_email', email);
    await prefs.setString('admin_phone', phone);
    
    if (permissionKey != null && permissionKey.isNotEmpty) {
      await prefs.setString('admin_permission', permissionKey);
    } else {
      await prefs.remove('admin_permission'); // Remove if it doesn't exist
    }
  }

  // Retrieve data from session
  static Future<Map<String, String?>> getSession() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'dbKey': prefs.getString('admin_db_key'),
      'id': prefs.getString('admin_id'),
      'name': prefs.getString('admin_name'),
      'email': prefs.getString('admin_email'),
      'phone': prefs.getString('admin_phone'),
      'permissionKey': prefs.getString('admin_permission'),
    };
  }

  // Clear session on logout
  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
