import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/search_result_model.dart';

class RecentlyViewedService {
  RecentlyViewedService._();
  static final RecentlyViewedService instance = RecentlyViewedService._();

  static const String _key = 'borrow_recently_viewed_v1';

  /// Saves a viewed item (Book or Equipment) into recent history (max 20)
  Future<void> addRecentlyViewed(SearchResultModel item) async {
    try {
      final list = await getRecentlyViewed();
      list.removeWhere((x) => x['id'] == item.id);

      final map = {
        'id': item.id,
        'type': item.type == SearchResultType.book ? 'book' : 'equipment',
        'title': item.title,
        'category': item.category,
        'imageUrl': item.imageUrl,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

      final prefs = await SharedPreferences.getInstance();
      final strList = prefs.getStringList(_key) ?? [];

      final updatedList = <String>[jsonEncode(map)];
      for (final raw in strList) {
        try {
          final decoded = jsonDecode(raw) as Map<String, dynamic>;
          if (decoded['id'] != item.id) {
            updatedList.add(raw);
          }
        } catch (_) {}
      }

      if (updatedList.length > 20) {
        updatedList.removeRange(20, updatedList.length);
      }

      await prefs.setStringList(_key, updatedList);
    } catch (_) {}
  }

  /// Retrieves up to 20 recently viewed items
  Future<List<Map<String, dynamic>>> getRecentlyViewed() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final strList = prefs.getStringList(_key) ?? [];
      final result = <Map<String, dynamic>>[];

      for (final raw in strList) {
        try {
          final decoded = jsonDecode(raw) as Map<String, dynamic>;
          result.add(decoded);
        } catch (_) {}
      }

      return result;
    } catch (_) {
      return [];
    }
  }

  Future<void> clearRecentlyViewed() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key);
    } catch (_) {}
  }
}
