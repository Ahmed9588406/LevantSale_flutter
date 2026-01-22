import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../auth/auth_config.dart';

class ApiCategory {
  final String id;
  final String name;
  final String? parentId;
  final String? parentName;
  final String? imageUrl;
  final String? iconUrl;
  final String? createdAt;

  ApiCategory({
    required this.id,
    required this.name,
    this.parentId,
    this.parentName,
    this.imageUrl,
    this.iconUrl,
    this.createdAt,
  });

  factory ApiCategory.fromJson(Map<String, dynamic> json) {
    return ApiCategory(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      parentId: json['parentId']?.toString(),
      parentName: json['parentName']?.toString(),
      imageUrl: json['imageUrl']?.toString(),
      iconUrl: json['iconUrl']?.toString(),
      createdAt: json['createdAt']?.toString(),
    );
  }
}

class ListingCurrency {
  final String code;
  final String symbol;
  final String name;

  ListingCurrency({
    required this.code,
    required this.symbol,
    required this.name,
  });

  factory ListingCurrency.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return ListingCurrency(code: '', symbol: '', name: '');
    }
    return ListingCurrency(
      code: (json['code'] ?? '').toString(),
      symbol: (json['symbol'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
    );
  }
}

class ListingAttribute {
  final String attributeName;
  final String valueString;

  ListingAttribute({required this.attributeName, required this.valueString});

  factory ListingAttribute.fromJson(Map<String, dynamic> json) {
    return ListingAttribute(
      attributeName: (json['attributeName'] ?? '').toString(),
      valueString: (json['valueString'] ?? '').toString(),
    );
  }
}

class Listing {
  final String id;
  final String title;
  final String description;
  final double price;
  final ListingCurrency currency;
  final String location;
  final List<String> imageUrls;
  final String createdAt;
  final String categoryName;
  final String categoryId;
  final String userName;
  final String? userPhone;
  final String? condition;
  final bool? isFeatured;
  final List<ListingAttribute>? attributes;

  Listing({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.currency,
    required this.location,
    required this.imageUrls,
    required this.createdAt,
    required this.categoryName,
    required this.categoryId,
    required this.userName,
    this.userPhone,
    this.condition,
    this.isFeatured,
    this.attributes,
  });

  factory Listing.fromJson(Map<String, dynamic> json) {
    final imgs =
        (json['imageUrls'] as List?)?.map((e) => e.toString()).toList() ??
        <String>[];
    final attrsRaw = json['attributes'] as List?;
    final attrs = attrsRaw
        ?.whereType<Map<String, dynamic>>()
        .map((e) => ListingAttribute.fromJson(e))
        .toList();
    return Listing(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      price: (json['price'] is num)
          ? (json['price'] as num).toDouble()
          : double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
      currency: ListingCurrency.fromJson(
        json['currency'] as Map<String, dynamic>?,
      ),
      location: (json['location'] ?? '').toString(),
      imageUrls: imgs,
      createdAt: (json['createdAt'] ?? '').toString(),
      categoryName: (json['categoryName'] ?? '').toString(),
      categoryId: (json['categoryId'] ?? '').toString(),
      userName: (json['userName'] ?? '').toString(),
      userPhone: json['userPhone']?.toString(),
      condition: json['condition']?.toString(),
      isFeatured: json['isFeatured'] as bool?,
      attributes: attrs,
    );
  }
}

class HomeService {
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

  static Future<List<ApiCategory>> fetchCategories() async {
    final url = Uri.parse('$baseUrl/api/v1/categories');
    final h = await _headers();
    final res = await http.get(url, headers: h);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final List<dynamic> arr = jsonDecode(res.body) as List<dynamic>;
      return arr
          .map((e) => ApiCategory.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception('Failed to fetch categories (${res.statusCode})');
    }
  }

  static Future<List<Listing>> fetchListings({
    int page = 0,
    int size = 100,
    String sortBy = 'date_desc',
  }) async {
    final url = Uri.parse(
      '$baseUrl/api/v1/listings?page=$page&size=$size&sortBy=$sortBy',
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
    } else {
      throw Exception('Failed to fetch listings (${res.statusCode})');
    }
  }

  static Future<Listing> fetchListingById(String id) async {
    final url = Uri.parse('$baseUrl/api/v1/listings/$id');
    final h = await _headers();
    final res = await http.get(url, headers: h);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final Map<String, dynamic> data =
          jsonDecode(res.body) as Map<String, dynamic>;
      return Listing.fromJson(data);
    } else {
      throw Exception('Failed to fetch listing (${res.statusCode})');
    }
  }

  static Future<List<Listing>> fetchSimilarListings({
    required String categoryId,
    String? excludeId,
    int limit = 5,
  }) async {
    final queryParams = <String, String>{
      'limit': limit.toString(),
    };
    if (excludeId != null && excludeId.isNotEmpty) {
      queryParams['exclude'] = excludeId;
    }
    final url = Uri.parse(
      '$baseUrl/api/v1/listings/similar/$categoryId',
    ).replace(queryParameters: queryParams);
    final h = await _headers();
    final res = await http.get(url, headers: h);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final List<dynamic> data = jsonDecode(res.body) as List<dynamic>;
      return data
          .map((e) => Listing.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception('Failed to fetch similar listings (${res.statusCode})');
    }
  }
}
