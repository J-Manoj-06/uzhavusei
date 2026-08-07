import 'dart:async';
import 'package:flutter/material.dart';
import '../models/library_activity_model.dart';
import '../services/library_service.dart';
import 'library_filter_provider.dart';

class LibraryProvider extends ChangeNotifier {
  final String uid;

  List<LibraryActivityModel> _rawActivities = [];
  bool _isLoading = true;
  String? _errorMessage;
  StreamSubscription<List<LibraryActivityModel>>? _subscription;
  bool _isDisposed = false;

  LibraryProvider({required this.uid}) {
    _initStream();
  }

  List<LibraryActivityModel> get rawActivities => _rawActivities;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<LibraryActivityModel> getFilteredActivities(LibraryFilterProvider filterProvider) {
    return filterProvider.filterAndSort(_rawActivities);
  }

  void _initStream() {
    _subscription?.cancel();
    _subscription = LibraryService.instance.watchStudentLibraryActivities(uid).listen(
      (data) {
        if (_isDisposed) return;
        _rawActivities = data;
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

  @override
  void dispose() {
    _isDisposed = true;
    _subscription?.cancel();
    super.dispose();
  }
}
