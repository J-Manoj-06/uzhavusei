import 'package:flutter/foundation.dart';

class UserGoal {
  final String description;
  final String? category;
  final double? maxDistanceKm;
  final String? searchKeywords;
  final Map<String, dynamic> additionalMetadata;

  UserGoal({
    required this.description,
    this.category,
    this.maxDistanceKm,
    this.searchKeywords,
    this.additionalMetadata = const {},
  });

  UserGoal copyWith({
    String? description,
    String? category,
    double? maxDistanceKm,
    String? searchKeywords,
    Map<String, dynamic>? additionalMetadata,
  }) {
    return UserGoal(
      description: description ?? this.description,
      category: category ?? this.category,
      maxDistanceKm: maxDistanceKm ?? this.maxDistanceKm,
      searchKeywords: searchKeywords ?? this.searchKeywords,
      additionalMetadata: additionalMetadata ?? this.additionalMetadata,
    );
  }
}

class GoalMemoryService extends ChangeNotifier {
  GoalMemoryService._();
  static final GoalMemoryService instance = GoalMemoryService._();

  UserGoal? _activeGoal;

  UserGoal? get activeGoal => _activeGoal;

  bool get hasActiveGoal => _activeGoal != null;

  /// Sets a new user goal.
  void setGoal(UserGoal goal) {
    _activeGoal = goal;
    notifyListeners();
  }

  /// Updates properties on the current active goal.
  void updateGoal({
    String? category,
    double? maxDistanceKm,
    String? searchKeywords,
    Map<String, dynamic>? additionalMetadata,
  }) {
    if (_activeGoal == null) return;
    _activeGoal = _activeGoal!.copyWith(
      category: category,
      maxDistanceKm: maxDistanceKm,
      searchKeywords: searchKeywords,
      additionalMetadata: additionalMetadata != null
          ? {..._activeGoal!.additionalMetadata, ...additionalMetadata}
          : null,
    );
    notifyListeners();
  }

  /// Clears the current goal memory.
  void clearGoal() {
    _activeGoal = null;
    notifyListeners();
  }
}
