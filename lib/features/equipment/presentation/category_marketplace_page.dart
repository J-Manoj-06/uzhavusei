import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../models/marketplace_equipment_model.dart';
import '../../../../services/marketplace_service.dart';
import '../../../../services/distance_service.dart';
import '../../../../providers/location_provider.dart';
import 'equipment_details_page.dart' as real_details;
import 'package:UzhavuSei/theme/app_theme.dart';

class FilterOption {
  final String key;
  final String label;
  final List<String> options;
  final String type; // 'chip' | 'text' | 'switch'

  FilterOption({
    required this.key,
    required this.label,
    required this.options,
    this.type = 'chip',
  });
}

class CategoryConfig {
  final String title;
  final String emoji;
  final String emptyStateText;
  final List<FilterOption> filters;

  CategoryConfig({
    required this.title,
    required this.emoji,
    required this.emptyStateText,
    required this.filters,
  });
}

final Map<String, CategoryConfig> categoryConfigs = {
  'books': CategoryConfig(
    title: 'Books',
    emoji: '📚',
    emptyStateText: 'No books found nearby.',
    filters: [
      FilterOption(key: 'author', label: 'Author', options: [], type: 'text'),
      FilterOption(key: 'language', label: 'Language', options: ['All', 'English', 'Tamil', 'Hindi']),
      FilterOption(key: 'condition', label: 'Condition', options: ['All', 'New', 'Very Good', 'Good', 'Fair']),
      FilterOption(key: 'availability', label: 'Available Only', options: [], type: 'switch'),
    ],
  ),
  'farm equipment': CategoryConfig(
    title: 'Farm Equipment',
    emoji: '🚜',
    emptyStateText: 'No farm equipment found nearby.',
    filters: [
      FilterOption(key: 'brand', label: 'Brand', options: ['All', 'John Deere', 'Mahindra', 'Kubota', 'Massey Ferguson']),
      FilterOption(key: 'machine_type', label: 'Machine Type', options: ['All', 'Tractor', 'Sprayer', 'Rotavator', 'Harvester']),
      FilterOption(key: 'condition', label: 'Condition', options: ['All', 'New', 'Very Good', 'Good', 'Fair']),
      FilterOption(key: 'availability', label: 'Available Only', options: [], type: 'switch'),
    ],
  ),
  'construction': CategoryConfig(
    title: 'Construction Equipment',
    emoji: '🏗️',
    emptyStateText: 'No construction equipment found nearby.',
    filters: [
      FilterOption(key: 'machine_type', label: 'Machine Type', options: ['All', 'Excavator', 'Concrete Mixer', 'Generator', 'Scaffolding', 'Drill']),
      FilterOption(key: 'brand', label: 'Brand', options: ['All', 'Caterpillar', 'JCB', 'Komatsu', 'Volvo', 'Generic']),
      FilterOption(key: 'condition', label: 'Condition', options: ['All', 'New', 'Very Good', 'Good', 'Fair']),
      FilterOption(key: 'availability', label: 'Available Only', options: [], type: 'switch'),
    ],
  ),
  'electronics': CategoryConfig(
    title: 'Electronics',
    emoji: '💻',
    emptyStateText: 'No electronics found nearby.',
    filters: [
      FilterOption(key: 'condition', label: 'Condition', options: ['All', 'New', 'Very Good', 'Good', 'Fair']),
      FilterOption(key: 'availability', label: 'Available Only', options: [], type: 'switch'),
    ],
  ),
  'sports equipment': CategoryConfig(
    title: 'Sports Equipment',
    emoji: '⚽',
    emptyStateText: 'No sports equipment found nearby.',
    filters: [
      FilterOption(key: 'condition', label: 'Condition', options: ['All', 'New', 'Very Good', 'Good', 'Fair']),
      FilterOption(key: 'availability', label: 'Available Only', options: [], type: 'switch'),
    ],
  ),
  'medical equipment': CategoryConfig(
    title: 'Medical Equipment',
    emoji: '🩺',
    emptyStateText: 'No medical equipment found nearby.',
    filters: [
      FilterOption(key: 'condition', label: 'Condition', options: ['All', 'New', 'Very Good', 'Good', 'Fair']),
      FilterOption(key: 'availability', label: 'Available Only', options: [], type: 'switch'),
    ],
  ),
  'musical instruments': CategoryConfig(
    title: 'Musical Instruments',
    emoji: '🎸',
    emptyStateText: 'No musical instruments found nearby.',
    filters: [
      FilterOption(key: 'condition', label: 'Condition', options: ['All', 'New', 'Very Good', 'Good', 'Fair']),
      FilterOption(key: 'availability', label: 'Available Only', options: [], type: 'switch'),
    ],
  ),
  'vehicles': CategoryConfig(
    title: 'Vehicles',
    emoji: '🚗',
    emptyStateText: 'No vehicles found nearby.',
    filters: [
      FilterOption(key: 'condition', label: 'Condition', options: ['All', 'New', 'Very Good', 'Good', 'Fair']),
      FilterOption(key: 'availability', label: 'Available Only', options: [], type: 'switch'),
    ],
  ),
  'tools': CategoryConfig(
    title: 'Tools',
    emoji: '🔧',
    emptyStateText: 'No tools found nearby.',
    filters: [
      FilterOption(key: 'condition', label: 'Condition', options: ['All', 'New', 'Very Good', 'Good', 'Fair']),
      FilterOption(key: 'availability', label: 'Available Only', options: [], type: 'switch'),
    ],
  ),
  'furniture': CategoryConfig(
    title: 'Furniture',
    emoji: '🪑',
    emptyStateText: 'No furniture found nearby.',
    filters: [
      FilterOption(key: 'condition', label: 'Condition', options: ['All', 'New', 'Very Good', 'Good', 'Fair']),
      FilterOption(key: 'availability', label: 'Available Only', options: [], type: 'switch'),
    ],
  ),
};

CategoryConfig getCategoryConfig(String categoryName) {
  final normalized = categoryName.toLowerCase();
  if (normalized.contains('book')) return categoryConfigs['books']!;
  if (normalized.contains('farm') || normalized.contains('agricultur')) return categoryConfigs['farm equipment']!;
  if (normalized.contains('construction')) return categoryConfigs['construction']!;
  if (normalized.contains('electron')) return categoryConfigs['electronics']!;
  if (normalized.contains('sport')) return categoryConfigs['sports equipment']!;
  if (normalized.contains('medic')) return categoryConfigs['medical equipment']!;
  if (normalized.contains('music')) return categoryConfigs['musical instruments']!;
  if (normalized.contains('vehic')) return categoryConfigs['vehicles']!;
  if (normalized.contains('tool')) return categoryConfigs['tools']!;
  if (normalized.contains('furnit')) return categoryConfigs['furniture']!;

  return CategoryConfig(
    title: categoryName,
    emoji: '🌱',
    emptyStateText: 'No $categoryName found nearby.',
    filters: [
      FilterOption(key: 'condition', label: 'Condition', options: ['All', 'New', 'Very Good', 'Good', 'Fair']),
      FilterOption(key: 'availability', label: 'Available Only', options: [], type: 'switch'),
    ],
  );
}

class CategoryMarketplacePage extends StatefulWidget {
  final String category;

  const CategoryMarketplacePage({
    super.key,
    required this.category,
  });

  @override
  State<CategoryMarketplacePage> createState() => _CategoryMarketplacePageState();
}

class _CategoryMarketplacePageState extends State<CategoryMarketplacePage> {
  final MarketplaceService _marketplaceService = MarketplaceService();
  final TextEditingController _searchCtrl = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<MarketplaceEquipmentModel> _rawListings = [];
  List<MarketplaceEquipmentModel> _filteredListings = [];
  List<MarketplaceEquipmentModel> _displayedListings = [];

  bool _isLoading = true;
  bool _isOffline = false;
  bool _isLoadingMore = false;
  int _displayedCount = 10;

  String _searchQuery = '';
  String _selectedSort = 'Nearest';
  double _latitude = 13.0827;
  double _longitude = 80.2707;

  String _currentRadiusLabel = '';
  bool _bypassRadiusFilter = false;

  final Map<String, String> _selectedFilters = {};
  bool _onlyAvailable = false;

  @override
  void initState() {
    super.initState();
    _initFilters();
    _scrollController.addListener(_onScroll);
    _loadLocationAndListings();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _initFilters() {
    final config = getCategoryConfig(widget.category);
    for (final filter in config.filters) {
      if (filter.type == 'chip') {
        _selectedFilters[filter.key] = 'All';
      } else if (filter.type == 'text') {
        _selectedFilters[filter.key] = '';
      }
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (_displayedCount < _filteredListings.length && !_isLoadingMore) {
        _loadNextPage();
      }
    }
  }

  Future<void> _loadLocationAndListings() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    final locationProvider = context.read<LocationProvider>();
    final lvl = locationProvider.lastVerifiedLocation;
    if (lvl != null) {
      _latitude = lvl.latitude;
      _longitude = lvl.longitude;
    }

    try {
      final equipments = await _marketplaceService.watchEquipments(onlyAvailable: false).first;
      if (!mounted) return;

      final currentUser = FirebaseAuth.instance.currentUser;
      final filteredListings = currentUser != null
          ? equipments.where((e) => e.ownerId != currentUser.uid).toList()
          : equipments;

      setState(() {
        _rawListings = filteredListings;
        _isOffline = false;
        _isLoading = false;
      });
      _applyFilterAndSort();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _rawListings = [];
        _isOffline = true;
        _isLoading = false;
      });
      _applyFilterAndSort();
    }
  }

  void _loadNextPage() {
    setState(() => _isLoadingMore = true);
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      setState(() {
        _displayedCount = min(_displayedCount + 10, _filteredListings.length);
        _displayedListings = _filteredListings.take(_displayedCount).toList();
        _isLoadingMore = false;
      });
    });
  }

  bool _isCategoryMatch(String itemCat, String selectedCat) {
    final itemLower = itemCat.toLowerCase();
    final selectedLower = selectedCat.toLowerCase();
    if (selectedLower.contains('book')) {
      return itemLower.contains('book');
    }
    if (selectedLower.contains('farm') || selectedLower.contains('agricultur')) {
      return itemLower.contains('farm') || itemLower.contains('agricultur');
    }
    if (selectedLower.contains('construction')) {
      return itemLower.contains('construction') || itemLower == 'construction equipment';
    }
    return itemLower == selectedLower;
  }

  void _applyFilterAndSort() {
    if (_rawListings.isEmpty) {
      setState(() {
        _filteredListings = [];
        _displayedListings = [];
      });
      return;
    }

    var list = _rawListings.where((item) => _isCategoryMatch(item.category, widget.category)).toList();

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      list = list.where((item) {
        final nameMatch = item.equipmentName.toLowerCase().contains(query);
        final descMatch = item.description.toLowerCase().contains(query);
        final specMatch = item.machineSpecs.toLowerCase().contains(query);

        bool extraMatch = false;
        final normCat = widget.category.toLowerCase();
        if (normCat.contains('book')) {
          extraMatch = _getAuthor(item).toLowerCase().contains(query);
        } else {
          extraMatch = _getBrand(item).toLowerCase().contains(query);
        }

        return nameMatch || descMatch || specMatch || extraMatch;
      }).toList();
    }

    final config = getCategoryConfig(widget.category);
    for (final filter in config.filters) {
      final selectedVal = _selectedFilters[filter.key];
      if (selectedVal != null && selectedVal != 'All' && selectedVal.isNotEmpty) {
        if (filter.key == 'condition') {
          list = list.where((item) => item.condition.toLowerCase() == selectedVal.toLowerCase()).toList();
        } else if (filter.key == 'brand') {
          list = list.where((item) => _getBrand(item).toLowerCase() == selectedVal.toLowerCase()).toList();
        } else if (filter.key == 'machine_type') {
          list = list.where((item) => _getMachineType(item).toLowerCase() == selectedVal.toLowerCase()).toList();
        } else if (filter.key == 'language') {
          list = list.where((item) => _getLanguage(item).toLowerCase() == selectedVal.toLowerCase()).toList();
        } else if (filter.key == 'author') {
          list = list.where((item) => _getAuthor(item).toLowerCase().contains(selectedVal.toLowerCase())).toList();
        }
      }
    }

    // Exclude all unavailable items from exploration category listing
    list = list.where((item) => item.availability).toList();

    list = list.map((e) {
      final distInfo = DistanceService.instance.getDistanceInfo(_latitude, _longitude, e.latitude, e.longitude);
      return e.copyWithDistance(distInfo);
    }).toList();

    if (!_bypassRadiusFilter) {
      final radii = [5000.0, 10000.0, 20000.0, 50000.0, double.infinity];
      final labels = [
        'Showing ${config.title} within 5 km',
        'Showing ${config.title} within 10 km',
        'Showing ${config.title} within 20 km',
        'Showing ${config.title} within 50 km',
        'Showing ${config.title} from all locations'
      ];

      List<MarketplaceEquipmentModel> radiusFiltered = [];
      String radiusLabel = labels[0];

      for (int i = 0; i < radii.length; i++) {
        final radius = radii[i];
        radiusLabel = labels[i];
        radiusFiltered = list.where((e) {
          if (e.distanceInfo == null) return false;
          return e.distanceInfo!.meters <= radius;
        }).toList();

        if (radiusFiltered.length >= 20 || radius == double.infinity) {
          break;
        }
      }
      list = radiusFiltered;
      _currentRadiusLabel = radiusLabel;
    } else {
      _currentRadiusLabel = 'Showing ${config.title} from all locations';
    }

    switch (_selectedSort) {
      case 'Nearest':
        list.sort((a, b) {
          final distA = a.distanceInfo?.meters ?? double.infinity;
          final distB = b.distanceInfo?.meters ?? double.infinity;
          return distA.compareTo(distB);
        });
        break;
      case 'Newest':
      case 'Recently Added':
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case 'Most Requested':
        list.sort((a, b) => b.bookingsCount.compareTo(a.bookingsCount));
        break;
      case 'Highest Rated':
        list.sort((a, b) => b.rating.compareTo(a.rating));
        break;
    }

    setState(() {
      _filteredListings = list;
      _displayedCount = 10;
      _displayedListings = _filteredListings.take(_displayedCount).toList();
    });
  }

  String _getAuthor(MarketplaceEquipmentModel book) {
    final specLower = book.machineSpecs.toLowerCase();
    if (specLower.contains('author:')) {
      final idx = specLower.indexOf('author:');
      final content = book.machineSpecs.substring(idx + 7).split(',')[0].trim();
      if (content.isNotEmpty) return content;
    }
    final descLower = book.description.toLowerCase();
    if (descLower.contains('by ')) {
      final idx = descLower.indexOf('by ');
      final content = book.description.substring(idx + 3).split('.')[0].trim();
      if (content.isNotEmpty) return content;
    }
    return '';
  }

  String _getLanguage(MarketplaceEquipmentModel book) {
    for (final tag in book.tags) {
      if (['english', 'tamil', 'hindi'].contains(tag.toLowerCase())) {
        return tag[0].toUpperCase() + tag.substring(1);
      }
    }
    final specs = book.machineSpecs.toLowerCase();
    if (specs.contains('tamil')) return 'Tamil';
    if (specs.contains('hindi')) return 'Hindi';
    return 'English';
  }

  String _getBrand(MarketplaceEquipmentModel eq) {
    final specLower = eq.machineSpecs.toLowerCase();
    final brandsList = ['john deere', 'mahindra', 'kubota', 'massey ferguson', 'caterpillar', 'jcb', 'komatsu', 'volvo'];
    for (final b in brandsList) {
      if (specLower.contains(b)) {
        return b.split(' ').map((word) => word[0].toUpperCase() + word.substring(1)).join(' ');
      }
    }
    if (specLower.contains('brand:')) {
      final idx = specLower.indexOf('brand:');
      final content = eq.machineSpecs.substring(idx + 6).split(',')[0].trim();
      if (content.isNotEmpty) return content;
    }
    return 'Generic';
  }

  String _getMachineType(MarketplaceEquipmentModel eq) {
    final title = eq.equipmentName.toLowerCase();
    final desc = eq.description.toLowerCase();
    final specs = eq.machineSpecs.toLowerCase();
    final types = ['tractor', 'sprayer', 'rotavator', 'harvester', 'excavator', 'concrete mixer', 'generator', 'scaffolding', 'drill'];
    for (final t in types) {
      if (title.contains(t) || desc.contains(t) || specs.contains(t)) {
        return t.split(' ').map((word) => word[0].toUpperCase() + word.substring(1)).join(' ');
      }
    }
    return 'Equipment';
  }

  void _showFilterPanel() {
    final config = getCategoryConfig(widget.category);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Filter Listings',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 20),
                  ...config.filters.map((filter) {
                    if (filter.type == 'switch') {
                      return SwitchListTile(
                        title: Text(filter.label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        value: _onlyAvailable,
                        activeColor: AppColors.primary,
                        contentPadding: EdgeInsets.zero,
                        onChanged: (val) {
                          setModalState(() {
                            _onlyAvailable = val;
                          });
                          setState(() {
                            _onlyAvailable = val;
                          });
                          _applyFilterAndSort();
                        },
                      );
                    } else if (filter.type == 'text') {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(filter.label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            const SizedBox(height: 8),
                            TextField(
                              decoration: InputDecoration(
                                hintText: 'Enter ${filter.label}...',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              ),
                              controller: TextEditingController(text: _selectedFilters[filter.key])
                                ..selection = TextSelection.collapsed(offset: (_selectedFilters[filter.key] ?? '').length),
                              onChanged: (val) {
                                _selectedFilters[filter.key] = val;
                                _applyFilterAndSort();
                              },
                            ),
                          ],
                        ),
                      );
                    } else {
                      final currentSel = _selectedFilters[filter.key] ?? 'All';
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(filter.label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              children: filter.options.map((opt) {
                                final isSel = currentSel == opt;
                                return ChoiceChip(
                                  label: Text(opt),
                                  selected: isSel,
                                  selectedColor: AppColors.primaryContainer,
                                  labelStyle: TextStyle(
                                    color: isSel ? AppColors.primary : Colors.black87,
                                    fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                                  ),
                                  onSelected: (selected) {
                                    if (selected) {
                                      setModalState(() {
                                        _selectedFilters[filter.key] = opt;
                                      });
                                      setState(() {
                                        _selectedFilters[filter.key] = opt;
                                      });
                                      _applyFilterAndSort();
                                    }
                                  },
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      );
                    }
                  }),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Apply Filters', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _navigateToDetails(MarketplaceEquipmentModel item) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in first.')),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => real_details.EquipmentDetailsPage(
          equipment: item,
          userId: user.uid,
          userName: user.displayName ?? 'User',
          userEmail: user.email ?? '',
          userPhone: '9000000000',
        ),
      ),
    );
  }

  Widget _buildEmptyStateWidget(CategoryConfig config) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(config.emoji, style: const TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          Text(
            config.emptyStateText,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try expanding your search radius or browsing all listings.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton(
                onPressed: () {
                  setState(() {
                    _bypassRadiusFilter = false;
                  });
                  _applyFilterAndSort();
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.primary),
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Expand Radius', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _bypassRadiusFilter = true;
                  });
                  _applyFilterAndSort();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Browse All', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonRecommendations() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: 4,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Container(
              height: 260,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFEBEFF0)),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final config = getCategoryConfig(widget.category);

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: Row(
          children: [
            Text(config.emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 8),
            Text(config.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
        centerTitle: false,
      ),
      body: RefreshIndicator(
        onRefresh: _loadLocationAndListings,
        color: AppColors.primary,
        child: SingleChildScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search & Filter Row
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFEBEFF0)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.search, color: Colors.grey, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: _searchCtrl,
                                style: const TextStyle(fontSize: 14),
                                decoration: InputDecoration(
                                  hintText: 'Search inside ${config.title}...',
                                  hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                                  border: InputBorder.none,
                                  isDense: true,
                                ),
                                onChanged: (val) {
                                  setState(() {
                                    _searchQuery = val;
                                  });
                                  _applyFilterAndSort();
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: _showFilterPanel,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.filter_list, color: AppColors.primary, size: 20),
                      ),
                    ),
                  ],
                ),
              ),

              // Radius badge and Sort dropdown row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _currentRadiusLabel,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                          ),
                          if (_isOffline)
                            const Text(
                              'Offline results. Newly added listings may be missing.',
                              style: TextStyle(fontSize: 10, color: Colors.red, fontWeight: FontWeight.w600),
                            ),
                        ],
                      ),
                    ),
                    DropdownButton<String>(
                      value: _selectedSort,
                      icon: const Icon(Icons.arrow_drop_down, color: AppColors.primary),
                      underline: const SizedBox(),
                      style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12),
                      items: <String>['Nearest', 'Recently Added', 'Most Requested', 'Highest Rated'].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedSort = val;
                          });
                          _applyFilterAndSort();
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              if (_isLoading)
                _buildSkeletonRecommendations()
              else if (_displayedListings.isEmpty)
                _buildEmptyStateWidget(config)
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _displayedListings.length,
                  itemBuilder: (context, index) {
                    final item = _displayedListings[index];
                    final distanceStr = item.distanceInfo?.formattedString ?? 'Unknown distance';
                    const isFav = false;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: const BorderSide(color: Color(0xFFEBEFF0)),
                        ),
                        color: Colors.white,
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () => _navigateToDetails(item),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AspectRatio(
                                aspectRatio: 16 / 9,
                                child: Stack(
                                  children: [
                                    Positioned.fill(
                                      child: Image.network(
                                        item.imageUrls.isNotEmpty ? item.imageUrls.first : 'https://images.unsplash.com/photo-1500937386664-56d1dfef3854?auto=format&fit=crop&w=400&q=80',
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Image.asset(
                                          'assets/logo.jpg',
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
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
                                            Text(config.emoji, style: const TextStyle(fontSize: 10)),
                                            const SizedBox(width: 3),
                                            Text(
                                              item.category,
                                              style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      top: 8,
                                      right: 8,
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
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.equipmentName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        const Icon(Icons.near_me_rounded, size: 12, color: AppColors.primary),
                                        const SizedBox(width: 4),
                                        Text(
                                          distanceStr,
                                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                                        ),
                                        const SizedBox(width: 8),
                                        const Icon(Icons.location_on_outlined, size: 12, color: Colors.grey),
                                        const SizedBox(width: 2),
                                        Expanded(
                                          child: Text(
                                            'Near ${item.area.isNotEmpty ? item.area : (item.city.isNotEmpty ? item.city : "Nearby")}',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(fontSize: 11, color: Colors.grey),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppColors.primaryContainer,
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            item.condition,
                                            style: const TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                        const Spacer(),
                                        const Icon(Icons.star, size: 12, color: Colors.amber),
                                        const SizedBox(width: 2),
                                        Text(
                                          item.rating > 0 ? item.rating.toStringAsFixed(1) : '5.0',
                                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        Container(
                                          width: 6,
                                          height: 6,
                                          decoration: BoxDecoration(
                                            color: item.availability ? AppColors.success : Colors.orange,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          item.availability ? 'Available Now' : 'Currently On Loan',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: item.availability ? AppColors.success : Colors.orange,
                                          ),
                                        ),
                                        const Spacer(),
                                        ElevatedButton(
                                          onPressed: () => _navigateToDetails(item),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColors.primary,
                                            foregroundColor: Colors.white,
                                            elevation: 0,
                                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                          ),
                                          child: const Text('Borrow', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
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
                  },
                ),

              if (_isLoadingMore)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                ),

              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }
}
