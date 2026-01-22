import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../api/auth/auth_config.dart';

class CreateAdService {
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

  static Future<List<Map<String, dynamic>>> fetchCategories() async {
    try {
      final url = Uri.parse('$baseUrl/api/v1/categories');
      final res = await http.get(url, headers: await _headers());
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final body = jsonDecode(res.body);
        if (body is List) return body.cast<Map<String, dynamic>>();
        if (body is Map && body['data'] is List) {
          return (body['data'] as List).cast<Map<String, dynamic>>();
        }
      }
      return <Map<String, dynamic>>[];
    } catch (_) {
      return <Map<String, dynamic>>[];
    }
  }

  // Finds a reasonable default subcategory id (cars) if the UI doesn't provide one.
  static Future<String?> getDefaultSubcategoryId() async {
    try {
      final url = Uri.parse('$baseUrl/api/v1/categories');
      final res = await http.get(url, headers: await _headers());
      if (res.statusCode < 200 || res.statusCode >= 300) return null;
      final List<dynamic> data = jsonDecode(res.body) as List<dynamic>;
      // Build simple parent->children map
      final List<Map<String, dynamic>> cats = data.cast<Map<String, dynamic>>();
      final children = <String, List<Map<String, dynamic>>>{};
      for (final c in cats) {
        final pid = c['parentId']?.toString();
        if (pid != null && pid.isNotEmpty) {
          children.putIfAbsent(pid, () => []).add(c);
        }
      }
      // Find a root category that looks like Cars
      Map<String, dynamic>? carsRoot;
      for (final c in cats) {
        final name = (c['name'] ?? '').toString().toLowerCase();
        final nameAr = (c['nameAr'] ?? '').toString();
        final isRoot = c['parentId'] == null;
        if (!isRoot) continue;
        if (name.contains('car') ||
            nameAr.contains('سي') ||
            nameAr.contains('سيارات')) {
          carsRoot = c;
          break;
        }
      }
      // Return first child of cars root, else first leaf
      if (carsRoot != null) {
        final kids = children[(carsRoot['id'] ?? '').toString()];
        if (kids != null && kids.isNotEmpty)
          return (kids.first['id'] ?? '').toString();
      }
      // Fallback: first leaf (no children)
      for (final c in cats) {
        final id = (c['id'] ?? '').toString();
        if ((children[id] ?? []).isEmpty) return id;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<http.Response> createListing({
    required Map<String, dynamic> data,
    List<File> images = const [],
  }) async {
    final url = Uri.parse('$baseUrl/api/v1/listings');
    final req = http.MultipartRequest('POST', url);
    req.headers.addAll(await _headers());
    // Send JSON payload under 'data' field to mirror Next.js
    req.fields['data'] = jsonEncode(data);
    for (final f in images) {
      final bytes = await f.readAsBytes();
      req.files.add(
        http.MultipartFile.fromBytes(
          'images',
          bytes,
          filename: f.path.split('/').last.split('\\').last,
        ),
      );
    }
    final resp = await http.Response.fromStream(await req.send());
    return resp;
  }

  static Future<http.Response> updateListing({
    required String id,
    required Map<String, dynamic> data,
    List<File> images = const [],
  }) async {
    final url = Uri.parse('$baseUrl/api/v1/listings/$id');
    final req = http.MultipartRequest('PUT', url);
    req.headers.addAll(await _headers());
    req.fields['data'] = jsonEncode(data);
    for (final f in images) {
      final bytes = await f.readAsBytes();
      req.files.add(
        http.MultipartFile.fromBytes(
          'images',
          bytes,
          filename: f.path.split('/').last.split('\\').last,
        ),
      );
    }
    final resp = await http.Response.fromStream(await req.send());
    return resp;
  }

  static Future<List<Map<String, dynamic>>> fetchAttributes(
    String categoryId,
  ) async {
    final url = Uri.parse('$baseUrl/api/v1/categories/$categoryId/attributes');
    final res = await http.get(url, headers: await _headers());
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final body = jsonDecode(res.body);
      if (body is List) return body.cast<Map<String, dynamic>>();
      if (body is Map && body['data'] is List)
        return (body['data'] as List).cast<Map<String, dynamic>>();
      return <Map<String, dynamic>>[];
    } else {
      return <Map<String, dynamic>>[];
    }
  }
}
