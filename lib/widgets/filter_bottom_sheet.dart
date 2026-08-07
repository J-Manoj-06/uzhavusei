import 'package:flutter/material.dart';
import '../models/search_filter_model.dart';
import '../theme/app_theme.dart';

class FilterBottomSheet extends StatefulWidget {
  final SearchFilterModel initialFilter;
  final ValueChanged<SearchFilterModel> onApply;

  const FilterBottomSheet({
    super.key,
    required this.initialFilter,
    required this.onApply,
  });

  static Future<void> show(
    BuildContext context, {
    required SearchFilterModel initialFilter,
    required ValueChanged<SearchFilterModel> onApply,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => FilterBottomSheet(
        initialFilter: initialFilter,
        onApply: onApply,
      ),
    );
  }

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  late SearchFilterModel _tempFilter;

  final List<String> _mainCategories = [
    'All',
    'Books',
    'Farm Equipment',
    'Construction Equipment',
  ];

  final List<String> _bookCategories = [
    'All',
    'Academic',
    'Programming & Technology',
    'Novel',
    'Reference',
    'Research',
    'Magazine',
    'Journal',
    'Competitive Exams',
    'Career & Placement',
    'Business & Management',
    'Science',
    'Mathematics',
    'Agriculture',
    'Arts & Literature',
    'Biography',
    'History',
    'Geography',
    'Politics & Law',
    'Health & Medicine',
    'Language Learning',
    'General Knowledge',
    'Project Reports',
    'Others',
  ];

  final List<String> _departments = [
    'All',
    'Computer Science',
    'Information Technology',
    'Artificial Intelligence & Data Science',
    'Electronics & Communication',
    'Electrical & Electronics',
    'Mechanical',
    'Civil',
    'Biomedical',
    'MBA',
    'MCA',
    'Agriculture',
    'Others',
  ];

  final List<String> _availabilities = [
    'All',
    'Available',
    'Unavailable',
    'Borrowed',
  ];

  final List<String> _sortOptions = [
    'Newest',
    'Oldest',
    'A-Z',
    'Z-A',
    'Recently Added',
    'Most Borrowed',
    'Nearest First',
  ];

  @override
  void initState() {
    super.initState();
    _tempFilter = widget.initialFilter;
  }

  @override
  Widget build(BuildContext context) {
    final showBookFilters = _tempFilter.mainCategory == 'Books' || _tempFilter.mainCategory == 'All';

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle & Header
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Filter & Sort',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _tempFilter = SearchFilterModel.initial;
                    });
                  },
                  child: const Text('Reset All', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),

          // Filter Sections List
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category Filter
                  _buildSectionTitle('Category'),
                  _buildChipGroup(_mainCategories, _tempFilter.mainCategory, (val) {
                    setState(() {
                      _tempFilter = _tempFilter.copyWith(mainCategory: val);
                    });
                  }),

                  const SizedBox(height: 20),

                  // Book Sub-Category Filter (if Books selected)
                  if (showBookFilters) ...[
                    _buildSectionTitle('Book Category'),
                    _buildChipGroup(_bookCategories, _tempFilter.bookCategory, (val) {
                      setState(() {
                        _tempFilter = _tempFilter.copyWith(bookCategory: val);
                      });
                    }),
                    const SizedBox(height: 20),

                    // Department Filter
                    _buildSectionTitle('Department'),
                    _buildChipGroup(_departments, _tempFilter.department, (val) {
                      setState(() {
                        _tempFilter = _tempFilter.copyWith(department: val);
                      });
                    }),
                    const SizedBox(height: 20),
                  ],

                  // Availability Filter
                  _buildSectionTitle('Availability'),
                  _buildChipGroup(_availabilities, _tempFilter.availability, (val) {
                    setState(() {
                      _tempFilter = _tempFilter.copyWith(availability: val);
                    });
                  }),

                  const SizedBox(height: 20),

                  // Sort Options
                  _buildSectionTitle('Sort By'),
                  _buildChipGroup(_sortOptions, _tempFilter.sortBy, (val) {
                    setState(() {
                      _tempFilter = _tempFilter.copyWith(sortBy: val);
                    });
                  }),
                ],
              ),
            ),
          ),

          // Bottom Action Bar
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 12,
              bottom: MediaQuery.of(context).padding.bottom + 12,
            ),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  widget.onApply(_tempFilter);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Apply Filters', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildChipGroup(List<String> options, String selectedValue, ValueChanged<String> onSelected) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((option) {
        final isSelected = option == selectedValue;
        return ChoiceChip(
          label: Text(option),
          selected: isSelected,
          selectedColor: AppColors.primaryContainer,
          backgroundColor: Colors.grey.shade100,
          labelStyle: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? AppColors.primary : AppColors.textPrimary,
          ),
          onSelected: (selected) {
            if (selected) onSelected(option);
          },
        );
      }).toList(),
    );
  }
}
