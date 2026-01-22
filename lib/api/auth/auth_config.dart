/// API Configuration for Authentication
class AuthConfig {
  /// Base URL for the API
  /// Replace with your actual API base URL
  static const String baseUrl = 'https://levant.twingroups.com';

  /// Login endpoint
  static const String loginEndpoint = '/auth/login/email';

  /// Full login URL
  static String get loginUrl => '$baseUrl$loginEndpoint';

  /// Request timeout in seconds
  static const int requestTimeout = 30;
}
