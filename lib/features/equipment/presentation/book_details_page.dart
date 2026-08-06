import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import '../../../models/app_user_model.dart';
import '../../../services/auth_service.dart';
import '../../profile/presentation/complete_profile_page.dart';
import '../../../models/marketplace_equipment_model.dart';
import '../../../models/book_model.dart';
import '../../../models/borrow_request_model.dart';
import '../../../services/marketplace_service.dart';
import '../../../services/inventory_service.dart';
import '../../../services/borrow_request_repository.dart';
import '../../../services/listing_context_service.dart';
import '../../../widgets/borrow_product_id_card.dart';
import '../../../widgets/image_loader.dart';
import 'widgets/borrow_request/borrow_request_bottom_sheet.dart';
import '../../explore/presentation/chatbot_page.dart';
import 'widgets/details/details_theme.dart';
import '../../../services/borrow_eligibility_service.dart';
import '../../../widgets/borrow_limit_dialog.dart';
import '../../../services/borrow_lifecycle_service.dart';

class BookDetailsPage extends StatefulWidget {
  final MarketplaceEquipmentModel initialItem;
  final String userId;
  final String userName;
  final String userEmail;
  final String userPhone;

  const BookDetailsPage({
    super.key,
    required this.initialItem,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.userPhone,
  });

  @override
  State<BookDetailsPage> createState() => _BookDetailsPageState();
}

class _BookDetailsPageState extends State<BookDetailsPage> {
  final PageController _imagePageCtrl = PageController();
  int _activeImageIndex = 0;
  bool _isSaved = false;

  @override
  void initState() {
    super.initState();
    _isSaved = widget.initialItem.savedBy.contains(widget.userId);
  }

  @override
  void dispose() {
    _imagePageCtrl.dispose();
    super.dispose();
  }

  void _toggleFavorite(MarketplaceEquipmentModel item) async {
    final newSaved = !_isSaved;
    setState(() => _isSaved = newSaved);

    try {
      final docRef = FirebaseFirestore.instance.collection('equipment').doc(item.equipmentId);
      if (newSaved) {
        await docRef.update({
          'savedBy': FieldValue.arrayUnion([widget.userId])
        });
      } else {
        await docRef.update({
          'savedBy': FieldValue.arrayRemove([widget.userId])
        });
      }
    } catch (_) {
      try {
        final bookRef = FirebaseFirestore.instance.collection('books').doc(item.equipmentId);
        if (newSaved) {
          await bookRef.update({
            'savedBy': FieldValue.arrayUnion([widget.userId])
          });
        } else {
          await bookRef.update({
            'savedBy': FieldValue.arrayRemove([widget.userId])
          });
        }
      } catch (_) {}
    }
  }

  void _showZoomImageModal(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.contain,
                  placeholder: (_, __) => const Center(child: CircularProgressIndicator(color: Colors.white)),
                  errorWidget: (_, __, ___) => const Icon(Icons.broken_image, color: Colors.white, size: 48),
                ),
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showQrCodeModal(BookCopyModel copy) {
    showModalBottomSheet(
      context: context,
      backgroundColor: DetailsTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Copy #${copy.copyNumber} - QR Code',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: DetailsTheme.text),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: DetailsTheme.border),
              ),
              child: Column(
                children: [
                  Icon(Icons.qr_code_2_rounded, size: 160, color: Colors.grey[900]),
                  const SizedBox(height: 8),
                  Text('Barcode: ${copy.barcode.isEmpty ? 'N/A' : copy.barcode}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black)),
                  Text('Rack: ${copy.rackNumber}', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    label: const Text('Close'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Share.share('Book Copy #${copy.copyNumber}\nBarcode: ${copy.barcode}\nRack: ${copy.rackNumber}');
                    },
                    icon: const Icon(Icons.share_rounded),
                    label: const Text('Share QR'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: DetailsTheme.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showProfileIncompleteDialog(BuildContext context, AppUserModel? userModel) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.assignment_ind_rounded, color: DetailsTheme.primary, size: 28),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Complete Your Profile',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: const Text(
          'Complete your profile before requesting library books.',
          style: TextStyle(fontSize: 14, color: Color(0xFF475569)),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CompleteProfilePage(
                    authService: AuthService(),
                    initialUser: userModel,
                    isMandatory: false,
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: DetailsTheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Complete Profile', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showActiveLoanDialog(BuildContext context, BorrowEligibilityState eligibilityState) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.auto_stories_rounded, color: Colors.orange, size: 28),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Active Loan Exists',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'You already have a borrowed book. Please return it before requesting another.',
              style: TextStyle(fontSize: 14, color: Color(0xFF475569), height: 1.35),
            ),
            if (eligibilityState.activeBookTitle != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.menu_book_rounded, size: 20, color: Colors.orange),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        eligibilityState.activeBookTitle!,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<bool> _ensureProfileComplete(AppUserModel? userModel) async {
    if (userModel == null || !userModel.isProfileComplete) {
      if (!mounted) return false;
      _showProfileIncompleteDialog(context, userModel);
      return false;
    }
    return true;
  }

  void _showBorrowDialog(MarketplaceEquipmentModel item, AppUserModel? userModel) async {
    final isComplete = await _ensureProfileComplete(userModel);
    if (!isComplete) return;

    if (!mounted) return;
    BorrowRequestBottomSheet.show(
      context: context,
      equipment: item,
      borrowerId: widget.userId,
      borrowerName: widget.userName,
    );
  }

  void _handleReserveBook(MarketplaceEquipmentModel item, AppUserModel? userModel) async {
    final isComplete = await _ensureProfileComplete(userModel);
    if (!isComplete) return;

    try {
      final req = BorrowRequestModel(
        requestId: '',
        listingId: item.equipmentId,
        listingTitle: item.equipmentName,
        listingImage: item.imageUrls.isNotEmpty ? item.imageUrls.first : '',
        category: item.category,
        ownerId: item.ownerId,
        borrowerId: widget.userId,
        borrowerName: widget.userName,
        borrowFrom: DateTime.now(),
        borrowUntil: DateTime.now().add(const Duration(days: 7)),
        borrowDuration: 7,
        status: 'Reserved',
        requestedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await BorrowRequestRepository().createReservation(req);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Book reserved successfully! You will be notified when a copy becomes available.'),
          backgroundColor: Colors.purple,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Reservation error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<BorrowEligibilityState>(
      stream: BorrowEligibilityService.instance.watchEligibility(widget.userId),
      builder: (context, eligSnap) {
        final eligState = eligSnap.data ?? BorrowEligibilityState.eligibleState();
        final hasActiveLoan = !eligState.eligible;

        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance.collection('users').doc(widget.userId).snapshots(),
          builder: (context, userSnap) {
            final userModel = userSnap.hasData && userSnap.data!.exists
                ? AppUserModel.fromDoc(userSnap.data!)
                : null;
            final isProfileComplete = userModel != null && userModel.isProfileComplete;
            final isEligibleToBorrow = isProfileComplete && !hasActiveLoan;

            return StreamBuilder<MarketplaceEquipmentModel>(
              stream: MarketplaceService().watchEquipmentById(widget.initialItem.equipmentId),
              initialData: widget.initialItem,
              builder: (context, snapshot) {
                final item = snapshot.data ?? widget.initialItem;
                final isOwner = item.ownerId == widget.userId;

            return Scaffold(
              backgroundColor: DetailsTheme.background,
              appBar: AppBar(
                backgroundColor: DetailsTheme.surface,
                foregroundColor: DetailsTheme.text,
                elevation: 0.5,
                title: Text(
                  item.equipmentName,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                actions: [
                  IconButton(
                    icon: Icon(_isSaved ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        color: _isSaved ? Colors.red : DetailsTheme.text),
                    onPressed: () => _toggleFavorite(item),
                  ),
                  IconButton(
                    icon: const Icon(Icons.share_outlined),
                    onPressed: () => Share.share('Check out "${item.equipmentName}" on Borrow!\nProduct ID: ${item.productId}'),
                  ),
                ],
              ),
              body: ListView(
                padding: const EdgeInsets.only(bottom: 120),
                children: [
                  // Hero Image Gallery Section
                  _buildImageGallerySection(item),

                  const SizedBox(height: 16),

                  // Title & Core Metadata
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: DetailsTheme.outerPadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                item.equipmentName,
                                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: DetailsTheme.text),
                              ),
                            ),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: [
                                // Stock status badge
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: item.availability ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    item.stockStatusBadge,
                                    style: TextStyle(
                                      color: item.availability ? Colors.green : Colors.red,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                                // Eligibility Badge
                                GestureDetector(
                                  onTap: () {
                                    if (!isProfileComplete) {
                                      _showProfileIncompleteDialog(context, userModel);
                                    } else if (hasActiveLoan) {
                                      _showActiveLoanDialog(context, eligState);
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isEligibleToBorrow
                                          ? const Color(0xFFDCFCE7)
                                          : (hasActiveLoan ? const Color(0xFFFFEDD5) : const Color(0xFFFEF3C7)),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isEligibleToBorrow
                                            ? const Color(0xFF86EFAC)
                                            : (hasActiveLoan ? const Color(0xFFFDBA74) : const Color(0xFFFDE68A)),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          isEligibleToBorrow
                                              ? Icons.verified_user_rounded
                                              : (hasActiveLoan ? Icons.menu_book_rounded : Icons.warning_amber_rounded),
                                          size: 13,
                                          color: isEligibleToBorrow
                                              ? const Color(0xFF15803D)
                                              : (hasActiveLoan ? const Color(0xFFC2410C) : const Color(0xFFB45309)),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          isEligibleToBorrow
                                              ? 'Eligible to Borrow'
                                              : (hasActiveLoan ? 'Active Loan Exists' : 'Profile Incomplete'),
                                          style: TextStyle(
                                            color: isEligibleToBorrow
                                                ? const Color(0xFF15803D)
                                                : (hasActiveLoan ? const Color(0xFFC2410C) : const Color(0xFFB45309)),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        if (item.machineSpecs.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            'By ${item.machineSpecs}',
                            style: const TextStyle(fontSize: 14, color: DetailsTheme.secondaryText, fontWeight: FontWeight.w500),
                          ),
                        ],
                        const SizedBox(height: 12),

                        // Price & Category Pill
                        Row(
                          children: [
                            Text(
                              '₹${item.pricePerDay.toStringAsFixed(0)} / day',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: DetailsTheme.primary),
                            ),
                            const SizedBox(width: 12),
                            Chip(
                              avatar: const Icon(Icons.book_rounded, size: 14, color: DetailsTheme.primary),
                              label: Text(item.category, style: const TextStyle(fontSize: 12)),
                              backgroundColor: DetailsTheme.primary.withValues(alpha: 0.08),
                              padding: EdgeInsets.zero,
                              side: BorderSide.none,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Product ID Card
                  if (item.productId.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: DetailsTheme.outerPadding),
                      child: BorrowProductIdCard(productId: item.productId),
                    ),

                  const SizedBox(height: 16),

                  // Description Section
                  if (item.description.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: DetailsTheme.outerPadding),
                      child: Card(
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
                              const Text('Overview & Summary',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: DetailsTheme.text)),
                              const SizedBox(height: 8),
                              Text(
                                item.description,
                                style: const TextStyle(fontSize: 14, color: DetailsTheme.secondaryText, height: 1.4),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                  // Live Inventory Breakdown & Physical Copies
                  _buildInventorySection(item),

                  const SizedBox(height: 16),

                  // Ask AI Assistance Button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: DetailsTheme.outerPadding),
                    child: ElevatedButton.icon(
                      onPressed: () {
                        ListingContextService.instance.cacheListing(item);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ChatbotPage(isFromListing: true)),
                        );
                      },
                      icon: const Icon(Icons.auto_awesome_rounded),
                      label: const Text('Ask Borrow AI About This Book'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: DetailsTheme.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Related Books Recommendations
                  _buildRelatedBooksSection(item),
                ],
              ),
              bottomNavigationBar: Container(
                padding: EdgeInsets.fromLTRB(
                  16,
                  12,
                  16,
                  12 + MediaQuery.of(context).padding.bottom,
                ),
                decoration: BoxDecoration(
                  color: DetailsTheme.surface,
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 10, offset: const Offset(0, -4)),
                  ],
                ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Rental Price', style: TextStyle(fontSize: 11, color: DetailsTheme.secondaryText)),
                            Text('₹${item.pricePerDay.toStringAsFixed(0)} / day',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: DetailsTheme.text)),
                          ],
                        ),
                      ),
                      StreamBuilder<List<BorrowRequestModel>>(
                        stream: BorrowRequestRepository().watchBorrowerRequests(widget.userId),
                        builder: (context, reqSnap) {
                          final requests = reqSnap.data ?? [];
                          final existingReq = requests.cast<BorrowRequestModel?>().firstWhere(
                            (r) => r?.listingId == item.equipmentId && (r?.status == 'Requested' || r?.status == 'Accepted' || r?.status == 'Borrowed' || r?.status == 'Reserved'),
                            orElse: () => null,
                          );

                          if (isOwner) {
                            return ElevatedButton.icon(
                              onPressed: null,
                              icon: const Icon(Icons.person),
                              label: const Text('Your Listing'),
                            );
                          }

                          if (existingReq != null) {
                            final s = existingReq.status;
                            if (s == 'Borrowed') {
                              return ElevatedButton.icon(
                                onPressed: null,
                                icon: const Icon(Icons.check_circle_rounded),
                                label: Text('Issued (${existingReq.daysRemaining}d left)'),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                              );
                            }
                            if (s == 'Requested') {
                              return ElevatedButton.icon(
                                onPressed: null,
                                icon: const Icon(Icons.hourglass_top_rounded),
                                label: const Text('Pending Approval'),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
                              );
                            }
                            if (s == 'Reserved') {
                              return ElevatedButton.icon(
                                onPressed: null,
                                icon: const Icon(Icons.bookmark_added_rounded),
                                label: const Text('Reserved'),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.purple, foregroundColor: Colors.white),
                              );
                            }
                          }

                          if (item.availableCopies <= 0) {
                            return ElevatedButton.icon(
                              onPressed: () {
                                if (!isProfileComplete) {
                                  _showProfileIncompleteDialog(context, userModel);
                                } else if (hasActiveLoan) {
                                  _showActiveLoanDialog(context, eligState);
                                } else {
                                  _handleReserveBook(item, userModel);
                                }
                              },
                              icon: const Icon(Icons.bookmark_add_outlined),
                              label: const Text('Reserve Book'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isEligibleToBorrow ? Colors.purple : Colors.grey.shade400,
                                foregroundColor: Colors.white,
                              ),
                            );
                          }

                          return ElevatedButton.icon(
                            onPressed: () {
                              if (!isProfileComplete) {
                                _showProfileIncompleteDialog(context, userModel);
                              } else if (hasActiveLoan) {
                                BorrowLimitDialog.show(context);
                              } else {
                                _showBorrowDialog(item, userModel);
                              }
                            },
                            icon: Icon(
                              isEligibleToBorrow
                                  ? Icons.bookmark_add_rounded
                                  : (hasActiveLoan ? Icons.block_rounded : Icons.lock_outline_rounded),
                            ),
                            label: Text(
                              isEligibleToBorrow
                                  ? 'Request to Borrow'
                                  : (hasActiveLoan ? 'Request Unavailable' : 'Complete Profile to Borrow'),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isEligibleToBorrow
                                  ? DetailsTheme.primary
                                  : (hasActiveLoan ? Colors.orange.shade800 : Colors.amber.shade700),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
          },
        );
      },
    );
  },
);
}

  Widget _buildImageGallerySection(MarketplaceEquipmentModel item) {
    final images = item.imageUrls.isNotEmpty ? item.imageUrls : [''];

    return Container(
      height: 280,
      width: double.infinity,
      color: Colors.black.withOpacity(0.03),
      child: Stack(
        children: [
          PageView.builder(
            controller: _imagePageCtrl,
            itemCount: images.length,
            onPageChanged: (index) => setState(() => _activeImageIndex = index),
            itemBuilder: (context, index) {
              final url = images[index];
              return GestureDetector(
                onTap: () => url.isNotEmpty ? _showZoomImageModal(url) : null,
                child: buildSmartImage(
                  url,
                  fit: BoxFit.contain,
                  isBook: true,
                ),
              );
            },
          ),
          if (images.length > 1)
            Positioned(
              bottom: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_activeImageIndex + 1} / ${images.length}',
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInventorySection(MarketplaceEquipmentModel item) {
    return StreamBuilder<BookInventoryModel>(
      stream: InventoryService.instance.watchBookInventory(item.equipmentId),
      builder: (context, snapshot) {
        final inventory = snapshot.data ?? BookInventoryModel.fromCopies(item.equipmentId, const [], fallbackTotal: item.totalCopies);

        return Card(
          color: DetailsTheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DetailsTheme.cardRadius),
            side: const BorderSide(color: DetailsTheme.border),
          ),
          elevation: 0,
          margin: const EdgeInsets.symmetric(horizontal: DetailsTheme.outerPadding, vertical: 8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Inventory Breakdown', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: DetailsTheme.text)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildChip('Total', '${inventory.totalCopies}', Colors.blue),
                    const SizedBox(width: 8),
                    _buildChip('Available', '${inventory.availableCopies}', Colors.green),
                    const SizedBox(width: 8),
                    _buildChip('Borrowed', '${inventory.borrowedCopies}', Colors.orange),
                    const SizedBox(width: 8),
                    _buildChip('Damaged', '${inventory.damagedCopies}', Colors.red),
                  ],
                ),
                if (inventory.copies.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text('Physical Copies', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: DetailsTheme.text)),
                  const SizedBox(height: 8),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: inventory.copies.length,
                    separatorBuilder: (_, __) => const Divider(height: 12),
                    itemBuilder: (context, index) {
                      final copy = inventory.copies[index];
                      return ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          radius: 14,
                          backgroundColor: Colors.blue.withOpacity(0.1),
                          child: Text('#${index + 1}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                        title: Text('Barcode: ${copy.barcode.isEmpty ? 'N/A' : copy.barcode}', style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text('Rack: ${copy.rackNumber} • Condition: ${copy.condition}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.qr_code_2_rounded, color: DetailsTheme.primary),
                          onPressed: () => _showQrCodeModal(copy),
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildChip(String label, String val, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Text(val, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 14)),
            Text(label, style: TextStyle(color: color, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _buildRelatedBooksSection(MarketplaceEquipmentModel currentItem) {
    return StreamBuilder<List<MarketplaceEquipmentModel>>(
      stream: MarketplaceService().watchRelatedEquipment(
        category: currentItem.category,
        currentEquipmentId: currentItem.equipmentId,
      ),
      builder: (context, snapshot) {
        final related = snapshot.data ?? [];
        if (related.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: DetailsTheme.outerPadding),
              child: Text('Related Books', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: DetailsTheme.text)),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 140,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: DetailsTheme.outerPadding),
                itemCount: related.length,
                itemBuilder: (context, index) {
                  final b = related[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BookDetailsPage(
                            initialItem: b,
                            userId: widget.userId,
                            userName: widget.userName,
                            userEmail: widget.userEmail,
                            userPhone: widget.userPhone,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      width: 110,
                      margin: const EdgeInsets.only(right: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: SizedBox(
                                width: double.infinity,
                                height: double.infinity,
                                child: buildSmartImage(
                                  b.imageUrls.isNotEmpty ? b.imageUrls.first : '',
                                  fit: BoxFit.cover,
                                  isBook: true,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(b.equipmentName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                          Text('₹${b.pricePerDay.toStringAsFixed(0)}/day', style: const TextStyle(color: DetailsTheme.primary, fontSize: 11, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
