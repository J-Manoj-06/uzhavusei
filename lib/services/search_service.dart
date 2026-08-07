import 'dart:async';
import '../models/book_model.dart';
import '../models/marketplace_equipment_model.dart';
import '../models/search_result_model.dart';
import '../repositories/search_repository.dart';

class SearchService {
  SearchService._();
  static final SearchService instance = SearchService._();

  final SearchRepository _repository = SearchRepository.instance;

  /// Performs global text search across Books and Equipment collections
  Future<List<SearchResultModel>> search(String query, {int limit = 20}) async {
    final cleanQuery = query.trim().toLowerCase();
    if (cleanQuery.isEmpty) return [];

    final results = <SearchResultModel>[];

    // Fetch from Firestore
    final booksFuture = _repository.fetchBooks();
    final equipmentsFuture = _repository.fetchEquipments();

    final books = await booksFuture;
    final equipments = await equipmentsFuture;

    // 1. Search Books
    for (final book in books) {
      final score = _calculateBookScore(book, cleanQuery);
      if (score > 0) {
        results.add(SearchResultModel.fromBook(book, score));
      }
    }

    // 2. Search Equipment
    for (final equip in equipments) {
      final score = _calculateEquipmentScore(equip, cleanQuery);
      if (score > 0) {
        results.add(SearchResultModel.fromEquipment(equip, score));
      }
    }

    // Rank results by score descending
    results.sort((a, b) => b.relevanceScore.compareTo(a.relevanceScore));

    return results.take(limit).toList();
  }

  /// Calculates relevance score for Book items based on query match type
  double _calculateBookScore(BookModel book, String q) {
    final title = book.title.toLowerCase();
    final author = book.author.toLowerCase();
    final isbn = book.isbn.toLowerCase();
    final category = book.category.toLowerCase();
    final dept = book.department.toLowerCase();
    final desc = book.description.toLowerCase();

    if (title == q) return 100.0;
    if (title.startsWith(q)) return 85.0;
    if (title.contains(q)) return 70.0;
    if (isbn.contains(q) && q.length >= 3) return 65.0;
    if (author.startsWith(q)) return 60.0;
    if (author.contains(q)) return 50.0;
    if (dept.contains(q) || category.contains(q)) return 40.0;
    if (desc.contains(q)) return 20.0;

    return 0.0;
  }

  /// Calculates relevance score for Equipment items based on query match type
  double _calculateEquipmentScore(MarketplaceEquipmentModel equip, String q) {
    final name = equip.equipmentName.toLowerCase();
    final category = equip.category.toLowerCase();
    final owner = equip.ownerName.toLowerCase();
    final desc = equip.description.toLowerCase();

    if (name == q) return 100.0;
    if (name.startsWith(q)) return 85.0;
    if (name.contains(q)) return 70.0;
    if (category.contains(q) || owner.contains(q)) return 45.0;
    if (desc.contains(q)) return 20.0;

    return 0.0;
  }

  /// Public calculateRelevance method for external services
  double calculateRelevance(MarketplaceEquipmentModel equip, String query) {
    return _calculateEquipmentScore(equip, query.trim().toLowerCase());
  }

  /// Fetch real trending books from Firestore sorted by createdAt descending
  Future<List<BookModel>> getTrendingBooks({int limit = 10}) {
    return _repository.fetchTrendingBooks(limit: limit);
  }
}
