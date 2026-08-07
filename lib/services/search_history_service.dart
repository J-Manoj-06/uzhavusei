import 'package:shared_preferences/shared_preferences.dart';

class SearchHistoryService {
  SearchHistoryService._();
  static final SearchHistoryService instance = SearchHistoryService._();

  static const String _key = 'borrow_recent_searches_v2';

  Future<List<String>> getRecentSearches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getStringList(_key) ?? [];
    } catch (_) {
      return [];
    }
  }

  Future<List<String>> addSearch(String query) async {
    final clean = query.trim();
    if (clean.isEmpty) return getRecentSearches();

    final list = await getRecentSearches();
    list.removeWhere((item) => item.toLowerCase() == clean.toLowerCase());
    list.insert(0, clean);

    if (list.length > 15) {
      list.removeRange(15, list.length);
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_key, list);
    } catch (_) {}

    return list;
  }

  Future<List<String>> removeSearch(String query) async {
    final list = await getRecentSearches();
    list.removeWhere((item) => item.toLowerCase() == query.trim().toLowerCase());

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_key, list);
    } catch (_) {}

    return list;
  }

  Future<void> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key);
    } catch (_) {}
  }
}
