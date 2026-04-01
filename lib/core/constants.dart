class AppConstants {
  AppConstants._();

  static const cacheValidity = Duration(milliseconds: 30000);
  static const pageSize = 10;
  static const defaultSpoolmanUrl = 'http://192.168.1.';
  static const connectTimeout = Duration(milliseconds: 3000);
  static const readTimeout = Duration(milliseconds: 5000);
  static const tagCacheDuration = Duration(seconds: 5);
}
