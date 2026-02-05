import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../api/auth/auth_config.dart';
import 'models/chat_models.dart';

class ChatService {
  static String get baseUrl => AuthConfig.baseUrl;

  static Future<Map<String, String>> _headers({bool jsonContent = true}) async {
    final headers = <String, String>{
      'Accept': 'application/json',
      'ngrok-skip-browser-warning': 'true',
      'User-Agent': 'LevantSaleFlutter/1.0',
    };
    if (jsonContent) headers['Content-Type'] = 'application/json';
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

  static Future<List<ConversationApi>> fetchConversations({
    int page = 0,
    int size = 20,
  }) async {
    final url = Uri.parse(
      '$baseUrl/api/v1/chat/conversations?page=$page&size=$size',
    );
    final h = await _headers();
    final res = await http.get(url, headers: h);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final data = jsonDecode(res.body);
      final List list = (data is Map && data['content'] is List)
          ? data['content']
          : (data as List);
      return list
          .map((e) => ConversationApi.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Failed to fetch conversations (${res.statusCode})');
  }

  /// Get or create a conversation with another user
  static Future<ConversationApi?> getOrCreateConversation(
    String otherUserId,
  ) async {
    final url = Uri.parse(
      '$baseUrl/api/v1/chat/conversations/get-or-create?otherUserId=$otherUserId',
    );
    final h = await _headers();
    final res = await http.post(url, headers: h);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final data = jsonDecode(res.body);
      return ConversationApi.fromJson(data as Map<String, dynamic>);
    }
    return null;
  }

  static Future<List<ChatMessageApi>> fetchMessages(
    String otherUserId, {
    int page = 0,
    int size = 50,
  }) async {
    final url = Uri.parse(
      '$baseUrl/api/v1/chat/messages/$otherUserId?page=$page&size=$size',
    );
    final h = await _headers();
    final res = await http.get(url, headers: h);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final data = jsonDecode(res.body);
      final List list = (data is Map && data['content'] is List)
          ? data['content']
          : (data as List);
      return list
          .map((e) => ChatMessageApi.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Failed to fetch messages (${res.statusCode})');
  }

  static Future<Map<String, dynamic>> uploadChatFile({
    required String fileName,
    required List<int> bytes,
  }) async {
    final url = Uri.parse('$baseUrl/api/v1/chat/upload');
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final req = http.MultipartRequest('POST', url);
    if (token != null && token.isNotEmpty) {
      req.headers['Authorization'] = token.startsWith('Bearer')
          ? token
          : 'Bearer $token';
    }
    req.files.add(
      http.MultipartFile.fromBytes('file', bytes, filename: fileName),
    );
    final streamed = await req.send();
    final res = await http.Response.fromStream(streamed);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    throw Exception('File upload failed (${res.statusCode})');
  }

  /// Delete message for current user only
  static Future<bool> deleteMessageForMe(String messageId) async {
    final url = Uri.parse('$baseUrl/api/v1/chat/messages/$messageId/me');
    final h = await _headers();
    final res = await http.delete(url, headers: h);
    return res.statusCode >= 200 && res.statusCode < 300;
  }

  /// Delete message for everyone
  static Future<bool> deleteMessageForEveryone(String messageId) async {
    final url = Uri.parse('$baseUrl/api/v1/chat/messages/$messageId/everyone');
    final h = await _headers();
    final res = await http.delete(url, headers: h);
    return res.statusCode >= 200 && res.statusCode < 300;
  }

  /// Fetch user details including phone
  static Future<Map<String, dynamic>?> fetchUserDetails(String userId) async {
    final url = Uri.parse('$baseUrl/api/v1/users/$userId');
    final h = await _headers();
    final res = await http.get(url, headers: h);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    return null;
  }

  /// Fetch listing details for ad context
  static Future<ChatAdData?> fetchListingDetails(String listingId) async {
    final url = Uri.parse('$baseUrl/api/v1/listings/$listingId');
    final h = await _headers();
    final res = await http.get(url, headers: h);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return ChatAdData.fromJson(data);
    }
    return null;
  }

  /// Report a user
  static Future<bool> reportUser({
    required String userId,
    required String reason,
    String? comment,
    String? listingId,
    bool blockUser = false,
  }) async {
    final url = Uri.parse('$baseUrl/api/v1/reports');
    final h = await _headers();
    final body = jsonEncode({
      'reportedUserId': userId,
      'reason': reason,
      'comment': comment,
      'listingId': listingId,
      'blockUser': blockUser,
    });
    final res = await http.post(url, headers: h, body: body);
    return res.statusCode >= 200 && res.statusCode < 300;
  }

  static Future<String?> getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null || token.isEmpty) return null;
      // Return raw JWT without Bearer prefix
      return token.startsWith('Bearer ') ? token.substring(7) : token;
    } catch (_) {
      return null;
    }
  }

  static Future<String?> getCurrentUserId() async {
    final raw = await getToken();
    if (raw == null) return null;
    try {
      final parts = raw.split('.');
      if (parts.length != 3) return null;
      final normalized = base64Url.normalize(parts[1]);
      final decoded = utf8.decode(base64Url.decode(normalized));
      final payload = jsonDecode(decoded) as Map<String, dynamic>;
      final value = payload['userId'] ?? payload['id'] ?? payload['sub'];
      return value?.toString();
    } catch (_) {
      return null;
    }
  }
}
