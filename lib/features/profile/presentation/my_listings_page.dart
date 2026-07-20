import 'dart:async';
import 'package:flutter/material.dart';
import '../../../models/app_user_model.dart';
import '../../../../../models/marketplace_equipment_model.dart';
import '../../../../../models/farm_surplus_exchange_model.dart';
import '../../../../../services/marketplace_service.dart';
import 'widgets/unified_listing.dart';
import 'widgets/equipment_listing_card.dart';
import '../../equipment/presentation/create_listing_flow.dart';
import '../../equipment/presentation/owner_borrow_requests_screen.dart';
import 'package:UzhavuSei/theme/app_theme.dart';

class MyListingsPage extends StatefulWidget {
  const MyListingsPage({
    super.key,
    required this.currentUser,
  });

  final AppUserModel currentUser;

  @override
  State<MyListingsPage> createState() => _MyListingsPageState();
}

class _MyListingsPageState extends State<MyListingsPage> {
  final MarketplaceService _service = MarketplaceService();

  StreamSubscription? _equipmentSub;
  StreamSubscription? _exchangeSub;
  StreamSubscription? _bookingsSub;

  List<MarketplaceEquipmentModel> _equipments = [];
  List<FarmSurplusExchangeModel> _exchanges = [];
  int _completedExchangesCount = 0;
  int _borrowRequestsCount = 0;
  bool _loading = true;

  // Filter & Sort State
  String _selectedCategory = 'All Categories';
  String _selectedStatus = 'All';
  String _sortBy = 'Newest First';
  bool _showAvailableOnly = false;

  final List<String> _statusOptions = [
    'All',
    'Available',
    'Borrowed',
    'Reserved',
    'Completed',
    'Expired',
  ];

  final List<String> _sortOptions = [
    'Newest First',
    'Oldest First',
    'Recently Updated',
    'Most Viewed',
    'Highest Rated',
    'Most Borrowed',
    'Alphabetical',
  ];

  @override
  void initState() {
    super.initState();
    _initStreams();
  }

  void _initStreams() {
    _equipmentSub = _service
        .watchEquipmentsByOwner(widget.currentUser.userId)
        .listen((equipments) {
      if (!mounted) return;
      setState(() {
        _equipments = equipments;
        _loading = false;
      });
    });

    _exchangeSub = _service
        .watchExchangesByOwner(widget.currentUser.userId)
        .listen((exchanges) {
      if (!mounted) return;
      setState(() {
        _exchanges = exchanges;
        _loading = false;
      });
    });

    _bookingsSub = _service
        .watchOwnerBookings(widget.currentUser.userId)
        .listen((bookings) {
      if (!mounted) return;
      int completed = 0;
      int pendingOrApproved = 0;
      for (var b in bookings) {
        if (b.status == 'completed') {
          completed++;
        }
        if (b.status == 'pending' || b.status == 'approved') {
          pendingOrApproved++;
        }
      }
      setState(() {
        _completedExchangesCount = completed;
        _borrowRequestsCount = pendingOrApproved;
      });
    });
  }

  @override
  void dispose() {
    _equipmentSub?.cancel();
    _exchangeSub?.cancel();
    _bookingsSub?.cancel();
    super.dispose();
  }

  /// Dynamically extract category list from active user listings
  List<String> _getDynamicCategories() {
    final Set<String> set = {'All Categories'};
    for (var e in _equipments) {
      if (e.category.trim().isNotEmpty) {
        set.add(e.category.trim());
      }
    }
    for (var ex in _exchanges) {
      if (ex.category.trim().isNotEmpty) {
        set.add(ex.category.trim());
      }
    }
    return set.toList();
  }

  // --- Combined listings mapper ---
  List<UnifiedListing> _getUnifiedListings() {
    final List<UnifiedListing> list = [];

    for (var e in _equipments) {
      list.add(UnifiedListing(
        id: e.equipmentId,
        ownerId: e.ownerId,
        ownerName: e.ownerName,
        title: e.equipmentName,
        category: e.category,
        description: e.description,
        price: e.pricePerDay > 0 ? e.pricePerDay : e.pricePerHour * 8,
        salePrice: null,
        condition: e.condition,
        location: e.location,
        latitude: e.latitude,
        longitude: e.longitude,
        imageUrls: e.imageUrls,
        status: e.status,
        views: e.views,
        savedBy: e.savedBy,
        bookingsCount: e.bookingsCount,
        createdAt: e.createdAt,
        rating: e.rating,
        productId: e.productId,
        originalEquipment: e,
      ));
    }

    for (var ex in _exchanges) {
      list.add(UnifiedListing(
        id: ex.exchangeId,
        ownerId: ex.ownerId,
        ownerName: ex.ownerName,
        title: ex.productName,
        category: ex.category,
        description: ex.description,
        price: ex.price,
        salePrice: ex.listingType == 'Sell Surplus' ? ex.price : null,
        condition: ex.condition,
        location: ex.location,
        latitude: ex.latitude,
        longitude: ex.longitude,
        imageUrls: ex.imageUrls,
        status: ex.status,
        views: ex.views,
        savedBy: ex.savedBy,
        bookingsCount: ex.bookingsCount,
        createdAt: ex.createdAt,
        rating: 4.8,
        originalExchange: ex,
      ));
    }

    // Apply Sorting
    if (_sortBy == 'Newest First') {
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } else if (_sortBy == 'Oldest First') {
      list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    } else if (_sortBy == 'Recently Updated') {
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } else if (_sortBy == 'Most Viewed') {
      list.sort((a, b) => b.views.compareTo(a.views));
    } else if (_sortBy == 'Highest Rated') {
      list.sort((a, b) => b.rating.compareTo(a.rating));
    } else if (_sortBy == 'Most Borrowed') {
      list.sort((a, b) => b.bookingsCount.compareTo(a.bookingsCount));
    } else if (_sortBy == 'Alphabetical') {
      list.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    }

    return list;
  }

  bool _matchesCategory(UnifiedListing item, String filter) {
    if (filter == 'All Categories' || filter == 'All') return true;
    return item.category.trim().toLowerCase() == filter.trim().toLowerCase();
  }

  bool _matchesStatus(UnifiedListing item, String filter) {
    if (filter == 'All') return true;
    final f = filter.toLowerCase();
    final s = item.status.toLowerCase();
    if (f == 'available') return s == 'published' || s == 'available';
    if (f == 'borrowed') return s == 'booked' || s == 'rented' || s == 'borrowed';
    if (f == 'reserved') return s == 'reserved';
    if (f == 'completed') return s == 'completed';
    if (f == 'expired') return s == 'expired';
    return s == f;
  }

  void _openCreateListingWizard() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CategorySelectionPage(
          currentUser: widget.currentUser,
        ),
      ),
    );
  }

  Future<void> _editListing(UnifiedListing item) async {
    if (item.isEquipment) {
      final equip = item.originalEquipment!;
      Widget page;
      if (equip.category.toLowerCase().contains('book')) {
        page = BookListingFormPage(
          currentUser: widget.currentUser,
          existing: equip,
        );
      } else if (equip.category.toLowerCase().contains('construction')) {
        page = ConstructionEquipmentFormPage(
          currentUser: widget.currentUser,
          existing: equip,
        );
      } else {
        page = FarmEquipmentFormPage(
          currentUser: widget.currentUser,
          existing: equip,
        );
      }
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => page),
      );
    }
  }

  Future<void> _pauseResumeListing(UnifiedListing item) async {
    try {
      final newStatus = item.status == 'published' ? 'hidden' : 'published';
      if (item.isEquipment) {
        await _service.updateEquipment(
            equipmentId: item.id, updates: {'status': newStatus});
      } else if (item.isExchange) {
        await _service.updateExchange(
            exchangeId: item.id, updates: {'status': newStatus});
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Listing is now ${newStatus == 'published' ? 'Available' : 'Hidden'}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to update listing: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _duplicateListing(UnifiedListing item) async {
    try {
      if (item.isEquipment) {
        final original = item.originalEquipment!;
        final duplicated = MarketplaceEquipmentModel(
          equipmentId: '',
          ownerId: original.ownerId,
          equipmentName: '[Copy] ${original.equipmentName}',
          category: original.category,
          description: original.description,
          titleLocalized: {
            'en': '[Copy] ${original.equipmentName}',
            'ta': original.equipmentName,
            'hi': original.equipmentName
          },
          categoryLocalized: original.categoryLocalized,
          descriptionLocalized: original.descriptionLocalized,
          pricePerHour: original.pricePerHour,
          pricePerDay: original.pricePerDay,
          location: original.location,
          latitude: original.latitude,
          longitude: original.longitude,
          imageUrls: original.imageUrls,
          availability: original.availability,
          rating: original.rating,
          createdAt: DateTime.now(),
          ownerName: original.ownerName,
          machineSpecs: original.machineSpecs,
          condition: original.condition,
          minRentalDuration: original.minRentalDuration,
          priceType: original.priceType,
          status: 'published',
          views: 0,
          savedBy: [],
          bookingsCount: 0,
        );
        await _service.addEquipment(duplicated);
      } else if (item.isExchange) {
        final original = item.originalExchange!;
        final duplicated = FarmSurplusExchangeModel(
          exchangeId: '',
          ownerId: original.ownerId,
          ownerName: original.ownerName,
          productName: '[Copy] ${original.productName}',
          brandName: original.brandName,
          description: original.description,
          category: original.category,
          quantity: original.quantity,
          unitType: original.unitType,
          reasonForSurplus: original.reasonForSurplus,
          condition: original.condition,
          expiryDate: original.expiryDate,
          listingType: original.listingType,
          price: original.price,
          exchangeRequirement: original.exchangeRequirement,
          location: original.location,
          latitude: original.latitude,
          longitude: original.longitude,
          imageUrls: original.imageUrls,
          imagePublicIds: original.imagePublicIds,
          status: 'published',
          createdAt: DateTime.now(),
          views: 0,
          savedBy: [],
          bookingsCount: 0,
        );
        await _service.addExchangeRecord(duplicated.toMap());
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('📋 Listing duplicated successfully!'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to duplicate: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _confirmDelete(UnifiedListing item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Listing?',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text(
            'Are you sure you want to delete "${item.title}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        if (item.isEquipment) {
          await _service.deleteEquipment(item.id);
        } else if (item.isExchange) {
          await _service.deleteExchange(item.id);
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('🗑 Listing deleted successfully.')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Failed to delete: $e'),
                backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  /// Open Modern Material 3 Filter Bottom Sheet
  void _openFilterBottomSheet() {
    String tempCategory = _selectedCategory;
    String tempStatus = _selectedStatus;
    String tempSortBy = _sortBy;
    bool tempShowAvailable = _showAvailableOnly;

    final categories = _getDynamicCategories();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: MediaQuery.of(context).padding.bottom + 20,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Drag Handle
                    Center(
                      child: Container(
                        width: 44,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE5E7EB),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Title
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Filter & Sort Listings',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 22),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),

                    const Divider(height: 24, color: Color(0xFFE5E7EB)),

                    // SECTION 1: Category (Dynamic)
                    const Text(
                      'Category',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: categories.map((cat) {
                        final isSelected = cat == tempCategory;
                        return ChoiceChip(
                          label: Text(cat),
                          selected: isSelected,
                          onSelected: (val) {
                            if (val) setModalState(() => tempCategory = cat);
                          },
                          selectedColor: AppColors.primary,
                          backgroundColor: Colors.white,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : AppColors.textPrimary,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            fontSize: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          side: BorderSide(
                            color: isSelected
                                ? Colors.transparent
                                : const Color(0xFFE5E7EB),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 24),

                    // SECTION 2: Listing Status
                    const Text(
                      'Listing Status',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _statusOptions.map((stat) {
                        final isSelected = stat == tempStatus;
                        return ChoiceChip(
                          label: Text(stat),
                          selected: isSelected,
                          onSelected: (val) {
                            if (val) setModalState(() => tempStatus = stat);
                          },
                          selectedColor: AppColors.primary,
                          backgroundColor: Colors.white,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : AppColors.textPrimary,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            fontSize: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          side: BorderSide(
                            color: isSelected
                                ? Colors.transparent
                                : const Color(0xFFE5E7EB),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 24),

                    // SECTION 3: Sorting
                    const Text(
                      'Sorting',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Column(
                      children: _sortOptions.map((opt) {
                        return RadioListTile<String>(
                          value: opt,
                          groupValue: tempSortBy,
                          activeColor: AppColors.primary,
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          title: Text(
                            opt,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          onChanged: (val) {
                            if (val != null) {
                              setModalState(() => tempSortBy = val);
                            }
                          },
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 16),

                    // SECTION 4: Availability Toggle
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: SwitchListTile.adaptive(
                        value: tempShowAvailable,
                        activeTrackColor: AppColors.primaryContainer,
                        activeThumbColor: AppColors.primary,
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          'Show Available Only',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        subtitle: const Text(
                          'Hide borrowed or reserved listings',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        onChanged: (val) {
                          setModalState(() => tempShowAvailable = val);
                        },
                      ),
                    ),

                    const SizedBox(height: 24),

                    // BOTTOM ACTIONS: Reset & Apply
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setModalState(() {
                                tempCategory = 'All Categories';
                                tempStatus = 'All';
                                tempSortBy = 'Newest First';
                                tempShowAvailable = false;
                              });
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.textSecondary,
                              side: const BorderSide(color: Color(0xFFE5E7EB)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text(
                              'Reset Filters',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _selectedCategory = tempCategory;
                                _selectedStatus = tempStatus;
                                _sortBy = tempSortBy;
                                _showAvailableOnly = tempShowAvailable;
                              });
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text(
                              'Apply Filters',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    final listings = _getUnifiedListings();

    // Stats calculations
    final totalCount = listings.length;
    final activeCount = listings
        .where((item) => item.status == 'published' || item.status == 'available')
        .length;

    // Apply Filters
    final filteredListings = listings.where((item) {
      final matchesCategory = _matchesCategory(item, _selectedCategory);
      final matchesStatus = _matchesStatus(item, _selectedStatus);
      bool matchesAvailable = true;
      if (_showAvailableOnly) {
        matchesAvailable =
            item.status == 'published' || item.status == 'available';
      }
      return matchesCategory && matchesStatus && matchesAvailable;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        toolbarHeight: 90,
        title: const Padding(
          padding: EdgeInsets.only(top: 10, bottom: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'My Listings',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 30, // 30sp Page Title
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Manage all your shared resources.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14, // 14sp Caption
                  fontWeight: FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded,
                size: 26, color: AppColors.textPrimary),
            onPressed: _openFilterBottomSheet,
            tooltip: 'Filter & Sort',
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 2x2 statistics dashboard
            _build2x2StatsDashboard(totalCount, activeCount),

            const SizedBox(height: 16),

            // Header title list count (Immediately below statistics cards!)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Shared Resources (${filteredListings.length})',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 12),

            filteredListings.isEmpty
                ? _buildPremiumEmptyState()
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(
                        top: 8, bottom: 88, left: 16, right: 16),
                    itemCount: filteredListings.length,
                    itemBuilder: (context, index) {
                      final item = filteredListings[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: EquipmentListingCard(
                          listing: item,
                          onTap: () {},
                          onEdit: () => _editListing(item),
                          onDelete: () => _confirmDelete(item),
                          onPauseResume: () => _pauseResumeListing(item),
                          onDuplicate: () => _duplicateListing(item),
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }

  Widget _build2x2StatsDashboard(int totalCount, int activeCount) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.5,
        children: [
          _buildStatCard(
            label: 'Total Listings',
            value: '$totalCount',
            icon: Icons.inventory_2_outlined,
            accentColor: AppColors.primary,
          ),
          _buildStatCard(
            label: 'Active Listings',
            value: '$activeCount',
            icon: Icons.check_circle_outline,
            accentColor: AppColors.primary,
          ),
          _buildStatCard(
            label: 'Borrow Requests',
            value: '$_borrowRequestsCount',
            icon: Icons.question_answer_outlined,
            accentColor: const Color(0xFF2196F3),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => OwnerBorrowRequestsScreen(
                    ownerId: widget.currentUser.userId,
                  ),
                ),
              );
            },
          ),
          _buildStatCard(
            label: 'Completed Exchanges',
            value: '$_completedExchangesCount',
            icon: Icons.handshake_outlined,
            accentColor: const Color(0xFFE65100),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required IconData icon,
    required Color accentColor,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: accentColor, size: 24),
                Text(
                  value,
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w500),
                ),
                if (onTap != null)
                  const Icon(Icons.arrow_forward_ios_rounded,
                      size: 12, color: AppColors.primary),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumEmptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: 140,
              width: 220,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer.withValues(alpha: 0.4),
                      shape: BoxShape.circle,
                    ),
                  ),
                  Container(
                    width: 70,
                    height: 70,
                    decoration: const BoxDecoration(
                      color: AppColors.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Positioned(
                    top: 15,
                    left: 30,
                    child: _emojiBubble('📚', 34, Colors.blue.shade50),
                  ),
                  Positioned(
                    top: 15,
                    right: 30,
                    child: _emojiBubble('🚜', 36, AppColors.success),
                  ),
                  Positioned(
                    bottom: 15,
                    left: 40,
                    child: _emojiBubble('🪖', 34, Colors.orange.shade50),
                  ),
                  Positioned(
                    bottom: 15,
                    right: 40,
                    child: _emojiBubble('🎻', 34, Colors.purple.shade50),
                  ),
                  const Icon(
                    Icons.storefront_rounded,
                    size: 40,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No Listings Found',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No items match your active filters.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _openCreateListingWizard,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: const Icon(Icons.add_rounded, size: 20),
              label: const Text(
                'Create New Listing',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emojiBubble(String emoji, double size, Color bg) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
      ),
      child: Text(emoji, style: TextStyle(fontSize: size / 2)),
    );
  }
}
