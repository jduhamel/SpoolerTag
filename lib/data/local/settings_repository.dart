import 'package:shared_preferences/shared_preferences.dart';
import 'package:spooler_tag/core/constants.dart';

class SettingsRepository {
  static const _keySpoolmanUrl = 'spoolman_url';
  static const _keySortOrder = 'spoolman_sort';
  static const _keyProviderType = 'provider_type';

  Future<String> getSpoolmanUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keySpoolmanUrl) ?? AppConstants.defaultSpoolmanUrl;
  }

  Future<void> setSpoolmanUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keySpoolmanUrl, url);
  }

  Future<String?> getSortOrder() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keySortOrder);
  }

  Future<void> setSortOrder(String? sort) async {
    final prefs = await SharedPreferences.getInstance();
    if (sort == null) {
      await prefs.remove(_keySortOrder);
    } else {
      await prefs.setString(_keySortOrder, sort);
    }
  }

  Future<String> getProviderType() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyProviderType) ?? 'spoolman';
  }

  Future<void> setProviderType(String type) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyProviderType, type);
  }
}
