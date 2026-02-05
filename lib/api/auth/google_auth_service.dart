import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_config.dart';

/// Google OAuth Configuration and Service
/// Mirrors the web app's Google login implementation
class GoogleAuthService {
  // Google Client ID - same as web app
  static const String googleClientId =
      '353128895794-f99rqndb19crc9j43irspgvqb46sfnc8.apps.googleusercontent.com';

  // Google Sign-In instance
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: googleClientId,
    scopes: ['email', 'profile'],
  );

  /// Sign in with Google and authenticate with backend
  /// Returns authentication result from backend
  static Future<Map<String, dynamic>> signInWithGoogle() async {
    try {
      // Trigger Google Sign-In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // User cancelled the sign-in
        return {
          'success': false,
          'message': 'Google sign-in was cancelled',
          'cancelled': true,
        };
      }

      // Get authentication details
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final String? idToken = googleAuth.idToken;

      if (idToken == null) {
        return {
          'success': false,
          'message': 'Failed to get Google authentication token',
        };
      }

      // Send to backend - same payload structure as web app
      final result = await _sendToBackend(
        idToken: idToken,
        name: googleUser.displayName ?? '',
        email: googleUser.email,
        googleId: googleUser.id,
        profilePicture: googleUser.photoUrl,
      );

      return result;
    } catch (e) {
      print('Google sign-in error: $e');
      return {
        'success': false,
        'message': 'Google sign-in failed: $e',
      };
    }
  }

  /// Send Google login data to backend
  /// Matches the web app's loginWithGoogle function
  static Future<Map<String, dynamic>> _sendToBackend({
    required String idToken,
    required String name,
    required String email,
    required String googleId,
    String? profilePicture,
  }) async {
    try {
      final url = Uri.parse('${AuthConfig.baseUrl}/auth/google');

      final payload = {
        'idToken': idToken,
        'name': name,
        'email': email,
        'googleId': googleId,
        'profilePicture': profilePicture,
      };

      print('Sending Google login to: $url');

      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(payload),
          )
          .timeout(
            const Duration(seconds: AuthConfig.requestTimeout),
            onTimeout: () => throw TimeoutException('Request timeout'),
          );

      print('Google login response status: ${response.statusCode}');
      print('Google login response body: ${response.body}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);

        // Save auth tokens - same as web app
        await _saveAuthData(data);

        return {
          'success': true,
          'data': data,
          'id': data['id'] ?? data['userId'],
          'name': data['name'] ?? name,
          'email': data['email'] ?? email,
          'avatar': data['avatar'] ?? data['profilePicture'] ?? profilePicture,
          'token': data['token'],
          'refreshToken': data['refreshToken'],
          'role': data['role'],
          'verified': data['verified'],
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Google login failed',
        };
      }
    } on TimeoutException {
      return {
        'success': false,
        'message': 'Connection timeout. Please try again.',
      };
    } catch (e) {
      print('Google backend error: $e');
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  /// Save authentication data to SharedPreferences
  static Future<void> _saveAuthData(Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      if (data['token'] != null) {
        await prefs.setString('token', data['token']);
      }
      if (data['refreshToken'] != null) {
        await prefs.setString('refreshToken', data['refreshToken']);
      }
      if (data['name'] != null) {
        await prefs.setString('name', data['name']);
      }
      if (data['id'] != null) {
        await prefs.setString('id', data['id'].toString());
      }
      if (data['userId'] != null) {
        await prefs.setString('id', data['userId'].toString());
      }
      if (data['email'] != null) {
        await prefs.setString('email', data['email']);
      }
      if (data['avatar'] != null || data['profilePicture'] != null) {
        await prefs.setString(
            'avatar', data['avatar'] ?? data['profilePicture']);
      }
      if (data['role'] != null) {
        await prefs.setString('role', data['role']);
      }
    } catch (e) {
      print('Error saving auth data: $e');
    }
  }

  /// Sign out from Google
  static Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (e) {
      print('Google sign-out error: $e');
    }
  }

  /// Check if user is currently signed in with Google
  static Future<bool> isSignedIn() async {
    return await _googleSignIn.isSignedIn();
  }

  /// Get current Google user
  static GoogleSignInAccount? get currentUser => _googleSignIn.currentUser;
}

/// Custom exception for timeout
class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);

  @override
  String toString() => message;
}
