import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'models/marketplace_equipment_model.dart';
import 'services/api_client.dart';
import 'services/marketplace_service.dart';
import 'services/distance_service.dart';
import 'providers/location_provider.dart';
import 'widgets/image_loader.dart';
import 'features/equipment/presentation/booking_payment_page.dart';
import 'features/equipment/presentation/equipment_details_page.dart' as real_details;

import 'features/explore/presentation/global_search_page.dart';
import 'features/equipment/presentation/category_marketplace_page.dart';
import 'features/equipment/presentation/equipment_form_page.dart';
import 'features/equipment/presentation/books_marketplace_page.dart';
import 'features/equipment/presentation/farm_marketplace_page.dart';
import 'features/equipment/presentation/construction_marketplace_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _currentLocation = 'Loading...';
  double _latitude = 13.0827;
  double _longitude = 80.2707;
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  final PageController _pageController = PageController(viewportFraction: 0.85);
  int _currentPage = 0;
  String _selectedCategory = 'All';
  String _selectedSort = 'Popular';
  List<Map<String, dynamic>> _allEquipment = [...featuredEquipment];
  List<Map<String, dynamic>> _allNearbyItems = [...nearbyItems];
  List<Map<String, dynamic>> _filteredEquipment = [...featuredEquipment];
  final List<Map<String, dynamic>> _filteredItems = [...nearbyItems];
  final List<Map<String, dynamic>> _wishlist = [];
  final MarketplaceService _marketplaceService = MarketplaceService();

  List<MarketplaceEquipmentModel> _rawEquipments = [];
  List<MarketplaceEquipmentModel> _recommendations = [];
  bool _isLoadingRecommendations = false;
  String _currentRadiusLabel = 'Showing items within 5 km';
  bool _isOffline = false;
  bool _bypassNearbyFilter = false;
  LocationProvider? _locationProvider;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _loadBackendData();
    _loadMarketplaceData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final lp = Provider.of<LocationProvider>(context);
    if (_locationProvider != lp) {
      _locationProvider?.removeListener(_onLocationProviderChanged);
      _locationProvider = lp;
      _locationProvider?.addListener(_onLocationProviderChanged);
      // Run once immediately
      _onLocationProviderChanged();
    }
  }

  @override
  void dispose() {
    _locationProvider?.removeListener(_onLocationProviderChanged);
    _searchController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _onLocationProviderChanged() {
    final lvl = _locationProvider?.lastVerifiedLocation;
    if (lvl != null && (lvl.latitude != _latitude || lvl.longitude != _longitude)) {
      setState(() {
        _latitude = lvl.latitude;
        _longitude = lvl.longitude;
        _currentLocation = '${lvl.latitude.toStringAsFixed(4)}, ${lvl.longitude.toStringAsFixed(4)}';
      });
      _saveLocationToFirestore(lvl.latitude, lvl.longitude);
      _rebuildRecommendations();
    }
  }

  void _rebuildRecommendations() {
    if (_rawEquipments.isEmpty) {
      setState(() {
        _recommendations = [];
        _currentRadiusLabel = 'Showing items from all locations';
      });
      return;
    }

    final userLat = _latitude;
    final userLng = _longitude;

    final enrichedList = _rawEquipments.map((e) {
      final distInfo = DistanceService.instance.getDistanceInfo(userLat, userLng, e.latitude, e.longitude);
      return e.copyWithDistance(distInfo);
    }).where((e) => e.distanceInfo != null).toList();

    if (_bypassNearbyFilter) {
      enrichedList.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      setState(() {
        _recommendations = enrichedList.where((e) => e.availability).toList();
        _currentRadiusLabel = 'Showing items from all locations';
      });
      return;
    }

    final radii = [5000.0, 10000.0, 20000.0, 50000.0, 100000.0, double.infinity];
    final labels = [
      'Showing items within 5 km',
      'Showing items within 10 km',
      'Showing items within 20 km',
      'Showing items within 50 km',
      'Showing items within 100 km',
      'Showing items from all locations'
    ];

    List<MarketplaceEquipmentModel> filtered = [];
    String radiusLabel = labels[0];

    for (int i = 0; i < radii.length; i++) {
      final radius = radii[i];
      radiusLabel = labels[i];
      filtered = enrichedList.where((e) {
        if (!e.availability) return false;
        return e.distanceInfo!.meters <= radius;
      }).toList();

      if (filtered.length >= 20 || radius == double.infinity) {
        break;
      }
    }

    filtered.sort((a, b) {
      final distA = a.distanceInfo?.meters ?? double.infinity;
      final distB = b.distanceInfo?.meters ?? double.infinity;
      final distComp = distA.compareTo(distB);
      if (distComp != 0) return distComp;

      final timeA = a.createdAt;
      final timeB = b.createdAt;
      final timeComp = timeB.compareTo(timeA);
      if (timeComp != 0) return timeComp;

      final ratingComp = b.rating.compareTo(a.rating);
      if (ratingComp != 0) return ratingComp;

      return b.bookingsCount.compareTo(a.bookingsCount);
    });

    setState(() {
      _recommendations = filtered;
      _currentRadiusLabel = radiusLabel;
    });
  }

  void _showAllResources() {
    setState(() {
      _bypassNearbyFilter = true;
    });
    _rebuildRecommendations();
  }

  void _navigateToDetailsModel(MarketplaceEquipmentModel equipment) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in to view equipment details.'),
          backgroundColor: Color(0xFFC62828),
        ),
      );
      return;
    }

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => real_details.EquipmentDetailsPage(
          equipment: equipment,
          userId: user.uid,
          userName: user.displayName ?? 'User',
          userEmail: user.email ?? '',
          userPhone: _formatPhoneNumber(user.phoneNumber ?? '9000000000'),
        ),
      ),
    );
  }

  String _getCategoryEmoji(String category) {
    final lower = category.toLowerCase();
    if (lower.contains('book')) return '📚';
    if (lower.contains('tractor') || lower.contains('farm') || lower.contains('agricultural')) return '🚜';
    if (lower.contains('drill') || lower.contains('construction') || lower.contains('mixer')) return '🏗️';
    if (lower.contains('power') || lower.contains('tool')) return '🧰';
    if (lower.contains('furniture')) return '🪑';
    return '🌱';
  }

  Widget _buildSkeletonRecommendations() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 16,
        childAspectRatio: 0.52,
      ),
      itemCount: 4,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFEBEFF0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AspectRatio(
                  aspectRatio: 1.6,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(width: 100, height: 12, color: Colors.white),
                        Container(width: 60, height: 10, color: Colors.white),
                        Container(width: 80, height: 10, color: Colors.white),
                        Container(width: 50, height: 10, color: Colors.white),
                        Container(width: double.infinity, height: 28, color: Colors.white),
                      ],
                    ),
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEBEFF0)),
      ),
      child: Column(
        children: [
          const Icon(Icons.location_off_outlined, size: 48, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'No nearby resources found.',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1A1A1A)),
          ),
          const SizedBox(height: 8),
          Text(
            'Try searching for a specific item or check back later.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade50),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _showAllResources,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Explore All Resources', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _startAutoScroll() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        if (_currentPage < 2) {
          _pageController.nextPage(
            duration: const Duration(milliseconds: 800),
            curve: Curves.fastOutSlowIn,
          );
        } else {
          _pageController.animateToPage(
            0,
            duration: const Duration(milliseconds: 800),
            curve: Curves.fastOutSlowIn,
          );
        }
        _startAutoScroll();
      }
    });
  }

  /// Syncs HomePage lat/lng from the LocationProvider's Last Verified Location.
  /// Falls back to a direct Geolocator call only if the provider has no data yet.
  Future<void> _getCurrentLocation() async {
    try {
      // Prefer the already-resolved location from LocationProvider
      final locationProvider =
          context.read<LocationProvider>();
      final lvl = locationProvider.lastVerifiedLocation;

      if (lvl != null) {
        if (!mounted) return;
        setState(() {
          _latitude = lvl.latitude;
          _longitude = lvl.longitude;
          _currentLocation =
              '${lvl.latitude.toStringAsFixed(4)}, ${lvl.longitude.toStringAsFixed(4)}';
          _isLoading = false;
        });
        _saveLocationToFirestore(lvl.latitude, lvl.longitude);
        return;
      }

      // Provider not ready yet – fall back to a direct call (rare, first launch only)
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (!mounted) return;
          setState(() {
            _currentLocation = 'Location permissions denied';
            _isLoading = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        setState(() {
          _currentLocation = 'Location permissions permanently denied';
          _isLoading = false;
        });
        return;
      }

      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        setState(() {
          _currentLocation = 'GPS is disabled. Tap to enable.';
          _isLoading = false;
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition();
      if (!mounted) return;
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _currentLocation =
            '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
        _isLoading = false;
      });
      _saveLocationToFirestore(position.latitude, position.longitude);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _currentLocation = 'Error getting location';
        _isLoading = false;
      });
    }
  }

  /// Persists the user's location to Firestore so other users can discover them.
  Future<void> _saveLocationToFirestore(double lat, double lng) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'latitude': lat, 'longitude': lng})
            .catchError((_) {});
      }
    } catch (_) {}
  }

  Future<void> _loadBackendData() async {
    try {
      final equipment = await ApiClient.instance.fetchFeaturedEquipment();
      final items = await ApiClient.instance.fetchNearbyItems();
      if (!mounted) return;
      setState(() {
        _allEquipment = equipment;
        _filteredEquipment = equipment;
        _allNearbyItems = items;
        _filteredItems
          ..clear()
          ..addAll(items);
      });
    } catch (e) {
      // Keep sample data on failure
    }
  }

  Future<void> _loadMarketplaceData() async {
    if (mounted) setState(() => _isLoadingRecommendations = true);
    try {
      final equipments =
          await _marketplaceService.watchEquipments(onlyAvailable: true).first;
      if (!mounted) return;

      final mapped =
          equipments.map(_marketplaceEquipmentToCard).toList(growable: false);

      setState(() {
        _rawEquipments = equipments;
        _allEquipment = mapped;
        _allNearbyItems = mapped;
        _filteredEquipment = mapped;
        _filteredItems
          ..clear()
          ..addAll(mapped);
        _isOffline = false;
        _isLoadingRecommendations = false;
      });
      _rebuildRecommendations();
    } catch (_) {
      if (mounted) {
        setState(() {
          _isOffline = true;
          _isLoadingRecommendations = false;
        });
      }
      _rebuildRecommendations();
    }
  }

  Map<String, dynamic> _marketplaceEquipmentToCard(
    MarketplaceEquipmentModel equipment,
  ) {
    final imageUrl = equipment.imageUrls.isEmpty
        ? 'assets/logo.jpg'
        : equipment.imageUrls.first;

    return {
      'title': equipment.equipmentName,
      'price': 'Free to Borrow',
      'rating': equipment.rating > 0 ? equipment.rating : 4.5,
      'distance': 'Near ${equipment.area.isNotEmpty ? equipment.area : (equipment.city.isNotEmpty ? equipment.city : equipment.location)}',
      'imageUrl': imageUrl,
      'description': equipment.description.isEmpty
          ? 'Well-maintained equipment available to borrow.'
          : equipment.description,
      'seller': equipment.ownerName,
      'delivery': 'Contact owner',
      'available': equipment.availability ? 'In Stock' : 'Unavailable',
      'category': equipment.category,
      'original_model': equipment,
    };
  }

  void _filterEquipment(String category) {
    setState(() {
      _selectedCategory = category;
      if (category == 'All') {
        _filteredEquipment = [..._allEquipment];
        _filteredItems
          ..clear()
          ..addAll(_allNearbyItems);
      } else {
        _filteredEquipment = _allEquipment
            .where((item) => _categoryMatches(
                  item['category']?.toString() ?? '',
                  category,
                ))
            .toList();
        _filteredItems
          ..clear()
          ..addAll(_allNearbyItems.where((item) {
            return _categoryMatches(
              item['category']?.toString() ?? '',
              category,
            );
          }));
      }
    });
  }

  bool _categoryMatches(String itemCategory, String selectedCategory) {
    final item = _normalizeCategory(itemCategory);
    final selected = _normalizeCategory(selectedCategory);
    if (selected.isEmpty) return true;
    return item == selected ||
        item.contains(selected) ||
        selected.contains(item);
  }

  String _normalizeCategory(String raw) {
    final value = raw.trim().toLowerCase();
    if (value.endsWith('ies') && value.length > 3) {
      return '${value.substring(0, value.length - 3)}y';
    }
    if (value.endsWith('s') && value.length > 1) {
      return value.substring(0, value.length - 1);
    }
    return value;
  }

  void _sortEquipment(String sortBy) {
    setState(() {
      _selectedSort = sortBy;
      switch (sortBy) {
        case 'Price: Low to High':
          _filteredEquipment.sort((a, b) => a['price'].compareTo(b['price']));
          break;
        case 'Price: High to Low':
          _filteredEquipment.sort((a, b) => b['price'].compareTo(a['price']));
          break;
        case 'Rating':
          _filteredEquipment.sort((a, b) => b['rating'].compareTo(a['rating']));
          break;
        case 'Distance':
          _filteredEquipment
              .sort((a, b) => a['distance'].compareTo(b['distance']));
          break;
        default:
          _filteredEquipment = [..._allEquipment];
      }
    });
  }

  String _formatPhoneNumber(String phone) {
    // Remove all non-digit characters
    String cleaned = phone.replaceAll(RegExp(r'\D'), '');
    // Ensure it's 10 digits, pad with leading zeros if needed
    if (cleaned.isEmpty) return '9000000000';
    if (cleaned.length < 10) {
      cleaned = cleaned.padLeft(10, '0');
    } else if (cleaned.length > 10) {
      cleaned = cleaned.substring(cleaned.length - 10); // Take last 10 digits
    }
    return cleaned;
  }

  Future<void> _openAddEquipmentForm() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in to add equipment.'),
          backgroundColor: Color(0xFFC62828),
        ),
      );
      return;
    }

    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => EquipmentFormPage(
          ownerId: user.uid,
          ownerName: (user.displayName ?? '').trim().isEmpty
              ? 'Farmer'
              : user.displayName!.trim(),
        ),
      ),
    );

    if (!mounted || created != true) return;
    await _loadMarketplaceData();
  }

  void _navigateToDetails(Map<String, dynamic> item) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in to view equipment details.'),
          backgroundColor: Color(0xFFC62828),
        ),
      );
      return;
    }

    final equipment = item['original_model'] as MarketplaceEquipmentModel? ??
        _mapCardItemToEquipment(item);

    if (!mounted) return;

    // Navigate to the newly redesigned EquipmentDetailsPage
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => real_details.EquipmentDetailsPage(
          equipment: equipment,
          userId: user.uid,
          userName: user.displayName ?? 'User',
          userEmail: user.email ?? '',
          userPhone: _formatPhoneNumber(user.phoneNumber ?? '9000000000'),
        ),
      ),
    );
  }

  MarketplaceEquipmentModel _mapCardItemToEquipment(Map<String, dynamic> item) {
    final priceText = (item['price'] ?? '').toString();
    final priceAmount = _extractPriceAmount(priceText);
    final priceType = _extractPriceType(priceText);

    final double pricePerHour = priceType == 'hour'
        ? priceAmount
        : (priceAmount > 0 ? priceAmount / 24.0 : 0.0);
    final double pricePerDay = priceType == 'day'
        ? priceAmount
        : (priceAmount > 0 ? priceAmount * 24.0 : 0.0);

    final rawRating = item['rating'];
    final rating = rawRating is num ? rawRating.toDouble() : 4.5;
    final title = (item['title'] ?? 'Equipment').toString();
    final category = (item['category'] ?? 'General').toString();
    final description =
        (item['description'] ?? 'No description available').toString();

    return MarketplaceEquipmentModel(
      equipmentId: item['title'] ?? 'equipment-${DateTime.now().millisecond}',
      ownerId: 'local-owner',
      equipmentName: title,
      category: category,
      description: description,
      titleLocalized: {'en': title, 'ta': title, 'hi': title},
      categoryLocalized: {
        'en': category,
        'ta': category,
        'hi': category,
      },
      descriptionLocalized: {
        'en': description,
        'ta': description,
        'hi': description,
      },
      pricePerHour: pricePerHour,
      pricePerDay: pricePerDay,
      location: item['distance'] ?? 'Unknown location',
      latitude: 0.0,
      longitude: 0.0,
      imageUrls: [item['imageUrl'] ?? 'assets/logo.jpg'],
      availability: item['available'] != 'Unavailable',
      rating: rating,
      createdAt: DateTime.now(),
      ownerName: item['seller'] ?? 'Local Seller',
      machineSpecs: '',
    );
  }

  double _extractPriceAmount(String priceText) {
    final normalized = priceText.replaceAll(',', '');
    final match = RegExp(r'(\d+(?:\.\d+)?)').firstMatch(normalized);
    if (match == null) return 0;
    return double.tryParse(match.group(1) ?? '') ?? 0;
  }

  String _extractPriceType(String priceText) {
    final normalized = priceText.toLowerCase();
    if (normalized.contains('/hr') || normalized.contains('/hour')) {
      return 'hour';
    }
    if (normalized.contains('/day')) {
      return 'day';
    }
    return 'day';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF8),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        toolbarHeight: 140,
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row 1: Logo and notifications / profile
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Borrow',
                    style: TextStyle(
                      color: Color(0xFF2E7D32),
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.8,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.notifications_none_rounded, color: Color(0xFF3F4A3C), size: 22),
                        onPressed: () {},
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 12),
                      const CircleAvatar(
                        radius: 14,
                        backgroundColor: Color(0xFFE8F5E9),
                        child: Icon(Icons.person_outline, size: 16, color: Color(0xFF2E7D32)),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 6),
              // Row 2: Location selector (stacked vertically to avoid horizontal overflow)
              Row(
                children: [
                  const Icon(Icons.location_on, color: Color(0xFF2E7D32), size: 14),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      _currentLocation.contains(',') ? 'Chennai, India' : _currentLocation,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF3F4A3C),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Search Capsule
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const GlobalSearchPage()),
                  );
                },
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAF8),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFEBEFF0), width: 1.5),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 14),
                      const Icon(Icons.search, color: Colors.grey, size: 18),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Search books, tractors, tools, equipment...',
                            style: TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                        ),
                      ),
                      const Icon(Icons.mic_none_rounded, color: Colors.grey, size: 18),
                      const SizedBox(width: 14),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        color: const Color(0xFF2E7D32),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              
              const SizedBox(height: 16),
  
              // Quick Categories Grid
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Explore Categories',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)),
                ),
              ),
              const SizedBox(height: 12),
              _buildCategoryGrid(),
              const SizedBox(height: 24),
  
              // Trust Features Chips
              _buildFeaturesChips(),
              const SizedBox(height: 24),
  
              // 📍 Nearby Recommendations Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '📍 Nearby Recommendations',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _currentRadiusLabel,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _buildFreshRecommendationsGrid(),
            const SizedBox(height: 24),

            // Community Picks Section
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Nearby Resources',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)),
              ),
            ),
            const SizedBox(height: 12),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _filteredItems.length,
              itemBuilder: (context, index) {
                return _buildNearbyItem(_filteredItems[index]);
              },
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildPromoBanner(String imagePath, String title) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFF2E7D32), Color(0xFF66BB6A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E7D32).withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Lend. Share. Borrow Together.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Find books, farm equipment, construction tools and more near you.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () {
                    if (_filteredEquipment.isNotEmpty) {
                      _navigateToDetails(_filteredEquipment.first);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF2E7D32),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Explore Now', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 70,
            height: 90,
            child: Stack(
              children: const [
                Positioned(top: 0, right: 0, child: Text('🚜', style: TextStyle(fontSize: 28))),
                Positioned(bottom: 10, left: 0, child: Text('📚', style: TextStyle(fontSize: 24))),
                Positioned(bottom: 0, right: 10, child: Text('🧰', style: TextStyle(fontSize: 20))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryGrid() {
    final List<Map<String, String>> catList = [
      {'emoji': '📚', 'label': 'Books'},
      {'emoji': '🚜', 'label': 'Farm Equipment'},
      {'emoji': '🏗️', 'label': 'Construction'},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: catList.map((cat) {
          return Expanded(
            child: GestureDetector(
              onTap: () {
                final category = cat['label'] == 'Construction' ? 'Construction Equipment' : cat['label']!;
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (context, anim, secondaryAnim) => CategoryMarketplacePage(
                      category: category,
                    ),
                    transitionsBuilder: (context, anim, secondaryAnim, child) {
                      return FadeTransition(opacity: anim, child: child);
                    },
                  ),
                );
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFEBEFF0),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(cat['emoji']!, style: const TextStyle(fontSize: 24)),
                    const SizedBox(height: 6),
                    Text(
                      cat['label']!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFeaturesChips() {
    final List<Map<String, String>> features = [
      {'emoji': '🛡️', 'label': 'Verified Owners'},
      {'emoji': '💳', 'label': 'Secure Payments'},
      {'emoji': '📍', 'label': 'GPS Tracking'},
      {'emoji': '🔧', 'label': 'Equipment Maintenance'},
      {'emoji': '⭐', 'label': 'Ratings & Reviews'},
      {'emoji': '⚡', 'label': 'Instant Booking'},
    ];

    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: features.length,
        itemBuilder: (context, idx) {
          final f = features[idx];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Chip(
              label: Text('${f['emoji']!} ${f['label']!}'),
              backgroundColor: const Color(0xFFF8FAF8),
              labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF3F4A3C)),
              side: const BorderSide(color: Color(0xFFEBEFF0)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        },
      ),
    );
  }

  void _showAddListingOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Add a Listing',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.share, color: Color(0xFF2E7D32)),
              title: const Text('Lend Out Resource', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Lend equipment or items to community members.'),
              onTap: () {
                Navigator.pop(ctx);
                _openAddEquipmentForm();
              },
            ),
            ListTile(
              leading: const Icon(Icons.add_box_outlined, color: Color(0xFF2E7D32)),
              title: const Text('Add Equipment to Share', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Add farming machinery or tools to share.'),
              onTap: () {
                Navigator.pop(ctx);
                _openAddEquipmentForm();
              },
            ),
            ListTile(
              leading: const Icon(Icons.book_outlined, color: Color(0xFF2E7D32)),
              title: const Text('Upload Book', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Share or lend textbooks and guides with others.'),
              onTap: () {
                Navigator.pop(ctx);
                _openAddEquipmentForm();
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _addToWishlist(Map<String, dynamic> item) {
    setState(() {
      if (!_isInWishlist(item)) {
        _wishlist.add(item);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Added to wishlist'),
            backgroundColor: Color(0xFF2E7D32),
          ),
        );
      }
    });
  }

  void _removeFromWishlist(Map<String, dynamic> item) {
    setState(() {
      _wishlist.removeWhere((element) => element['title'] == item['title']);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Removed from wishlist'),
          backgroundColor: Color(0xFF2E7D32),
        ),
      );
    });
  }

  void _toggleWishlist(Map<String, dynamic> item) {
    if (_isInWishlist(item)) {
      _removeFromWishlist(item);
    } else {
      _addToWishlist(item);
    }
  }

  bool _isInWishlist(Map<String, dynamic> item) {
    return _wishlist.any((element) => element['title'] == item['title']);
  }

  Widget _buildEquipmentCard(Map<String, dynamic> equipment, {VoidCallback? onTap}) {
    return Container(
      width: 200,
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEBEFF0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: SizedBox(
              height: 110,
              width: double.infinity,
              child: buildSmartImage(equipment['imageUrl'], fit: BoxFit.cover),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  equipment['title'],
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1A1A1A)),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 12, color: Colors.grey),
                    const SizedBox(width: 2),
                    Expanded(
                      child: Text(
                        equipment['distance'],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Borrow for Free',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.star, size: 12, color: Colors.amber),
                        const SizedBox(width: 2),
                        Text(
                          equipment['rating'].toString(),
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 30,
                  child: ElevatedButton(
                    onPressed: onTap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: EdgeInsets.zero,
                    ),
                    child: const Text('Borrow Now', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNearbyItem(Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEBEFF0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.01),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.horizontal(left: Radius.circular(18)),
            child: SizedBox(
              width: 100,
              height: 100,
              child: buildSmartImage(item['imageUrl'], fit: BoxFit.cover),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['title'],
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1A1A1A)),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Text(
                        'Borrow for Free',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF2E7D32)),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '• By ${item['seller']}',
                        style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 12, color: Colors.grey),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          item['distance'],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        height: 26,
                        child: TextButton(
                          onPressed: () => _navigateToDetails(item),
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF2E7D32),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: const BorderSide(color: Color(0xFF2E7D32)),
                            ),
                          ),
                          child: const Text('View', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendedCard(Map<String, dynamic> item) {
    return Container(
      width: 280,
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEBEFF0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Large photo with Availability badge overlay
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: SizedBox(
                  height: 140,
                  width: double.infinity,
                  child: buildSmartImage(item['imageUrl'], fit: BoxFit.cover),
                ),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: item['available'] == 'Unavailable' ? Colors.red : const Color(0xFF2E7D32),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    item['available'] ?? 'Available',
                    style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['title'],
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1A1A1A)),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 10,
                      backgroundColor: const Color(0xFFE8F5E9),
                      child: Text(
                        (item['seller'] ?? 'O')[0].toUpperCase(),
                        style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      item['seller'] ?? 'Verified Owner',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.star, size: 12, color: Colors.amber),
                    const SizedBox(width: 2),
                    Text(
                      item['rating'].toString(),
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Borrow for Free',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF2E7D32)),
                    ),
                    Text(
                      item['distance'],
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleRefresh() async {
    final locationProvider = context.read<LocationProvider>();
    final lvl = locationProvider.lastVerifiedLocation;
    if (lvl == null || lvl.isStale) {
      await locationProvider.refresh();
    } else {
      await _loadMarketplaceData();
    }
  }

  Widget _buildFreshRecommendationsGrid() {
    if (_isLoadingRecommendations) {
      return _buildSkeletonRecommendations();
    }

    if (_recommendations.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_isOffline)
          Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3E0),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(Icons.wifi_off_rounded, size: 16, color: Colors.orange),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Offline results may not include newly added resources.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF795548)),
                  ),
                ),
              ],
            ),
          ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 16,
            childAspectRatio: 0.52,
          ),
          itemCount: _recommendations.length,
          itemBuilder: (context, index) {
            final item = _recommendations[index];
            final cardMap = _marketplaceEquipmentToCard(item);
            final isFav = _isInWishlist(cardMap);
            final distanceStr = item.distanceInfo?.formattedString ?? 'Unknown distance';
            final imageUrl = item.imageUrls.isNotEmpty ? item.imageUrls.first : 'https://images.unsplash.com/photo-1500937386664-56d1dfef3854?auto=format&fit=crop&w=400&q=80';
            final categoryEmoji = _getCategoryEmoji(item.category);
            final areaStr = 'Near ${item.area.isNotEmpty ? item.area : (item.city.isNotEmpty ? item.city : 'Nearby')}';

            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFEBEFF0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Image block with overlays
                  AspectRatio(
                    aspectRatio: 1.6,
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                          child: SizedBox(
                            width: double.infinity,
                            height: double.infinity,
                            child: Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Image.asset(
                                'assets/logo.jpg',
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                        // Category Badge top-left
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.65),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(categoryEmoji, style: const TextStyle(fontSize: 10)),
                                const SizedBox(width: 3),
                                Text(
                                  item.category,
                                  style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Favorite top-right
                        Positioned(
                          top: 8,
                          right: 8,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _toggleWishlist(cardMap);
                              });
                            },
                            child: CircleAvatar(
                              radius: 14,
                              backgroundColor: Colors.white.withValues(alpha: 0.85),
                              child: Icon(
                                  isFav ? Icons.favorite : Icons.favorite_border,
                                  color: isFav ? Colors.red : Colors.black,
                                  size: 14,
                                ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Title (2 lines max)
                          Text(
                            item.equipmentName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A1A1A),
                              height: 1.25,
                            ),
                          ),
                          
                          // Condition & Rating row
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE8F5E9),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  item.condition,
                                  style: const TextStyle(color: Color(0xFF2E7D32), fontSize: 9, fontWeight: FontWeight.bold),
                                ),
                              ),
                              const Spacer(),
                              const Icon(Icons.star, size: 12, color: Colors.amber),
                              const SizedBox(width: 2),
                              Text(
                                item.rating > 0 ? item.rating.toStringAsFixed(1) : '5.0',
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),

                          // Distance Info
                          Row(
                            children: [
                              const Icon(Icons.near_me_outlined, size: 11, color: Color(0xFF2E7D32)),
                              const SizedBox(width: 4),
                              Text(
                                distanceStr,
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF2E7D32)),
                              ),
                            ],
                          ),
                          
                          // Location / Area
                          Row(
                            children: [
                              const Icon(Icons.location_on_outlined, size: 10, color: Colors.grey),
                              const SizedBox(width: 2),
                              Expanded(
                                child: Text(
                                  areaStr,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 9, color: Colors.grey),
                                ),
                              ),
                            ],
                          ),
                          
                          // Status Dot
                          Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: item.availability ? Colors.green : Colors.orange,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                item.availability ? 'Available Now' : 'Currently On Loan',
                                style: TextStyle(
                                  fontSize: 9, 
                                  fontWeight: FontWeight.bold, 
                                  color: item.availability ? Colors.green : Colors.orange,
                                ),
                              ),
                            ],
                          ),
                          
                          // Actions row
                          SizedBox(
                            width: double.infinity,
                            height: 28,
                            child: ElevatedButton(
                              onPressed: () {
                                _navigateToDetailsModel(item);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2E7D32),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                padding: EdgeInsets.zero,
                              ),
                              child: const Text('Borrow Now', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

// Sample data
final List<Map<String, dynamic>> featuredEquipment = [];

final List<Map<String, dynamic>> nearbyItems = [];

// New Equipment List Page
class EquipmentListPage extends StatelessWidget {
  final List<Map<String, dynamic>> equipment;
  final Function(Map<String, dynamic>) onItemSelected;

  const EquipmentListPage({
    super.key,
    required this.equipment,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Equipment'),
        backgroundColor: const Color(0xFF4CAF50),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: equipment.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: InkWell(
                onTap: () => onItemSelected(equipment[index]),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: CachedNetworkImage(
                              imageUrl: equipment[index]['imageUrl'],
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  equipment[index]['title'],
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.location_pin,
                                      size: 16,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      equipment[index]['distance'],
                                      style:
                                          const TextStyle(color: Colors.grey),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Borrow for Free',
                                  style: TextStyle(
                                    color: Color(0xFF4CAF50),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.star,
                                color: Colors.amber,
                                size: 20,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                equipment[index]['rating'].toString(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          ElevatedButton(
                            onPressed: () => onItemSelected(equipment[index]),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4CAF50),
                            ),
                            child: const Text('Borrow Now'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
