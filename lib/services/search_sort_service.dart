import '../models/search_filter_model.dart';
import '../models/search_result_model.dart';

class SearchSortService {
  SearchSortService._();
  static final SearchSortService instance = SearchSortService._();

  /// Applies local in-memory filtering and sorting over SearchResultModel items
  List<SearchResultModel> applyFiltersAndSort(
    List<SearchResultModel> results,
    SearchFilterModel filter,
  ) {
    var filtered = results.where((item) {
      // 1. Main Category Filter
      if (filter.mainCategory != 'All') {
        if (filter.mainCategory == 'Books' && item.type != SearchResultType.book) {
          return false;
        }
        if ((filter.mainCategory == 'Farm Equipment' || filter.mainCategory == 'Construction Equipment') &&
            item.type != SearchResultType.equipment) {
          return false;
        }
      }

      // 2. Book Specific Filters
      if (item.type == SearchResultType.book && item.book != null) {
        final book = item.book!;

        // Sub category filter
        if (filter.bookCategory != 'All') {
          final catMatch = book.category.toLowerCase().contains(filter.bookCategory.toLowerCase());
          if (!catMatch) return false;
        }

        // Department filter
        if (filter.department != 'All') {
          final deptMatch = book.department.toLowerCase().contains(filter.department.toLowerCase());
          if (!deptMatch) return false;
        }

        // Availability filter for books
        if (filter.availability != 'All') {
          if (filter.availability == 'Available' && book.availableCopies <= 0) return false;
          if (filter.availability == 'Borrowed' && book.availableCopies > 0) return false;
          if (filter.availability == 'Unavailable' && book.availableCopies > 0) return false;
        }
      }

      // 3. Equipment Specific Filters
      if (item.type == SearchResultType.equipment && item.equipment != null) {
        final equip = item.equipment!;

        // Availability filter for equipment
        if (filter.availability != 'All') {
          if (filter.availability == 'Available' && !equip.availability) return false;
          if (filter.availability == 'Unavailable' && equip.availability) return false;
          if (filter.availability == 'Borrowed' && equip.availability) return false;
        }
      }

      return true;
    }).toList();

    // Sort Results
    _sortList(filtered, filter.sortBy);

    return filtered;
  }

  void _sortList(List<SearchResultModel> list, String sortBy) {
    switch (sortBy) {
      case 'Oldest':
        list.sort((a, b) {
          final dateA = a.book?.createdAt ?? a.equipment?.createdAt ?? DateTime(2000);
          final dateB = b.book?.createdAt ?? b.equipment?.createdAt ?? DateTime(2000);
          return dateA.compareTo(dateB);
        });
        break;
      case 'A-Z':
        list.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
        break;
      case 'Z-A':
        list.sort((a, b) => b.title.toLowerCase().compareTo(a.title.toLowerCase()));
        break;
      case 'Most Borrowed':
        list.sort((a, b) {
          final copiesA = a.book?.totalCopies ?? 0;
          final copiesB = b.book?.totalCopies ?? 0;
          return copiesB.compareTo(copiesA);
        });
        break;
      case 'Newest':
      case 'Recently Added':
      default:
        list.sort((a, b) {
          final dateA = a.book?.createdAt ?? a.equipment?.createdAt ?? DateTime(2000);
          final dateB = b.book?.createdAt ?? b.equipment?.createdAt ?? DateTime(2000);
          return dateB.compareTo(dateA);
        });
        break;
    }
  }
}
