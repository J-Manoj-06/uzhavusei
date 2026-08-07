import 'dart:async';
import 'package:flutter/material.dart';
import '../models/book_model.dart';
import '../models/search_result_model.dart';
import '../services/search_analytics_service.dart';
import '../services/search_history_service.dart';
import '../services/search_pagination_service.dart';
import '../services/search_service.dart';
import '../services/search_suggestion_service.dart';

class SearchProvider extends ChangeNotifier {
  String _searchQuery = '';
  List<SearchResultModel> _masterSearchResults = [];
  final SearchPaginationService _paginationService = SearchPaginationService();

  List<BookModel> _trendingBooks = [];
  List<String> _recentSearches = [];
  String? _didYouMean;
  bool _isSearching = false;
  bool _isLoadingTrending = true;
  String? _errorMessage;

  Timer? _debounceTimer;
  bool _isDisposed = false;

  SearchProvider() {
    _loadRecentSearches();
    _loadTrendingBooks();
  }

  String get searchQuery => _searchQuery;
  List<SearchResultModel> get searchResults => _paginationService.paginatedResults;
  List<SearchResultModel> get masterSearchResults => _masterSearchResults;
  List<BookModel> get trendingBooks => _trendingBooks;
  List<String> get recentSearches => _recentSearches;
  List<String> get popularSearches => _recentSearches.take(5).toList();
  String? get didYouMean => _didYouMean;
  bool get isSearching => _isSearching;
  bool get isLoadingTrending => _isLoadingTrending;
  bool get hasMore => _paginationService.hasMore;
  bool get isLoadingMore => _paginationService.isLoadingMore;
  String? get errorMessage => _errorMessage;

  void onQueryChanged(String query) {
    _searchQuery = query;
    _errorMessage = null;
    _didYouMean = null;

    if (_debounceTimer?.isActive ?? false) {
      _debounceTimer!.cancel();
    }

    if (query.trim().isEmpty) {
      _masterSearchResults = [];
      _paginationService.reset();
      _isSearching = false;
      notifyListeners();
      return;
    }

    _isSearching = true;
    notifyListeners();

    // 300ms Debounce Timer
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _executeSearch(query);
    });
  }

  Future<void> loadMore() async {
    if (_paginationService.hasMore && !_paginationService.isLoadingMore) {
      _paginationService.loadNextBatch();
      notifyListeners();
    }
  }

  Future<void> refreshCurrentSearch() async {
    if (_searchQuery.trim().isNotEmpty) {
      await _executeSearch(_searchQuery);
    }
  }

  Future<void> _executeSearch(String query) async {
    final clean = query.trim();
    if (clean.isEmpty) return;

    try {
      final results = await SearchService.instance.search(clean);
      if (_isDisposed) return;

      if (_searchQuery.trim() == clean) {
        _masterSearchResults = results;
        _paginationService.initialize(results, pageSize: 20);

        _isSearching = false;
        _errorMessage = null;

        if (results.isNotEmpty) {
          addRecentSearch(clean);
          SearchAnalyticsService.instance.logSearchQuery(clean);
          _didYouMean = null;
        } else {
          final correction = await SearchSuggestionService.instance.findTypoCorrection(clean);
          if (!_isDisposed && _searchQuery.trim() == clean) {
            _didYouMean = correction;
          }
        }
        notifyListeners();
      }
    } catch (err) {
      if (_isDisposed) return;
      _isSearching = false;
      _errorMessage = 'Unable to complete search. Please check internet connection.';
      notifyListeners();
    }
  }

  Future<void> _loadRecentSearches() async {
    final list = await SearchHistoryService.instance.getRecentSearches();
    if (!_isDisposed) {
      _recentSearches = list;
      notifyListeners();
    }
  }

  Future<void> addRecentSearch(String query) async {
    final list = await SearchHistoryService.instance.addSearch(query);
    if (!_isDisposed) {
      _recentSearches = list;
      notifyListeners();
    }
  }

  Future<void> removeRecentSearch(String query) async {
    final list = await SearchHistoryService.instance.removeSearch(query);
    if (!_isDisposed) {
      _recentSearches = list;
      notifyListeners();
    }
  }

  Future<void> clearRecentSearches() async {
    await SearchHistoryService.instance.clearAll();
    if (!_isDisposed) {
      _recentSearches = [];
      notifyListeners();
    }
  }

  Future<void> _loadTrendingBooks() async {
    try {
      final books = await SearchService.instance.getTrendingBooks(limit: 10);
      if (!_isDisposed) {
        _trendingBooks = books;
        _isLoadingTrending = false;
        notifyListeners();
      }
    } catch (_) {
      if (!_isDisposed) {
        _isLoadingTrending = false;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _debounceTimer?.cancel();
    _paginationService.reset();
    super.dispose();
  }
}
