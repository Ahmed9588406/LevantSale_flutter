import 'package:shared_preferences/shared_preferences.dart';
import '../api/auth/auth_service.dart';

/// Service to manage user session and auto-login functionality
class SessionService {
  // Keys for SharedPreferences
  static const String _keyToken = 'token';
  static const String _keyEmail = 'user_email';
  static const String _keyPassword = 'user_password';
  static const String _keyRememberMe = 'remember_me';
  static const String _keyIsLoggedIn = 'is_logged_in';
  static const String _keyUserName = 'user_name';
  static const String _keyUserPhone = 'user_phone';
  static const String _keyUserId = 'user_id';

  /// Save user session after successful login
  static Future<void> saveSession({
    required String email,
    required String password,
    required String token,
    String? userName,
    String? userPhone,
    String? userId,
    bool rememberMe = true,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_keyToken, token);
    await prefs.setBool(_keyIsLoggedIn, true);

    if (rememberMe) {
      await prefs.setString(_keyEmail, email);
      await prefs.setString(_keyPassword, password);
      await prefs.setBool(_keyRememberMe, true);
    }

    if (userName != null) {
      await prefs.setString(_keyUserName, userName);
    }
    if (userPhone != null) {
      await prefs.setString(_keyUserPhone, userPhone);
    }
    if (userId != null) {
      await prefs.setString(_keyUserId, userId);
    }
  }

  /// Check if user has a valid session
  static Future<bool> hasValidSession() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool(_keyIsLoggedIn) ?? false;
    final token = prefs.getString(_keyToken);
    final email = prefs.getString(_keyEmail);
    final password = prefs.getString(_keyPassword);

    return isLoggedIn &&
        token != null &&
        token.isNotEmpty &&
        email != null &&
        email.isNotEmpty &&
        password != null &&
        password.isNotEmpty;
  }

  /// Get saved credentials
  static Future<Map<String, String?>> getSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'email': prefs.getString(_keyEmail),
      'password': prefs.getString(_keyPassword),
      'token': prefs.getString(_keyToken),
      'userName': prefs.getString(_keyUserName),
      'userPhone': prefs.getString(_keyUserPhone),
      'userId': prefs.getString(_keyUserId),
    };
  }

  /// Attempt auto-login with saved credentials
  /// Returns true if login was successful, false otherwise
  static Future<Map<String, dynamic>> tryAutoLogin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rememberMe = prefs.getBool(_keyRememberMe) ?? false;

      if (!rememberMe) {
        return {'success': false, 'message': 'Remember me not enabled'};
      }

      final email = prefs.getString(_keyEmail);
      final password = prefs.getString(_keyPassword);

      if (email == null ||
          email.isEmpty ||
          password == null ||
          password.isEmpty) {
        return {'success': false, 'message': 'No saved credentials'};
      }

      // Attempt login with saved credentials
      final result = await AuthService.loginWithEmail(
        email: email,
        password: password,
      );

      if (result['success']) {
        // Update token if login successful
        final data = result['data'] as Map<String, dynamic>?;
        final newToken = data?['token']?.toString();
        if (newToken != null && newToken.isNotEmpty) {
          await prefs.setString(_keyToken, newToken);
        }

        // Update user info if available
        final userName = data?['name']?.toString();
        final userPhone = data?['phone']?.toString();
        final userId = data?['id']?.toString();

        if (userName != null) await prefs.setString(_keyUserName, userName);
        if (userPhone != null) await prefs.setString(_keyUserPhone, userPhone);
        if (userId != null) await prefs.setString(_keyUserId, userId);

        return {
          'success': true,
          'message': 'Auto-login successful',
          'data': data,
        };
      } else {
        // Clear invalid session
        await clearSession();
        return {
          'success': false,
          'message': result['message'] ?? 'Auto-login failed',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Auto-login error: $e'};
    }
  }

  /// Clear user session (logout)
  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyToken);
    await prefs.remove(_keyEmail);
    await prefs.remove(_keyPassword);
    await prefs.remove(_keyRememberMe);
    await prefs.remove(_keyIsLoggedIn);
    await prefs.remove(_keyUserName);
    await prefs.remove(_keyUserPhone);
    await prefs.remove(_keyUserId);
  }

  /// Get current auth token
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyToken);
  }

  /// Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsLoggedIn) ?? false;
  }

  /// Get user info
  static Future<Map<String, String?>> getUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'name': prefs.getString(_keyUserName),
      'email': prefs.getString(_keyEmail),
      'phone': prefs.getString(_keyUserPhone),
      'id': prefs.getString(_keyUserId),
    };
  }

  /// Update just the token (for token refresh)
  static Future<void> updateToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyToken, token);
  }
}
