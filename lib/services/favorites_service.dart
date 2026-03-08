import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../api/auth/auth_config.dart';
import '../api/home/home_service.dart';

/// Service for managing favorites (add/remove listings from favorites)
class FavoritesService {
  static String get baseUrl => AuthConfig.baseUrl;

  /// Get authorization headers with token
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

  /// Check if user is logged in
  static Future<bool> isLoggedIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      return token != null && token.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Add a listing to favorites
  /// Returns a FavoriteResult with success status and message
  static Future<FavoriteResult> addToFavorites(String listingId) async {
    try {
      // Check if user is logged in
      if (!await isLoggedIn()) {
        return FavoriteResult(
          success: false,
          message: 'يجب تسجيل الدخول أولاً',
          errorCode: 'NOT_LOGGED_IN',
        );
      }

      final url = Uri.parse('$baseUrl/api/v1/favorites/$listingId');
      final headers = await _headers();

      final response = await http.post(url, headers: headers);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return FavoriteResult(
          success: true,
          message: 'تمت الإضافة إلى المفضلة',
          isFavorite: true,
        );
      } else if (response.statusCode == 401) {
        return FavoriteResult(
          success: false,
          message: 'جلسة منتهية، يرجى تسجيل الدخول مرة أخرى',
          errorCode: 'UNAUTHORIZED',
        );
      } else if (response.statusCode == 409) {
        // Already favorited
        return FavoriteResult(
          success: true,
          message: 'الإعلان موجود بالفعل في المفضلة',
          isFavorite: true,
        );
      } else {
        final body = _parseErrorBody(response.body);
        return FavoriteResult(
          success: false,
          message: body ?? 'فشل إضافة الإعلان إلى المفضلة',
          errorCode: 'API_ERROR',
        );
      }
    } catch (e) {
      return FavoriteResult(
        success: false,
        message: 'خطأ في الاتصال: ${e.toString()}',
        errorCode: 'NETWORK_ERROR',
      );
    }
  }

  /// Remove a listing from favorites
  /// Returns a FavoriteResult with success status and message
  static Future<FavoriteResult> removeFromFavorites(String listingId) async {
    try {
      // Check if user is logged in
      if (!await isLoggedIn()) {
        return FavoriteResult(
          success: false,
          message: 'يجب تسجيل الدخول أولاً',
          errorCode: 'NOT_LOGGED_IN',
        );
      }

      final url = Uri.parse('$baseUrl/api/v1/favorites/$listingId');
      final headers = await _headers();

      final response = await http.delete(url, headers: headers);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return FavoriteResult(
          success: true,
          message: 'تمت الإزالة من المفضلة',
          isFavorite: false,
        );
      } else if (response.statusCode == 401) {
        return FavoriteResult(
          success: false,
          message: 'جلسة منتهية، يرجى تسجيل الدخول مرة أخرى',
          errorCode: 'UNAUTHORIZED',
        );
      } else if (response.statusCode == 404) {
        // Not in favorites - treat as success
        return FavoriteResult(
          success: true,
          message: 'الإعلان غير موجود في المفضلة',
          isFavorite: false,
        );
      } else {
        final body = _parseErrorBody(response.body);
        return FavoriteResult(
          success: false,
          message: body ?? 'فشل إزالة الإعلان من المفضلة',
          errorCode: 'API_ERROR',
        );
      }
    } catch (e) {
      return FavoriteResult(
        success: false,
        message: 'خطأ في الاتصال: ${e.toString()}',
        errorCode: 'NETWORK_ERROR',
      );
    }
  }

  /// Toggle favorite status
  /// If currently favorited, remove it. If not, add it.
  static Future<FavoriteResult> toggleFavorite(
    String listingId,
    bool currentlyFavorited,
  ) async {
    if (currentlyFavorited) {
      return await removeFromFavorites(listingId);
    } else {
      return await addToFavorites(listingId);
    }
  }

  /// Check if a specific listing is favorited
  /// Returns true if favorited, false otherwise
  static Future<bool> checkFavoriteStatus(String listingId) async {
    try {
      if (!await isLoggedIn()) {
        return false;
      }

      final url = Uri.parse('$baseUrl/api/v1/favorites/$listingId/check');
      final headers = await _headers();

      final response = await http.get(url, headers: headers);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final dynamic data = jsonDecode(response.body);
        // API might return {isFavorite: true/false} or just true/false
        if (data is bool) {
          return data;
        } else if (data is Map) {
          return data['isFavorite'] == true || data['favorite'] == true;
        }
        return false;
      }
      return false;
    } catch (e) {
      // Silently fail - not critical
      return false;
    }
  }

  /// Fetch user's favorite listings with pagination
  static Future<List<Listing>> fetchFavoriteListings({
    int page = 0,
    int size = 10,
  }) async {
    try {
      if (!await isLoggedIn()) {
        return <Listing>[];
      }

      final url = Uri.parse('$baseUrl/api/v1/favorites?page=$page&size=$size');
      final headers = await _headers();

      final response = await http.get(url, headers: headers);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final dynamic data = jsonDecode(response.body);

        // Handle paginated response
        final List<dynamic> content = data is Map
            ? (data['content'] as List? ?? [])
            : (data as List? ?? []);

        final List<Listing> listings = [];
        for (final item in content) {
          if (item is Map<String, dynamic>) {
            listings.add(Listing.fromJson(item));
          }
        }
        return listings;
      }
      return <Listing>[];
    } catch (e) {
      // Silently fail - not critical
      return <Listing>[];
    }
  }

  /// Fetch list of user's favorite listing IDs
  static Future<Set<String>> fetchFavoriteIds() async {
    try {
      if (!await isLoggedIn()) {
        print('[FavoritesService] User not logged in');
        return <String>{};
      }

      final url = Uri.parse('$baseUrl/api/v1/favorites');
      final headers = await _headers();

      print('[FavoritesService] Fetching favorite IDs from: $url');
      final response = await http.get(url, headers: headers);
      print('[FavoritesService] Response status: ${response.statusCode}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final dynamic data = jsonDecode(response.body);
        print('[FavoritesService] Response data type: ${data.runtimeType}');

        // Handle both paginated and non-paginated responses
        final List<dynamic> list = data is List
            ? data
            : (data['content'] ?? data['data'] ?? data['favorites'] ?? []);

        print('[FavoritesService] Found ${list.length} favorite items');

        final Set<String> ids = {};
        for (final item in list) {
          if (item is Map) {
            // Could be {listingId: ...} or {id: ...} or full listing object
            final id = item['listingId'] ?? item['id'] ?? '';
            if (id.toString().isNotEmpty) {
              ids.add(id.toString());
            }
          } else if (item is String) {
            ids.add(item);
          }
        }

        print(
          '[FavoritesService] Total favorite IDs: ${ids.length} - IDs: $ids',
        );
        return ids;
      }

      print('[FavoritesService] Failed with status: ${response.statusCode}');
      return <String>{};
    } catch (e) {
      print('[FavoritesService] Error fetching favorite IDs: $e');
      return <String>{};
    }
  }

  /// Parse error message from response body
  static String? _parseErrorBody(String body) {
    try {
      final json = jsonDecode(body);
      return json['message']?.toString() ?? json['error']?.toString();
    } catch (_) {
      return null;
    }
  }
}

/// Result of a favorite operation
class FavoriteResult {
  final bool success;
  final String message;
  final String? errorCode;
  final bool? isFavorite;

  FavoriteResult({
    required this.success,
    required this.message,
    this.errorCode,
    this.isFavorite,
  });
}
