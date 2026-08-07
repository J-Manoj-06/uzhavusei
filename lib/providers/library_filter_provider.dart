import 'package:flutter/material.dart';
import '../models/library_activity_model.dart';

enum LibraryStatusFilter {
  all,
  pending,
  approved,
  borrowed,
  returned,
  rejected,
  cancelled,
}

enum LibrarySortOption {
  newestFirst,
  oldestFirst,
  titleAZ,
  titleZA,
}

class LibraryFilterProvider extends ChangeNotifier {
  LibraryStatusFilter _statusFilter = LibraryStatusFilter.all;
  LibrarySortOption _sortOption = LibrarySortOption.newestFirst;
  String _searchQuery = '';

  LibraryStatusFilter get statusFilter => _statusFilter;
  LibrarySortOption get sortOption => _sortOption;
  String get searchQuery => _searchQuery;

  void setStatusFilter(LibraryStatusFilter filter) {
    _statusFilter = filter;
    notifyListeners();
  }

  void setSortOption(LibrarySortOption option) {
    _sortOption = option;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query.trim().toLowerCase();
    notifyListeners();
  }

  void resetFilters() {
    _statusFilter = LibraryStatusFilter.all;
    _sortOption = LibrarySortOption.newestFirst;
    _searchQuery = '';
    notifyListeners();
  }

  /// Performs local in-memory filtering and sorting on raw activity list
  List<LibraryActivityModel> filterAndSort(List<LibraryActivityModel> rawList) {
    List<LibraryActivityModel> result = rawList.where((item) {
      // 1. Status Filter
      if (_statusFilter != LibraryStatusFilter.all) {
        switch (_statusFilter) {
          case LibraryStatusFilter.pending:
            if (item.status != LibraryActivityStatus.pending) return false;
            break;
          case LibraryStatusFilter.approved:
            if (item.status != LibraryActivityStatus.approved) return false;
            break;
          case LibraryStatusFilter.borrowed:
            if (item.status != LibraryActivityStatus.borrowed) return false;
            break;
          case LibraryStatusFilter.returned:
            if (item.status != LibraryActivityStatus.returned) return false;
            break;
          case LibraryStatusFilter.rejected:
            if (item.status != LibraryActivityStatus.rejected) return false;
            break;
          case LibraryStatusFilter.cancelled:
            if (item.status != LibraryActivityStatus.cancelled) return false;
            break;
          case LibraryStatusFilter.all:
            break;
        }
      }

      // 2. Search Query (Book Title, Author, Status)
      if (_searchQuery.isNotEmpty) {
        final title = item.bookTitle.toLowerCase();
        final author = item.author.toLowerCase();
        final statusLabel = item.statusLabel.toLowerCase();
        final stage = item.stageMessage.toLowerCase();
        final matches = title.contains(_searchQuery) ||
            author.contains(_searchQuery) ||
            statusLabel.contains(_searchQuery) ||
            stage.contains(_searchQuery);
        if (!matches) return false;
      }

      return true;
    }).toList();

    // 3. Sorting
    switch (_sortOption) {
      case LibrarySortOption.newestFirst:
        result.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        break;
      case LibrarySortOption.oldestFirst:
        result.sort((a, b) => a.updatedAt.compareTo(b.updatedAt));
        break;
      case LibrarySortOption.titleAZ:
        result.sort((a, b) => a.bookTitle.toLowerCase().compareTo(b.bookTitle.toLowerCase()));
        break;
      case LibrarySortOption.titleZA:
        result.sort((a, b) => b.bookTitle.toLowerCase().compareTo(a.bookTitle.toLowerCase()));
        break;
    }

    return result;
  }
}
