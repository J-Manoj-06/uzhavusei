import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/app_user_model.dart';
import '../../models/library_activity_model.dart';
import '../../providers/library_activity_provider.dart';
import '../../widgets/image_loader.dart';
import '../../theme/app_theme.dart';
import '../../features/equipment/presentation/book_details_page.dart';
import '../../models/marketplace_equipment_model.dart';

class MyLibraryPage extends StatefulWidget {
  final AppUserModel currentUser;

  const MyLibraryPage({super.key, required this.currentUser});

  @override
  State<MyLibraryPage> createState() => _MyLibraryPageState();
}

class _MyLibraryPageState extends State<MyLibraryPage> {
  late final LibraryActivityProvider _provider;

  @override
  void initState() {
    super.initState();
    _provider = LibraryActivityProvider(uid: widget.currentUser.uid);
    _provider.addListener(_onProviderChanged);
  }

  @override
  void dispose() {
    _provider.removeListener(_onProviderChanged);
    _provider.dispose();
    super.dispose();
  }

  void _onProviderChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        surfaceTintColor: Colors.transparent,
        toolbarHeight: 76,
        title: Column(
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
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _provider.filter != ActivityFilterOption.all
                    ? AppColors.primaryContainer
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.filter_list_rounded,
                color: _provider.filter != ActivityFilterOption.all
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
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_provider.isLoading) {
      return _buildSkeletonLoader();
    }

    final activities = _provider.filteredActivities;

    if (activities.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: activities.length,
      itemBuilder: (context, index) {
        final item = activities[index];
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
                  width: 60,
                  height: 82,
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer.withValues(alpha: 0.4),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.collections_bookmark_rounded,
                size: 56,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No library activity yet.',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your book requests, approvals, borrowed books, and history will appear here in a unified timeline.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityCard(BuildContext context, LibraryActivityModel item) {
    final statusStyle = _getStatusStyle(item.activityType);
    final dateStr = DateFormat('MMM d, yyyy • h:mm a').format(item.timestamp);

    return Card(
      elevation: 1.5,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: statusStyle.borderColor),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _openBookDetails(context, item),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Book Cover
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 60,
                  height: 82,
                  child: buildSmartImage(
                    item.bookCover,
                    fit: BoxFit.cover,
                    isBook: true,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              // Activity Metadata
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
                        color: statusStyle.bgColor.withValues(alpha: 0.5),
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
                            'Date: $dateStr',
                            style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500),
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
        ),
      ),
    );
  }

  _StatusStyle _getStatusStyle(LibraryActivityType type) {
    switch (type) {
      case LibraryActivityType.pendingRequest:
        return const _StatusStyle(
          bgColor: Color(0xFFFFF7ED),
          textColor: Color(0xFFC2410C),
          borderColor: Color(0xFFFFEDD5),
        );
      case LibraryActivityType.approvedRequest:
        return const _StatusStyle(
          bgColor: Color(0xFFEFF6FF),
          textColor: Color(0xFF1D4ED8),
          borderColor: Color(0xFFDBEAFE),
        );
      case LibraryActivityType.issuedBook:
        return const _StatusStyle(
          bgColor: Color(0xFFF0FDF4),
          textColor: Color(0xFF15803D),
          borderColor: Color(0xFFDCFCE7),
        );
      case LibraryActivityType.returnedBook:
        return const _StatusStyle(
          bgColor: Color(0xFFF8FAFC),
          textColor: Color(0xFF475569),
          borderColor: Color(0xFFE2E8F0),
        );
      case LibraryActivityType.rejectedRequest:
        return const _StatusStyle(
          bgColor: Color(0xFFFEF2F2),
          textColor: Color(0xFFDC2626),
          borderColor: Color(0xFFFEE2E2),
        );
      case LibraryActivityType.cancelledRequest:
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
                          _provider.resetFilters();
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
                    children: ActivityFilterOption.values.map((filter) {
                      final isSelected = _provider.filter == filter;
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
                            _provider.setFilter(filter);
                            setModalState(() {});
                          }
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  const Text('SORT ORDER', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(child: Text('Newest First')),
                          selected: _provider.sortOrder == ActivitySortOrder.newestFirst,
                          selectedColor: AppColors.primaryContainer,
                          labelStyle: TextStyle(
                            color: _provider.sortOrder == ActivitySortOrder.newestFirst ? AppColors.primary : AppColors.textPrimary,
                            fontWeight: _provider.sortOrder == ActivitySortOrder.newestFirst ? FontWeight.bold : FontWeight.normal,
                          ),
                          onSelected: (selected) {
                            if (selected) {
                              _provider.setSortOrder(ActivitySortOrder.newestFirst);
                              setModalState(() {});
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(child: Text('Oldest First')),
                          selected: _provider.sortOrder == ActivitySortOrder.oldestFirst,
                          selectedColor: AppColors.primaryContainer,
                          labelStyle: TextStyle(
                            color: _provider.sortOrder == ActivitySortOrder.oldestFirst ? AppColors.primary : AppColors.textPrimary,
                            fontWeight: _provider.sortOrder == ActivitySortOrder.oldestFirst ? FontWeight.bold : FontWeight.normal,
                          ),
                          onSelected: (selected) {
                            if (selected) {
                              _provider.setSortOrder(ActivitySortOrder.oldestFirst);
                              setModalState(() {});
                            }
                          },
                        ),
                      ),
                    ],
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

  String _getFilterLabel(ActivityFilterOption filter) {
    switch (filter) {
      case ActivityFilterOption.all:
        return 'All (Default)';
      case ActivityFilterOption.pending:
        return 'Pending';
      case ActivityFilterOption.approved:
        return 'Approved';
      case ActivityFilterOption.borrowed:
        return 'Borrowed';
      case ActivityFilterOption.returned:
        return 'Returned';
      case ActivityFilterOption.rejected:
        return 'Rejected';
      case ActivityFilterOption.cancelled:
        return 'Cancelled';
    }
  }

  void _openBookDetails(BuildContext context, LibraryActivityModel item) {
    final itemModel = MarketplaceEquipmentModel(
      equipmentId: item.bookId.isNotEmpty ? item.bookId : 'activity-book',
      ownerId: 'library',
      equipmentName: item.bookTitle,
      category: 'Books',
      description: '${item.stageMessage}. Activity record from college library.',
      titleLocalized: {},
      categoryLocalized: {},
      descriptionLocalized: {},
      pricePerHour: 0,
      pricePerDay: 0,
      location: 'Main Library',
      latitude: 0,
      longitude: 0,
      imageUrls: [item.bookCover],
      availability: false,
      rating: 5.0,
      createdAt: DateTime.now(),
      ownerName: 'Library Administration',
      machineSpecs: '',
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BookDetailsPage(
          initialItem: itemModel,
          userId: widget.currentUser.uid,
          userName: widget.currentUser.name,
          userEmail: widget.currentUser.email,
          userPhone: widget.currentUser.phoneNumber,
        ),
      ),
    );
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
