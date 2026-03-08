import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../auth/auth_config.dart';
import 'home_service.dart';

class SearchService {
  static String get baseUrl => AuthConfig.baseUrl;

  static Future<Map<String, String>> _headers() async {
    final headers = <String, String>{
      'Accept': 'application/json',
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

  /// Search listings by query string
  /// Returns a list of Listing objects that match the search criteria
  static Future<List<Listing>> searchListings({
    required String query,
    int page = 0,
    int size = 10,
    String sortBy = 'date_asc',
  }) async {
    try {
      final url = Uri.parse(
        '$baseUrl/api/v1/listings/search?q=$query&page=$page&size=$size&sortBy=$sortBy',
      );
      final h = await _headers();
      final res = await http.get(url, headers: h);

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final Map<String, dynamic> data =
            jsonDecode(res.body) as Map<String, dynamic>;
        final List<dynamic> content = (data['content'] as List?) ?? <dynamic>[];
        return content
            .map((e) => Listing.fromJson(e as Map<String, dynamic>))
            .toList();
      } else if (res.statusCode == 404) {
        // No results found
        return [];
      } else {
        throw Exception('Failed to search listings (${res.statusCode})');
      }
    } catch (e) {
      throw Exception('Error searching listings: $e');
    }
  }
}
