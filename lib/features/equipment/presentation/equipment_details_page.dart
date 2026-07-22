import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../../../models/marketplace_equipment_model.dart';
import '../../../models/app_user_model.dart';
import '../../../providers/locale_provider.dart';
import '../../../services/marketplace_service.dart';
import '../../../services/deep_link_handler.dart';
import '../../../services/logger_service.dart';
import '../../../services/borrow_request_repository.dart';
import '../../../services/listing_context_service.dart';
import '../../../services/cloudinary_service.dart';
import '../../../widgets/image_loader.dart';
import '../../../widgets/borrow_product_id_card.dart';
import 'widgets/borrow_image_picker.dart';
import 'create_listing_flow.dart';
import '../../profile/presentation/my_listings_page.dart';
import '../../explore/presentation/chatbot_page.dart';

import 'widgets/details/details_theme.dart';
import 'widgets/details/hero_section.dart';
import 'widgets/details/product_header.dart';
import 'widgets/details/owner_card.dart';
import 'widgets/details/stats_section.dart';
import 'widgets/details/description_section.dart';
import 'widgets/details/features_section.dart';
import 'widgets/details/specification_grid.dart';
import 'widgets/details/availability_card.dart';
import 'widgets/details/location_card.dart';
import 'widgets/details/safety_card.dart';
import 'widgets/details/similar_items_section.dart';
import 'widgets/details/bottom_action_bar.dart';
import 'widgets/borrow_request/borrow_request_bottom_sheet.dart';
import 'owner_borrow_requests_screen.dart';

class EquipmentDetailsPage extends StatefulWidget {
  const EquipmentDetailsPage({
    super.key,
    required this.equipment,
    required this.userId,
    this.userName = 'User',
    this.userEmail = '',
    this.userPhone = '9000000000',
    this.isPreviewMode = false,
  });

  final MarketplaceEquipmentModel equipment;
  final String userId;
  final String userName;
  final String userEmail;
  final String userPhone;
  final bool isPreviewMode;

  @override
  State<EquipmentDetailsPage> createState() => _EquipmentDetailsPageState();
}

class _EquipmentDetailsPageState extends State<EquipmentDetailsPage> {
  final MarketplaceService _service = MarketplaceService();

  DateTime? _selectedStartDay;
  DateTime? _selectedEndDay;
  bool _isSaving = false;
  bool _hasActiveRequest = false;

  @override
  void initState() {
    super.initState();
    if (widget.equipment.ownerId != widget.userId) {
      _service.incrementEquipmentViews(
        widget.equipment.equipmentId,
        userId: widget.userId,
      );
      _checkActiveRequest();
    }
  }

  Future<void> _checkActiveRequest() async {
    try {
      final repo = BorrowRequestRepository();
      final active = await repo.hasActiveRequest(
        listingId: widget.equipment.equipmentId,
        borrowerId: widget.userId,
      );
      if (mounted) {
        setState(() => _hasActiveRequest = active);
      }
    } catch (e) {
      // Ignore background check failure
    }
  }

  Future<void> _toggleSave(MarketplaceEquipmentModel item) async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      await _service.toggleSaveEquipment(widget.userId, item.equipmentId);
    } catch (e, stacktrace) {
      LoggerService.error('Save Error', e, stacktrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save listing: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _shareListing(MarketplaceEquipmentModel item) async {
    final url =
        'https://uzhavusei-a8be3.web.app/equipment/${item.equipmentId}';
    final text =
        'Check out this ${item.equipmentName} available to borrow on Borrow!\n📍 ${item.location}\n🌱 Free community sharing\n\n$url';

    DeepLinkHandler.logShareEvent(item.equipmentId, widget.userId);
    await Share.share(text);
  }

  void _openFullscreenImage(String imageUrl) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (ctx) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: Center(
          child: InteractiveViewer(
            panEnabled: false,
            boundaryMargin: const EdgeInsets.all(100),
            minScale: 0.5,
            maxScale: 2,
            child: buildSmartImage(imageUrl, fit: BoxFit.contain),
          ),
        ),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final languageCode = context.watch<LocaleProvider>().languageCode;

    return StreamBuilder<MarketplaceEquipmentModel>(
      stream: _service.watchEquipmentById(widget.equipment.equipmentId),
      initialData: widget.equipment,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Scaffold(
            body: Center(child: Text('Something went wrong')),
          );
        }
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: DetailsTheme.primary),
            ),
          );
        }

        final item = snapshot.data!;
        final title = item.titleForLanguage(languageCode);
        final category = item.categoryForLanguage(languageCode);
        final description = item.descriptionForLanguage(languageCode);
        final isSaved = item.savedBy.contains(widget.userId);
        final bool isOwner =
            item.ownerId == widget.userId && !widget.isPreviewMode;

        if (isOwner) {
          return _buildOwnerView(item, title, category, description);
        }

        return Scaffold(
          backgroundColor: DetailsTheme.background,
          body: Stack(
            children: [
              SafeArea(
                top: false,
                child: ListView(
                  padding: const EdgeInsets.only(bottom: 120),
                  children: [
                    // Top Hero Section
                    HeroSection(
                      equipment: item,
                      isSaved: isSaved,
                      isOwner: isOwner,
                      onBack: () => Navigator.pop(context),
                      onShare: () => _shareListing(item),
                      onToggleSave: () => _toggleSave(item),
                      onOpenFullscreen: _openFullscreenImage,
                    ),

                    const SizedBox(height: DetailsTheme.sectionSpacing),

                    // Product Header (Title, Category, Location, Rating, Borrows, Product ID + Copy button)
                    ProductHeader(
                      equipment: item,
                      title: title,
                      category: category,
                    ),

                    const SizedBox(height: DetailsTheme.sectionSpacing),

                    // Owner Card
                    OwnerCard(
                      equipment: item,
                      currentUserId: widget.userId,
                    ),

                    const SizedBox(height: DetailsTheme.sectionSpacing),

                    // Statistics Row
                    StatsSection(equipment: item),

                    const SizedBox(height: DetailsTheme.sectionSpacing),

                    // Expandable Description
                    DescriptionSection(description: description),

                    const SizedBox(height: DetailsTheme.sectionSpacing),

                    // Dynamic Features Section
                    FeaturesSection(equipment: item),

                    const SizedBox(height: DetailsTheme.sectionSpacing),

                    // Ask Borrow AI Action Banner
                    _buildAskAiButton(item),

                    const SizedBox(height: DetailsTheme.sectionSpacing),

                    // Responsive Specification Grid
                    SpecificationGrid(equipment: item),

                    const SizedBox(height: DetailsTheme.sectionSpacing),

                    // Borrow Availability Card
                    AvailabilityCard(
                      equipment: item,
                      selectedStartDay: _selectedStartDay,
                      selectedEndDay: _selectedEndDay,
                      onDatesSelected: (start, end) {
                        setState(() {
                          _selectedStartDay = start;
                          _selectedEndDay = end;
                        });
                      },
                      onRequestToBorrow: () => _showBorrowRequestDialog(item),
                    ),

                    const SizedBox(height: DetailsTheme.sectionSpacing),

                    // Pickup Location Card
                    LocationCard(equipment: item),

                    const SizedBox(height: DetailsTheme.sectionSpacing),

                    // Owner Safety Tips Card
                    const SafetyCard(),

                    const SizedBox(height: DetailsTheme.sectionSpacing),

                    // Similar Listings Section
                    SimilarItemsSection(
                      equipment: item,
                      category: category,
                      userId: widget.userId,
                      userName: widget.userName,
                      userEmail: widget.userEmail,
                      userPhone: widget.userPhone,
                    ),
                  ],
                ),
              ),

              // Sticky Bottom Action Bar
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: BottomActionBar(
                  equipment: item,
                  isOwner: isOwner,
                  hasActiveRequest: _hasActiveRequest,
                  onRequestToBorrow: () => _showBorrowRequestDialog(item),
                  onEditListing: _handleEditListing,
                  onManageListing: _handleManageListing,
                  onViewRequests: _handleViewRequests,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAskAiButton(MarketplaceEquipmentModel item) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DetailsTheme.outerPadding),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () {
            ListingContextService.instance.cacheListing(item);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ChatbotPage(isFromListing: true),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: DetailsTheme.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          icon: const Icon(Icons.auto_awesome_rounded, size: 20),
          label: const Text(
            'Ask Borrow AI',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  void _showBorrowRequestDialog(MarketplaceEquipmentModel item) {
    BorrowRequestBottomSheet.show(
      context: context,
      equipment: item,
      borrowerId: widget.userId,
      borrowerName: widget.userName,
      initialStartDate: _selectedStartDay,
      initialEndDate: _selectedEndDay,
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // OWNER VIEW HANDLERS & DASHBOARD
  // ──────────────────────────────────────────────────────────────────────────

  Widget _buildOwnerView(MarketplaceEquipmentModel item, String title,
      String category, String description) {
    return Scaffold(
      backgroundColor: DetailsTheme.background,
      appBar: AppBar(
        title: const Text(
          'Manage Listing',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: DetailsTheme.text,
          ),
        ),
        backgroundColor: DetailsTheme.surface,
        foregroundColor: DetailsTheme.text,
        elevation: 0.5,
        actions: [
          IconButton(
            icon: const Icon(Icons.visibility_outlined),
            tooltip: 'Preview as Borrower',
            onPressed: () => _handlePreviewListing(item),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert_rounded),
            tooltip: 'Menu',
            onPressed: () => _showOwnerMenuBottomSheet(item),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          DetailsTheme.outerPadding,
          DetailsTheme.outerPadding,
          DetailsTheme.outerPadding,
          120,
        ),
        children: [
          _buildOwnerHeaderBanner(item),
          const SizedBox(height: 20),
          _buildBookingSummaryCards(item),
          const SizedBox(height: 20),
          _buildOwnerQuickActions(item),
          const SizedBox(height: 20),
          if (item.productId.isNotEmpty) ...[
            BorrowProductIdCard(productId: item.productId),
            const SizedBox(height: 20),
          ],
          DescriptionSection(description: description),
          const SizedBox(height: 12),
          _buildAskAiButton(item),
          const SizedBox(height: 20),
          SpecificationGrid(equipment: item),
          const SizedBox(height: 20),
          _buildListingInfoPanel(item),
        ],
      ),
      bottomNavigationBar: BottomActionBar(
        equipment: item,
        isOwner: true,
        onRequestToBorrow: () {},
        onEditListing: _handleEditListing,
        onManageListing: _handleManageListing,
        onViewRequests: _handleViewRequests,
      ),
    );
  }

  Widget _buildOwnerHeaderBanner(MarketplaceEquipmentModel item) {
    final isAvailable = item.availability;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DetailsTheme.surface,
        borderRadius: BorderRadius.circular(DetailsTheme.cardRadius),
        border: Border.all(color: DetailsTheme.border),
        boxShadow: DetailsTheme.cardShadow,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: DetailsTheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle,
                    color: DetailsTheme.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '✓ Your Listing',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: DetailsTheme.primary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.equipmentName,
                    style: DetailsTheme.captionStyle,
                  ),
                ],
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isAvailable
                  ? DetailsTheme.primaryContainer
                  : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              isAvailable ? 'Available' : 'Unavailable',
              style: TextStyle(
                color: isAvailable
                    ? DetailsTheme.primary
                    : DetailsTheme.secondaryText,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingSummaryCards(MarketplaceEquipmentModel item) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .where('equipmentId', isEqualTo: item.equipmentId)
          .snapshots(),
      builder: (context, snapshot) {
        int pending = 0;
        int active = 0;
        int completed = 0;
        String currentBorrower = 'None';

        if (snapshot.hasData) {
          for (var doc in snapshot.data!.docs) {
            final data = doc.data();
            final stat = (data['status'] ?? '').toString().toLowerCase();
            if (stat == 'pending') {
              pending++;
            } else if (stat == 'approved' || stat == 'confirmed') {
              active++;
              currentBorrower = (data['userName'] ?? 'User').toString();
            } else if (stat == 'completed') {
              completed++;
            }
          }
        }

        return GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.6,
          children: [
            _buildStatSummaryCard('Pending Requests', '$pending',
                Icons.hourglass_empty_rounded, Colors.orange),
            _buildStatSummaryCard('Current Borrower', currentBorrower,
                Icons.person_outline_rounded, DetailsTheme.primary),
            _buildStatSummaryCard(
                'Active Loans', '$active', Icons.loop_rounded, Colors.blue),
            _buildStatSummaryCard('Completed Borrows', '$completed',
                Icons.done_all_rounded, DetailsTheme.secondaryText),
          ],
        );
      },
    );
  }

  Widget _buildStatSummaryCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: DetailsTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DetailsTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: DetailsTheme.secondaryText,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Icon(icon, color: color, size: 18),
            ],
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: DetailsTheme.text,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildOwnerQuickActions(MarketplaceEquipmentModel item) {
    return Card(
      color: DetailsTheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DetailsTheme.cardRadius),
        side: const BorderSide(color: DetailsTheme.border),
      ),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quick Actions',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: DetailsTheme.text,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildActionButton(
                    'Edit Listing', Icons.edit_outlined, _handleEditListing),
                _buildActionButton(
                    'Borrow Requests', Icons.inbox_outlined, _handleViewRequests),
                _buildActionButton(
                    'Preview Listing',
                    Icons.visibility_outlined,
                    () => _handlePreviewListing(item)),
                _buildActionButton(
                    'Edit Availability',
                    Icons.calendar_month_outlined,
                    () => _showEditAvailabilitySheet(item)),
                _buildActionButton(
                    'Manage Images',
                    Icons.image_outlined,
                    () => _showManageImagesSheet(item)),
                _buildActionButton(
                    'Delete Listing',
                    Icons.delete_outline_rounded,
                    () => _handleDeleteListing(item),
                    isDestructive: true),
              ],
            ),
            const Divider(height: 24, color: DetailsTheme.border),
            SwitchListTile.adaptive(
              value: item.availability,
              activeTrackColor: DetailsTheme.primaryContainer,
              activeThumbColor: DetailsTheme.primary,
              title: const Text(
                'Available to Borrow',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              subtitle: Text(
                item.availability
                    ? 'Visible to borrowers in marketplace search and feeds'
                    : 'Hidden from marketplace exploration feeds',
                style: DetailsTheme.captionStyle,
              ),
              onChanged: (val) async {
                await _service.updateEquipment(
                  equipmentId: item.equipmentId,
                  updates: {'availability': val},
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Listing is now ${val ? "Available" : "Unavailable"}',
                      ),
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, VoidCallback onTap,
      {bool isDestructive = false}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 104,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          border: Border.all(
            color: isDestructive ? Colors.red.shade100 : DetailsTheme.border,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isDestructive
              ? Colors.red.withValues(alpha: 0.03)
              : Colors.transparent,
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isDestructive ? Colors.red : DetailsTheme.primary,
              size: 20,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: isDestructive ? Colors.red : DetailsTheme.text,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListingInfoPanel(MarketplaceEquipmentModel item) {
    final dateFormat = DateFormat.yMMMd();
    return Card(
      color: DetailsTheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DetailsTheme.cardRadius),
        side: const BorderSide(color: DetailsTheme.border),
      ),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Listing Details',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: DetailsTheme.text,
              ),
            ),
            const SizedBox(height: 12),
            _buildInfoRow('Category', item.category),
            _buildInfoRow('Location', item.location),
            _buildInfoRow('Condition', item.condition),
            _buildInfoRow('Created Date', dateFormat.format(item.createdAt)),
            _buildInfoRow('Views Count', '${item.views}'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: DetailsTheme.captionStyle),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: DetailsTheme.text,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleEditListing() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          const Center(child: CircularProgressIndicator(color: DetailsTheme.primary)),
    );
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();
      if (!mounted) return;
      Navigator.pop(context);
      if (doc.exists) {
        final appUser = AppUserModel.fromDoc(doc);
        final equip = widget.equipment;
        Widget page;
        if (equip.category.toLowerCase().contains('book')) {
          page = BookListingFormPage(currentUser: appUser, existing: equip);
        } else if (equip.category.toLowerCase().contains('construction')) {
          page = ConstructionEquipmentFormPage(
              currentUser: appUser, existing: equip);
        } else {
          page = FarmEquipmentFormPage(currentUser: appUser, existing: equip);
        }
        Navigator.push(context, MaterialPageRoute(builder: (_) => page));
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profile: $e')),
        );
      }
    }
  }

  Future<void> _handleManageListing() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          const Center(child: CircularProgressIndicator(color: DetailsTheme.primary)),
    );
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();
      if (!mounted) return;
      Navigator.pop(context);
      if (doc.exists) {
        final appUser = AppUserModel.fromDoc(doc);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MyListingsPage(currentUser: appUser),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profile: $e')),
        );
      }
    }
  }

  Future<void> _handleViewRequests() async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OwnerBorrowRequestsScreen(ownerId: widget.userId),
      ),
    );
  }

  void _handlePreviewListing(MarketplaceEquipmentModel item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EquipmentDetailsPage(
          equipment: item,
          userId: widget.userId,
          userName: widget.userName,
          userEmail: widget.userEmail,
          userPhone: widget.userPhone,
          isPreviewMode: true,
        ),
      ),
    );
  }

  Future<void> _handleDeleteListing(MarketplaceEquipmentModel item) async {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Delete this listing?',
              style: TextStyle(fontWeight: FontWeight.bold)),
          content: const Text(
            'This action cannot be undone. All associated requests and logs will be permanently deleted.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel',
                  style: TextStyle(
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const Center(
                    child: CircularProgressIndicator(color: DetailsTheme.primary),
                  ),
                );

                try {
                  await _service.deleteEquipment(item.equipmentId);
                  if (mounted) {
                    Navigator.pop(context);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Listing deleted successfully.'),
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error deleting listing: $e')),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Delete',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _showEditAvailabilitySheet(MarketplaceEquipmentModel item) {
    DateTime? fromDate = item.availabilityFrom ?? DateTime.now();
    DateTime? toDate =
        item.availabilityTo ?? DateTime.now().add(const Duration(days: 30));
    final durationCtrl =
        TextEditingController(text: '${item.minRentalDuration.toInt()}');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            Future<void> pickDate(bool isFrom) async {
              final picked = await showDatePicker(
                context: context,
                initialDate: isFrom ? fromDate! : toDate!,
                firstDate: DateTime.now().subtract(const Duration(days: 365)),
                lastDate: DateTime.now().add(const Duration(days: 1000)),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: const ColorScheme.light(
                        primary: DetailsTheme.primary,
                        onPrimary: Colors.white,
                        onSurface: Colors.black,
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (picked != null) {
                setModalState(() {
                  if (isFrom) {
                    fromDate = picked;
                    if (toDate!.isBefore(fromDate!)) {
                      toDate = fromDate!.add(const Duration(days: 1));
                    }
                  } else {
                    toDate = picked;
                  }
                });
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 32,
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
                        color: DetailsTheme.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Edit Availability Calendar',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: DetailsTheme.text)),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => pickDate(true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              border: Border.all(color: DetailsTheme.border),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Available From',
                                    style: DetailsTheme.captionStyle),
                                const SizedBox(height: 4),
                                Text(DateFormat.yMMMd().format(fromDate!),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: InkWell(
                          onTap: () => pickDate(false),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              border: Border.all(color: DetailsTheme.border),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Available Until',
                                    style: DetailsTheme.captionStyle),
                                const SizedBox(height: 4),
                                Text(DateFormat.yMMMd().format(toDate!),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: durationCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Minimum Borrow Duration (days)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(ctx);

                        final minDuration =
                            double.tryParse(durationCtrl.text.trim()) ?? 1.0;
                        await _service.updateEquipment(
                          equipmentId: item.equipmentId,
                          updates: {
                            'availabilityFrom': Timestamp.fromDate(fromDate!),
                            'availabilityTo': Timestamp.fromDate(toDate!),
                            'minRentalDuration': minDuration,
                          },
                        );

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'Availability details updated successfully.'),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: DetailsTheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text('Save Details',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
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

  void _showManageImagesSheet(MarketplaceEquipmentModel item) {
    List<BorrowImageItem> currentImages = item.imageUrls
        .map((url) => BorrowImageItem(remoteUrl: url))
        .toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.8,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: DetailsTheme.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Manage Photos',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: DetailsTheme.text)),
                  const SizedBox(height: 4),
                  Text(
                    'The first image is the cover photo. Reorder or delete images below.',
                    style: DetailsTheme.captionStyle,
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: BorrowImagePicker(
                      initialImages: currentImages,
                      onImagesChanged: (updated) {
                        currentImages = updated;
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(ctx);

                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (context) => const Center(
                            child: CircularProgressIndicator(color: DetailsTheme.primary),
                          ),
                        );

                        try {
                          final List<String> finalUrls = [];
                          final CloudinaryService cloudinary =
                              CloudinaryService();

                          for (var img in currentImages) {
                            if (img.isLocal) {
                              final secureUrl = await cloudinary
                                  .uploadImage(img.localFile!);
                              finalUrls.add(secureUrl);
                            } else {
                              finalUrls.add(img.remoteUrl!);
                            }
                          }

                          await _service.updateEquipment(
                            equipmentId: item.equipmentId,
                            updates: {
                              'imageUrls': finalUrls,
                            },
                          );

                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Listing photos updated successfully.'),
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error updating photos: $e'),
                              ),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: DetailsTheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text('Save Images',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
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

  void _showOwnerMenuBottomSheet(MarketplaceEquipmentModel item) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: DetailsTheme.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Listing Options',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 20),
              ListTile(
                leading:
                    const Icon(Icons.edit_outlined, color: DetailsTheme.primary),
                title: const Text('Edit Listing details',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                onTap: () {
                  Navigator.pop(ctx);
                  _handleEditListing();
                },
              ),
              ListTile(
                leading: const Icon(Icons.image_outlined,
                    color: DetailsTheme.primary),
                title: const Text('Manage listing photos',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                onTap: () {
                  Navigator.pop(ctx);
                  _showManageImagesSheet(item);
                },
              ),
              ListTile(
                leading: const Icon(Icons.notifications_active_outlined,
                    color: DetailsTheme.primary),
                title: const Text('Manage Borrow requests',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                onTap: () {
                  Navigator.pop(ctx);
                  _handleViewRequests();
                },
              ),
              ListTile(
                leading: const Icon(Icons.calendar_month_outlined,
                    color: DetailsTheme.primary),
                title: const Text('Change calendar availability',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                onTap: () {
                  Navigator.pop(ctx);
                  _showEditAvailabilitySheet(item);
                },
              ),
              ListTile(
                leading:
                    const Icon(Icons.delete_outline_rounded, color: Colors.red),
                title: const Text('Delete Listing permanently',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.red)),
                onTap: () {
                  Navigator.pop(ctx);
                  _handleDeleteListing(item);
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }
}
