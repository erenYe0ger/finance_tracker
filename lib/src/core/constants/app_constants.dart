/// Application-wide constants
class AppConstants {
  AppConstants._();

  /// Base URL for the FastAPI backend
  /// Configure via --dart-define=API_BASE_URL=http://YOUR_IP:8000
  /// For Android emulator: http://10.0.2.2:8000
  /// For real device on same network: http://`PC_LAN_IP`:8000
  /// For real device on mobile hotspot: http://`PC_HOTSPOT_IP`:8000
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000', // Default works for Android emulator
  );

  /// API version prefix
  static const String apiVersion = '/api/v1';

  /// Full API base path
  static String get apiBasePath => '$apiBaseUrl$apiVersion';

  /// Auth endpoints
  static const String registerEndpoint = '/auth/register';
  static const String loginEndpoint = '/auth/login';
  static const String refreshEndpoint = '/auth/refresh';
  static const String logoutEndpoint = '/auth/logout';
  static const String meEndpoint = '/auth/me';
  static const String healthEndpoint = '/health';

  /// Secure storage keys
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userIdKey = 'user_id';
  static const String userEmailKey = 'user_email';

  /// Token buffer time (seconds) before expiry to trigger refresh
  static const int tokenRefreshBufferSeconds = 60;

  /// Default page size for pagination
  static const int defaultPageSize = 20;

  /// Currency settings
  static const String currencyCode = 'INR';
  static const String currencySymbol = '₹';
  static const String currencyLocale = 'en_IN';

  /// App metadata
  static const String appName = 'Finance Tracker';
  static const String appVersion = '1.0.0';
}