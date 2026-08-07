import 'package:flutter/material.dart';
import '../models/search_filter_model.dart';
import '../models/search_result_model.dart';
import '../services/search_sort_service.dart';

class SearchFilterProvider extends ChangeNotifier {
  SearchFilterModel _filter = SearchFilterModel.initial;

  SearchFilterModel get filter => _filter;
  bool get hasActiveFilters => _filter.hasActiveFilters;

  void setMainCategory(String category) {
    _filter = _filter.copyWith(
      mainCategory: category,
      bookCategory: category == 'Books' ? _filter.bookCategory : 'All',
      department: category == 'Books' ? _filter.department : 'All',
    );
    notifyListeners();
  }

  void setBookCategory(String bookCategory) {
    _filter = _filter.copyWith(bookCategory: bookCategory);
    notifyListeners();
  }

  void setDepartment(String department) {
    _filter = _filter.copyWith(department: department);
    notifyListeners();
  }

  void setAvailability(String availability) {
    _filter = _filter.copyWith(availability: availability);
    notifyListeners();
  }

  void setDistance(double? maxDistanceKm) {
    if (maxDistanceKm == null) {
      _filter = _filter.copyWith(clearDistance: true);
    } else {
      _filter = _filter.copyWith(maxDistanceKm: maxDistanceKm);
    }
    notifyListeners();
  }

  void setSortBy(String sortBy) {
    _filter = _filter.copyWith(sortBy: sortBy);
    notifyListeners();
  }

  void clearAll() {
    _filter = SearchFilterModel.initial;
    notifyListeners();
  }

  List<SearchResultModel> applyFilters(List<SearchResultModel> rawResults) {
    return SearchSortService.instance.applyFiltersAndSort(rawResults, _filter);
  }
}
