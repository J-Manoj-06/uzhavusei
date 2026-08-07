import '../models/book_model.dart';
import '../repositories/search_repository.dart';
import 'recently_viewed_service.dart';
import 'search_history_service.dart';

class SearchRecommendationService {
  SearchRecommendationService._();
  static final SearchRecommendationService instance = SearchRecommendationService._();

  final SearchRepository _repository = SearchRepository.instance;

  /// Returns rule-based personalized book recommendations based on user history
  Future<List<BookModel>> getPersonalizedRecommendations({int limit = 10}) async {
    try {
      final allBooks = await _repository.fetchBooks();
      if (allBooks.isEmpty) return [];

      final recentSearches = await SearchHistoryService.instance.getRecentSearches();
      final recentlyViewed = await RecentlyViewedService.instance.getRecentlyViewed();

      final searchKeywords = recentSearches.map((e) => e.toLowerCase()).toList();
      final viewedCategories = recentlyViewed.map((e) => (e['category'] ?? '').toString().toLowerCase()).toSet();

      if (searchKeywords.isEmpty && viewedCategories.isEmpty) {
        return allBooks.take(limit).toList();
      }

      final scored = <BookModel, double>{};

      for (final book in allBooks) {
        double score = 0.0;
        final title = book.title.toLowerCase();
        final cat = book.category.toLowerCase();
        final dept = book.department.toLowerCase();

        for (final kw in searchKeywords) {
          if (title.contains(kw)) score += 3.0;
          if (cat.contains(kw) || dept.contains(kw)) score += 2.0;
        }

        if (viewedCategories.contains(cat)) {
          score += 2.5;
        }

        if (score > 0) {
          scored[book] = score;
        }
      }

      if (scored.isEmpty) {
        return allBooks.take(limit).toList();
      }

      final list = scored.keys.toList();
      list.sort((a, b) => scored[b]!.compareTo(scored[a]!));
      return list.take(limit).toList();
    } catch (_) {
      return [];
    }
  }
}
