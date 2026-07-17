import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import '../../../models/app_user_model.dart';
import '../../../models/marketplace_equipment_model.dart';
import '../../../services/marketplace_service.dart';
import '../../../services/location_service.dart';
import '../../../services/logger_service.dart';
import 'package:geolocator/geolocator.dart';

import 'widgets/borrow_image_picker.dart';
import 'widgets/listing_draft_manager.dart';
import '../../../services/cloudinary_service.dart';


// ── CATEGORY SELECTION PAGE ──────────────────────────────────────────────────

class _CategoryMeta {
  final String emoji;
  final String label;
  final String keywords;
  final Widget Function(BuildContext, AppUserModel) formBuilder;
  final bool isAvailable;

  const _CategoryMeta({
    required this.emoji,
    required this.label,
    required this.keywords,
    required this.formBuilder,
    this.isAvailable = true,
  });
}

class CategorySelectionPage extends StatefulWidget {
  const CategorySelectionPage({
    super.key,
    required this.currentUser,
  });

  final AppUserModel currentUser;

  @override
  State<CategorySelectionPage> createState() => _CategorySelectionPageState();
}

class _CategorySelectionPageState extends State<CategorySelectionPage> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  late final List<_CategoryMeta> _categories;

  @override
  void initState() {
    super.initState();
    _categories = [
      _CategoryMeta(
        emoji: '📚',
        label: 'Books',
        keywords: 'books novels academic reference engineering exam school library textbook study',
        formBuilder: (ctx, user) => BookListingFormPage(currentUser: user),
      ),
      _CategoryMeta(
        emoji: '🚜',
        label: 'Farm Equipment',
        keywords: 'farm equipment tractor rotavator sprayer seeder cultivator harvester agriculture crop machinery tool',
        formBuilder: (ctx, user) => FarmEquipmentFormPage(currentUser: user),
      ),
      _CategoryMeta(
        emoji: '🏗️',
        label: 'Construction Equipment',
        keywords: 'construction tools equipment drill machine ladder concrete mixer power tools safety helmet drill saw',
        formBuilder: (ctx, user) => ConstructionEquipmentFormPage(currentUser: user),
      ),
    ];
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<_CategoryMeta> get _filteredCategories {
    if (_searchQuery.trim().isEmpty) return _categories;
    final query = _searchQuery.toLowerCase().trim();
    return _categories.where((c) {
      return c.label.toLowerCase().contains(query) || c.keywords.toLowerCase().contains(query);
    }).toList();
  }

  void _onCategoryTap(_CategoryMeta category) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => category.formBuilder(ctx, widget.currentUser),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredCategories;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: const Text('Share an Item', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1A1A1A))),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isTablet = constraints.maxWidth > 600;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title & Search Header
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Share an Item',
                      style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Choose a category to create your listing.',
                      style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 20),
                    _buildSearchBar(),
                  ],
                ),
              ),

              // Scrollable Body
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  children: [
                    _buildGridSection(filtered, isTablet),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Icon(Icons.search, color: Colors.grey.shade500),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _searchCtrl,
              decoration: const InputDecoration(
                hintText: 'Search categories...',
                hintStyle: TextStyle(color: Colors.grey),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 14),
              ),
              onChanged: (val) {
                setState(() => _searchQuery = val);
              },
            ),
          ),
          if (_searchQuery.isNotEmpty)
            GestureDetector(
              onTap: () {
                _searchCtrl.clear();
                setState(() => _searchQuery = '');
              },
              child: Icon(Icons.close, color: Colors.grey.shade500),
            ),
        ],
      ),
    );
  }


  Widget _buildGridSection(List<_CategoryMeta> items, bool isTablet) {
    if (items.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 48),
        alignment: Alignment.center,
        child: Column(
          children: [
            const Icon(Icons.search_off_rounded, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'No categories found.',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)),
            ),
            const SizedBox(height: 4),
            Text(
              'Try another keyword.',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'All Categories',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey.shade800, letterSpacing: 0.5),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isTablet ? 3 : 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.5,
          ),
          itemCount: items.length,
          itemBuilder: (ctx, idx) {
            final c = items[idx];
            return _buildCategoryGridCard(c);
          },
        ),
      ],
    );
  }

  Widget _buildCategoryGridCard(_CategoryMeta category) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.95, end: 1.0),
      duration: const Duration(milliseconds: 200),
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: child,
        );
      },
      child: GestureDetector(
        onTap: () => _onCategoryTap(category),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFEBEFF0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(category.emoji, style: const TextStyle(fontSize: 28)),
                  const Icon(Icons.arrow_forward, size: 16, color: Colors.grey),
                ],
              ),
              Text(
                category.label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1A1A1A)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── BOOK LISTING FORM ────────────────────────────────────────────────────────

class BookListingFormPage extends StatefulWidget {
  const BookListingFormPage({super.key, required this.currentUser, this.existing});
  final AppUserModel currentUser;
  final MarketplaceEquipmentModel? existing;

  @override
  State<BookListingFormPage> createState() => _BookListingFormPageState();
}

class _BookListingFormPageState extends State<BookListingFormPage> with WidgetsBindingObserver {
  final _formKey = GlobalKey<FormState>();
  final MarketplaceService _service = MarketplaceService();
  final ImagePicker _picker = ImagePicker();

  late TextEditingController _titleCtrl;
  late TextEditingController _authorCtrl;
  late TextEditingController _languageCtrl;
  late TextEditingController _publisherCtrl;
  late TextEditingController _pubYearCtrl;
  late TextEditingController _editionCtrl;
  late TextEditingController _isbnCtrl;
  late TextEditingController _pagesCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _qtyCtrl;

  int _activeStep = 0;
  String _genre = 'Academic';
  String _condition = 'Good';
  bool _availability = true;
  bool _submitting = false;
  final List<BorrowImageItem> _pickerImages = [];
  double _uploadProgress = 0.0;
  String _uploadStatus = '';
  bool _waitingForGps = false;
  bool _gpsDisabledBannerVisible = false;

  DateTime? _availableFrom;
  DateTime? _availableUntil;
  bool _loadingDraft = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    _titleCtrl = TextEditingController();
    _authorCtrl = TextEditingController();
    _languageCtrl = TextEditingController(text: 'English');
    _publisherCtrl = TextEditingController();
    _pubYearCtrl = TextEditingController();
    _editionCtrl = TextEditingController();
    _isbnCtrl = TextEditingController();
    _pagesCtrl = TextEditingController();
    _descCtrl = TextEditingController();
    _qtyCtrl = TextEditingController(text: '1');

    if (widget.existing != null) {
      final specsStr = widget.existing!.machineSpecs;
      _titleCtrl.text = widget.existing!.equipmentName;
      _authorCtrl.text = _parseSpec(specsStr, 'Author: ');
      _languageCtrl.text = _parseSpec(specsStr, 'Language: ', defaultValue: 'English');
      _publisherCtrl.text = _parseSpec(specsStr, 'Publisher: ');
      _pubYearCtrl.text = _parseSpec(specsStr, 'Year: ');
      _editionCtrl.text = _parseSpec(specsStr, 'Edition: ');
      _isbnCtrl.text = _parseSpec(specsStr, 'ISBN: ');
      _genre = _parseSpec(specsStr, 'Genre: ', defaultValue: 'Academic');
      _pagesCtrl.text = _parseSpec(specsStr, 'Pages: ');
      _condition = widget.existing!.condition;
      _descCtrl.text = widget.existing!.description;
      _qtyCtrl.text = widget.existing!.minRentalDuration.toInt().toString();
      _availability = widget.existing!.availability;
      _availableFrom = widget.existing!.availabilityFrom;
      _availableUntil = widget.existing!.availabilityTo;
      _pickerImages.addAll(widget.existing!.imageUrls.map((u) => BorrowImageItem(remoteUrl: u)));
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await _loadDraft();
      });
    }

    _titleCtrl.addListener(_saveDraft);
    _authorCtrl.addListener(_saveDraft);
    _languageCtrl.addListener(_saveDraft);
    _publisherCtrl.addListener(_saveDraft);
    _pubYearCtrl.addListener(_saveDraft);
    _editionCtrl.addListener(_saveDraft);
    _isbnCtrl.addListener(_saveDraft);
    _pagesCtrl.addListener(_saveDraft);
    _descCtrl.addListener(_saveDraft);
    _qtyCtrl.addListener(_saveDraft);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _titleCtrl.dispose();
    _authorCtrl.dispose();
    _languageCtrl.dispose();
    _publisherCtrl.dispose();
    _pubYearCtrl.dispose();
    _editionCtrl.dispose();
    _isbnCtrl.dispose();
    _pagesCtrl.dispose();
    _descCtrl.dispose();
    _qtyCtrl.dispose();
    super.dispose();
  }

  String _parseSpec(String specs, String prefix, {String defaultValue = ''}) {
    if (specs.isEmpty) return defaultValue;
    try {
      final parts = specs.split(', ');
      final found = parts.firstWhere((p) => p.startsWith(prefix), orElse: () => '');
      if (found.isNotEmpty) {
        return found.replaceAll(prefix, '');
      }
    } catch (_) {}
    return defaultValue;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _waitingForGps) {
      _checkGpsAndContinuePublishing();
    }
  }

  Future<void> _checkGpsAndContinuePublishing() async {
    setState(() {
      _submitting = true;
      _uploadProgress = 0.0;
      _uploadStatus = 'Checking location...';
      _gpsDisabledBannerVisible = false;
    });

    final isGpsEnabled = await LocationService.instance.isLocationServiceEnabled();
    if (!isGpsEnabled) {
      setState(() {
        _submitting = false;
        _waitingForGps = false;
        _gpsDisabledBannerVisible = true;
      });
      return;
    }

    _waitingForGps = false;
    _continuePublishingWithLocation();
  }

  Future<void> _continuePublishingWithLocation() async {
    setState(() {
      _submitting = true;
      _uploadStatus = 'Getting your location...';
      _uploadProgress = 0.0;
    });

    try {
      final locResult = await LocationService.instance.getCurrentLocation();
      if (locResult is LocationFailure) {
        setState(() {
          _submitting = false;
        });
        if (locResult.isPermanent) {
          _showErrorBottomSheet(
            title: 'Permission Required',
            message: 'Borrow needs location permissions. Please enable them in your app settings to proceed.',
            actionLabel: 'Open Settings',
            onAction: () => Geolocator.openAppSettings(),
          );
        } else {
          _showErrorBottomSheet(
            title: 'Location Error',
            message: locResult.reason,
            actionLabel: 'Retry',
            onAction: () => _continuePublishingWithLocation(),
          );
        }
        return;
      }

      final loc = (locResult as LocationSuccess).location;
      await _publishWithLocation(loc);
    } catch (e) {
      setState(() => _submitting = false);
      _showErrorBottomSheet(
        title: 'Publish Failed',
        message: 'Something went wrong while getting your location: $e',
        actionLabel: 'Retry',
        onAction: () => _continuePublishingWithLocation(),
      );
    }
  }

  Future<void> _publishWithLocation(VerifiedLocation loc) async {
    setState(() {
      _submitting = true;
      _uploadStatus = 'Publishing Listing...';
      _uploadProgress = 0.0;
    });

    try {
      final List<String> finalUrls = [];
      final CloudinaryService cloudinary = CloudinaryService();

      for (var i = 0; i < _pickerImages.length; i++) {
        final img = _pickerImages[i];
        setState(() {
          _uploadStatus = 'Publishing Listing...';
          _uploadProgress = (i / _pickerImages.length);
        });

        if (img.isLocal) {
          final secureUrl = await cloudinary.uploadImage(img.localFile!);
          finalUrls.add(secureUrl);
        } else {
          finalUrls.add(img.remoteUrl!);
        }
      }

      setState(() {
        _uploadStatus = 'Publishing Listing...';
        _uploadProgress = 1.0;
      });

      final specs = 'Author: ${_authorCtrl.text.trim()}, Language: ${_languageCtrl.text.trim()}, Publisher: ${_publisherCtrl.text.trim()}, Year: ${_pubYearCtrl.text.trim()}, Edition: ${_editionCtrl.text.trim()}, ISBN: ${_isbnCtrl.text.trim()}, Genre: $_genre, Pages: ${_pagesCtrl.text.trim()}';

      final model = MarketplaceEquipmentModel(
        equipmentId: widget.existing?.equipmentId ?? '',
        ownerId: widget.currentUser.userId,
        ownerName: widget.currentUser.name,
        equipmentName: _titleCtrl.text.trim(),
        category: 'Books',
        description: _descCtrl.text.trim(),
        titleLocalized: {'en': _titleCtrl.text.trim()},
        categoryLocalized: {'en': 'Books'},
        descriptionLocalized: {'en': _descCtrl.text.trim()},
        pricePerHour: 0.0,
        pricePerDay: 0.0,
        location: [loc.area, loc.city].where((e) => e != null && e.isNotEmpty).join(', '),
        latitude: loc.latitude,
        longitude: loc.longitude,
        area: loc.area ?? '',
        city: loc.city ?? '',
        state: loc.state ?? '',
        country: loc.country ?? '',
        locationAccuracy: loc.accuracy ?? 0.0,
        locationCapturedAt: loc.timestamp,
        imageUrls: finalUrls,
        availability: _availability,
        rating: 5.0,
        createdAt: widget.existing?.createdAt ?? DateTime.now(),
        machineSpecs: specs,
        condition: _condition,
        minRentalDuration: double.tryParse(_qtyCtrl.text.trim()) ?? 1.0,
        priceType: 'day',
        status: 'published',
        views: widget.existing?.views ?? 0,
        savedBy: widget.existing?.savedBy ?? [],
        bookingsCount: widget.existing?.bookingsCount ?? 0,
        availabilityFrom: _availableFrom,
        availabilityTo: _availableUntil,
      );

      if (widget.existing != null) {
        await _service.updateEquipment(equipmentId: widget.existing!.equipmentId, updates: model.toMap());
      } else {
        await _service.addEquipment(model);
        await ListingDraftManager.clearDraft('Books');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('🎉 Listing Published Successfully'), backgroundColor: Color(0xFF2E7D32)),
        );
        Navigator.popUntil(context, (r) => r.isFirst);
      }
    } catch (e) {
      LoggerService.error('Error publishing listing', e);
      setState(() => _submitting = false);
      _showErrorBottomSheet(
        title: 'Publish Failed',
        message: 'Failed to upload images or save listing: $e. Please check your internet connection.',
        actionLabel: 'Retry',
        onAction: () => _publishWithLocation(loc),
      );
    }
  }

  Future<void> _publish() async {
    if (!_formKey.currentState!.validate()) return;
    if (_pickerImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload at least one image.'), backgroundColor: Colors.red),
      );
      return;
    }
    if (_availableFrom == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an available start date.'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() {
      _submitting = true;
      _uploadProgress = 0.0;
      _uploadStatus = 'Checking location...';
    });

    try {
      final result = await InternetAddress.lookup('example.com');
      if (result.isEmpty || result[0].rawAddress.isEmpty) {
        throw const SocketException("No internet connection");
      }
    } catch (_) {
      setState(() => _submitting = false);
      _showErrorBottomSheet(
        title: 'No Internet Connection',
        message: 'Borrow requires an active internet connection to publish listings.',
        actionLabel: 'Retry',
        onAction: () => _publish(),
      );
      return;
    }

    final isGpsEnabled = await LocationService.instance.isLocationServiceEnabled();
    if (!isGpsEnabled) {
      setState(() => _submitting = false);
      _showGpsRequiredBottomSheet();
      return;
    }

    _continuePublishingWithLocation();
  }

  void _showGpsRequiredBottomSheet() {
    showModalBottomSheet(
      context: context,
      isDismissible: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('📍', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 16),
              const Text(
                'Location Required',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Color(0xFF1A1A1A)),
              ),
              const SizedBox(height: 12),
              const Text(
                'Borrow needs your location to publish this listing and recommend it to nearby users. Your exact address will never be shared.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF6F7A6B), fontSize: 14, height: 1.4),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    setState(() {
                      _waitingForGps = true;
                    });
                    Geolocator.openLocationSettings();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Enable GPS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey.shade700,
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showErrorBottomSheet({
    required String title,
    required String message,
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    showModalBottomSheet(
      context: context,
      isDismissible: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.info_outline, color: Colors.orange, size: 48),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Color(0xFF1A1A1A)),
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14, height: 1.4),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    onAction();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(actionLabel, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey.shade700,
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGpsDisabledBanner() {
    if (!_gpsDisabledBannerVisible) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3CD),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFEEBA)),
      ),
      child: Row(
        children: [
          const Text('📍', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'GPS is still disabled. Enable location to publish your listing.',
              style: TextStyle(color: Color(0xFF856404), fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () {
              setState(() {
                _waitingForGps = true;
              });
              Geolocator.openLocationSettings();
            },
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF2E7D32),
              padding: EdgeInsets.zero,
              minimumSize: const Size(50, 30),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('Enable', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _loadDraft() async {
    if (widget.existing != null) return;
    setState(() => _loadingDraft = true);
    final draft = await ListingDraftManager.loadDraft('Books');
    if (draft != null && mounted) {
      setState(() {
        _titleCtrl.text = draft['title'] ?? '';
        _authorCtrl.text = draft['author'] ?? '';
        _languageCtrl.text = draft['language'] ?? 'English';
        _publisherCtrl.text = draft['publisher'] ?? '';
        _pubYearCtrl.text = draft['year'] ?? '';
        _editionCtrl.text = draft['edition'] ?? '';
        _isbnCtrl.text = draft['isbn'] ?? '';
        _pagesCtrl.text = draft['pages'] ?? '';
        _descCtrl.text = draft['description'] ?? '';
        _qtyCtrl.text = draft['quantity'] ?? '1';
        _genre = draft['genre'] ?? 'Academic';
        _condition = draft['condition'] ?? 'Good';
        _availability = draft['availability'] ?? true;
        if (draft['from'] != null) {
          _availableFrom = DateTime.tryParse(draft['from']);
        }
        if (draft['until'] != null) {
          _availableUntil = DateTime.tryParse(draft['until']);
        }
        final List<dynamic> imgPaths = draft['imagePaths'] ?? [];
        _pickerImages.clear();
        for (var p in imgPaths) {
          _pickerImages.add(BorrowImageItem(localFile: File(p)));
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✍ Restored your unfinished book draft.'),
          backgroundColor: Color(0xFF2E7D32),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
    setState(() => _loadingDraft = false);
  }

  void _saveDraft() {
    if (_loadingDraft || widget.existing != null) return;
    final draft = {
      'title': _titleCtrl.text,
      'author': _authorCtrl.text,
      'language': _languageCtrl.text,
      'publisher': _publisherCtrl.text,
      'year': _pubYearCtrl.text,
      'edition': _editionCtrl.text,
      'isbn': _isbnCtrl.text,
      'pages': _pagesCtrl.text,
      'description': _descCtrl.text,
      'quantity': _qtyCtrl.text,
      'genre': _genre,
      'condition': _condition,
      'availability': _availability,
      'from': _availableFrom?.toIso8601String(),
      'until': _availableUntil?.toIso8601String(),
      'imagePaths': _pickerImages.where((i) => i.isLocal).map((i) => i.localFile!.path).toList(),
    };
    ListingDraftManager.saveDraft('Books', draft);
  }

  Future<void> _selectDate(BuildContext context, bool isFrom) async {
    final DateTime now = DateTime.now();
    final DateTime firstDate = isFrom
        ? DateTime(now.year, now.month, now.day)
        : (_availableFrom ?? DateTime(now.year, now.month, now.day));

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isFrom
          ? (_availableFrom ?? firstDate)
          : (_availableUntil ?? firstDate),
      firstDate: firstDate,
      lastDate: DateTime(now.year + 5),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF2E7D32),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isFrom) {
          _availableFrom = picked;
          if (_availableUntil != null && _availableUntil!.isBefore(_availableFrom!)) {
            _availableUntil = null;
          }
        } else {
          _availableUntil = picked;
        }
      });
      _saveDraft();
    }
  }

  Widget _buildStepIndicator() {
    final steps = ['Media & Info', 'Details', 'Availability'];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: List.generate(steps.length, (idx) {
          final isActive = idx == _activeStep;
          final isCompleted = idx < _activeStep;
          return Expanded(
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isActive
                        ? const Color(0xFF2E7D32)
                        : (isCompleted ? const Color(0xFFE8F5E9) : Colors.grey.shade200),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: isCompleted
                      ? const Icon(Icons.check, size: 14, color: Color(0xFF2E7D32))
                      : Text(
                          '${idx + 1}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isActive ? Colors.white : Colors.grey.shade600,
                          ),
                        ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    steps[idx],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                      color: isActive ? const Color(0xFF2E7D32) : Colors.grey.shade600,
                    ),
                  ),
                ),
                if (idx < steps.length - 1)
                  Icon(Icons.chevron_right, size: 14, color: Colors.grey.shade400),
              ],
            ),
          );
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF8),
      appBar: AppBar(
        title: const Text('Share a Book', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          if (widget.existing == null)
            TextButton.icon(
              onPressed: () {
                _saveDraft();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('💾 Draft Saved Locally'), backgroundColor: Color(0xFF2E7D32)),
                );
              },
              icon: const Icon(Icons.save_outlined, color: Color(0xFF2E7D32)),
              label: const Text('Save Draft', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
            ),
        ],
      ),
      body: _submitting
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(value: _uploadProgress, color: const Color(0xFF2E7D32)),
                    const SizedBox(height: 16),
                    Text(
                      _uploadStatus,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${(_uploadProgress * 100).toInt()}%',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                    ),
                  ],
                ),
              ),
            )
          : Form(
              key: _formKey,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: _buildStepIndicator(),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(24),
                      children: [
                        _buildGpsDisabledBanner(),
                        if (_activeStep == 0) ...[
                          Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(color: Colors.grey.shade200),
                            ),
                            color: Colors.white,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  BorrowImagePicker(
                                    initialImages: _pickerImages,
                                    onImagesChanged: (list) {
                                      setState(() {
                                        _pickerImages.clear();
                                        _pickerImages.addAll(list);
                                      });
                                      _saveDraft();
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildTextField('Book Title *', _titleCtrl, validator: (v) => v!.isEmpty ? 'Enter book title' : null),
                          const SizedBox(height: 16),
                          _buildTextField('Description *', _descCtrl, maxLines: 4, validator: (v) => v!.isEmpty ? 'Enter description' : null),
                          const SizedBox(height: 16),
                          _buildConditionDropdown(),
                        ],
                        if (_activeStep == 1) ...[
                          _buildTextField('Author *', _authorCtrl, validator: (v) => v!.isEmpty ? 'Enter author name' : null),
                          const SizedBox(height: 16),
                          _buildTextField('Language *', _languageCtrl, validator: (v) => v!.isEmpty ? 'Enter language' : null),
                          const SizedBox(height: 16),
                          _buildTextField('Publisher (Optional)', _publisherCtrl),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(child: _buildTextField('Publication Year (Optional)', _pubYearCtrl, isNumeric: true)),
                              const SizedBox(width: 16),
                              Expanded(child: _buildTextField('Edition (Optional)', _editionCtrl)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(child: _buildTextField('ISBN (Optional)', _isbnCtrl)),
                              const SizedBox(width: 16),
                              Expanded(child: _buildTextField('Number of Pages (Optional)', _pagesCtrl, isNumeric: true)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildGenreDropdown(),
                        ],
                        if (_activeStep == 2) ...[
                          _buildTextField('Available Quantity *', _qtyCtrl, isNumeric: true, validator: (v) => v!.isEmpty ? 'Enter available quantity' : null),
                          const SizedBox(height: 20),
                          const Text('Borrowing Period *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: () => _selectDate(context, true),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.grey.shade400),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Available From', style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
                                        const SizedBox(height: 4),
                                        Text(
                                          _availableFrom == null ? 'Select Date' : DateFormat('yyyy-MM-dd').format(_availableFrom!),
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: InkWell(
                                  onTap: () => _selectDate(context, false),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.grey.shade400),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Available Until', style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
                                        const SizedBox(height: 4),
                                        Text(
                                          _availableUntil == null ? 'Optional' : DateFormat('yyyy-MM-dd').format(_availableUntil!),
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          SwitchListTile(
                            title: const Text('Available for Borrowing', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            activeColor: const Color(0xFF2E7D32),
                            value: _availability,
                            onChanged: (val) {
                              setState(() => _availability = val);
                              _saveDraft();
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                  _buildStepperFooter(),
                ],
              ),
            ),
    );
  }

  Widget _buildStepperFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_activeStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  setState(() {
                    _activeStep--;
                  });
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF2E7D32),
                  side: const BorderSide(color: Color(0xFF2E7D32)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  minimumSize: const Size(0, 48),
                ),
                child: const Text('Back', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            )
          else
            const Spacer(),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  if (_activeStep < 2) {
                    setState(() {
                      _activeStep++;
                    });
                  } else {
                    _publish();
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                minimumSize: const Size(0, 48),
              ),
              child: Text(
                _activeStep < 2 ? 'Next' : 'Publish',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController ctrl, {bool isNumeric = false, int maxLines = 1, String? Function(String?)? validator}) {
    return TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey.shade600),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }

  Widget _buildConditionDropdown() {
    return DropdownButtonFormField<String>(
      value: _condition,
      decoration: InputDecoration(
        labelText: 'Condition *',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
      ),
      items: ['New', 'Like New', 'Good', 'Fair', 'Poor']
          .map((c) => DropdownMenuItem(value: c, child: Text(c)))
          .toList(),
      onChanged: (val) {
        setState(() => _condition = val!);
        _saveDraft();
      },
    );
  }

  Widget _buildGenreDropdown() {
    return DropdownButtonFormField<String>(
      value: _genre,
      decoration: InputDecoration(
        labelText: 'Genre',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
      ),
      items: ['Academic', 'Novel', 'Biography', 'Reference', 'Competitive Exam', 'Children', 'Magazine', 'Other']
          .map((g) => DropdownMenuItem(value: g, child: Text(g)))
          .toList(),
      onChanged: (val) {
        setState(() => _genre = val!);
        _saveDraft();
      },
    );
  }
}

// ── FARM EQUIPMENT FORM ──────────────────────────────────────────────────────

class FarmEquipmentFormPage extends StatefulWidget {
  const FarmEquipmentFormPage({super.key, required this.currentUser, this.existing});
  final AppUserModel currentUser;
  final MarketplaceEquipmentModel? existing;

  @override
  State<FarmEquipmentFormPage> createState() => _FarmEquipmentFormPageState();
}

class _FarmEquipmentFormPageState extends State<FarmEquipmentFormPage> with WidgetsBindingObserver {
  final _formKey = GlobalKey<FormState>();
  final MarketplaceService _service = MarketplaceService();
  final ImagePicker _picker = ImagePicker();

  late TextEditingController _nameCtrl;
  late TextEditingController _brandCtrl;
  late TextEditingController _yearCtrl;
  late TextEditingController _modelCtrl;
  late TextEditingController _instructionsCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _customDurationCtrl;

  int _activeStep = 0;
  String _type = 'Tractor';
  String _condition = 'Good';
  String _fuel = 'Diesel';
  String _delivery = 'Pickup Only';
  String _duration = '1 Week';
  bool _operatorRequired = false;
  bool _availability = true;
  bool _submitting = false;
  final List<BorrowImageItem> _pickerImages = [];
  double _uploadProgress = 0.0;
  String _uploadStatus = '';
  bool _waitingForGps = false;
  bool _gpsDisabledBannerVisible = false;

  DateTime? _availableFrom;
  DateTime? _availableUntil;
  bool _loadingDraft = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _nameCtrl = TextEditingController();
    _brandCtrl = TextEditingController();
    _yearCtrl = TextEditingController();
    _modelCtrl = TextEditingController();
    _instructionsCtrl = TextEditingController();
    _descCtrl = TextEditingController();
    _customDurationCtrl = TextEditingController();

    if (widget.existing != null) {
      final specsStr = widget.existing!.machineSpecs;
      _nameCtrl.text = widget.existing!.equipmentName;
      _brandCtrl.text = _parseSpec(specsStr, 'Brand: ');
      _type = _parseSpec(specsStr, 'Type: ', defaultValue: 'Tractor');
      _yearCtrl.text = _parseSpec(specsStr, 'Year: ');
      _modelCtrl.text = _parseSpec(specsStr, 'Model: ');
      _condition = widget.existing!.condition;
      _instructionsCtrl.text = _parseSpec(specsStr, 'Instructions: ');
      _fuel = _parseSpec(specsStr, 'Fuel Type: ', defaultValue: 'Diesel');
      _delivery = _parseSpec(specsStr, 'Delivery: ', defaultValue: 'Pickup Only');
      _duration = _parseSpec(specsStr, 'Max Duration: ', defaultValue: '1 Week');
      if (!['1 Day', '2 Days', '3 Days', '1 Week', '2 Weeks'].contains(_duration)) {
        _customDurationCtrl.text = _duration;
        _duration = 'Custom';
      }
      _operatorRequired = _parseSpec(specsStr, 'Operator: ') == 'Yes';
      _descCtrl.text = widget.existing!.description;
      _availability = widget.existing!.availability;
      _availableFrom = widget.existing!.availabilityFrom;
      _availableUntil = widget.existing!.availabilityTo;
      _pickerImages.addAll(widget.existing!.imageUrls.map((u) => BorrowImageItem(remoteUrl: u)));
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await _loadDraft();
      });
    }

    _nameCtrl.addListener(_saveDraft);
    _brandCtrl.addListener(_saveDraft);
    _yearCtrl.addListener(_saveDraft);
    _modelCtrl.addListener(_saveDraft);
    _instructionsCtrl.addListener(_saveDraft);
    _descCtrl.addListener(_saveDraft);
    _customDurationCtrl.addListener(_saveDraft);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _nameCtrl.dispose();
    _brandCtrl.dispose();
    _yearCtrl.dispose();
    _modelCtrl.dispose();
    _instructionsCtrl.dispose();
    _descCtrl.dispose();
    _customDurationCtrl.dispose();
    super.dispose();
  }

  String _parseSpec(String specs, String prefix, {String defaultValue = ''}) {
    if (specs.isEmpty) return defaultValue;
    try {
      final parts = specs.split(', ');
      final found = parts.firstWhere((p) => p.startsWith(prefix), orElse: () => '');
      if (found.isNotEmpty) {
        return found.replaceAll(prefix, '');
      }
    } catch (_) {}
    return defaultValue;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _waitingForGps) {
      _checkGpsAndContinuePublishing();
    }
  }

  Future<void> _checkGpsAndContinuePublishing() async {
    setState(() {
      _submitting = true;
      _uploadProgress = 0.0;
      _uploadStatus = 'Checking location...';
      _gpsDisabledBannerVisible = false;
    });

    final isGpsEnabled = await LocationService.instance.isLocationServiceEnabled();
    if (!isGpsEnabled) {
      setState(() {
        _submitting = false;
        _waitingForGps = false;
        _gpsDisabledBannerVisible = true;
      });
      return;
    }

    _waitingForGps = false;
    _continuePublishingWithLocation();
  }

  Future<void> _continuePublishingWithLocation() async {
    setState(() {
      _submitting = true;
      _uploadStatus = 'Getting your location...';
      _uploadProgress = 0.0;
    });

    try {
      final locResult = await LocationService.instance.getCurrentLocation();
      if (locResult is LocationFailure) {
        setState(() {
          _submitting = false;
        });
        if (locResult.isPermanent) {
          _showErrorBottomSheet(
            title: 'Permission Required',
            message: 'Borrow needs location permissions. Please enable them in your app settings to proceed.',
            actionLabel: 'Open Settings',
            onAction: () => Geolocator.openAppSettings(),
          );
        } else {
          _showErrorBottomSheet(
            title: 'Location Error',
            message: locResult.reason,
            actionLabel: 'Retry',
            onAction: () => _continuePublishingWithLocation(),
          );
        }
        return;
      }

      final loc = (locResult as LocationSuccess).location;
      await _publishWithLocation(loc);
    } catch (e) {
      setState(() => _submitting = false);
      _showErrorBottomSheet(
        title: 'Publish Failed',
        message: 'Something went wrong while getting your location: $e',
        actionLabel: 'Retry',
        onAction: () => _continuePublishingWithLocation(),
      );
    }
  }

  Future<void> _publishWithLocation(VerifiedLocation loc) async {
    setState(() {
      _submitting = true;
      _uploadStatus = 'Publishing Listing...';
      _uploadProgress = 0.0;
    });

    try {
      final List<String> finalUrls = [];
      final CloudinaryService cloudinary = CloudinaryService();

      for (var i = 0; i < _pickerImages.length; i++) {
        final img = _pickerImages[i];
        setState(() {
          _uploadStatus = 'Publishing Listing...';
          _uploadProgress = (i / _pickerImages.length);
        });

        if (img.isLocal) {
          final secureUrl = await cloudinary.uploadImage(img.localFile!);
          finalUrls.add(secureUrl);
        } else {
          finalUrls.add(img.remoteUrl!);
        }
      }

      setState(() {
        _uploadStatus = 'Publishing Listing...';
        _uploadProgress = 1.0;
      });

      final specs = 'Brand: ${_brandCtrl.text.trim()}, Type: $_type, Year: ${_yearCtrl.text.trim()}, Model: ${_modelCtrl.text.trim()}, Fuel Type: $_fuel, Operator: ${_operatorRequired ? 'Yes' : 'No'}, Delivery: $_delivery, Max Duration: ${_duration == 'Custom' ? _customDurationCtrl.text.trim() : _duration}, Instructions: ${_instructionsCtrl.text.trim()}';

      final model = MarketplaceEquipmentModel(
        equipmentId: widget.existing?.equipmentId ?? '',
        ownerId: widget.currentUser.userId,
        ownerName: widget.currentUser.name,
        equipmentName: _nameCtrl.text.trim(),
        category: 'Farm Equipment',
        description: _descCtrl.text.trim(),
        titleLocalized: {'en': _nameCtrl.text.trim()},
        categoryLocalized: {'en': 'Farm Equipment'},
        descriptionLocalized: {'en': _descCtrl.text.trim()},
        pricePerHour: 0.0,
        pricePerDay: 0.0,
        location: [loc.area, loc.city].where((e) => e != null && e.isNotEmpty).join(', '),
        latitude: loc.latitude,
        longitude: loc.longitude,
        area: loc.area ?? '',
        city: loc.city ?? '',
        state: loc.state ?? '',
        country: loc.country ?? '',
        locationAccuracy: loc.accuracy ?? 0.0,
        locationCapturedAt: loc.timestamp,
        imageUrls: finalUrls,
        availability: _availability,
        rating: 5.0,
        createdAt: widget.existing?.createdAt ?? DateTime.now(),
        machineSpecs: specs,
        condition: _condition,
        minRentalDuration: 1.0,
        priceType: 'day',
        status: 'published',
        views: widget.existing?.views ?? 0,
        savedBy: widget.existing?.savedBy ?? [],
        bookingsCount: widget.existing?.bookingsCount ?? 0,
        availabilityFrom: _availableFrom,
        availabilityTo: _availableUntil,
      );

      if (widget.existing != null) {
        await _service.updateEquipment(equipmentId: widget.existing!.equipmentId, updates: model.toMap());
      } else {
        await _service.addEquipment(model);
        await ListingDraftManager.clearDraft('Farm Equipment');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('🎉 Listing Published Successfully'), backgroundColor: Color(0xFF2E7D32)),
        );
        Navigator.popUntil(context, (r) => r.isFirst);
      }
    } catch (e) {
      LoggerService.error('Error publishing listing', e);
      setState(() => _submitting = false);
      _showErrorBottomSheet(
        title: 'Publish Failed',
        message: 'Failed to upload images or save listing: $e. Please check your internet connection.',
        actionLabel: 'Retry',
        onAction: () => _publishWithLocation(loc),
      );
    }
  }

  Future<void> _publish() async {
    if (!_formKey.currentState!.validate()) return;
    if (_pickerImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload at least one image.'), backgroundColor: Colors.red),
      );
      return;
    }
    if (_availableFrom == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an available start date.'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() {
      _submitting = true;
      _uploadProgress = 0.0;
      _uploadStatus = 'Checking location...';
    });

    try {
      final result = await InternetAddress.lookup('example.com');
      if (result.isEmpty || result[0].rawAddress.isEmpty) {
        throw const SocketException("No internet connection");
      }
    } catch (_) {
      setState(() => _submitting = false);
      _showErrorBottomSheet(
        title: 'No Internet Connection',
        message: 'Borrow requires an active internet connection to publish listings.',
        actionLabel: 'Retry',
        onAction: () => _publish(),
      );
      return;
    }

    final isGpsEnabled = await LocationService.instance.isLocationServiceEnabled();
    if (!isGpsEnabled) {
      setState(() => _submitting = false);
      _showGpsRequiredBottomSheet();
      return;
    }

    _continuePublishingWithLocation();
  }

  void _showGpsRequiredBottomSheet() {
    showModalBottomSheet(
      context: context,
      isDismissible: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('📍', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 16),
              const Text(
                'Location Required',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Color(0xFF1A1A1A)),
              ),
              const SizedBox(height: 12),
              const Text(
                'Borrow needs your location to publish this listing and recommend it to nearby users. Your exact address will never be shared.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF6F7A6B), fontSize: 14, height: 1.4),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    setState(() {
                      _waitingForGps = true;
                    });
                    Geolocator.openLocationSettings();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Enable GPS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey.shade700,
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showErrorBottomSheet({
    required String title,
    required String message,
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    showModalBottomSheet(
      context: context,
      isDismissible: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.info_outline, color: Colors.orange, size: 48),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Color(0xFF1A1A1A)),
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14, height: 1.4),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    onAction();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(actionLabel, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey.shade700,
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGpsDisabledBanner() {
    if (!_gpsDisabledBannerVisible) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3CD),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFEEBA)),
      ),
      child: Row(
        children: [
          const Text('📍', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'GPS is still disabled. Enable location to publish your listing.',
              style: TextStyle(color: Color(0xFF856404), fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () {
              setState(() {
                _waitingForGps = true;
              });
              Geolocator.openLocationSettings();
            },
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF2E7D32),
              padding: EdgeInsets.zero,
              minimumSize: const Size(50, 30),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('Enable', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _loadDraft() async {
    if (widget.existing != null) return;
    setState(() => _loadingDraft = true);
    final draft = await ListingDraftManager.loadDraft('Farm Equipment');
    if (draft != null && mounted) {
      setState(() {
        _nameCtrl.text = draft['name'] ?? '';
        _type = draft['type'] ?? 'Tractor';
        _brandCtrl.text = draft['brand'] ?? '';
        _yearCtrl.text = draft['year'] ?? '';
        _modelCtrl.text = draft['model'] ?? '';
        _condition = draft['condition'] ?? 'Good';
        _fuel = draft['fuel'] ?? 'Diesel';
        _delivery = draft['delivery'] ?? 'Pickup Only';
        _duration = draft['duration'] ?? '1 Week';
        if (!['1 Day', '2 Days', '3 Days', '1 Week', '2 Weeks'].contains(_duration)) {
          _customDurationCtrl.text = _duration;
          _duration = 'Custom';
        }
        _operatorRequired = draft['operator'] ?? false;
        _instructionsCtrl.text = draft['instructions'] ?? '';
        _descCtrl.text = draft['description'] ?? '';
        _availability = draft['availability'] ?? true;
        if (draft['from'] != null) {
          _availableFrom = DateTime.tryParse(draft['from']);
        }
        if (draft['until'] != null) {
          _availableUntil = DateTime.tryParse(draft['until']);
        }
        final List<dynamic> imgPaths = draft['imagePaths'] ?? [];
        _pickerImages.clear();
        for (var p in imgPaths) {
          _pickerImages.add(BorrowImageItem(localFile: File(p)));
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✍ Restored your unfinished farm equipment draft.'),
          backgroundColor: Color(0xFF2E7D32),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
    setState(() => _loadingDraft = false);
  }

  void _saveDraft() {
    if (_loadingDraft || widget.existing != null) return;
    final draft = {
      'name': _nameCtrl.text,
      'type': _type,
      'brand': _brandCtrl.text,
      'year': _yearCtrl.text,
      'model': _modelCtrl.text,
      'condition': _condition,
      'fuel': _fuel,
      'delivery': _delivery,
      'duration': _duration == 'Custom' ? _customDurationCtrl.text : _duration,
      'operator': _operatorRequired,
      'instructions': _instructionsCtrl.text,
      'description': _descCtrl.text,
      'availability': _availability,
      'from': _availableFrom?.toIso8601String(),
      'until': _availableUntil?.toIso8601String(),
      'imagePaths': _pickerImages.where((i) => i.isLocal).map((i) => i.localFile!.path).toList(),
    };
    ListingDraftManager.saveDraft('Farm Equipment', draft);
  }

  Future<void> _selectDate(BuildContext context, bool isFrom) async {
    final DateTime now = DateTime.now();
    final DateTime firstDate = isFrom
        ? DateTime(now.year, now.month, now.day)
        : (_availableFrom ?? DateTime(now.year, now.month, now.day));

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isFrom
          ? (_availableFrom ?? firstDate)
          : (_availableUntil ?? firstDate),
      firstDate: firstDate,
      lastDate: DateTime(now.year + 5),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF2E7D32),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isFrom) {
          _availableFrom = picked;
          if (_availableUntil != null && _availableUntil!.isBefore(_availableFrom!)) {
            _availableUntil = null;
          }
        } else {
          _availableUntil = picked;
        }
      });
      _saveDraft();
    }
  }

  Widget _buildStepIndicator() {
    final steps = ['Media & Info', 'Details', 'Logistics'];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: List.generate(steps.length, (idx) {
          final isActive = idx == _activeStep;
          final isCompleted = idx < _activeStep;
          return Expanded(
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isActive
                        ? const Color(0xFF2E7D32)
                        : (isCompleted ? const Color(0xFFE8F5E9) : Colors.grey.shade200),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: isCompleted
                      ? const Icon(Icons.check, size: 14, color: Color(0xFF2E7D32))
                      : Text(
                          '${idx + 1}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isActive ? Colors.white : Colors.grey.shade600,
                          ),
                        ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    steps[idx],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                      color: isActive ? const Color(0xFF2E7D32) : Colors.grey.shade600,
                    ),
                  ),
                ),
                if (idx < steps.length - 1)
                  Icon(Icons.chevron_right, size: 14, color: Colors.grey.shade400),
              ],
            ),
          );
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF8),
      appBar: AppBar(
        title: const Text('Share Farm Equipment', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          if (widget.existing == null)
            TextButton.icon(
              onPressed: () {
                _saveDraft();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('💾 Draft Saved Locally'), backgroundColor: Color(0xFF2E7D32)),
                );
              },
              icon: const Icon(Icons.save_outlined, color: Color(0xFF2E7D32)),
              label: const Text('Save Draft', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
            ),
        ],
      ),
      body: _submitting
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(value: _uploadProgress, color: const Color(0xFF2E7D32)),
                    const SizedBox(height: 16),
                    Text(
                      _uploadStatus,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${(_uploadProgress * 100).toInt()}%',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                    ),
                  ],
                ),
              ),
            )
          : Form(
              key: _formKey,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: _buildStepIndicator(),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(24),
                      children: [
                        _buildGpsDisabledBanner(),
                        if (_activeStep == 0) ...[
                          Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(color: Colors.grey.shade200),
                            ),
                            color: Colors.white,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  BorrowImagePicker(
                                    initialImages: _pickerImages,
                                    onImagesChanged: (list) {
                                      setState(() {
                                        _pickerImages.clear();
                                        _pickerImages.addAll(list);
                                      });
                                      _saveDraft();
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildTextField('Equipment Name *', _nameCtrl, validator: (v) => v!.isEmpty ? 'Enter equipment name' : null),
                          const SizedBox(height: 16),
                          _buildTextField('Description *', _descCtrl, maxLines: 4, validator: (v) => v!.isEmpty ? 'Enter description' : null),
                          const SizedBox(height: 16),
                          _buildConditionDropdown(),
                        ],
                        if (_activeStep == 1) ...[
                          _buildTypeDropdown(),
                          const SizedBox(height: 16),
                          _buildTextField('Brand', _brandCtrl),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(child: _buildTextField('Manufacturing Year (Optional)', _yearCtrl, isNumeric: true)),
                              const SizedBox(width: 16),
                              Expanded(child: _buildTextField('Model Number (Optional)', _modelCtrl)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildFuelDropdown(),
                          const SizedBox(height: 16),
                          _buildOperatorRadio(),
                        ],
                        if (_activeStep == 2) ...[
                          _buildDeliveryDropdown(),
                          const SizedBox(height: 16),
                          _buildDurationDropdown(),
                          if (_duration == 'Custom') ...[
                            const SizedBox(height: 16),
                            _buildTextField('Custom Duration (e.g. 3 Weeks) *', _customDurationCtrl, validator: (v) => v!.isEmpty ? 'Enter custom duration limit' : null),
                          ],
                          const SizedBox(height: 20),
                          const Text('Availability Period *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: () => _selectDate(context, true),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.grey.shade400),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Available From', style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
                                        const SizedBox(height: 4),
                                        Text(
                                          _availableFrom == null ? 'Select Date' : DateFormat('yyyy-MM-dd').format(_availableFrom!),
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: InkWell(
                                  onTap: () => _selectDate(context, false),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.grey.shade400),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Available Until', style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
                                        const SizedBox(height: 4),
                                        Text(
                                          _availableUntil == null ? 'Optional' : DateFormat('yyyy-MM-dd').format(_availableUntil!),
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildTextField('Usage Instructions (Optional)', _instructionsCtrl, maxLines: 3),
                          const SizedBox(height: 20),
                          SwitchListTile(
                            title: const Text('Available for Borrowing', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            activeColor: const Color(0xFF2E7D32),
                            value: _availability,
                            onChanged: (val) {
                              setState(() => _availability = val);
                              _saveDraft();
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                  _buildStepperFooter(),
                ],
              ),
            ),
    );
  }

  Widget _buildStepperFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_activeStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  setState(() {
                    _activeStep--;
                  });
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF2E7D32),
                  side: const BorderSide(color: Color(0xFF2E7D32)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  minimumSize: const Size(0, 48),
                ),
                child: const Text('Back', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            )
          else
            const Spacer(),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  if (_activeStep < 2) {
                    setState(() {
                      _activeStep++;
                    });
                  } else {
                    _publish();
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                minimumSize: const Size(0, 48),
              ),
              child: Text(
                _activeStep < 2 ? 'Next' : 'Publish',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController ctrl, {bool isNumeric = false, int maxLines = 1, String? Function(String?)? validator}) {
    return TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey.shade600),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }

  Widget _buildConditionDropdown() {
    return DropdownButtonFormField<String>(
      value: _condition,
      decoration: InputDecoration(
        labelText: 'Condition *',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
      ),
      items: ['New', 'Excellent', 'Good', 'Fair', 'Needs Repair']
          .map((c) => DropdownMenuItem(value: c, child: Text(c)))
          .toList(),
      onChanged: (val) {
        setState(() => _condition = val!);
        _saveDraft();
      },
    );
  }

  Widget _buildTypeDropdown() {
    return DropdownButtonFormField<String>(
      value: _type,
      decoration: InputDecoration(
        labelText: 'Equipment Type *',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
      ),
      items: ['Tractor', 'Rotavator', 'Sprayer', 'Cultivator', 'Seeder', 'Harvester', 'Pump', 'Other']
          .map((t) => DropdownMenuItem(value: t, child: Text(t)))
          .toList(),
      onChanged: (val) {
        setState(() => _type = val!);
        _saveDraft();
      },
    );
  }

  Widget _buildFuelDropdown() {
    return DropdownButtonFormField<String>(
      value: _fuel,
      decoration: InputDecoration(
        labelText: 'Fuel Type *',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
      ),
      items: ['Diesel', 'Petrol', 'Electric', 'Battery', 'Manual', 'Other']
          .map((f) => DropdownMenuItem(value: f, child: Text(f)))
          .toList(),
      onChanged: (val) {
        setState(() => _fuel = val!);
        _saveDraft();
      },
    );
  }

  Widget _buildOperatorRadio() {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade400),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Operator Required? *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            Row(
              children: [
                const Text('No', style: TextStyle(fontSize: 13)),
                Radio<bool>(
                  value: false,
                  groupValue: _operatorRequired,
                  activeColor: const Color(0xFF2E7D32),
                  onChanged: (val) {
                    setState(() => _operatorRequired = val!);
                    _saveDraft();
                  },
                ),
                const SizedBox(width: 8),
                const Text('Yes', style: TextStyle(fontSize: 13)),
                Radio<bool>(
                  value: true,
                  groupValue: _operatorRequired,
                  activeColor: const Color(0xFF2E7D32),
                  onChanged: (val) {
                    setState(() => _operatorRequired = val!);
                    _saveDraft();
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryDropdown() {
    return DropdownButtonFormField<String>(
      value: _delivery,
      decoration: InputDecoration(
        labelText: 'Delivery Option *',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
      ),
      items: ['Pickup Only', 'Owner Can Deliver', 'Meet at Location']
          .map((d) => DropdownMenuItem(value: d, child: Text(d)))
          .toList(),
      onChanged: (val) {
        setState(() => _delivery = val!);
        _saveDraft();
      },
    );
  }

  Widget _buildDurationDropdown() {
    return DropdownButtonFormField<String>(
      value: _duration,
      decoration: InputDecoration(
        labelText: 'Maximum Borrow Duration *',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
      ),
      items: ['1 Day', '2 Days', '3 Days', '1 Week', '2 Weeks', 'Custom']
          .map((d) => DropdownMenuItem(value: d, child: Text(d)))
          .toList(),
      onChanged: (val) {
        setState(() => _duration = val!);
        _saveDraft();
      },
    );
  }
}

// ── CONSTRUCTION EQUIPMENT FORM ──────────────────────────────────────────────

class ConstructionEquipmentFormPage extends StatefulWidget {
  const ConstructionEquipmentFormPage({super.key, required this.currentUser, this.existing});
  final AppUserModel currentUser;
  final MarketplaceEquipmentModel? existing;

  @override
  State<ConstructionEquipmentFormPage> createState() => _ConstructionEquipmentFormPageState();
}

class _ConstructionEquipmentFormPageState extends State<ConstructionEquipmentFormPage> with WidgetsBindingObserver {
  final _formKey = GlobalKey<FormState>();
  final MarketplaceService _service = MarketplaceService();
  final ImagePicker _picker = ImagePicker();

  late TextEditingController _nameCtrl;
  late TextEditingController _typeCtrl;
  late TextEditingController _brandCtrl;
  late TextEditingController _modelCtrl;
  late TextEditingController _weightCtrl;
  late TextEditingController _safetyCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _customDurationCtrl;

  int _activeStep = 0;
  String _category = 'Power Tool';
  String _condition = 'Good';
  String _powerSource = 'Electric';
  String _delivery = 'Pickup';
  String _duration = '1 Week';
  bool _availability = true;
  bool _submitting = false;
  final List<BorrowImageItem> _pickerImages = [];
  double _uploadProgress = 0.0;
  String _uploadStatus = '';
  bool _waitingForGps = false;
  bool _gpsDisabledBannerVisible = false;

  DateTime? _availableFrom;
  DateTime? _availableUntil;
  bool _loadingDraft = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _nameCtrl = TextEditingController();
    _typeCtrl = TextEditingController();
    _brandCtrl = TextEditingController();
    _modelCtrl = TextEditingController();
    _weightCtrl = TextEditingController();
    _safetyCtrl = TextEditingController();
    _descCtrl = TextEditingController();
    _customDurationCtrl = TextEditingController();

    if (widget.existing != null) {
      final specsStr = widget.existing!.machineSpecs;
      _nameCtrl.text = widget.existing!.equipmentName;
      _brandCtrl.text = _parseSpec(specsStr, 'Brand: ');
      _modelCtrl.text = _parseSpec(specsStr, 'Model: ');
      _typeCtrl.text = _parseSpec(specsStr, 'Type: ');
      _category = _parseSpec(specsStr, 'Category: ', defaultValue: 'Power Tool');
      _condition = widget.existing!.condition;
      _powerSource = _parseSpec(specsStr, 'Power Source: ', defaultValue: 'Electric');
      _weightCtrl.text = _parseSpec(specsStr, 'Weight: ');
      _delivery = _parseSpec(specsStr, 'Delivery: ', defaultValue: 'Pickup');
      _duration = _parseSpec(specsStr, 'Max Duration: ', defaultValue: '1 Week');
      if (!['1 Day', '2 Days', '3 Days', '1 Week', '2 Weeks'].contains(_duration)) {
        _customDurationCtrl.text = _duration;
        _duration = 'Custom';
      }
      _safetyCtrl.text = _parseSpec(specsStr, 'Safety: ');
      _descCtrl.text = widget.existing!.description;
      _availability = widget.existing!.availability;
      _availableFrom = widget.existing!.availabilityFrom;
      _availableUntil = widget.existing!.availabilityTo;
      _pickerImages.addAll(widget.existing!.imageUrls.map((u) => BorrowImageItem(remoteUrl: u)));
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await _loadDraft();
      });
    }

    _nameCtrl.addListener(_saveDraft);
    _typeCtrl.addListener(_saveDraft);
    _brandCtrl.addListener(_saveDraft);
    _modelCtrl.addListener(_saveDraft);
    _weightCtrl.addListener(_saveDraft);
    _safetyCtrl.addListener(_saveDraft);
    _descCtrl.addListener(_saveDraft);
    _customDurationCtrl.addListener(_saveDraft);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _nameCtrl.dispose();
    _typeCtrl.dispose();
    _brandCtrl.dispose();
    _modelCtrl.dispose();
    _weightCtrl.dispose();
    _safetyCtrl.dispose();
    _descCtrl.dispose();
    _customDurationCtrl.dispose();
    super.dispose();
  }

  String _parseSpec(String specs, String prefix, {String defaultValue = ''}) {
    if (specs.isEmpty) return defaultValue;
    try {
      final parts = specs.split(', ');
      final found = parts.firstWhere((p) => p.startsWith(prefix), orElse: () => '');
      if (found.isNotEmpty) {
        return found.replaceAll(prefix, '');
      }
    } catch (_) {}
    return defaultValue;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _waitingForGps) {
      _checkGpsAndContinuePublishing();
    }
  }

  Future<void> _checkGpsAndContinuePublishing() async {
    setState(() {
      _submitting = true;
      _uploadProgress = 0.0;
      _uploadStatus = 'Checking location...';
      _gpsDisabledBannerVisible = false;
    });

    final isGpsEnabled = await LocationService.instance.isLocationServiceEnabled();
    if (!isGpsEnabled) {
      setState(() {
        _submitting = false;
        _waitingForGps = false;
        _gpsDisabledBannerVisible = true;
      });
      return;
    }

    _waitingForGps = false;
    _continuePublishingWithLocation();
  }

  Future<void> _continuePublishingWithLocation() async {
    setState(() {
      _submitting = true;
      _uploadStatus = 'Getting your location...';
      _uploadProgress = 0.0;
    });

    try {
      final locResult = await LocationService.instance.getCurrentLocation();
      if (locResult is LocationFailure) {
        setState(() {
          _submitting = false;
        });
        if (locResult.isPermanent) {
          _showErrorBottomSheet(
            title: 'Permission Required',
            message: 'Borrow needs location permissions. Please enable them in your app settings to proceed.',
            actionLabel: 'Open Settings',
            onAction: () => Geolocator.openAppSettings(),
          );
        } else {
          _showErrorBottomSheet(
            title: 'Location Error',
            message: locResult.reason,
            actionLabel: 'Retry',
            onAction: () => _continuePublishingWithLocation(),
          );
        }
        return;
      }

      final loc = (locResult as LocationSuccess).location;
      await _publishWithLocation(loc);
    } catch (e) {
      setState(() => _submitting = false);
      _showErrorBottomSheet(
        title: 'Publish Failed',
        message: 'Something went wrong while getting your location: $e',
        actionLabel: 'Retry',
        onAction: () => _continuePublishingWithLocation(),
      );
    }
  }

  Future<void> _publishWithLocation(VerifiedLocation loc) async {
    setState(() {
      _submitting = true;
      _uploadStatus = 'Publishing Listing...';
      _uploadProgress = 0.0;
    });

    try {
      final List<String> finalUrls = [];
      final CloudinaryService cloudinary = CloudinaryService();

      for (var i = 0; i < _pickerImages.length; i++) {
        final img = _pickerImages[i];
        setState(() {
          _uploadStatus = 'Publishing Listing...';
          _uploadProgress = (i / _pickerImages.length);
        });

        if (img.isLocal) {
          final secureUrl = await cloudinary.uploadImage(img.localFile!);
          finalUrls.add(secureUrl);
        } else {
          finalUrls.add(img.remoteUrl!);
        }
      }

      setState(() {
        _uploadStatus = 'Publishing Listing...';
        _uploadProgress = 1.0;
      });

      final specs = 'Brand: ${_brandCtrl.text.trim()}, Model: ${_modelCtrl.text.trim()}, Category: $_category, Power Source: $_powerSource, Weight: ${_weightCtrl.text.trim()}, Delivery: $_delivery, Max Duration: ${_duration == 'Custom' ? _customDurationCtrl.text.trim() : _duration}, Safety: ${_safetyCtrl.text.trim()}';

      final model = MarketplaceEquipmentModel(
        equipmentId: widget.existing?.equipmentId ?? '',
        ownerId: widget.currentUser.userId,
        ownerName: widget.currentUser.name,
        equipmentName: _nameCtrl.text.trim(),
        category: 'Construction Equipment',
        description: _descCtrl.text.trim(),
        titleLocalized: {'en': _nameCtrl.text.trim()},
        categoryLocalized: {'en': 'Construction Equipment'},
        descriptionLocalized: {'en': _descCtrl.text.trim()},
        pricePerHour: 0.0,
        pricePerDay: 0.0,
        location: [loc.area, loc.city].where((e) => e != null && e.isNotEmpty).join(', '),
        latitude: loc.latitude,
        longitude: loc.longitude,
        area: loc.area ?? '',
        city: loc.city ?? '',
        state: loc.state ?? '',
        country: loc.country ?? '',
        locationAccuracy: loc.accuracy ?? 0.0,
        locationCapturedAt: loc.timestamp,
        imageUrls: finalUrls,
        availability: _availability,
        rating: 5.0,
        createdAt: widget.existing?.createdAt ?? DateTime.now(),
        machineSpecs: specs,
        condition: _condition,
        minRentalDuration: 1.0,
        priceType: 'day',
        status: 'published',
        views: widget.existing?.views ?? 0,
        savedBy: widget.existing?.savedBy ?? [],
        bookingsCount: widget.existing?.bookingsCount ?? 0,
        availabilityFrom: _availableFrom,
        availabilityTo: _availableUntil,
      );

      if (widget.existing != null) {
        await _service.updateEquipment(equipmentId: widget.existing!.equipmentId, updates: model.toMap());
      } else {
        await _service.addEquipment(model);
        await ListingDraftManager.clearDraft('Construction Equipment');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('🎉 Listing Published Successfully'), backgroundColor: Color(0xFF2E7D32)),
        );
        Navigator.popUntil(context, (r) => r.isFirst);
      }
    } catch (e) {
      LoggerService.error('Error publishing listing', e);
      setState(() => _submitting = false);
      _showErrorBottomSheet(
        title: 'Publish Failed',
        message: 'Failed to upload images or save listing: $e. Please check your internet connection.',
        actionLabel: 'Retry',
        onAction: () => _publishWithLocation(loc),
      );
    }
  }

  Future<void> _publish() async {
    if (!_formKey.currentState!.validate()) return;
    if (_pickerImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload at least one image.'), backgroundColor: Colors.red),
      );
      return;
    }
    if (_availableFrom == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an available start date.'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() {
      _submitting = true;
      _uploadProgress = 0.0;
      _uploadStatus = 'Checking location...';
    });

    try {
      final result = await InternetAddress.lookup('example.com');
      if (result.isEmpty || result[0].rawAddress.isEmpty) {
        throw const SocketException("No internet connection");
      }
    } catch (_) {
      setState(() => _submitting = false);
      _showErrorBottomSheet(
        title: 'No Internet Connection',
        message: 'Borrow requires an active internet connection to publish listings.',
        actionLabel: 'Retry',
        onAction: () => _publish(),
      );
      return;
    }

    final isGpsEnabled = await LocationService.instance.isLocationServiceEnabled();
    if (!isGpsEnabled) {
      setState(() => _submitting = false);
      _showGpsRequiredBottomSheet();
      return;
    }

    _continuePublishingWithLocation();
  }

  void _showGpsRequiredBottomSheet() {
    showModalBottomSheet(
      context: context,
      isDismissible: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('📍', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 16),
              const Text(
                'Location Required',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Color(0xFF1A1A1A)),
              ),
              const SizedBox(height: 12),
              const Text(
                'Borrow needs your location to publish this listing and recommend it to nearby users. Your exact address will never be shared.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF6F7A6B), fontSize: 14, height: 1.4),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    setState(() {
                      _waitingForGps = true;
                    });
                    Geolocator.openLocationSettings();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Enable GPS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey.shade700,
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showErrorBottomSheet({
    required String title,
    required String message,
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    showModalBottomSheet(
      context: context,
      isDismissible: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.info_outline, color: Colors.orange, size: 48),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Color(0xFF1A1A1A)),
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14, height: 1.4),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    onAction();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(actionLabel, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey.shade700,
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGpsDisabledBanner() {
    if (!_gpsDisabledBannerVisible) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3CD),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFEEBA)),
      ),
      child: Row(
        children: [
          const Text('📍', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'GPS is still disabled. Enable location to publish your listing.',
              style: TextStyle(color: Color(0xFF856404), fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () {
              setState(() {
                _waitingForGps = true;
              });
              Geolocator.openLocationSettings();
            },
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF2E7D32),
              padding: EdgeInsets.zero,
              minimumSize: const Size(50, 30),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('Enable', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _loadDraft() async {
    if (widget.existing != null) return;
    setState(() => _loadingDraft = true);
    final draft = await ListingDraftManager.loadDraft('Construction Equipment');
    if (draft != null && mounted) {
      setState(() {
        _nameCtrl.text = draft['name'] ?? '';
        _typeCtrl.text = draft['type'] ?? '';
        _category = draft['category'] ?? 'Power Tool';
        _brandCtrl.text = draft['brand'] ?? '';
        _modelCtrl.text = draft['model'] ?? '';
        _condition = draft['condition'] ?? 'Good';
        _powerSource = draft['power'] ?? 'Electric';
        _weightCtrl.text = draft['weight'] ?? '';
        _delivery = draft['delivery'] ?? 'Pickup';
        _duration = draft['duration'] ?? '1 Week';
        if (!['1 Day', '2 Days', '3 Days', '1 Week', '2 Weeks'].contains(_duration)) {
          _customDurationCtrl.text = _duration;
          _duration = 'Custom';
        }
        _safetyCtrl.text = draft['safety'] ?? '';
        _descCtrl.text = draft['description'] ?? '';
        _availability = draft['availability'] ?? true;
        if (draft['from'] != null) {
          _availableFrom = DateTime.tryParse(draft['from']);
        }
        if (draft['until'] != null) {
          _availableUntil = DateTime.tryParse(draft['until']);
        }
        final List<dynamic> imgPaths = draft['imagePaths'] ?? [];
        _pickerImages.clear();
        for (var p in imgPaths) {
          _pickerImages.add(BorrowImageItem(localFile: File(p)));
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✍ Restored your unfinished construction equipment draft.'),
          backgroundColor: Color(0xFF2E7D32),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
    setState(() => _loadingDraft = false);
  }

  void _saveDraft() {
    if (_loadingDraft || widget.existing != null) return;
    final draft = {
      'name': _nameCtrl.text,
      'type': _typeCtrl.text,
      'category': _category,
      'brand': _brandCtrl.text,
      'model': _modelCtrl.text,
      'condition': _condition,
      'power': _powerSource,
      'weight': _weightCtrl.text,
      'delivery': _delivery,
      'duration': _duration == 'Custom' ? _customDurationCtrl.text : _duration,
      'safety': _safetyCtrl.text,
      'description': _descCtrl.text,
      'availability': _availability,
      'from': _availableFrom?.toIso8601String(),
      'until': _availableUntil?.toIso8601String(),
      'imagePaths': _pickerImages.where((i) => i.isLocal).map((i) => i.localFile!.path).toList(),
    };
    ListingDraftManager.saveDraft('Construction Equipment', draft);
  }

  Future<void> _selectDate(BuildContext context, bool isFrom) async {
    final DateTime now = DateTime.now();
    final DateTime firstDate = isFrom
        ? DateTime(now.year, now.month, now.day)
        : (_availableFrom ?? DateTime(now.year, now.month, now.day));

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isFrom
          ? (_availableFrom ?? firstDate)
          : (_availableUntil ?? firstDate),
      firstDate: firstDate,
      lastDate: DateTime(now.year + 5),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF2E7D32),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isFrom) {
          _availableFrom = picked;
          if (_availableUntil != null && _availableUntil!.isBefore(_availableFrom!)) {
            _availableUntil = null;
          }
        } else {
          _availableUntil = picked;
        }
      });
      _saveDraft();
    }
  }

  Widget _buildStepIndicator() {
    final steps = ['Media & Info', 'Details', 'Logistics'];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: List.generate(steps.length, (idx) {
          final isActive = idx == _activeStep;
          final isCompleted = idx < _activeStep;
          return Expanded(
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isActive
                        ? const Color(0xFF2E7D32)
                        : (isCompleted ? const Color(0xFFE8F5E9) : Colors.grey.shade200),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: isCompleted
                      ? const Icon(Icons.check, size: 14, color: Color(0xFF2E7D32))
                      : Text(
                          '${idx + 1}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isActive ? Colors.white : Colors.grey.shade600,
                          ),
                        ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    steps[idx],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                      color: isActive ? const Color(0xFF2E7D32) : Colors.grey.shade600,
                    ),
                  ),
                ),
                if (idx < steps.length - 1)
                  Icon(Icons.chevron_right, size: 14, color: Colors.grey.shade400),
              ],
            ),
          );
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF8),
      appBar: AppBar(
        title: const Text('Share Construction Equipment', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          if (widget.existing == null)
            TextButton.icon(
              onPressed: () {
                _saveDraft();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('💾 Draft Saved Locally'), backgroundColor: Color(0xFF2E7D32)),
                );
              },
              icon: const Icon(Icons.save_outlined, color: Color(0xFF2E7D32)),
              label: const Text('Save Draft', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
            ),
        ],
      ),
      body: _submitting
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(value: _uploadProgress, color: const Color(0xFF2E7D32)),
                    const SizedBox(height: 16),
                    Text(
                      _uploadStatus,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${(_uploadProgress * 100).toInt()}%',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                    ),
                  ],
                ),
              ),
            )
          : Form(
              key: _formKey,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: _buildStepIndicator(),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(24),
                      children: [
                        _buildGpsDisabledBanner(),
                        if (_activeStep == 0) ...[
                          Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(color: Colors.grey.shade200),
                            ),
                            color: Colors.white,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  BorrowImagePicker(
                                    initialImages: _pickerImages,
                                    onImagesChanged: (list) {
                                      setState(() {
                                        _pickerImages.clear();
                                        _pickerImages.addAll(list);
                                      });
                                      _saveDraft();
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildTextField('Equipment Name *', _nameCtrl, validator: (v) => v!.isEmpty ? 'Enter equipment name' : null),
                          const SizedBox(height: 16),
                          _buildTextField('Description *', _descCtrl, maxLines: 4, validator: (v) => v!.isEmpty ? 'Enter description' : null),
                          const SizedBox(height: 16),
                          _buildConditionDropdown(),
                        ],
                        if (_activeStep == 1) ...[
                          _buildCategoryDropdown(),
                          const SizedBox(height: 16),
                          _buildTextField('Equipment Type (e.g. Hammer, Drill)', _typeCtrl),
                          const SizedBox(height: 16),
                          _buildTextField('Brand', _brandCtrl),
                          const SizedBox(height: 16),
                          _buildTextField('Model', _modelCtrl),
                          const SizedBox(height: 16),
                          _buildPowerDropdown(),
                          const SizedBox(height: 16),
                          _buildTextField('Weight (Optional)', _weightCtrl),
                        ],
                        if (_activeStep == 2) ...[
                          _buildDeliveryDropdown(),
                          const SizedBox(height: 16),
                          _buildDurationDropdown(),
                          if (_duration == 'Custom') ...[
                            const SizedBox(height: 16),
                            _buildTextField('Custom Duration (e.g. 3 Weeks) *', _customDurationCtrl, validator: (v) => v!.isEmpty ? 'Enter custom duration limit' : null),
                          ],
                          const SizedBox(height: 20),
                          const Text('Availability Period *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: () => _selectDate(context, true),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.grey.shade400),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Available From', style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
                                        const SizedBox(height: 4),
                                        Text(
                                          _availableFrom == null ? 'Select Date' : DateFormat('yyyy-MM-dd').format(_availableFrom!),
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: InkWell(
                                  onTap: () => _selectDate(context, false),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.grey.shade400),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Available Until', style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
                                        const SizedBox(height: 4),
                                        Text(
                                          _availableUntil == null ? 'Optional' : DateFormat('yyyy-MM-dd').format(_availableUntil!),
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildTextField('Safety Instructions (Optional)', _safetyCtrl, maxLines: 3),
                          const SizedBox(height: 20),
                          SwitchListTile(
                            title: const Text('Available for Borrowing', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            activeColor: const Color(0xFF2E7D32),
                            value: _availability,
                            onChanged: (val) {
                              setState(() => _availability = val);
                              _saveDraft();
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                  _buildStepperFooter(),
                ],
              ),
            ),
    );
  }

  Widget _buildStepperFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_activeStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  setState(() {
                    _activeStep--;
                  });
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF2E7D32),
                  side: const BorderSide(color: Color(0xFF2E7D32)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  minimumSize: const Size(0, 48),
                ),
                child: const Text('Back', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            )
          else
            const Spacer(),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  if (_activeStep < 2) {
                    setState(() {
                      _activeStep++;
                    });
                  } else {
                    _publish();
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                minimumSize: const Size(0, 48),
              ),
              child: Text(
                _activeStep < 2 ? 'Next' : 'Publish',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController ctrl, {bool isNumeric = false, int maxLines = 1, String? Function(String?)? validator}) {
    return TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey.shade600),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }

  Widget _buildConditionDropdown() {
    return DropdownButtonFormField<String>(
      value: _condition,
      decoration: InputDecoration(
        labelText: 'Condition *',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
      ),
      items: ['New', 'Excellent', 'Good', 'Fair', 'Needs Repair']
          .map((c) => DropdownMenuItem(value: c, child: Text(c)))
          .toList(),
      onChanged: (val) {
        setState(() => _condition = val!);
        _saveDraft();
      },
    );
  }

  Widget _buildCategoryDropdown() {
    return DropdownButtonFormField<String>(
      value: _category,
      decoration: InputDecoration(
        labelText: 'Equipment Category *',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
      ),
      items: ['Drill', 'Concrete Mixer', 'Ladder', 'Generator', 'Scaffolding', 'Power Tool', 'Safety Equipment', 'Other']
          .map((c) => DropdownMenuItem(value: c, child: Text(c)))
          .toList(),
      onChanged: (val) {
        setState(() => _category = val!);
        _saveDraft();
      },
    );
  }

  Widget _buildPowerDropdown() {
    return DropdownButtonFormField<String>(
      value: _powerSource,
      decoration: InputDecoration(
        labelText: 'Power Source *',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
      ),
      items: ['Electric', 'Battery', 'Diesel', 'Petrol', 'Manual']
          .map((p) => DropdownMenuItem(value: p, child: Text(p)))
          .toList(),
      onChanged: (val) {
        setState(() => _powerSource = val!);
        _saveDraft();
      },
    );
  }

  Widget _buildDeliveryDropdown() {
    return DropdownButtonFormField<String>(
      value: _delivery,
      decoration: InputDecoration(
        labelText: 'Delivery Option *',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
      ),
      items: ['Pickup', 'Delivery', 'Meet Halfway']
          .map((d) => DropdownMenuItem(value: d, child: Text(d)))
          .toList(),
      onChanged: (val) {
        setState(() => _delivery = val!);
        _saveDraft();
      },
    );
  }

  Widget _buildDurationDropdown() {
    return DropdownButtonFormField<String>(
      value: _duration,
      decoration: InputDecoration(
        labelText: 'Maximum Borrow Duration *',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
      ),
      items: ['1 Day', '2 Days', '3 Days', '1 Week', '2 Weeks', 'Custom']
          .map((d) => DropdownMenuItem(value: d, child: Text(d)))
          .toList(),
      onChanged: (val) {
        setState(() => _duration = val!);
        _saveDraft();
      },
    );
  }
}
