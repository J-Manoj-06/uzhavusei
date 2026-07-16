import 'package:shared_preferences/shared_preferences.dart';

class SearchHistoryManager {
  static const String _key = 'recent_searches';

  static Future<List<String>> getRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_key) ?? [];
  }

  static Future<void> addSearch(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getStringList(_key) ?? [];

    current.remove(trimmed);
    current.insert(0, trimmed);

    if (current.length > 10) {
      current.removeLast();
    }
    await prefs.setStringList(_key, current);
  }

  static Future<void> deleteSearch(String query) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getStringList(_key) ?? [];
    current.remove(query);
    await prefs.setStringList(_key, current);
  }

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
