import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/auth/auth_config.dart';
import 'ad_form_model.dart';

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

  /// Fetch all categories from backend and transform to tree structure
  static Future<List<CategoryModel>> fetchCategoriesTree() async {
    try {
      final url = Uri.parse('$baseUrl/api/v1/categories');
      final res = await http.get(url, headers: await _headers());
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final List<dynamic> rawList = jsonDecode(res.body) is List
            ? jsonDecode(res.body)
            : (jsonDecode(res.body)['data'] ?? []);

        // Build nodes map
        final Map<String, CategoryModel> nodeMap = {};
        for (final c in rawList) {
          final node = CategoryModel.fromJson(c as Map<String, dynamic>);
          nodeMap[node.id] = node;
        }

        // Attach children to parents and collect roots
        final List<CategoryModel> roots = [];
        for (final entry in rawList) {
          final c = entry as Map<String, dynamic>;
          final id = c['id']?.toString() ?? '';
          final parentId = c['parentId']?.toString();

          if (parentId != null &&
              parentId.isNotEmpty &&
              nodeMap.containsKey(parentId)) {
            final parent = nodeMap[parentId]!;
            final child = nodeMap[id]!;
            nodeMap[parentId] = parent.copyWith(
              subcategories: [...parent.subcategories, child],
            );
          } else if (parentId == null || parentId.isEmpty) {
            final node = nodeMap[id];
            if (node != null) roots.add(node);
          }
        }

        // Rebuild roots with their updated subcategories
        final finalRoots = <CategoryModel>[];
        for (final root in roots) {
          finalRoots.add(nodeMap[root.id] ?? root);
        }

        return finalRoots;
      }
      return <CategoryModel>[];
    } catch (e) {
      print('Error fetching categories: $e');
      return <CategoryModel>[];
    }
  }

  /// Fetch flat list of categories (original method for compatibility)
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

  /// Fetch available currencies from backend
  static Future<List<CurrencyModel>> fetchCurrencies() async {
    try {
      final url = Uri.parse('$baseUrl/api/v1/currencies');
      final res = await http.get(url, headers: await _headers());
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final List<dynamic> data = jsonDecode(res.body) is List
            ? jsonDecode(res.body)
            : (jsonDecode(res.body)['data'] ?? []);

        return data
            .map((e) => CurrencyModel.fromJson(e as Map<String, dynamic>))
            .where((c) => c.active)
            .toList();
      }
      return <CurrencyModel>[];
    } catch (e) {
      print('Error fetching currencies: $e');
      return <CurrencyModel>[];
    }
  }

  /// Fetch attributes for a specific category
  static Future<List<AttributeModel>> fetchAttributeModels(
    String categoryId,
  ) async {
    try {
      final url = Uri.parse(
        '$baseUrl/api/v1/categories/$categoryId/attributes',
      );
      final res = await http.get(url, headers: await _headers());
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final List<dynamic> data = jsonDecode(res.body) is List
            ? jsonDecode(res.body)
            : (jsonDecode(res.body)['data'] ?? []);

        return data
            .map((e) => AttributeModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return <AttributeModel>[];
    } catch (e) {
      print('Error fetching attributes: $e');
      return <AttributeModel>[];
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

  /// Create a new listing
  static Future<http.Response> createListing({
    required Map<String, dynamic> data,
    List<File> images = const [],
  }) async {
    final url = Uri.parse('$baseUrl/api/v1/listings');
    final req = http.MultipartRequest('POST', url);
    req.headers.addAll(await _headers());

    // Send JSON payload as a file with content-type application/json
    // This mirrors how the Next.js web app sends data using Blob with type 'application/json'
    final jsonBytes = utf8.encode(jsonEncode(data));
    req.files.add(
      http.MultipartFile.fromBytes(
        'data',
        jsonBytes,
        contentType: MediaType('application', 'json'),
      ),
    );

    for (final f in images) {
      final bytes = await f.readAsBytes();
      final filename = f.path.split('/').last.split('\\').last;
      final mimeType = _getMimeType(filename);
      req.files.add(
        http.MultipartFile.fromBytes(
          'images',
          bytes,
          filename: filename,
          contentType: mimeType,
        ),
      );
    }
    final resp = await http.Response.fromStream(await req.send());
    return resp;
  }

  /// Update an existing listing
  static Future<http.Response> updateListing({
    required String id,
    required Map<String, dynamic> data,
    List<File> images = const [],
  }) async {
    final url = Uri.parse('$baseUrl/api/v1/listings/$id');
    final req = http.MultipartRequest('PUT', url);
    req.headers.addAll(await _headers());

    // Send JSON payload as a file with content-type application/json
    // This mirrors how the Next.js web app sends data using Blob with type 'application/json'
    final jsonBytes = utf8.encode(jsonEncode(data));
    req.files.add(
      http.MultipartFile.fromBytes(
        'data',
        jsonBytes,
        contentType: MediaType('application', 'json'),
      ),
    );

    for (final f in images) {
      final bytes = await f.readAsBytes();
      final filename = f.path.split('/').last.split('\\').last;
      final mimeType = _getMimeType(filename);
      req.files.add(
        http.MultipartFile.fromBytes(
          'images',
          bytes,
          filename: filename,
          contentType: mimeType,
        ),
      );
    }
    final resp = await http.Response.fromStream(await req.send());
    return resp;
  }

  /// Helper to determine MIME type from filename
  static MediaType _getMimeType(String filename) {
    final ext = filename.split('.').last.toLowerCase();
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return MediaType('image', 'jpeg');
      case 'png':
        return MediaType('image', 'png');
      case 'gif':
        return MediaType('image', 'gif');
      case 'webp':
        return MediaType('image', 'webp');
      default:
        return MediaType('application', 'octet-stream');
    }
  }

  /// Fetch a single listing for editing
  static Future<Map<String, dynamic>?> fetchListing(String id) async {
    try {
      final url = Uri.parse('$baseUrl/api/v1/listings/$id');
      final res = await http.get(url, headers: await _headers());
      if (res.statusCode >= 200 && res.statusCode < 300) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('Error fetching listing: $e');
      return null;
    }
  }

  /// Fetch attributes for a category (original method for compatibility)
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
