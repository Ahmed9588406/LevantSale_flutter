import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../api/auth/auth_config.dart';

class VerificationService {
  static String get baseUrl => AuthConfig.baseUrl;

  static Future<Map<String, String>> _authHeaders() async {
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

  static Future<bool> submitVerification({
    required String fullName,
    required String aboutYou,
    required String gender,
    required String phoneNumber,
    required File nationalIdFront,
    required File nationalIdBack,
    required File facePhoto,
  }) async {
    final uri = Uri.parse('$baseUrl/api/v1/verification/submit');
    final req = http.MultipartRequest('POST', uri);
    req.fields['fullName'] = fullName;
    req.fields['aboutYou'] = aboutYou;
    req.fields['gender'] = gender; // MALE or FEMALE
    req.fields['phoneNumber'] = phoneNumber;

    req.files.add(
      await http.MultipartFile.fromPath(
        'nationalIdFront',
        nationalIdFront.path,
      ),
    );
    req.files.add(
      await http.MultipartFile.fromPath('nationalIdBack', nationalIdBack.path),
    );
    req.files.add(
      await http.MultipartFile.fromPath('facePhoto', facePhoto.path),
    );

    req.headers.addAll(await _authHeaders());

    final res = await req.send();
    return res.statusCode >= 200 && res.statusCode < 300;
  }
}
