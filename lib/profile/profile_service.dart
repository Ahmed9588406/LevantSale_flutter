import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../api/auth/auth_config.dart';

class ProfileService {
  static String get baseUrl => AuthConfig.baseUrl;

  static Future<Map<String, String>> _headers() async {
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'ngrok-skip-browser-warning': 'true',
      'User-Agent': 'PostmanRuntime/7.32.2',
    };
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = token.startsWith('Bearer')
            ? token
            : 'Bearer $token';
      }
    } catch (_) {}
    return headers;
  }

  static Future<Map<String, dynamic>?> fetchProfile() async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/api/v1/users/profile'),
        headers: await _headers(),
      );
      if (res.statusCode >= 200 && res.statusCode < 300) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<Map<String, dynamic>?> updateProfile(
    Map<String, dynamic> data,
  ) async {
    try {
      final res = await http.put(
        Uri.parse('$baseUrl/api/v1/users/profile'),
        headers: await _headers(),
        body: jsonEncode(data),
      );
      if (res.statusCode >= 200 && res.statusCode < 300) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<bool> updatePhone(String phone) async {
    try {
      final res = await http.put(
        Uri.parse('$baseUrl/api/v1/users/profile/phone'),
        headers: await _headers(),
        body: jsonEncode({'phone': phone}),
      );
      return res.statusCode >= 200 && res.statusCode < 300;
    } catch (_) {
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> fetchUserListingsByStatus(
    String status,
  ) async {
    try {
      final url = Uri.parse(
        '$baseUrl/api/v1/listings/my-listings-by-status?status=$status&page=0&size=100&sort=desc',
      );
      final res = await http.get(url, headers: await _headers());
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final body = jsonDecode(res.body);
        if (body is Map && body['content'] is List) {
          return (body['content'] as List).cast<Map<String, dynamic>>();
        }
        if (body is List) return body.cast<Map<String, dynamic>>();
      }
      return <Map<String, dynamic>>[];
    } catch (_) {
      return <Map<String, dynamic>>[];
    }
  }

  static Future<bool> deleteListing(String id) async {
    try {
      final res = await http.delete(
        Uri.parse('$baseUrl/api/v1/listings/$id'),
        headers: await _headers(),
      );
      return res.statusCode >= 200 && res.statusCode < 300;
    } catch (_) {
      return false;
    }
  }

  static Future<Map<String, dynamic>?> fetchVerificationStatus() async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/api/v1/verification/my-status'),
        headers: await _headers(),
      );
      if (res.statusCode == 404) return null;
      if (res.statusCode >= 200 && res.statusCode < 300) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>> fetchFeatureRequests() async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/api/v1/feature-requests/my-requests'),
        headers: await _headers(),
      );
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final body = jsonDecode(res.body);
        if (body is List) return body.cast<Map<String, dynamic>>();
        if (body is Map && body['content'] is List) {
          return (body['content'] as List).cast<Map<String, dynamic>>();
        }
      }
      return <Map<String, dynamic>>[];
    } catch (_) {
      return <Map<String, dynamic>>[];
    }
  }

  static Future<bool> createFeatureRequest({
    required String listingId,
    required int durationWeeks,
    required String contactDetails,
    required String message,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/v1/feature-requests'),
        headers: await _headers(),
        body: jsonEncode({
          'listingId': listingId,
          'durationWeeks': durationWeeks,
          'contactDetails': contactDetails,
          'message': message,
        }),
      );
      return res.statusCode >= 200 && res.statusCode < 300;
    } catch (_) {
      return false;
    }
  }

  static Future<Map<String, dynamic>?> fetchListingById(String id) async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/api/v1/listings/$id'),
        headers: await _headers(),
      );
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final body = jsonDecode(res.body);
        if (body is Map<String, dynamic>) return body;
        if (body is Map && body['data'] is Map<String, dynamic>) {
          return body['data'] as Map<String, dynamic>;
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
