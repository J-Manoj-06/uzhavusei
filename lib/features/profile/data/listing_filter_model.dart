class ListingFilterModel {
  final String category;
  final String status;
  final String sortBy;

  const ListingFilterModel({
    this.category = 'All',
    this.status = 'All',
    this.sortBy = 'Newest First',
  });

  bool get isActive =>
      category != 'All' || status != 'All' || sortBy != 'Newest First';

  ListingFilterModel copyWith({
    String? category,
    String? status,
    String? sortBy,
  }) {
    return ListingFilterModel(
      category: category ?? this.category,
      status: status ?? this.status,
      sortBy: sortBy ?? this.sortBy,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ListingFilterModel &&
          runtimeType == other.runtimeType &&
          category == other.category &&
          status == other.status &&
          sortBy == other.sortBy;

  @override
  int get hashCode => category.hashCode ^ status.hashCode ^ sortBy.hashCode;

  @override
  String toString() {
    return 'ListingFilterModel(category: $category, status: $status, sortBy: $sortBy)';
  }
}
