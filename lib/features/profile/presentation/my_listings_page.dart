import 'dart:async';
import 'package:flutter/material.dart';
import '../../../models/app_user_model.dart';
import '../../../../../models/marketplace_equipment_model.dart';
import '../../../../../models/farm_surplus_exchange_model.dart';
import '../../../../../services/marketplace_service.dart';
import 'widgets/unified_listing.dart';
import 'widgets/equipment_listing_card.dart';
import 'widgets/create_listing_wizard.dart';

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
  double _potentialEarnings = 0;
  bool _loading = true;

  // Filters State
  String _selectedCategory = 'All';
  String _selectedStatus = 'All';
  String _searchQuery = '';
  String _sortBy = 'Newest'; // Newest, Price Low-High, Price High-Low

  final List<String> _categories = [
    'All',
    '📚 Books',
    '🚜 Farm Equipment',
    '🏗️ Construction Equipment',
    '🔌 Electronics',
    '🎸 Musical Instruments',
    '🛠️ Tools'
  ];

  final List<String> _statuses = [
    'All',
    'Available',
    'Booked',
    'Rented',
    'Sold',
    'Expired',
    'Draft',
    'Hidden',
    'Completed',
    'Cancelled'
  ];

  @override
  void initState() {
    super.initState();
    _initStreams();
  }

  void _initStreams() {
    _equipmentSub = _service.watchEquipmentsByOwner(widget.currentUser.userId).listen((equipments) {
      if (!mounted) return;
      setState(() {
        _equipments = equipments;
        _loading = false;
      });
    });

    _exchangeSub = _service.watchExchangesByOwner(widget.currentUser.userId).listen((exchanges) {
      if (!mounted) return;
      setState(() {
        _exchanges = exchanges;
        _loading = false;
      });
    });

    _bookingsSub = _service.watchOwnerBookings(widget.currentUser.userId).listen((bookings) {
      if (!mounted) return;
      double earnings = 0;
      for (var b in bookings) {
        if (b.status == 'confirmed' || b.status == 'completed' || b.status == 'pending') {
          earnings += b.totalPrice;
        }
      }
      setState(() {
        _potentialEarnings = earnings;
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

    // Dynamic sorting
    if (_sortBy == 'Price Low-High') {
      list.sort((a, b) => a.price.compareTo(b.price));
    } else if (_sortBy == 'Price High-Low') {
      list.sort((a, b) => b.price.compareTo(a.price));
    } else {
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    return list;
  }

  // --- Filter logics ---
  bool _matchesCategory(UnifiedListing item, String filter) {
    if (filter == 'All') return true;
    final cat = item.category.toLowerCase();
    
    if (filter.contains('Books')) {
      return cat == 'books' || cat == 'book';
    }
    if (filter.contains('Farm Equipment')) {
      final isLegacyFarm = ['tractor', 'harvester', 'sprayer', 'seeder', 'rotavator', 'pump set', 'cultivator', 'seeds', 'fertilizers', 'pesticides'].contains(cat);
      return cat.contains('farm') || cat.contains('agri') || isLegacyFarm || item.isExchange;
    }
    if (filter.contains('Construction')) {
      return cat.contains('construction') || cat.contains('excavator') || cat.contains('crane') || cat.contains('cement') || cat == 'construction equipment';
    }
    final cleanFilter = filter.replaceAll(RegExp(r'[^\w\s]'), '').trim().toLowerCase();
    return cat.contains(cleanFilter);
  }

  bool _matchesStatus(UnifiedListing item, String filter) {
    if (filter == 'All') return true;
    final status = item.status.toLowerCase();
    final f = filter.toLowerCase();
    if (f == 'available') return status == 'available' || status == 'published';
    if (f == 'paused') return status == 'hidden';
    return status == f;
  }

  // --- Custom Action Handlers ---
  void _openCreateListingWizard() {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      pageBuilder: (context, anim1, anim2) => CreateListingWizard(
        ownerId: widget.currentUser.userId,
        ownerName: widget.currentUser.name,
        onPublished: () {
          setState(() {});
        },
      ),
    );
  }

  Future<void> _editListing(UnifiedListing item) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('✏️ Editing "${item.title}"...')),
    );
  }

  Future<void> _pauseResumeListing(UnifiedListing item) async {
    final isPaused = item.status.toLowerCase() == 'hidden';
    final newStatus = isPaused ? 'published' : 'hidden';

    try {
      if (item.isEquipment) {
        await _service.updateEquipment(equipmentId: item.id, updates: {'status': newStatus});
      } else if (item.isExchange) {
        await _service.updateExchange(exchangeId: item.id, updates: {'status': newStatus});
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isPaused ? '▶️ Resumed listing successfully!' : '⏸ Paused listing successfully!'),
            backgroundColor: const Color(0xFF2E7D32),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update: $e'), backgroundColor: Colors.red),
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
          titleLocalized: {'en': '[Copy] ${original.equipmentName}', 'ta': original.equipmentName, 'hi': original.equipmentName},
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
            backgroundColor: Color(0xFF2E7D32),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to duplicate: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _confirmDelete(UnifiedListing item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Listing?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to delete "${item.title}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF6F7A6B))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
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
            SnackBar(content: Text('Failed to delete: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Search Listings', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: TextField(
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Search by title or category...',
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: (val) {
            setState(() => _searchQuery = val.trim());
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() => _searchQuery = '');
              Navigator.pop(ctx);
            },
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Search', style: TextStyle(color: Color(0xFF2E7D32))),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Sort & Filter Options', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Sort by Newest'),
              leading: Radio<String>(
                value: 'Newest',
                groupValue: _sortBy,
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _sortBy = val);
                    Navigator.pop(ctx);
                  }
                },
              ),
            ),
            ListTile(
              title: const Text('Price: Low to High'),
              leading: Radio<String>(
                value: 'Price Low-High',
                groupValue: _sortBy,
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _sortBy = val);
                    Navigator.pop(ctx);
                  }
                },
              ),
            ),
            ListTile(
              title: const Text('Price: High to Low'),
              leading: Radio<String>(
                value: 'Price High-Low',
                groupValue: _sortBy,
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _sortBy = val);
                    Navigator.pop(ctx);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32))),
      );
    }

    final listings = _getUnifiedListings();
    
    // Stats calculation
    final totalCount = listings.length;
    final activeCount = listings.where((item) => item.status == 'published' || item.status == 'available').length;
    final rentalCount = listings.where((item) => item.status == 'booked' || item.status == 'rented').length;
    final totalViews = listings.fold<int>(0, (sum, item) => sum + item.views);
    final wishlistCount = listings.fold<int>(0, (sum, item) => sum + item.savedBy.length);
    final ratedItems = listings.where((item) => item.rating > 0).toList();
    final avgRating = ratedItems.isNotEmpty 
        ? ratedItems.map((e) => e.rating).reduce((a, b) => a + b) / ratedItems.length 
        : 4.8;

    // Apply Filter & Search
    final filteredListings = listings.where((item) {
      final matchesCategory = _matchesCategory(item, _selectedCategory);
      final matchesStatus = _matchesStatus(item, _selectedStatus);
      final matchesSearch = _searchQuery.isEmpty || 
          item.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.category.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesStatus && matchesSearch;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'My Listings',
              style: TextStyle(
                color: Color(0xFF1A1A1A),
                fontSize: 20,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.4,
              ),
            ),
            Text(
              'Manage all your rentals and marketplace listings.',
              style: TextStyle(
                color: Color(0xFF6F7A6B),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          _circularActionButton(icon: Icons.search, onPressed: _showSearchDialog, tooltip: 'Search'),
          const SizedBox(width: 8),
          _circularActionButton(icon: Icons.tune, onPressed: _showFilterDialog, tooltip: 'Filter'),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          // Expanded M3 Statistics Section
          _buildStatsDashboard(
            totalCount: totalCount,
            activeCount: activeCount,
            rentalCount: rentalCount,
            earnings: _potentialEarnings,
            views: totalViews,
            wishlist: wishlistCount,
            rating: avgRating,
          ),
          
          // Category chips selector
          _buildCategoryFilters(),

          // Status Filter Chips
          _buildStatusFilters(),

          // Main list or Empty State
          Expanded(
            child: filteredListings.isEmpty
                ? _buildPremiumEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.only(top: 8, bottom: 88),
                    itemCount: filteredListings.length,
                    itemBuilder: (context, index) {
                      final item = filteredListings[index];
                      return EquipmentListingCard(
                        listing: item,
                        onTap: () {}, // Detail routing is handled inside card or defaults
                        onEdit: () => _editListing(item),
                        onDelete: () => _confirmDelete(item),
                        onPauseResume: () => _pauseResumeListing(item),
                        onDuplicate: () => _duplicateListing(item),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateListingWizard,
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Listing', style: TextStyle(fontWeight: FontWeight.bold)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Widget _circularActionButton({
    required IconData icon,
    required VoidCallback onPressed,
    required String tooltip,
  }) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: Tooltip(
            message: tooltip,
            child: Icon(icon, color: const Color(0xFF3F4A3C), size: 20),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsDashboard({
    required int totalCount,
    required int activeCount,
    required int rentalCount,
    required double earnings,
    required int views,
    required int wishlist,
    required double rating,
  }) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: SizedBox(
        height: 80,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            _buildStatCard('Total Listings', '$totalCount', Icons.inventory_2_outlined, const Color(0xFF2E7D32)),
            const SizedBox(width: 10),
            _buildStatCard('Active Listings', '$activeCount', Icons.check_circle_outline, const Color(0xFF4CAF50)),
            const SizedBox(width: 10),
            _buildStatCard('Current Rentals', '$rentalCount', Icons.calendar_month_outlined, const Color(0xFF2196F3)),
            const SizedBox(width: 10),
            _buildStatCard('Total Earnings', '₹${earnings.toStringAsFixed(0)}', Icons.payments_outlined, const Color(0xFFE65100)),
            const SizedBox(width: 10),
            _buildStatCard('Total Views', '$views', Icons.visibility_outlined, const Color(0xFF00838F)),
            const SizedBox(width: 10),
            _buildStatCard('Wishlist Count', '$wishlist', Icons.favorite_border, const Color(0xFFD81B60)),
            const SizedBox(width: 10),
            _buildStatCard('Avg Rating', '${rating.toStringAsFixed(1)} ⭐', Icons.star_border, const Color(0xFFF57F17)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      width: 130,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEBEFF0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.01),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 16),
              Text(
                label.split(' ')[0],
                style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey.shade400),
              ),
            ],
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF1A1A1A)),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilters() {
    return Container(
      height: 48,
      color: Colors.white,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final isSelected = cat == _selectedCategory;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(cat),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) setState(() => _selectedCategory = cat);
              },
              selectedColor: const Color(0xFF2E7D32),
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF1A1A1A),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 12,
              ),
              backgroundColor: const Color(0xFFF8FAF8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              side: BorderSide(color: isSelected ? Colors.transparent : const Color(0xFFEBEFF0)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusFilters() {
    return Container(
      height: 44,
      color: Colors.white,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        itemCount: _statuses.length,
        itemBuilder: (context, index) {
          final stat = _statuses[index];
          final isSelected = stat == _selectedStatus;
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: ChoiceChip(
              label: Text(stat),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) setState(() => _selectedStatus = stat);
              },
              selectedColor: const Color(0xFFE8F5E9),
              labelStyle: TextStyle(
                color: isSelected ? const Color(0xFF2E7D32) : Colors.grey.shade600,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 11,
              ),
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              side: BorderSide(color: isSelected ? const Color(0xFF2E7D32) : const Color(0xFFEBEFF0)),
            ),
          );
        },
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
            // Premium Illustration collage
            SizedBox(
              height: 180,
              width: 280,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9).withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                  ),
                  Container(
                    width: 100,
                    height: 100,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE8F5E9),
                      shape: BoxShape.circle,
                    ),
                  ),
                  Positioned(
                    top: 15,
                    left: 45,
                    child: _emojiBubble('📚', 44, Colors.blue.shade50),
                  ),
                  Positioned(
                    top: 15,
                    right: 45,
                    child: _emojiBubble('🚜', 48, Colors.green.shade50),
                  ),
                  Positioned(
                    bottom: 15,
                    left: 55,
                    child: _emojiBubble('🪖', 44, Colors.orange.shade50),
                  ),
                  Positioned(
                    bottom: 15,
                    right: 55,
                    child: _emojiBubble('🧰', 44, Colors.red.shade50),
                  ),
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E7D32),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2E7D32).withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.storefront_outlined, color: Colors.white, size: 28),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No Listings Yet',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'List your unused items and start earning from your community.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 32),
            // Actions
            ElevatedButton.icon(
              onPressed: _openCreateListingWizard,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Create Listing', style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                elevation: 4,
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Exploring marketplace...')),
                );
              },
              child: const Text(
                'Explore Marketplace',
                style: TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emojiBubble(String emoji, double size, Color bgColor) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(emoji, style: TextStyle(fontSize: size * 0.5)),
    );
  }
}
