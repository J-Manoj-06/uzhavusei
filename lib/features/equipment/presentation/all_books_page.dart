import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shimmer/shimmer.dart';

import '../../../models/book_model.dart';
import '../../../models/marketplace_equipment_model.dart';
import '../../../services/book_repository.dart';
import 'package:UzhavuSei/theme/app_theme.dart';
import 'widgets/book_card.dart';
import 'book_details_page.dart';

// ─────────────────────────────────────────────────────────────────────────────
// All Books Page — Master Library Catalogue
// ─────────────────────────────────────────────────────────────────────────────

class AllBooksPage extends StatefulWidget {
  const AllBooksPage({super.key});

  @override
  State<AllBooksPage> createState() => _AllBooksPageState();
}

class _AllBooksPageState extends State<AllBooksPage> {
  // ── Pagination state ────────────────────────────────────────
  final List<BookModel> _books = [];
  DocumentSnapshot? _lastDoc;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  bool _isOffline = false;

  // ── Filter / search state ───────────────────────────────────
  BookFilter _filter = const BookFilter();
  String _searchQuery = '';
  Timer? _debounce;
  final TextEditingController _searchCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();

  // ── Category chips state ─────────────────────────────────────
  String _selectedCategory = 'All';
  List<String> _categories = ['All'];
  StreamSubscription<Map<String, int>>? _categorySub;

  @override
  void initState() {
    super.initState();
    _subscribeToCategoryCounts();
    _loadFirstPage();
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _categorySub?.cancel();
    _searchCtrl.dispose();
    _scrollCtrl.removeListener(_onScroll);
    _scrollCtrl.dispose();
    super.dispose();
  }

  // ── Category subscription ────────────────────────────────────

  void _subscribeToCategoryCounts() {
    _categorySub = BookRepository.instance.watchCategoryCounts().listen((counts) {
      if (!mounted) return;
      final cats = <String>['All', ...counts.keys.where((k) => k != 'All').toList()..sort()];
      setState(() => _categories = cats);
    });
  }

  // ── Scroll pagination ────────────────────────────────────────

  void _onScroll() {
    if (_scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 300) {
      _loadMore();
    }
  }

  // ── Data loading ─────────────────────────────────────────────

  Future<void> _loadFirstPage() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _books.clear();
      _lastDoc = null;
      _hasMore = true;
      _isOffline = false;
    });

    try {
      final page = await BookRepository.instance.fetchFirstPage(
        _filter,
        query: _searchQuery,
      );
      if (!mounted) return;
      setState(() {
        _books.addAll(page.books);
        _lastDoc = page.lastDoc;
        _hasMore = page.hasMore;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isOffline = true;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore || _lastDoc == null) return;
    setState(() => _isLoadingMore = true);

    try {
      final page = await BookRepository.instance.fetchNextPage(
        _filter,
        lastDoc: _lastDoc!,
        query: _searchQuery,
      );
      if (!mounted) return;
      setState(() {
        _books.addAll(page.books);
        _lastDoc = page.lastDoc;
        _hasMore = page.hasMore;
        _isLoadingMore = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  // ── Search with 300ms debounce ────────────────────────────────

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      setState(() => _searchQuery = value.trim());
      _loadFirstPage();
    });
  }

  void _clearSearch() {
    _searchCtrl.clear();
    setState(() => _searchQuery = '');
    _loadFirstPage();
  }

  // ── Category selection ────────────────────────────────────────

  void _selectCategory(String cat) {
    if (_selectedCategory == cat) return;
    setState(() {
      _selectedCategory = cat;
      _filter = _filter.copyWith(
        category: cat == 'All' ? null : cat,
      );
    });
    _loadFirstPage();
  }

  // ── Filter bottom sheet ───────────────────────────────────────

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FilterSheet(
        initialFilter: _filter,
        onApply: (newFilter) {
          setState(() => _filter = newFilter);
          _loadFirstPage();
        },
      ),
    );
  }

  // ── Navigation ────────────────────────────────────────────────

  void _openBookDetails(BookModel book) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to view book details.')),
      );
      return;
    }

    // Convert BookModel → MarketplaceEquipmentModel for the existing details page
    final equip = _bookToEquipment(book);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BookDetailsPage(
          initialItem: equip,
          userId: user.uid,
          userName: user.displayName ?? 'User',
          userEmail: user.email ?? '',
          userPhone: '9000000000',
        ),
      ),
    );
  }

  MarketplaceEquipmentModel _bookToEquipment(BookModel book) {
    return MarketplaceEquipmentModel(
      equipmentId: book.bookId,
      ownerId: '',
      equipmentName: book.title,
      category: book.category,
      description: book.description,
      titleLocalized: {'en': book.title, 'ta': book.title, 'hi': book.title},
      categoryLocalized: {'en': book.category, 'ta': book.category, 'hi': book.category},
      descriptionLocalized: {'en': book.description, 'ta': book.description, 'hi': book.description},
      pricePerHour: 0,
      pricePerDay: 0,
      location: '',
      latitude: 0,
      longitude: 0,
      imageUrls: book.imageUrls.isNotEmpty ? book.imageUrls : (book.coverImage.isNotEmpty ? [book.coverImage] : []),
      availability: book.availableCopies > 0,
      rating: book.rating,
      createdAt: book.createdAt,
      ownerName: book.author.isNotEmpty ? book.author : 'Library',
      machineSpecs: book.author,
      status: 'published',
      totalCopies: book.totalCopies,
      availableCopies: book.availableCopies,
      condition: 'Good',
      productId: book.isbn,
      productIdLower: book.isbn.toLowerCase(),
    );
  }

  // ── Build ─────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          '📚 All Books',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded, color: AppColors.primary),
            onPressed: _showFilterSheet,
            tooltip: 'Filters',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: _buildSearchBar(),
        ),
      ),
      body: Column(
        children: [
          // Category chips
          _buildCategoryChips(),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),

          // Offline banner
          if (_isOffline) _buildOfflineBanner(),

          // Book grid
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadFirstPage,
              color: AppColors.primary,
              child: _isLoading ? _buildSkeleton() : _buildGrid(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          children: [
            const SizedBox(width: 14),
            const Icon(Icons.search, color: Colors.grey, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _searchCtrl,
                onChanged: _onSearchChanged,
                style: const TextStyle(fontSize: 14),
                decoration: const InputDecoration(
                  hintText: 'Search by title, author, ISBN...',
                  hintStyle: TextStyle(color: Colors.grey, fontSize: 13),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            if (_searchQuery.isNotEmpty)
              GestureDetector(
                onTap: _clearSearch,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Icon(Icons.close, color: Colors.grey, size: 18),
                ),
              )
            else
              const SizedBox(width: 14),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChips() {
    return Container(
      color: Colors.white,
      height: 48,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _categories.length,
        itemBuilder: (context, i) {
          final cat = _categories[i];
          final selected = cat == _selectedCategory;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(
                cat,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : AppColors.textPrimary,
                ),
              ),
              selected: selected,
              onSelected: (_) => _selectCategory(cat),
              selectedColor: AppColors.primary,
              backgroundColor: AppColors.background,
              side: BorderSide(
                color: selected ? AppColors.primary : const Color(0xFFE5E7EB),
              ),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              padding: const EdgeInsets.symmetric(horizontal: 4),
            ),
          );
        },
      ),
    );
  }

  Widget _buildOfflineBanner() {
    return Container(
      width: double.infinity,
      color: const Color(0xFFFFF3E0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: const Row(
        children: [
          Icon(Icons.wifi_off_rounded, color: Colors.orange, size: 16),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'You\'re offline. Showing cached books.',
              style: TextStyle(fontSize: 12, color: Color(0xFF795548)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid() {
    if (_books.isEmpty && !_isLoadingMore) {
      return _buildEmptyState();
    }

    return GridView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 16,
        childAspectRatio: 0.52,
      ),
      itemCount: _books.length + (_isLoadingMore ? 2 : 0),
      itemBuilder: (context, i) {
        if (i >= _books.length) {
          return _buildSkeletonCard();
        }
        final book = _books[i];
        return BookCard(
          book: book,
          onTap: () => _openBookDetails(book),
        );
      },
    );
  }

  Widget _buildSkeleton() {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 16,
        childAspectRatio: 0.52,
      ),
      itemCount: 8,
      itemBuilder: (_, __) => _buildSkeletonCard(),
    );
  }

  Widget _buildSkeletonCard() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade200,
      highlightColor: Colors.grey.shade100,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
      ),
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
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.menu_book_rounded,
                size: 64,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No books available yet.',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isNotEmpty
                  ? 'No books matched "$_searchQuery". Try clearing your search.'
                  : 'Books will appear here automatically when added by the librarian.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                if (_searchQuery.isNotEmpty) {
                  _clearSearch();
                } else {
                  _loadFirstPage();
                }
              },
              icon: const Icon(Icons.refresh_rounded),
              label: Text(_searchQuery.isNotEmpty ? 'Clear Search' : 'Refresh'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Filter Bottom Sheet
// ─────────────────────────────────────────────────────────────────────────────

class _FilterSheet extends StatefulWidget {
  final BookFilter initialFilter;
  final ValueChanged<BookFilter> onApply;

  const _FilterSheet({required this.initialFilter, required this.onApply});

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late BookFilter _filter;
  final TextEditingController _authorCtrl = TextEditingController();
  final TextEditingController _publisherCtrl = TextEditingController();

  static const _sortOptions = [
    ('newest', 'Newest First'),
    ('oldest', 'Oldest First'),
    ('az', 'A → Z'),
    ('za', 'Z → A'),
    ('mostAvailable', 'Most Available'),
    ('lowStock', 'Low Stock Only'),
  ];

  static const _languages = ['All', 'English', 'Tamil', 'Hindi', 'Telugu', 'Kannada', 'Malayalam'];

  @override
  void initState() {
    super.initState();
    _filter = widget.initialFilter;
    _authorCtrl.text = _filter.author ?? '';
    _publisherCtrl.text = _filter.publisher ?? '';
  }

  @override
  void dispose() {
    _authorCtrl.dispose();
    _publisherCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: 16,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
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
            const SizedBox(height: 20),

            // Title row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Filters',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _filter = const BookFilter();
                      _authorCtrl.clear();
                      _publisherCtrl.clear();
                    });
                  },
                  child: const Text('Reset All'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Sort by
            _sectionLabel('Sort By'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _sortOptions.map((opt) {
                final selected = _filter.sortBy == opt.$1;
                return ChoiceChip(
                  label: Text(opt.$2, style: const TextStyle(fontSize: 12)),
                  selected: selected,
                  onSelected: (_) => setState(() => _filter = _filter.copyWith(sortBy: opt.$1)),
                  selectedColor: AppColors.primary,
                  backgroundColor: AppColors.background,
                  side: BorderSide(
                      color: selected ? AppColors.primary : const Color(0xFFE5E7EB)),
                  labelStyle: TextStyle(
                      color: selected ? Colors.white : AppColors.textPrimary,
                      fontWeight: FontWeight.w600),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Availability toggle
            _sectionLabel('Availability'),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Available books only', style: TextStyle(fontSize: 14)),
              value: _filter.availableOnly == true,
              onChanged: (v) => setState(
                  () => _filter = _filter.copyWith(availableOnly: v ? true : null)),
              activeTrackColor: AppColors.primary,
            ),
            const SizedBox(height: 16),

            // Language
            _sectionLabel('Language'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _languages.map((lang) {
                final selected = (_filter.language ?? 'All') == lang;
                return ChoiceChip(
                  label: Text(lang, style: const TextStyle(fontSize: 12)),
                  selected: selected,
                  onSelected: (_) => setState(() =>
                      _filter = _filter.copyWith(language: lang == 'All' ? null : lang)),
                  selectedColor: AppColors.primary,
                  backgroundColor: AppColors.background,
                  side: BorderSide(
                      color: selected ? AppColors.primary : const Color(0xFFE5E7EB)),
                  labelStyle: TextStyle(
                      color: selected ? Colors.white : AppColors.textPrimary,
                      fontWeight: FontWeight.w600),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Author text field
            _sectionLabel('Author'),
            TextField(
              controller: _authorCtrl,
              onChanged: (v) => _filter = _filter.copyWith(author: v.isEmpty ? null : v),
              decoration: InputDecoration(
                hintText: 'e.g. Robert Kiyosaki',
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Publisher text field
            _sectionLabel('Publisher'),
            TextField(
              controller: _publisherCtrl,
              onChanged: (v) => _filter = _filter.copyWith(publisher: v.isEmpty ? null : v),
              decoration: InputDecoration(
                hintText: 'e.g. Penguin Random House',
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
              ),
            ),
            const SizedBox(height: 28),

            // Apply button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  final finalFilter = _filter.copyWith(
                    author: _authorCtrl.text.trim().isEmpty ? null : _authorCtrl.text.trim(),
                    publisher: _publisherCtrl.text.trim().isEmpty ? null : _publisherCtrl.text.trim(),
                  );
                  Navigator.pop(context);
                  widget.onApply(finalFilter);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: const Text(
                  'Apply Filters',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}
