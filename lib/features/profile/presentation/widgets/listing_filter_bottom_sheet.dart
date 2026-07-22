import 'package:flutter/material.dart';
import 'package:UzhavuSei/theme/app_theme.dart';
import '../../data/listing_filter_model.dart';

class ListingFilterBottomSheet extends StatefulWidget {
  final ListingFilterModel initialFilter;

  const ListingFilterBottomSheet({
    super.key,
    required this.initialFilter,
  });

  @override
  State<ListingFilterBottomSheet> createState() => _ListingFilterBottomSheetState();
}

class _ListingFilterBottomSheetState extends State<ListingFilterBottomSheet> {
  late String _selectedCategory;
  late String _selectedStatus;
  late String _selectedSortBy;

  final List<String> _categories = [
    'All',
    'Books',
    'Farm Equipment',
    'Construction Equipment',
  ];

  final List<String> _statuses = [
    'All',
    'Available',
    'Borrowed',
    'Pending',
    'Completed',
  ];

  final List<String> _sortOptions = [
    'Newest First',
    'Oldest First',
    'Recently Updated',
    'Most Viewed',
    'Alphabetical',
  ];

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialFilter.category;
    _selectedStatus = widget.initialFilter.status;
    _selectedSortBy = widget.initialFilter.sortBy;
  }

  void _reset() {
    setState(() {
      _selectedCategory = 'All';
      _selectedStatus = 'All';
      _selectedSortBy = 'Newest First';
    });
  }

  void _apply() {
    final result = ListingFilterModel(
      category: _selectedCategory,
      status: _selectedStatus,
      sortBy: _selectedSortBy,
    );
    Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Filter Listings',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                TextButton(
                  onPressed: _reset,
                  child: const Text(
                    'Reset',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 16),

            // Category Section
            const Text(
              'Category',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _categories.map((cat) {
                final isSelected = _selectedCategory == cat;
                return ChoiceChip(
                  label: Text(
                    cat,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: AppColors.primary,
                  checkmarkColor: Colors.white,
                  backgroundColor: Colors.grey.shade100,
                  onSelected: (val) {
                    if (val) {
                      setState(() => _selectedCategory = cat);
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Status Section
            const Text(
              'Status',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _statuses.map((status) {
                final isSelected = _selectedStatus == status;
                return ChoiceChip(
                  label: Text(
                    status,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: AppColors.primary,
                  checkmarkColor: Colors.white,
                  backgroundColor: Colors.grey.shade100,
                  onSelected: (val) {
                    if (val) {
                      setState(() => _selectedStatus = status);
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Sort By Section
            const Text(
              'Sort By',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _sortOptions.map((opt) {
                final isSelected = _selectedSortBy == opt;
                return ChoiceChip(
                  label: Text(
                    opt,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: AppColors.primary,
                  checkmarkColor: Colors.white,
                  backgroundColor: Colors.grey.shade100,
                  onSelected: (val) {
                    if (val) {
                      setState(() => _selectedSortBy = opt);
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 32),

            // Apply Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _apply,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Apply Filters',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
