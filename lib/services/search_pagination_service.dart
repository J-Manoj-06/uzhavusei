import '../models/search_result_model.dart';

class SearchPaginationService {
  List<SearchResultModel> _allMasterResults = [];
  List<SearchResultModel> _paginatedResults = [];
  int _currentIndex = 0;
  bool _hasMore = false;
  bool _isLoadingMore = false;

  List<SearchResultModel> get paginatedResults => List.unmodifiable(_paginatedResults);
  bool get hasMore => _hasMore;
  bool get isLoadingMore => _isLoadingMore;

  void initialize(List<SearchResultModel> masterResults, {int pageSize = 20}) {
    _allMasterResults = masterResults;
    _paginatedResults = [];
    _currentIndex = 0;
    _isLoadingMore = false;

    loadNextBatch(pageSize: pageSize);
  }

  bool loadNextBatch({int pageSize = 20}) {
    if (_currentIndex >= _allMasterResults.length) {
      _hasMore = false;
      return false;
    }

    _isLoadingMore = true;
    final nextEnd = (_currentIndex + pageSize < _allMasterResults.length)
        ? _currentIndex + pageSize
        : _allMasterResults.length;

    final newBatch = _allMasterResults.sublist(_currentIndex, nextEnd);

    // Deduplicate against existing items by ID
    final existingIds = _paginatedResults.map((e) => e.id).toSet();
    for (final item in newBatch) {
      if (!existingIds.contains(item.id)) {
        _paginatedResults.add(item);
        existingIds.add(item.id);
      }
    }

    _currentIndex = nextEnd;
    _hasMore = _currentIndex < _allMasterResults.length;
    _isLoadingMore = false;
    return true;
  }

  void reset() {
    _allMasterResults = [];
    _paginatedResults = [];
    _currentIndex = 0;
    _hasMore = false;
    _isLoadingMore = false;
  }
}
