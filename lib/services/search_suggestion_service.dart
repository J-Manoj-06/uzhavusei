import 'dart:math';
import '../repositories/search_repository.dart';

class SearchSuggestionService {
  SearchSuggestionService._();
  static final SearchSuggestionService instance = SearchSuggestionService._();

  final SearchRepository _repository = SearchRepository.instance;

  /// Fetches live autocomplete suggestions up to 8 items
  Future<List<String>> getSuggestions(String query, {int limit = 8}) async {
    final cleanQ = query.trim().toLowerCase();
    if (cleanQ.isEmpty) return [];

    final suggestionsSet = <String>{};

    try {
      final books = await _repository.fetchBooks();
      final equipments = await _repository.fetchEquipments();

      // Collect potential titles, authors, categories, departments, ISBNs
      for (final book in books) {
        _checkAndAdd(suggestionsSet, book.title, cleanQ);
        _checkAndAdd(suggestionsSet, book.author, cleanQ);
        _checkAndAdd(suggestionsSet, book.category, cleanQ);
        _checkAndAdd(suggestionsSet, book.department, cleanQ);
        if (book.isbn.isNotEmpty) _checkAndAdd(suggestionsSet, book.isbn, cleanQ);
      }

      for (final equip in equipments) {
        _checkAndAdd(suggestionsSet, equip.equipmentName, cleanQ);
        _checkAndAdd(suggestionsSet, equip.category, cleanQ);
        _checkAndAdd(suggestionsSet, equip.ownerName, cleanQ);
      }
    } catch (_) {}

    final list = suggestionsSet.toList();

    // Sort by Exact Match -> Starts With -> Contains
    list.sort((a, b) {
      final aLower = a.toLowerCase();
      final bLower = b.toLowerCase();

      if (aLower == cleanQ) return -1;
      if (bLower == cleanQ) return 1;

      final aStarts = aLower.startsWith(cleanQ);
      final bStarts = bLower.startsWith(cleanQ);

      if (aStarts && !bStarts) return -1;
      if (!aStarts && bStarts) return 1;

      return aLower.indexOf(cleanQ).compareTo(bLower.indexOf(cleanQ));
    });

    return list.take(limit).toList();
  }

  void _checkAndAdd(Set<String> set, String value, String q) {
    final valTrim = value.trim();
    if (valTrim.isEmpty) return;
    if (valTrim.toLowerCase().contains(q)) {
      set.add(valTrim);
    }
  }

  /// Calculates Levenshtein Distance for typo correction
  int _levenshteinDistance(String s1, String s2) {
    if (s1 == s2) return 0;
    if (s1.isEmpty) return s2.length;
    if (s2.isEmpty) return s1.length;

    List<int> v0 = List<int>.generate(s2.length + 1, (i) => i);
    List<int> v1 = List<int>.filled(s2.length + 1, 0);

    for (int i = 0; i < s1.length; i++) {
      v1[0] = i + 1;
      for (int j = 0; j < s2.length; j++) {
        int cost = (s1[i] == s2[j]) ? 0 : 1;
        v1[j + 1] = min(v1[j] + 1, min(v0[j + 1] + 1, v0[j] + cost));
      }
      for (int j = 0; j < v0.length; j++) {
        v0[j] = v1[j];
      }
    }
    return v1[s2.length];
  }

  /// Finds fuzzy typo correction ("Did you mean...?")
  Future<String?> findTypoCorrection(String query) async {
    final cleanQ = query.trim().toLowerCase();
    if (cleanQ.length < 3) return null;

    final candidates = <String>{};

    try {
      final books = await _repository.fetchBooks();
      final equipments = await _repository.fetchEquipments();

      for (final b in books) {
        candidates.add(b.title);
        candidates.add(b.author);
        candidates.add(b.category);
        candidates.add(b.department);
      }
      for (final e in equipments) {
        candidates.add(e.equipmentName);
        candidates.add(e.category);
      }
    } catch (_) {}

    String? bestMatch;
    int minDistance = 999;

    for (final candidate in candidates) {
      final candLower = candidate.toLowerCase();
      // Check distance against words or full candidate
      final distance = _levenshteinDistance(cleanQ, candLower);
      if (distance > 0 && distance <= 2 && distance < minDistance) {
        minDistance = distance;
        bestMatch = candidate;
      }
    }

    return bestMatch;
  }
}
