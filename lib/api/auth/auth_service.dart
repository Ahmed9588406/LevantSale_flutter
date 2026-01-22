import 'package:http/http.dart' as http;
import 'dart:convert';
import 'auth_config.dart';

class AuthService {
  /// Login with email and password
  static Future<Map<String, dynamic>> loginWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final url = Uri.parse(AuthConfig.loginUrl);

      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(
            const Duration(seconds: AuthConfig.requestTimeout),
            onTimeout: () => throw TimeoutException('Request timeout'),
          );

      return _handleResponse(response);
    } on TimeoutException {
      return {
        'success': false,
        'message': 'Connection timeout. Please try again.',
      };
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  /// Login with phone and password
  static Future<Map<String, dynamic>> loginWithPhone({
    required String phone,
    required String password,
  }) async {
    try {
      final url = Uri.parse('${AuthConfig.baseUrl}/auth/login/phone');

      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({'phone': phone, 'password': password}),
          )
          .timeout(
            const Duration(seconds: AuthConfig.requestTimeout),
            onTimeout: () => throw TimeoutException('Request timeout'),
          );

      return _handleResponse(response);
    } on TimeoutException {
      return {
        'success': false,
        'message': 'Connection timeout. Please try again.',
      };
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  /// Register new user
  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String phone,
    String role = 'USER',
  }) async {
    try {
      final url = Uri.parse('${AuthConfig.baseUrl}/auth/register');

      print('Registering user: $name, $email, $phone');
      print('URL: $url');

      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'name': name,
              'email': email,
              'password': password,
              'phone': phone,
              'role': role,
            }),
          )
          .timeout(
            const Duration(seconds: AuthConfig.requestTimeout),
            onTimeout: () => throw TimeoutException('Request timeout'),
          );

      print('Register response status: ${response.statusCode}');
      print('Register response body: ${response.body}');

      return _handleResponse(response);
    } on TimeoutException {
      return {
        'success': false,
        'message': 'Connection timeout. Please try again.',
      };
    } catch (e) {
      print('Error in register: $e');
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  /// Activate account with OTP
  static Future<Map<String, dynamic>> activateAccount({
    required String email,
    required String otp,
  }) async {
    try {
      final url = Uri.parse('${AuthConfig.baseUrl}/auth/activate');

      print('Activating account for: $email with OTP: $otp');
      print('URL: $url');

      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({'email': email, 'otp': otp}),
          )
          .timeout(
            const Duration(seconds: AuthConfig.requestTimeout),
            onTimeout: () => throw TimeoutException('Request timeout'),
          );

      print('Activate response status: ${response.statusCode}');
      print('Activate response body: ${response.body}');

      return _handleResponse(response);
    } on TimeoutException {
      return {
        'success': false,
        'message': 'Connection timeout. Please try again.',
      };
    } catch (e) {
      print('Error in activateAccount: $e');
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  /// Resend OTP
  static Future<Map<String, dynamic>> resendOtp({required String email}) async {
    try {
      final url = Uri.parse('${AuthConfig.baseUrl}/auth/resend-otp');

      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({'email': email}),
          )
          .timeout(
            const Duration(seconds: AuthConfig.requestTimeout),
            onTimeout: () => throw TimeoutException('Request timeout'),
          );

      return _handleResponse(response);
    } on TimeoutException {
      return {
        'success': false,
        'message': 'Connection timeout. Please try again.',
      };
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  /// Request password reset (sends OTP)
  static Future<Map<String, dynamic>> requestPasswordReset({
    required String email,
  }) async {
    try {
      final url = Uri.parse('${AuthConfig.baseUrl}/auth/forgot-password');

      print('Requesting password reset for: $email');
      print('URL: $url');

      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({'email': email}),
          )
          .timeout(
            const Duration(seconds: AuthConfig.requestTimeout),
            onTimeout: () => throw TimeoutException('Request timeout'),
          );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      return _handleResponse(response);
    } on TimeoutException {
      return {
        'success': false,
        'message': 'Connection timeout. Please try again.',
      };
    } catch (e) {
      print('Error in requestPasswordReset: $e');
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  /// Verify reset password OTP
  static Future<Map<String, dynamic>> verifyResetOtp({
    required String email,
    required String otp,
  }) async {
    try {
      final url = Uri.parse('${AuthConfig.baseUrl}/auth/verify-reset-otp');

      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({'email': email, 'otp': otp}),
          )
          .timeout(
            const Duration(seconds: AuthConfig.requestTimeout),
            onTimeout: () => throw TimeoutException('Request timeout'),
          );

      return _handleResponse(response);
    } on TimeoutException {
      return {
        'success': false,
        'message': 'Connection timeout. Please try again.',
      };
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  /// Reset password with OTP
  static Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    try {
      final url = Uri.parse('${AuthConfig.baseUrl}/auth/reset-password');

      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'email': email,
              'otp': otp,
              'newPassword': newPassword,
            }),
          )
          .timeout(
            const Duration(seconds: AuthConfig.requestTimeout),
            onTimeout: () => throw TimeoutException('Request timeout'),
          );

      return _handleResponse(response);
    } on TimeoutException {
      return {
        'success': false,
        'message': 'Connection timeout. Please try again.',
      };
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  /// Handle HTTP response
  static Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode == 200 || response.statusCode == 201) {
      try {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data, 'message': 'Operation successful'};
      } catch (e) {
        // Handle plain text response
        return {
          'success': true,
          'data': {'message': response.body},
          'message': response.body,
        };
      }
    } else if (response.statusCode == 401) {
      return {'success': false, 'message': 'Invalid credentials'};
    } else if (response.statusCode == 400) {
      try {
        final data = jsonDecode(response.body);
        return {'success': false, 'message': data['message'] ?? 'Bad request'};
      } catch (e) {
        return {'success': false, 'message': response.body};
      }
    } else if (response.statusCode == 409) {
      return {'success': false, 'message': 'Email or phone already exists'};
    } else {
      return {
        'success': false,
        'message': 'Server error: ${response.statusCode}',
      };
    }
  }
}

class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);

  @override
  String toString() => message;
}
