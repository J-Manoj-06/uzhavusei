import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../models/marketplace_equipment_model.dart';
import '../../../../models/search_result_model.dart';
import '../../../../services/search_service.dart';
import '../../../../services/search_history_manager.dart';
import '../../../../providers/location_provider.dart';
import '../../equipment/presentation/equipment_details_page.dart' as real_details;
import 'package:UzhavuSei/theme/app_theme.dart';

class GlobalSearchPage extends StatefulWidget {
  const GlobalSearchPage({super.key});

  @override
  State<GlobalSearchPage> createState() => _GlobalSearchPageState();
}

class _GlobalSearchPageState extends State<GlobalSearchPage> {
  final TextEditingController _searchCtrl = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _debounce;

  List<String> _recentSearches = [];
  final List<String> _popularSearches = [
    'Engineering Books',
    'Tractors',
    'Rotavator',
    'Concrete Mixer',
    'Civil Books',
  ];

  List<SearchResultModel> _allSearchResults = [];
  List<SearchResultModel> _displayedSearchResults = [];
  bool _isLoading = false;
  bool _isOffline = false;
  bool _isLoadingMore = false;
  int _displayedCount = 10;

  // Filter States
  String _selectedCategory = 'All';
  String _selectedCondition = 'All';
  bool _onlyAvailable = false;
  String _selectedCity = '';
  String _selectedState = '';
  double? _maxDistanceKm;
  String _selectedSort = 'Relevance';

  double _userLat = 13.0827;
  double _userLng = 80.2707;
  bool _locationAvailable = false;

  @override
  void initState() {
    super.initState();
    _loadLocation();
    _loadRecentSearches();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (_displayedCount < _allSearchResults.length && !_isLoadingMore) {
        _loadNextPage();
      }
    }
  }

  void _loadLocation() {
    final locationProvider = context.read<LocationProvider>();
    final lvl = locationProvider.lastVerifiedLocation;
    if (lvl != null) {
      setState(() {
        _userLat = lvl.latitude;
        _userLng = lvl.longitude;
        _locationAvailable = true;
      });
    }
  }

  Future<void> _loadRecentSearches() async {
    final list = await SearchHistoryManager.getRecentSearches();
    setState(() {
      _recentSearches = list;
    });
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _performSearch(query);
    });
  }

  Future<void> _performSearch(String query) async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    if (query.trim().isNotEmpty) {
      await SearchHistoryManager.addSearch(query.trim());
      _loadRecentSearches();
    }

    try {
      final results = await SearchService.instance.searchListings(
        query: query,
        userLat: _userLat,
        userLng: _userLng,
        category: _selectedCategory,
        condition: _selectedCondition,
        onlyAvailable: _onlyAvailable,
        city: _selectedCity,
        state: _selectedState,
        maxDistanceKm: _maxDistanceKm,
        sortBy: _selectedSort,
      );

      if (!mounted) return;
      setState(() {
        _allSearchResults = results;
        _displayedCount = 10;
        _displayedSearchResults = _allSearchResults.take(_displayedCount).toList();
        _isLoading = false;
        _isOffline = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _allSearchResults = [];
        _displayedSearchResults = [];
        _isLoading = false;
        _isOffline = true;
      });
    }
  }

  void _loadNextPage() {
    setState(() => _isLoadingMore = true);
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      setState(() {
        _displayedCount = min(_displayedCount + 10, _allSearchResults.length);
        _displayedSearchResults = _allSearchResults.take(_displayedCount).toList();
        _isLoadingMore = false;
      });
    });
  }

  void _clearRecentSearches() async {
    await SearchHistoryManager.clearAll();
    _loadRecentSearches();
  }

  void _deleteRecentSearch(String term) async {
    await SearchHistoryManager.deleteSearch(term);
    _loadRecentSearches();
  }

  void _selectSearchTerm(String term) {
    _searchCtrl.text = term;
    _performSearch(term);
  }

  void _showFilterPanel() {
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
              child: SingleChildScrollView(
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
                      'Filter Search Results',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 20),

                    // Category Filter
                    const Text('Category', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: ['All', 'Books', 'Farm Equipment', 'Construction Equipment'].map((cat) {
                        final isSel = _selectedCategory == cat;
                        return ChoiceChip(
                          label: Text(cat),
                          selected: isSel,
                          selectedColor: AppColors.primaryContainer,
                          labelStyle: TextStyle(
                            color: isSel ? AppColors.primary : Colors.black87,
                            fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                          ),
                          onSelected: (selected) {
                            if (selected) {
                              setModalState(() => _selectedCategory = cat);
                              setState(() => _selectedCategory = cat);
                              _performSearch(_searchCtrl.text);
                            }
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // Condition Filter
                    const Text('Condition', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: ['All', 'New', 'Very Good', 'Good', 'Fair'].map((cond) {
                        final isSel = _selectedCondition == cond;
                        return ChoiceChip(
                          label: Text(cond),
                          selected: isSel,
                          selectedColor: AppColors.primaryContainer,
                          labelStyle: TextStyle(
                            color: isSel ? AppColors.primary : Colors.black87,
                            fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                          ),
                          onSelected: (selected) {
                            if (selected) {
                              setModalState(() => _selectedCondition = cond);
                              setState(() => _selectedCondition = cond);
                              _performSearch(_searchCtrl.text);
                            }
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // Location Input
                    const Text('Location', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: 'City...',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            controller: TextEditingController(text: _selectedCity)..selection = TextSelection.collapsed(offset: _selectedCity.length),
                            onChanged: (val) {
                              _selectedCity = val;
                              _performSearch(_searchCtrl.text);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: 'State...',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            controller: TextEditingController(text: _selectedState)..selection = TextSelection.collapsed(offset: _selectedState.length),
                            onChanged: (val) {
                              _selectedState = val;
                              _performSearch(_searchCtrl.text);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Distance Slider
                    if (_locationAvailable) ...[
                      const Text('Maximum Distance (KM)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Slider(
                              value: _maxDistanceKm ?? 100,
                              min: 5,
                              max: 100,
                              divisions: 19,
                              activeColor: AppColors.primary,
                              inactiveColor: AppColors.primaryContainer,
                              label: _maxDistanceKm != null ? '${_maxDistanceKm!.round()} KM' : 'Anywhere',
                              onChanged: (val) {
                                setModalState(() {
                                  _maxDistanceKm = val;
                                });
                                setState(() {
                                  _maxDistanceKm = val;
                                });
                                _performSearch(_searchCtrl.text);
                              },
                            ),
                          ),
                          Text(
                            _maxDistanceKm != null ? '${_maxDistanceKm!.round()} km' : 'Anywhere',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Availability Switch
                    SwitchListTile(
                      title: const Text('Available Only', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      value: _onlyAvailable,
                      activeColor: AppColors.primary,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (val) {
                        setModalState(() => _onlyAvailable = val);
                        setState(() => _onlyAvailable = val);
                        _performSearch(_searchCtrl.text);
                      },
                    ),

                    const SizedBox(height: 20),
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

  Widget _buildHighlightedTitle(String title, String query) {
    if (query.isEmpty) {
      return Text(
        title,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
      );
    }

    final lowerTitle = title.toLowerCase();
    final lowerQuery = query.toLowerCase();

    if (!lowerTitle.contains(lowerQuery)) {
      return Text(
        title,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
      );
    }

    final List<TextSpan> spans = [];
    int start = 0;
    int indexOfMatch;

    while ((indexOfMatch = lowerTitle.indexOf(lowerQuery, start)) != -1) {
      if (indexOfMatch > start) {
        spans.add(TextSpan(
          text: title.substring(start, indexOfMatch),
          style: const TextStyle(color: AppColors.textPrimary),
        ));
      }

      spans.add(TextSpan(
        text: title.substring(indexOfMatch, indexOfMatch + query.length),
        style: const TextStyle(
          color: AppColors.primary,
          backgroundColor: AppColors.primaryContainer,
          fontWeight: FontWeight.bold,
        ),
      ));

      start = indexOfMatch + query.length;
    }

    if (start < title.length) {
      spans.add(TextSpan(
        text: title.substring(start),
        style: const TextStyle(color: AppColors.textPrimary),
      ));
    }

    return RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        children: spans,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildEmptyStateWidget() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off_rounded, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'No matching resources found.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Try checking your spelling, removing filters, or browsing general categories.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Tapping Browse Categories returns home
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Browse Categories', style: TextStyle(fontWeight: FontWeight.bold)),
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

  String _getCategoryEmoji(String category) {
    final lower = category.toLowerCase();
    if (lower.contains('book')) return '📚';
    if (lower.contains('tractor') || lower.contains('farm') || lower.contains('agricultural')) return '🚜';
    if (lower.contains('drill') || lower.contains('construction') || lower.contains('mixer')) return '🏗️';
    if (lower.contains('power') || lower.contains('tool')) return '🧰';
    if (lower.contains('furniture')) return '🪑';
    return '🌱';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: const Text('Global Search', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: RefreshIndicator(
        onRefresh: () => _performSearch(_searchCtrl.text),
        color: AppColors.primary,
        child: SingleChildScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search Input Row
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
                                decoration: const InputDecoration(
                                  hintText: 'Search items name, category, author, brand...',
                                  hintStyle: TextStyle(color: Colors.grey, fontSize: 13),
                                  border: InputBorder.none,
                                  isDense: true,
                                ),
                                onChanged: _onSearchChanged,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.mic, color: Colors.grey, size: 20),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Voice search feature coming soon!'),
                                    backgroundColor: AppColors.primary,
                                  ),
                                );
                              },
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

              // Dynamic Offline state banner
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
                          'Offline results. Newly added resources may not be visible.',
                          style: TextStyle(fontSize: 12, color: Color(0xFF795548)),
                        ),
                      ),
                    ],
                  ),
                ),

              // Categories Row chips
              if (_searchCtrl.text.isEmpty && _allSearchResults.isEmpty) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text('Popular Categories', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary)),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ['Books', 'Farm Equipment', 'Construction Equipment'].map((cat) {
                      return ActionChip(
                        avatar: Text(_getCategoryEmoji(cat)),
                        label: Text(cat, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: Color(0xFFEBEFF0)),
                        ),
                        onPressed: () {
                          setState(() {
                            _selectedCategory = cat;
                          });
                          _performSearch(_searchCtrl.text);
                        },
                      );
                    }).toList(),
                  ),
                ),

                // Popular Searches Chips
                const SizedBox(height: 16),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text('Popular Searches', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary)),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: _popularSearches.map((term) {
                      return ActionChip(
                        label: Text(term, style: const TextStyle(fontSize: 11)),
                        backgroundColor: const Color(0xFFF5F5F5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide.none),
                        onPressed: () => _selectSearchTerm(term),
                      );
                    }).toList(),
                  ),
                ),

                // Recent Searches List
                if (_recentSearches.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Recent Searches', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary)),
                        TextButton(
                          onPressed: _clearRecentSearches,
                          style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(40, 20), tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                          child: const Text('Clear All', style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _recentSearches.length,
                    itemBuilder: (context, index) {
                      final term = _recentSearches[index];
                      return ListTile(
                        leading: const Icon(Icons.history, color: Colors.grey, size: 20),
                        title: Text(term, style: const TextStyle(fontSize: 13)),
                        trailing: IconButton(
                          icon: const Icon(Icons.close, color: Colors.grey, size: 16),
                          onPressed: () => _deleteRecentSearch(term),
                        ),
                        onTap: () => _selectSearchTerm(term),
                        dense: true,
                      );
                    },
                  ),
                ],
              ],

              // Results Section Header
              if (_searchCtrl.text.isNotEmpty || _allSearchResults.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Text(
                        'Search Results (${_allSearchResults.length})',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                      ),
                      const Spacer(),
                      DropdownButton<String>(
                        value: _selectedSort,
                        icon: const Icon(Icons.arrow_drop_down, color: AppColors.primary),
                        underline: const SizedBox(),
                        style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12),
                        items: <String>['Relevance', 'Newest', 'Nearest', 'Highest Rated', 'Most Requested'].map((String value) {
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
                            _performSearch(_searchCtrl.text);
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                if (_isLoading)
                  _buildSkeletonRecommendations()
                else if (_displayedSearchResults.isEmpty)
                  _buildEmptyStateWidget()
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _displayedSearchResults.length,
                    itemBuilder: (context, index) {
                      final item = _displayedSearchResults[index].listing;
                      final distanceStr = item.distanceInfo?.formattedString ?? '';
                      final isFav = false;

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
                                              Text(_getCategoryEmoji(item.category), style: const TextStyle(fontSize: 10)),
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
                                      _buildHighlightedTitle(item.equipmentName, _searchCtrl.text),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          if (_locationAvailable && distanceStr.isNotEmpty) ...[
                                            const Icon(Icons.near_me_rounded, size: 12, color: AppColors.primary),
                                            const SizedBox(width: 4),
                                            Text(
                                              distanceStr,
                                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                                            ),
                                            const SizedBox(width: 8),
                                          ],
                                          const Icon(Icons.location_on_outlined, size: 12, color: Colors.grey),
                                          const SizedBox(width: 2),
                                          Expanded(
                                            child: Text(
                                              'Near ${item.area.isNotEmpty ? "${item.area}, " : ""}${item.city}',
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
              ],
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }
}
