class CategoryItem {
  final String dbValue;
  final String label;
  final String emoji;

  const CategoryItem({
    required this.dbValue,
    required this.label,
    required this.emoji,
  });

  String get displayName => '$emoji $label';
}

class CategoriesConfig {
  static const List<CategoryItem> categories = [
    CategoryItem(dbValue: 'Books', label: 'Books', emoji: '📚'),
    CategoryItem(dbValue: 'Farm Equipment', label: 'Farm Equipment', emoji: '🚜'),
    CategoryItem(dbValue: 'Construction Equipment', label: 'Construction Equipment', emoji: '🏗'),
  ];

  static const List<String> indianStates = [
    'Andhra Pradesh',
    'Arunachal Pradesh',
    'Assam',
    'Bihar',
    'Chhattisgarh',
    'Goa',
    'Gujarat',
    'Haryana',
    'Himachal Pradesh',
    'Jharkhand',
    'Karnataka',
    'Kerala',
    'Madhya Pradesh',
    'Maharashtra',
    'Manipur',
    'Meghalaya',
    'Mizoram',
    'Nagaland',
    'Odisha',
    'Punjab',
    'Rajasthan',
    'Sikkim',
    'Tamil Nadu',
    'Telangana',
    'Tripura',
    'Uttar Pradesh',
    'Uttarakhand',
    'West Bengal',
    'Andaman and Nicobar Islands',
    'Chandigarh',
    'Dadra and Nagar Haveli and Daman and Diu',
    'Delhi',
    'Jammu and Kashmir',
    'Ladakh',
    'Lakshadweep',
    'Puducherry',
  ];
}
