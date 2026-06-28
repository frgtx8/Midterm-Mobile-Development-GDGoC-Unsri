/// API and app-wide constants for MyDompet.
class ApiConstants {
  ApiConstants._();

  // Auth endpoints
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String refreshToken = '/auth/refresh';
  static const String logout = '/auth/logout';
  static const String profile = '/auth/profile';

  // Transaction endpoints
  static const String transactions = '/transactions';
  static const String transactionSummary = '/transactions/summary';

  // Category endpoints
  static const String categories = '/categories';

  // Health check
  static const String health = '/health';
}

class AppConstants {
  AppConstants._();

  static const String appName = 'MyDompet';
  static const String currencySymbol = 'Rp';
  static const String currencyLocale = 'id_ID';
  static const int connectionTimeout = 15000; // ms
  static const int receiveTimeout = 15000; // ms
}

class StorageKeys {
  StorageKeys._();

  static const String accessToken = 'access_token';
  static const String refreshToken = 'refresh_token';
  static const String userId = 'user_id';
  static const String userName = 'user_name';
  static const String userEmail = 'user_email';
  static const String themeMode = 'theme_mode';
  static const String isOfflineMode = 'is_offline_mode';
}
