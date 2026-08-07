import 'package:cloud_firestore/cloud_firestore.dart';

class SearchAnalyticsService {
  SearchAnalyticsService._();
  static final SearchAnalyticsService instance = SearchAnalyticsService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  int _totalSearches = 0;
  int _cacheHits = 0;

  int get totalSearches => _totalSearches;
  int get cacheHits => _cacheHits;
  double get cacheHitRate => _totalSearches == 0 ? 0.0 : (_cacheHits / _totalSearches) * 100;

  void recordCacheHit() {
    _totalSearches++;
    _cacheHits++;
  }

  /// Log search metrics (query, results count, duration, source) to Firestore
  Future<void> logSearchQuery(
    String query, {
    String category = 'All',
    int resultCount = 0,
    int durationMs = 0,
    String source = 'text', // 'text' or 'voice'
  }) async {
    final clean = query.trim().toLowerCase();
    if (clean.length < 2) return;
    _totalSearches++;

    try {
      final docRef = _firestore.collection('search_analytics').doc(clean);
      await docRef.set({
        'keyword': query.trim(),
        'keywordLower': clean,
        'searchCount': FieldValue.increment(1),
        'lastSearchedAt': FieldValue.serverTimestamp(),
        'category': category,
        'lastResultCount': resultCount,
        'lastDurationMs': durationMs,
        'lastSource': source,
      }, SetOptions(merge: true));
    } catch (_) {}
  }
}
