import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/app_user_model.dart';
import '../../models/library_activity_model.dart';
import '../../providers/library_provider.dart';
import '../../providers/library_filter_provider.dart';
import '../../widgets/image_loader.dart';
import '../../theme/app_theme.dart';
import 'library_activity_details_page.dart';

class MyLibraryPage extends StatefulWidget {
  final AppUserModel currentUser;

  const MyLibraryPage({super.key, required this.currentUser});

  @override
  State<MyLibraryPage> createState() => _MyLibraryPageState();
}

class _MyLibraryPageState extends State<MyLibraryPage> {
  late final LibraryProvider _libraryProvider;
  late final LibraryFilterProvider _filterProvider;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearchVisible = false;

  @override
  void initState() {
    super.initState();
    _libraryProvider = LibraryProvider(uid: widget.currentUser.uid);
    _filterProvider = LibraryFilterProvider();

    _libraryProvider.addListener(_onStateChanged);
    _filterProvider.addListener(_onStateChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _libraryProvider.removeListener(_onStateChanged);
    _filterProvider.removeListener(_onStateChanged);
    _libraryProvider.dispose();
    _filterProvider.dispose();
    super.dispose();
  }

  void _onStateChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final filteredItems = _libraryProvider.getFilteredActivities(_filterProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        surfaceTintColor: Colors.transparent,
        toolbarHeight: _isSearchVisible ? 120 : 76,
        title: _isSearchVisible
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search by title, author, or status...',
                  border: InputBorder.none,
                  hintStyle: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear_rounded, color: Colors.grey),
                    onPressed: () {
                      _searchController.clear();
                      _filterProvider.setSearchQuery('');
                    },
                  ),
                ),
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                onChanged: (val) => _filterProvider.setSearchQuery(val),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text(
                    'My Library',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Manage your library requests and borrowed books.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
        actions: [
          IconButton(
            icon: Icon(
              _isSearchVisible ? Icons.search_off_rounded : Icons.search_rounded,
              color: AppColors.textPrimary,
            ),
            tooltip: _isSearchVisible ? 'Close Search' : 'Search Library',
            onPressed: () {
              setState(() {
                _isSearchVisible = !_isSearchVisible;
                if (!_isSearchVisible) {
                  _searchController.clear();
                  _filterProvider.setSearchQuery('');
                }
              });
            },
          ),
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _filterProvider.statusFilter != LibraryStatusFilter.all
                    ? AppColors.primaryContainer
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.filter_list_rounded,
                color: _filterProvider.statusFilter != LibraryStatusFilter.all
                    ? AppColors.primary
                    : AppColors.textPrimary,
                size: 20,
              ),
            ),
            tooltip: 'Filter Library Activities',
            onPressed: _showFilterModal,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _buildBody(filteredItems),
    );
  }

  Widget _buildBody(List<LibraryActivityModel> items) {
    if (_libraryProvider.isLoading) {
      return _buildSkeletonLoader();
    }

    if (items.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return _buildActivityCard(context, item);
      },
    );
  }

  Widget _buildSkeletonLoader() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 3,
      itemBuilder: (context, index) {
        return Card(
          elevation: 1,
          margin: const EdgeInsets.only(bottom: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 62,
                  height: 84,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(width: 140, height: 16, color: Colors.grey.shade200),
                      const SizedBox(height: 8),
                      Container(width: 100, height: 12, color: Colors.grey.shade200),
                      const SizedBox(height: 8),
                      Container(width: 120, height: 12, color: Colors.grey.shade200),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    final isFiltered = _filterProvider.statusFilter != LibraryStatusFilter.all || _filterProvider.searchQuery.isNotEmpty;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer.withOpacity(0.4),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.collections_bookmark_rounded,
                size: 56,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isFiltered ? 'No matching library activity' : 'No Library Activity',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isFiltered
                  ? 'Try adjusting your search query or filter options.'
                  : 'Your library requests and borrowed books will appear here.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            if (isFiltered) ...[
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () {
                  _searchController.clear();
                  _filterProvider.resetFilters();
                },
                child: const Text('Reset Filters'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActivityCard(BuildContext context, LibraryActivityModel item) {
    final statusStyle = _getStatusStyle(item.status);
    final requestDateStr = DateFormat('MMM d, yyyy').format(item.requestDate);
    final updatedDateStr = DateFormat('MMM d, yyyy • h:mm a').format(item.updatedAt);

    return Card(
      elevation: 1.5,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: statusStyle.borderColor),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => LibraryActivityDetailsPage(item: item),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Book Cover
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: SizedBox(
                      width: 62,
                      height: 84,
                      child: buildSmartImage(
                        item.bookCover,
                        fit: BoxFit.cover,
                        isBook: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  // Metadata
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                item.bookTitle,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Status Badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: statusStyle.bgColor,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: statusStyle.borderColor),
                              ),
                              child: Text(
                                item.statusLabel,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: statusStyle.textColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Author: ${item.author}',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 6),
                        // Stage Message Container
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusStyle.bgColor.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            item.stageMessage,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: statusStyle.textColor,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.access_time_rounded, size: 12, color: Colors.grey),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'Requested: $requestDateStr • Updated: $updatedDateStr',
                                style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w500),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              // Prominent Action Bar for Approved Items
              if (item.status == LibraryActivityStatus.approved) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => LibraryActivityDetailsPage(item: item),
                        ),
                      );
                    },
                    icon: const Icon(Icons.qr_code_2_rounded, size: 18),
                    label: const Text('Ready for Collection — View Details', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  _StatusStyle _getStatusStyle(LibraryActivityStatus status) {
    switch (status) {
      case LibraryActivityStatus.pending:
        return const _StatusStyle(
          bgColor: Color(0xFFFFF7ED),
          textColor: Color(0xFFC2410C),
          borderColor: Color(0xFFFFEDD5),
        );
      case LibraryActivityStatus.approved:
        return const _StatusStyle(
          bgColor: Color(0xFFEFF6FF),
          textColor: Color(0xFF1D4ED8),
          borderColor: Color(0xFFDBEAFE),
        );
      case LibraryActivityStatus.borrowed:
        return const _StatusStyle(
          bgColor: Color(0xFFF0FDF4),
          textColor: Color(0xFF15803D),
          borderColor: Color(0xFFDCFCE7),
        );
      case LibraryActivityStatus.returned:
        return const _StatusStyle(
          bgColor: Color(0xFFF8FAFC),
          textColor: Color(0xFF475569),
          borderColor: Color(0xFFE2E8F0),
        );
      case LibraryActivityStatus.rejected:
        return const _StatusStyle(
          bgColor: Color(0xFFFEF2F2),
          textColor: Color(0xFFDC2626),
          borderColor: Color(0xFFFEE2E2),
        );
      case LibraryActivityStatus.cancelled:
        return const _StatusStyle(
          bgColor: Color(0xFFF1F5F9),
          textColor: Color(0xFF334155),
          borderColor: Color(0xFFCBD5E1),
        );
    }
  }

  void _showFilterModal() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Filter & Sort Activities',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      TextButton(
                        onPressed: () {
                          _filterProvider.resetFilters();
                          setModalState(() {});
                          Navigator.pop(context);
                        },
                        child: const Text('Reset', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 8),
                  const Text('STATUS FILTER', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: LibraryStatusFilter.values.map((filter) {
                      final isSelected = _filterProvider.statusFilter == filter;
                      final label = _getFilterLabel(filter);
                      return ChoiceChip(
                        label: Text(label),
                        selected: isSelected,
                        selectedColor: AppColors.primaryContainer,
                        labelStyle: TextStyle(
                          color: isSelected ? AppColors.primary : AppColors.textPrimary,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 12,
                        ),
                        onSelected: (selected) {
                          if (selected) {
                            _filterProvider.setStatusFilter(filter);
                            setModalState(() {});
                          }
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  const Text('SORT ORDER', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: LibrarySortOption.values.map((sort) {
                      final isSelected = _filterProvider.sortOption == sort;
                      final label = _getSortLabel(sort);
                      return ChoiceChip(
                        label: Text(label),
                        selected: isSelected,
                        selectedColor: AppColors.primaryContainer,
                        labelStyle: TextStyle(
                          color: isSelected ? AppColors.primary : AppColors.textPrimary,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 12,
                        ),
                        onSelected: (selected) {
                          if (selected) {
                            _filterProvider.setSortOption(sort);
                            setModalState(() {});
                          }
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Apply Filter', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _getFilterLabel(LibraryStatusFilter filter) {
    switch (filter) {
      case LibraryStatusFilter.all:
        return 'All (Default)';
      case LibraryStatusFilter.pending:
        return 'Pending';
      case LibraryStatusFilter.approved:
        return 'Approved';
      case LibraryStatusFilter.borrowed:
        return 'Borrowed';
      case LibraryStatusFilter.returned:
        return 'Returned';
      case LibraryStatusFilter.rejected:
        return 'Rejected';
      case LibraryStatusFilter.cancelled:
        return 'Cancelled';
    }
  }

  String _getSortLabel(LibrarySortOption sort) {
    switch (sort) {
      case LibrarySortOption.newestFirst:
        return 'Newest First';
      case LibrarySortOption.oldestFirst:
        return 'Oldest First';
      case LibrarySortOption.titleAZ:
        return 'Title A-Z';
      case LibrarySortOption.titleZA:
        return 'Title Z-A';
    }
  }
}

class _StatusStyle {
  final Color bgColor;
  final Color textColor;
  final Color borderColor;

  const _StatusStyle({
    required this.bgColor,
    required this.textColor,
    required this.borderColor,
  });
}
