import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:UzhavuSei/theme/app_theme.dart';
import '../../../models/book_model.dart';
import '../../../models/marketplace_equipment_model.dart';
import '../../../models/search_result_model.dart';
import '../../../providers/offline_search_provider.dart';
import '../../../providers/search_filter_provider.dart';
import '../../../providers/search_provider.dart';
import '../../../providers/search_suggestion_provider.dart';
import '../../../services/recently_viewed_service.dart';
import '../../../services/search_recommendation_service.dart';
import '../../../widgets/filter_bottom_sheet.dart';
import '../../../widgets/image_loader.dart';
import '../../equipment/presentation/book_details_page.dart';
import '../../equipment/presentation/equipment_details_page.dart' as real_details;
import 'widgets/search_bar_widget.dart';
import 'widgets/search_filter_button.dart';
import 'widgets/search_empty_state.dart';
import 'widgets/recent_search_section.dart';

class GlobalSearchPage extends StatefulWidget {
  final String? initialQuery;

  const GlobalSearchPage({super.key, this.initialQuery});

  @override
  State<GlobalSearchPage> createState() => _GlobalSearchPageState();
}

class _GlobalSearchPageState extends State<GlobalSearchPage> {
  late final SearchProvider _searchProvider;
  late final SearchFilterProvider _filterProvider;
  late final SearchSuggestionProvider _suggestionProvider;
  late final OfflineSearchProvider _offlineProvider;

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _showSuggestions = false;

  List<Map<String, dynamic>> _recentlyViewedItems = [];
  List<BookModel> _recommendedBooks = [];

  @override
  void initState() {
    super.initState();
    _searchProvider = SearchProvider();
    _filterProvider = SearchFilterProvider();
    _suggestionProvider = SearchSuggestionProvider();
    _offlineProvider = OfflineSearchProvider();

    _searchProvider.addListener(_onStateChanged);
    _filterProvider.addListener(_onStateChanged);
    _suggestionProvider.addListener(_onStateChanged);
    _offlineProvider.addListener(_onStateChanged);

    _scrollController.addListener(_onScroll);

    _loadRecentAndRecommendations();

    if (widget.initialQuery != null && widget.initialQuery!.trim().isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _executeSearchQuery(widget.initialQuery!);
      });
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();

    _searchProvider.removeListener(_onStateChanged);
    _filterProvider.removeListener(_onStateChanged);
    _suggestionProvider.removeListener(_onStateChanged);
    _offlineProvider.removeListener(_onStateChanged);

    _searchProvider.dispose();
    _filterProvider.dispose();
    _suggestionProvider.dispose();
    _offlineProvider.dispose();
    super.dispose();
  }

  Future<void> _loadRecentAndRecommendations() async {
    final viewed = await RecentlyViewedService.instance.getRecentlyViewed();
    final recs = await SearchRecommendationService.instance.getPersonalizedRecommendations();

    if (mounted) {
      setState(() {
        _recentlyViewedItems = viewed;
        _recommendedBooks = recs;
      });
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (_searchProvider.hasMore && !_searchProvider.isLoadingMore) {
        _searchProvider.loadMore();
      }
    }
  }

  void _onStateChanged() {
    if (mounted) setState(() {});
  }

  void _executeSearchQuery(String query) {
    _searchController.text = query;
    _searchController.selection = TextSelection.fromPosition(TextPosition(offset: query.length));
    _showSuggestions = false;
    _suggestionProvider.clearSuggestions();
    _searchProvider.onQueryChanged(query);
  }

  void _confirmClearHistory() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Search History'),
        content: const Text('Are you sure you want to delete all stored searches?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _searchProvider.clearRecentSearches();
            },
            child: const Text('Clear All', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _navigateToBookDetails(BuildContext context, BookModel book) {
    RecentlyViewedService.instance.addRecentlyViewed(
      SearchResultModel.fromBook(book, 100.0),
    );

    final user = FirebaseAuth.instance.currentUser;
    final equip = MarketplaceEquipmentModel(
      equipmentId: book.bookId,
      ownerId: 'library-admin',
      equipmentName: book.title,
      category: book.category,
      description: book.description,
      titleLocalized: book.titleLocalized,
      categoryLocalized: book.categoryLocalized,
      descriptionLocalized: book.descriptionLocalized,
      pricePerHour: 0.0,
      pricePerDay: 0.0,
      location: 'College Library',
      latitude: 0.0,
      longitude: 0.0,
      imageUrls: [book.coverImage],
      availability: book.availableCopies > 0,
      rating: book.rating,
      createdAt: book.createdAt,
      ownerName: 'College Librarian',
      machineSpecs: book.isbn,
      productId: book.isbn,
      productIdLower: book.isbn.toLowerCase(),
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BookDetailsPage(
          initialItem: equip,
          userId: user?.uid ?? 'guest',
          userName: user?.displayName ?? 'User',
          userEmail: user?.email ?? '',
          userPhone: user?.phoneNumber ?? '',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchProvider.searchQuery;
    final isSearching = _searchProvider.isSearching;
    final rawResults = _searchProvider.searchResults;
    final filteredResults = _filterProvider.applyFilters(rawResults);
    final error = _searchProvider.errorMessage;
    final suggestions = _suggestionProvider.suggestions;
    final isOffline = _offlineProvider.isOffline;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Global Search',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // Offline Status Banner
                if (isOffline)
                  Container(
                    width: double.infinity,
                    color: Colors.amber.shade700,
                    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.wifi_off_rounded, size: 14, color: Colors.white),
                        SizedBox(width: 6),
                        Text(
                          'Offline Mode — Showing cached results',
                          style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),

                // Search Bar & Filter Header Row
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: SearchBarWidget(
                              controller: _searchController,
                              onChanged: (val) {
                                _showSuggestions = val.trim().isNotEmpty;
                                _suggestionProvider.onQueryChanged(val);
                                _searchProvider.onQueryChanged(val);
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          SearchFilterButton(
                            onTap: () {
                              FilterBottomSheet.show(
                                context,
                                initialFilter: _filterProvider.filter,
                                onApply: (newFilter) {
                                  _filterProvider.setMainCategory(newFilter.mainCategory);
                                  _filterProvider.setBookCategory(newFilter.bookCategory);
                                  _filterProvider.setDepartment(newFilter.department);
                                  _filterProvider.setAvailability(newFilter.availability);
                                  _filterProvider.setSortBy(newFilter.sortBy);
                                },
                              );
                            },
                          ),
                        ],
                      ),

                      // Active Filter Chips Row
                      if (_filterProvider.hasActiveFilters) ...[
                        const SizedBox(height: 10),
                        _buildActiveFilterChips(),
                      ],
                    ],
                  ),
                ),

                const Divider(height: 1, color: Color(0xFFE2E8F0)),

                // Search Content Switcher with Pull-to-Refresh
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      await _searchProvider.refreshCurrentSearch();
                      await _loadRecentAndRecommendations();
                    },
                    child: _buildMainContent(query, isSearching, rawResults, filteredResults, error),
                  ),
                ),
              ],
            ),

            // Live Autocomplete Suggestions Dropdown Overlay
            if (_showSuggestions && suggestions.isNotEmpty)
              Positioned(
                top: isOffline ? 96 : 68,
                left: 16,
                right: 74,
                child: Material(
                  elevation: 6,
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.white,
                  child: Container(
                    constraints: const BoxConstraints(maxHeight: 280),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      shrinkWrap: true,
                      itemCount: suggestions.length,
                      separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                      itemBuilder: (context, index) {
                        final item = suggestions[index];
                        return ListTile(
                          dense: true,
                          leading: const Icon(Icons.search_rounded, size: 18, color: AppColors.textSecondary),
                          title: Text(
                            item,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                          ),
                          trailing: const Icon(Icons.north_west_rounded, size: 14, color: Colors.grey),
                          onTap: () => _executeSearchQuery(item),
                        );
                      },
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveFilterChips() {
    final filter = _filterProvider.filter;
    final chips = <Widget>[];

    if (filter.mainCategory != 'All') {
      chips.add(_buildFilterChip(filter.mainCategory, () => _filterProvider.setMainCategory('All')));
    }
    if (filter.bookCategory != 'All') {
      chips.add(_buildFilterChip(filter.bookCategory, () => _filterProvider.setBookCategory('All')));
    }
    if (filter.department != 'All') {
      chips.add(_buildFilterChip(filter.department, () => _filterProvider.setDepartment('All')));
    }
    if (filter.availability != 'All') {
      chips.add(_buildFilterChip(filter.availability, () => _filterProvider.setAvailability('All')));
    }
    if (filter.sortBy != 'Newest') {
      chips.add(_buildFilterChip('Sort: ${filter.sortBy}', () => _filterProvider.setSortBy('Newest')));
    }

    return Row(
      children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: chips),
          ),
        ),
        TextButton(
          onPressed: () => _filterProvider.clearAll(),
          style: TextButton.styleFrom(padding: const EdgeInsets.only(left: 8)),
          child: const Text('Clear All', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.red)),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, VoidCallback onRemove) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InputChip(
        label: Text(label),
        onDeleted: onRemove,
        deleteIcon: const Icon(Icons.close_rounded, size: 14),
        backgroundColor: AppColors.primaryContainer.withOpacity(0.5),
        labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Widget _buildMainContent(
    String query,
    bool isSearching,
    List<SearchResultModel> rawResults,
    List<SearchResultModel> filteredResults,
    String? error,
  ) {
    if (error != null && rawResults.isEmpty) {
      return _buildErrorState(error);
    }

    if (isSearching) {
      return _buildShimmerLoading();
    }

    if (query.trim().isNotEmpty) {
      if (rawResults.isEmpty) {
        return _buildNoResultsState(query);
      }
      if (filteredResults.isEmpty) {
        return _buildNoFilterResultsState();
      }
      return _buildSearchResultsList(filteredResults, query);
    }

    // Idle State — Recent Searches, Recently Viewed, Recommended For You & Trending Books
    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Recent Searches
          RecentSearchSection(
            recentSearches: _searchProvider.recentSearches,
            onSelectQuery: _executeSearchQuery,
            onDeleteQuery: (term) => _searchProvider.removeRecentSearch(term),
            onClearAll: _confirmClearHistory,
          ),

          const SizedBox(height: 20),

          // Recently Viewed Items Section
          if (_recentlyViewedItems.isNotEmpty) ...[
            _buildRecentlyViewedSection(),
            const SizedBox(height: 24),
          ],

          // Recommended For You Section
          if (_recommendedBooks.isNotEmpty) ...[
            _buildRecommendedForYouSection(),
            const SizedBox(height: 24),
          ],

          // Popular Searches (generated dynamically from recent history)
          if (_searchProvider.popularSearches.isNotEmpty) ...[
            _buildPopularSearchesSection(),
            const SizedBox(height: 24),
          ],

          // Real Trending Books from Firestore
          _buildTrendingBooksSection(),

          const SizedBox(height: 32),

          // Search Empty State Indicator
          const SearchEmptyState(),
        ],
      ),
    );
  }

  Widget _buildRecentlyViewedSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recently Viewed',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            TextButton(
              onPressed: () async {
                await RecentlyViewedService.instance.clearRecentlyViewed();
                setState(() => _recentlyViewedItems = []);
              },
              child: const Text('Clear', style: TextStyle(fontSize: 11, color: Colors.grey)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _recentlyViewedItems.length,
            itemBuilder: (context, index) {
              final item = _recentlyViewedItems[index];
              final title = (item['title'] ?? '').toString();
              final img = (item['imageUrl'] ?? '').toString();
              final isBook = item['type'] == 'book';

              return GestureDetector(
                onTap: () => _executeSearchQuery(title),
                child: Container(
                  width: 72,
                  margin: const EdgeInsets.only(right: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: SizedBox(
                          width: 72,
                          height: 76,
                          child: buildSmartImage(img, fit: BoxFit.cover, isBook: isBook),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendedForYouSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recommended For You',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 165,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _recommendedBooks.length,
            itemBuilder: (context, index) {
              final book = _recommendedBooks[index];
              return GestureDetector(
                onTap: () => _navigateToBookDetails(context, book),
                child: Container(
                  width: 100,
                  margin: const EdgeInsets.only(right: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: SizedBox(
                          width: 100,
                          height: 120,
                          child: buildSmartImage(book.coverImage, fit: BoxFit.cover, isBook: true),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        book.title,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        book.author,
                        style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPopularSearchesSection() {
    final popular = _searchProvider.popularSearches;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Popular Searches',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: popular.map((term) {
            return ActionChip(
              avatar: const Icon(Icons.trending_up_rounded, size: 14, color: AppColors.primary),
              label: Text(term),
              backgroundColor: AppColors.primaryContainer.withOpacity(0.4),
              labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
              onPressed: () => _executeSearchQuery(term),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTrendingBooksSection() {
    final trending = _searchProvider.trendingBooks;
    final isLoading = _searchProvider.isLoadingTrending;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text(
              'Trending Books',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            Text(
              'Newest Additions',
              style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (isLoading)
          SizedBox(
            height: 140,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 4,
              itemBuilder: (_, __) => Container(
                width: 90,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          )
        else if (trending.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: const Text(
              'Will appear automatically as books become popular.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          )
        else
          SizedBox(
            height: 165,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: trending.length,
              itemBuilder: (context, index) {
                final book = trending[index];
                return GestureDetector(
                  onTap: () => _navigateToBookDetails(context, book),
                  child: Container(
                    width: 100,
                    margin: const EdgeInsets.only(right: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: SizedBox(
                            width: 100,
                            height: 120,
                            child: buildSmartImage(book.coverImage, fit: BoxFit.cover, isBook: true),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          book.title,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          book.author,
                          style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildSearchResultsList(List<SearchResultModel> results, String query) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: results.length + (_searchProvider.hasMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == results.length) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    ),
                  ),
                );
              }

              final item = results[index];
              if (item.type == SearchResultType.book && item.book != null) {
                return _buildBookResultCard(context, item.book!, query);
              } else if (item.type == SearchResultType.equipment && item.equipment != null) {
                return _buildEquipmentResultCard(context, item.equipment!, query);
              }
              return const SizedBox.shrink();
            },
          ),
        ),

        // Recommendations Section "You May Also Like"
        _buildYouMayAlsoLikeSection(),
      ],
    );
  }

  Widget _buildYouMayAlsoLikeSection() {
    final trending = _searchProvider.trendingBooks.take(5).toList();
    if (trending.isEmpty) return const SizedBox.shrink();

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'You May Also Like',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: trending.length,
              itemBuilder: (context, index) {
                final b = trending[index];
                return GestureDetector(
                  onTap: () => _navigateToBookDetails(context, b),
                  child: Container(
                    width: 70,
                    margin: const EdgeInsets.only(right: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: SizedBox(
                            width: 70,
                            height: 75,
                            child: buildSmartImage(b.coverImage, fit: BoxFit.cover, isBook: true),
                          ),
                        ),
                        Text(
                          b.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookResultCard(BuildContext context, BookModel book, String query) {
    return Card(
      elevation: 1.5,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _navigateToBookDetails(context, book),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 60,
                  height: 82,
                  child: buildSmartImage(book.coverImage, fit: BoxFit.cover, isBook: true),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text('BOOK', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.blue)),
                        ),
                        const SizedBox(width: 6),
                        if (book.department.isNotEmpty)
                          Expanded(
                            child: Text(
                              book.department,
                              style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w500),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    _buildHighlightedText(
                      book.title,
                      query,
                      normalStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Text('Author: ', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        Expanded(
                          child: _buildHighlightedText(
                            book.author,
                            query,
                            normalStyle: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: book.availableCopies > 0 ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            book.availableCopies > 0 ? '${book.availableCopies} available' : 'Borrowed',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: book.availableCopies > 0 ? const Color(0xFF15803D) : const Color(0xFFDC2626),
                            ),
                          ),
                        ),
                        if (book.isbn.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Text(
                            'ISBN: ${book.isbn}',
                            style: const TextStyle(fontSize: 10, color: Colors.grey),
                          ),
                        ],
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

  Widget _buildEquipmentResultCard(BuildContext context, MarketplaceEquipmentModel equip, String query) {
    final user = FirebaseAuth.instance.currentUser;

    return Card(
      elevation: 1.5,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          RecentlyViewedService.instance.addRecentlyViewed(
            SearchResultModel.fromEquipment(equip, 100.0),
          );

          if (user != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => real_details.EquipmentDetailsPage(
                  equipment: equip,
                  userId: user.uid,
                  userName: user.displayName ?? 'User',
                  userEmail: user.email ?? '',
                  userPhone: user.phoneNumber ?? '',
                ),
              ),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 60,
                  height: 82,
                  child: buildSmartImage(
                    equip.imageUrls.isNotEmpty ? equip.imageUrls.first : '',
                    fit: BoxFit.cover,
                    isBook: false,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primaryContainer,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text('EQUIPMENT', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.primary)),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: _buildHighlightedText(
                            equip.category,
                            query,
                            normalStyle: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    _buildHighlightedText(
                      equip.equipmentName,
                      query,
                      normalStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Owner: ${equip.ownerName} • ${equip.location}',
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          '₹${equip.pricePerDay.toStringAsFixed(0)}/day',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: equip.availability ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            equip.availability ? 'Available' : 'Booked',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: equip.availability ? const Color(0xFF15803D) : const Color(0xFFDC2626),
                            ),
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

  Widget _buildHighlightedText(String fullText, String query, {TextStyle? normalStyle}) {
    final cleanQ = query.trim();
    if (cleanQ.isEmpty || fullText.isEmpty) {
      return Text(fullText, style: normalStyle);
    }

    final lowerText = fullText.toLowerCase();
    final lowerQuery = cleanQ.toLowerCase();
    final index = lowerText.indexOf(lowerQuery);

    if (index == -1) {
      return Text(fullText, style: normalStyle);
    }

    final before = fullText.substring(0, index);
    final matched = fullText.substring(index, index + cleanQ.length);
    final after = fullText.substring(index + cleanQ.length);

    return RichText(
      text: TextSpan(
        style: normalStyle ?? const TextStyle(color: AppColors.textPrimary, fontSize: 14),
        children: [
          TextSpan(text: before),
          TextSpan(
            text: matched,
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
              backgroundColor: Color(0xFFDCFCE7),
            ),
          ),
          TextSpan(text: after),
        ],
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 4,
      itemBuilder: (_, __) {
        return Card(
          elevation: 1,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 82,
                  decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(10)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(width: 80, height: 12, color: Colors.grey.shade200),
                      const SizedBox(height: 8),
                      Container(width: 140, height: 16, color: Colors.grey.shade200),
                      const SizedBox(height: 8),
                      Container(width: 100, height: 12, color: Colors.grey.shade200),
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

  Widget _buildNoResultsState(String query) {
    final typoCorrection = _searchProvider.didYouMean;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.search_off_rounded, size: 56, color: Colors.red),
            ),
            const SizedBox(height: 20),
            Text(
              'No matching results for "$query"',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            if (typoCorrection != null) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Did you mean: ', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                  ActionChip(
                    label: Text(typoCorrection, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                    backgroundColor: AppColors.primaryContainer.withOpacity(0.5),
                    onPressed: () => _executeSearchQuery(typoCorrection),
                  ),
                ],
              ),
            ] else ...[
              const SizedBox(height: 8),
              const Text(
                'Try another keyword, book title, author, or category.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNoFilterResultsState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.filter_alt_off_rounded, size: 56, color: Colors.amber),
            ),
            const SizedBox(height: 20),
            const Text(
              'No matching results',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            const Text(
              'Try changing your filters to see more results.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _filterProvider.clearAll(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Clear Filters'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 56, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _searchProvider.onQueryChanged(_searchController.text),
              child: const Text('Retry Search'),
            ),
          ],
        ),
      ),
    );
  }
}
