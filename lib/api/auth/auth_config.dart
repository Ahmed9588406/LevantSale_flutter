import 'package:flutter_dotenv/flutter_dotenv.dart';

/// API Configuration for Authentication
class AuthConfig {
  /// Base URL for the API
  /// Reads from .env file, falls back to default if not set
  static String get baseUrl =>
      dotenv.env['BASE_URL'] ?? 'https://api.levantsale.com';

  /// Login endpoint
  static const String loginEndpoint = '/auth/login/email';

  /// Full login URL
  static String get loginUrl => '$baseUrl$loginEndpoint';

  /// Request timeout in seconds
  static const int requestTimeout = 30;
}
