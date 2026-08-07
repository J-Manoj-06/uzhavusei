class SearchFilterModel {
  final String mainCategory; // 'All', 'Books', 'Farm Equipment', 'Construction Equipment'
  final String bookCategory; // 'All', 'Academic', 'Programming & Technology', etc.
  final String department; // 'All', 'Computer Science', etc.
  final String availability; // 'All', 'Available', 'Unavailable', 'Borrowed'
  final double? maxDistanceKm; // null for Anywhere, 2.0, 5.0, 10.0, 25.0
  final String sortBy; // 'Newest', 'Oldest', 'A-Z', 'Z-A', 'Recently Added', 'Most Borrowed', 'Nearest First'

  const SearchFilterModel({
    this.mainCategory = 'All',
    this.bookCategory = 'All',
    this.department = 'All',
    this.availability = 'All',
    this.maxDistanceKm,
    this.sortBy = 'Newest',
  });

  bool get hasActiveFilters {
    return mainCategory != 'All' ||
        bookCategory != 'All' ||
        department != 'All' ||
        availability != 'All' ||
        maxDistanceKm != null ||
        sortBy != 'Newest';
  }

  SearchFilterModel copyWith({
    String? mainCategory,
    String? bookCategory,
    String? department,
    String? availability,
    double? maxDistanceKm,
    bool clearDistance = false,
    String? sortBy,
  }) {
    return SearchFilterModel(
      mainCategory: mainCategory ?? this.mainCategory,
      bookCategory: bookCategory ?? this.bookCategory,
      department: department ?? this.department,
      availability: availability ?? this.availability,
      maxDistanceKm: clearDistance ? null : (maxDistanceKm ?? this.maxDistanceKm),
      sortBy: sortBy ?? this.sortBy,
    );
  }

  static const SearchFilterModel initial = SearchFilterModel();
}
