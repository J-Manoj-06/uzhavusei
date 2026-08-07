import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SearchCacheService {
  SearchCacheService._();
  static final SearchCacheService instance = SearchCacheService._();

  static const String _cachePrefix = 'borrow_search_cache_v1_';
  static const String _trendingCacheKey = 'borrow_trending_cache_v1';
  static const Duration _cacheTtl = Duration(hours: 24);

  /// Saves search query results locally with timestamp
  Future<void> cacheQueryResults(String query, List<Map<String, dynamic>> data) async {
    final clean = query.trim().toLowerCase();
    if (clean.isEmpty) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final payload = jsonEncode({
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'data': data,
      });
      await prefs.setString('$_cachePrefix$clean', payload);
    } catch (_) {}
  }

  /// Retrieves cached results if within 24-hour TTL
  Future<List<Map<String, dynamic>>?> getCachedQueryResults(String query) async {
    final clean = query.trim().toLowerCase();
    if (clean.isEmpty) return null;

    try {
      final prefs = await SharedPreferences.getInstance();
      final str = prefs.getString('$_cachePrefix$clean');
      if (str == null) return null;

      final map = jsonDecode(str) as Map<String, dynamic>;
      final ts = map['timestamp'] as int?;
      if (ts == null) return null;

      final cachedTime = DateTime.fromMillisecondsSinceEpoch(ts);
      if (DateTime.now().difference(cachedTime) > _cacheTtl) {
        await prefs.remove('$_cachePrefix$clean');
        return null;
      }

      final list = (map['data'] as List).cast<Map<String, dynamic>>();
      return list;
    } catch (_) {
      return null;
    }
  }

  /// Saves trending books cache
  Future<void> cacheTrendingBooks(List<Map<String, dynamic>> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final payload = jsonEncode({
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'data': data,
      });
      await prefs.setString(_trendingCacheKey, payload);
    } catch (_) {}
  }

  /// Retrieves cached trending books
  Future<List<Map<String, dynamic>>?> getCachedTrendingBooks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final str = prefs.getString(_trendingCacheKey);
      if (str == null) return null;

      final map = jsonDecode(str) as Map<String, dynamic>;
      final ts = map['timestamp'] as int?;
      if (ts == null) return null;

      final cachedTime = DateTime.fromMillisecondsSinceEpoch(ts);
      if (DateTime.now().difference(cachedTime) > _cacheTtl) {
        await prefs.remove(_trendingCacheKey);
        return null;
      }

      final list = (map['data'] as List).cast<Map<String, dynamic>>();
      return list;
    } catch (_) {
      return null;
    }
  }
}
