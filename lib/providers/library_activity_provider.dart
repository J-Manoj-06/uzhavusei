import 'dart:async';
import 'package:flutter/material.dart';
import '../models/library_activity_model.dart';
import '../services/library_activity_service.dart';

enum ActivityFilterOption {
  all,
  pending,
  approved,
  borrowed,
  returned,
  rejected,
  cancelled,
}

enum ActivitySortOrder {
  newestFirst,
  oldestFirst,
}

class LibraryActivityProvider extends ChangeNotifier {
  final String uid;

  List<LibraryActivityModel> _allActivities = [];
  ActivityFilterOption _filter = ActivityFilterOption.all;
  ActivitySortOrder _sortOrder = ActivitySortOrder.newestFirst;
  bool _isLoading = true;
  String? _errorMessage;
  StreamSubscription<List<LibraryActivityModel>>? _subscription;
  bool _isDisposed = false;

  LibraryActivityProvider({required this.uid}) {
    _initStream();
  }

  List<LibraryActivityModel> get allActivities => _allActivities;
  ActivityFilterOption get filter => _filter;
  ActivitySortOrder get sortOrder => _sortOrder;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Returns locally filtered and sorted activities
  List<LibraryActivityModel> get filteredActivities {
    List<LibraryActivityModel> list = _allActivities.where((item) {
      switch (_filter) {
        case ActivityFilterOption.pending:
          return item.activityType == LibraryActivityType.pendingRequest;
        case ActivityFilterOption.approved:
          return item.activityType == LibraryActivityType.approvedRequest;
        case ActivityFilterOption.borrowed:
          return item.activityType == LibraryActivityType.issuedBook;
        case ActivityFilterOption.returned:
          return item.activityType == LibraryActivityType.returnedBook;
        case ActivityFilterOption.rejected:
          return item.activityType == LibraryActivityType.rejectedRequest;
        case ActivityFilterOption.cancelled:
          return item.activityType == LibraryActivityType.cancelledRequest;
        case ActivityFilterOption.all:
          return true;
      }
    }).toList();

    if (_sortOrder == ActivitySortOrder.newestFirst) {
      list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    } else {
      list.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    }

    return list;
  }

  void _initStream() {
    _subscription?.cancel();
    _subscription = LibraryActivityService.instance.watchStudentActivities(uid).listen(
      (data) {
        if (_isDisposed) return;
        _allActivities = data;
        _isLoading = false;
        _errorMessage = null;
        notifyListeners();
      },
      onError: (err) {
        if (_isDisposed) return;
        _isLoading = false;
        _errorMessage = err.toString();
        notifyListeners();
      },
    );
  }

  void setFilter(ActivityFilterOption option) {
    _filter = option;
    if (!_isDisposed) notifyListeners();
  }

  void setSortOrder(ActivitySortOrder order) {
    _sortOrder = order;
    if (!_isDisposed) notifyListeners();
  }

  void resetFilters() {
    _filter = ActivityFilterOption.all;
    _sortOrder = ActivitySortOrder.newestFirst;
    if (!_isDisposed) notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _subscription?.cancel();
    super.dispose();
  }
}
