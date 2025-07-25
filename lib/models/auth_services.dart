import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static Future<void> saveUserSession(
    String username,
    int userId,
    String role,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('username', username);
    prefs.setInt('user_id', userId);
    prefs.setString('role', role);
  }

  static Future<String?> getLoggedInUser() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('username');
  }

  static Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('user_id');
  }

  static Future<String?> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('role');
  }
}
