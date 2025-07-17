// lib/utils/recent_search_helper.dart

import 'package:shared_preferences/shared_preferences.dart';

class RecentSearchHelper {
  static const String _key = 'recent_search_queries';
  static const int _maxRecentSearches = 10;

  static Future<void> addSearchQuery(String query) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> recent = prefs.getStringList(_key) ?? [];

    // 중복 제거 후 맨 앞에 추가
    recent.remove(query);
    recent.insert(0, query);

    // 최대 개수 제한
    if (recent.length > _maxRecentSearches) {
      recent = recent.sublist(0, _maxRecentSearches);
    }

    await prefs.setStringList(_key, recent);
  }

  static Future<List<String>> getRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_key) ?? [];
  }

  static Future<void> clearRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
