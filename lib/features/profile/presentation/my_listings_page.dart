import 'dart:async';
import 'package:flutter/material.dart';
import '../../../models/app_user_model.dart';
import '../../../../../models/marketplace_equipment_model.dart';
import '../../../../../models/farm_surplus_exchange_model.dart';
import '../../../../../services/marketplace_service.dart';
import 'widgets/unified_listing.dart';
import 'widgets/equipment_listing_card.dart';
import '../../equipment/presentation/create_listing_flow.dart';
import '../../../localization/app_localizations.dart';

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
  int _completedExchangesCount = 0;
  int _borrowRequestsCount = 0;
  bool _loading = true;

  // Filters State
  String _selectedCategory = 'All';
  String _selectedStatus = 'All';
  String _searchQuery = '';
  String _sortBy = 'Newest';

  final List<String> _categories = [
    'All',
    'Books',
    'Farm Equipment',
    'Construction Equipment',
    'Electronics',
    'Musical Instruments',
    'Tools'
  ];

  final List<String> _statuses = [
    'All',
    'Available',
    'Borrowed',
    'Completed',
    'Hidden'
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
      int completed = 0;
      int pendingOrApproved = 0;
      double earnings = 0;
      for (var b in bookings) {
        if (b.status == 'completed') {
          completed++;
        }
        if (b.status == 'pending' || b.status == 'approved') {
          pendingOrApproved++;
        }
        if (b.status == 'confirmed' || b.status == 'completed' || b.status == 'pending') {
          earnings += b.totalPrice;
        }
      }
      setState(() {
        _potentialEarnings = earnings;
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

    // Sort listings
    if (_sortBy == 'Newest') {
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } else if (_sortBy == 'Price Low-High') {
      list.sort((a, b) => a.price.compareTo(b.price));
    } else if (_sortBy == 'Price High-Low') {
      list.sort((a, b) => b.price.compareTo(a.price));
    }

    return list;
  }

  bool _matchesCategory(UnifiedListing item, String filter) {
    if (filter == 'All') return true;
    final f = filter.toLowerCase();
    final c = item.category.toLowerCase();
    if (f.contains('book')) return c.contains('book');
    if (f.contains('farm') || f.contains('agri')) return c.contains('farm') || c.contains('agri');
    if (f.contains('construction') || f.contains('tool')) return c.contains('construction') || c.contains('tool');
    if (f.contains('electron')) return c.contains('electron');
    if (f.contains('music')) return c.contains('music');
    return c == f;
  }

  bool _matchesStatus(UnifiedListing item, String filter) {
    if (filter == 'All') return true;
    final f = filter.toLowerCase();
    final s = item.status.toLowerCase();
    if (f == 'available') return s == 'published' || s == 'available';
    if (f == 'borrowed') return s == 'booked' || s == 'rented';
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
        await _service.updateEquipment(equipmentId: item.id, updates: {'status': newStatus});
      } else if (item.isExchange) {
        await _service.updateExchange(exchangeId: item.id, updates: {'status': newStatus});
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Listing is now ${newStatus == 'published' ? 'Available' : 'Hidden'}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update listing: $e'), backgroundColor: Colors.red),
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
        title: const Text('Sort Options', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Sort by Newest', style: TextStyle(fontSize: 14)),
              leading: Radio<String>(
                value: 'Newest',
                groupValue: _sortBy,
                activeColor: const Color(0xFF2E7D32),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _sortBy = val);
                    Navigator.pop(ctx);
                  }
                },
              ),
            ),
            ListTile(
              title: const Text('Price: Low to High', style: TextStyle(fontSize: 14)),
              leading: Radio<String>(
                value: 'Price Low-High',
                groupValue: _sortBy,
                activeColor: const Color(0xFF2E7D32),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _sortBy = val);
                    Navigator.pop(ctx);
                  }
                },
              ),
            ),
            ListTile(
              title: const Text('Price: High to Low', style: TextStyle(fontSize: 14)),
              leading: Radio<String>(
                value: 'Price High-Low',
                groupValue: _sortBy,
                activeColor: const Color(0xFF2E7D32),
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
        backgroundColor: Color(0xFFF8FAF8),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32))),
      );
    }

    final listings = _getUnifiedListings();

    // Stats calculations
    final totalCount = listings.length;
    final activeCount = listings.where((item) => item.status == 'published' || item.status == 'available').length;

    // Apply Filters
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
        toolbarHeight: 90,
        title: const Padding(
          padding: EdgeInsets.only(top: 10, bottom: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'My Listings',
                style: TextStyle(
                  color: Color(0xFF1A1A1A),
                  fontSize: 30, // 30sp Page Title
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Manage all your shared resources.',
                style: TextStyle(
                  color: Color(0xFF6F7A6B),
                  fontSize: 14, // 14sp Caption
                  fontWeight: FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, size: 28, color: Color(0xFF1A1A1A)),
            onPressed: _showSearchDialog,
            tooltip: 'Search',
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.tune, size: 28, color: Color(0xFF1A1A1A)),
            onPressed: _showFilterDialog,
            tooltip: 'Sort Options',
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 2x2 statistics dashboard
            _build2x2StatsDashboard(totalCount, activeCount),
            
            const SizedBox(height: 24),
  
            // Category filters
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Categories',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.grey.shade800),
              ),
            ),
            const SizedBox(height: 10),
            _buildCategoryFiltersList(),
  
            const SizedBox(height: 24),
  
            // Status filters
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Filter by Status',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.grey.shade800),
              ),
            ),
            const SizedBox(height: 10),
            _buildStatusFiltersList(),
  
            const SizedBox(height: 24),
  
            // Header title list count
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Shared Resources (${filteredListings.length})',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)),
              ),
            ),
            const SizedBox(height: 12),
  
            filteredListings.isEmpty
                ? _buildPremiumEmptyState()
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(top: 8, bottom: 88, left: 16, right: 16),
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
          _buildStatCard('Total Listings', '$totalCount', Icons.inventory_2_outlined, const Color(0xFF2E7D32)),
          _buildStatCard('Active Listings', '$activeCount', Icons.check_circle_outline, const Color(0xFF4CAF50)),
          _buildStatCard('Borrow Requests', '$_borrowRequestsCount', Icons.question_answer_outlined, const Color(0xFF2196F3)),
          _buildStatCard('Completed Exchanges', '$_completedExchangesCount', Icons.handshake_outlined, const Color(0xFFE65100)),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color accentColor) {
    return Container(
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
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)),
              ),
            ],
          ),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFiltersList() {
    return SizedBox(
      height: 48,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
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
              backgroundColor: Colors.white,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF1A1A1A),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 12,
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              side: BorderSide(color: isSelected ? Colors.transparent : const Color(0xFFE5E7EB)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusFiltersList() {
    return SizedBox(
      height: 48,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _statuses.length,
        itemBuilder: (context, index) {
          final stat = _statuses[index];
          final isSelected = stat == _selectedStatus;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(stat),
              ),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) setState(() => _selectedStatus = stat);
              },
              selectedColor: const Color(0xFF2E7D32),
              backgroundColor: Colors.white,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF1A1A1A),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 12,
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              side: BorderSide(color: isSelected ? Colors.transparent : const Color(0xFFE5E7EB)),
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
                      color: const Color(0xFFE8F5E9).withValues(alpha: 0.4),
                      shape: BoxShape.circle,
                    ),
                  ),
                  Container(
                    width: 70,
                    height: 70,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE8F5E9),
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
                    child: _emojiBubble('🚜', 36, Colors.green.shade50),
                  ),
                  Positioned(
                    bottom: 15,
                    left: 40,
                    child: _emojiBubble('🪖', 34, Colors.orange.shade50),
                  ),
                  Positioned(
                    bottom: 15,
                    right: 40,
                    child: _emojiBubble('🧰', 34, Colors.red.shade50),
                  ),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E7D32),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2E7D32).withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.storefront_outlined, color: Colors.white, size: 22),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No Listings Yet',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start sharing your unused resources with your community.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _openCreateListingWizard,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Create Listing', style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                elevation: 2,
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
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(emoji, style: TextStyle(fontSize: size * 0.5)),
    );
  }
}
