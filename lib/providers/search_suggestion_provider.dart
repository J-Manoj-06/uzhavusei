import 'dart:async';
import 'package:flutter/material.dart';
import '../services/search_suggestion_service.dart';

class SearchSuggestionProvider extends ChangeNotifier {
  List<String> _suggestions = [];
  String? _didYouMean;
  bool _isLoading = false;
  Timer? _debounceTimer;

  List<String> get suggestions => _suggestions;
  String? get didYouMean => _didYouMean;
  bool get isLoading => _isLoading;

  void onQueryChanged(String query) {
    _debounceTimer?.cancel();

    if (query.trim().isEmpty) {
      _suggestions = [];
      _didYouMean = null;
      _isLoading = false;
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    _debounceTimer = Timer(const Duration(milliseconds: 250), () async {
      final results = await SearchSuggestionService.instance.getSuggestions(query);
      _suggestions = results;
      _isLoading = false;
      notifyListeners();
    });
  }

  Future<void> checkForTypoCorrection(String query) async {
    final correction = await SearchSuggestionService.instance.findTypoCorrection(query);
    _didYouMean = correction;
    notifyListeners();
  }

  void clearSuggestions() {
    _suggestions = [];
    _didYouMean = null;
    notifyListeners();
  }
}
