import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../../widgets/image_loader.dart';
import '../../../equipment/presentation/widgets/borrow_image_picker.dart';
import '../../../../../services/cloudinary_service.dart';
import 'unified_listing.dart';
import 'listing_analytics_sheet.dart';
import 'package:UzhavuSei/theme/app_theme.dart';
import '../../../../../services/product_id_service.dart';

class EquipmentListingCard extends StatefulWidget {
  const EquipmentListingCard({
    super.key,
    required this.listing,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onPauseResume,
    required this.onDuplicate,
  });

  final UnifiedListing listing;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onPauseResume;
  final VoidCallback onDuplicate;

  @override
  State<EquipmentListingCard> createState() => _EquipmentListingCardState();
}

class _EquipmentListingCardState extends State<EquipmentListingCard> {
  // Mock features states
  bool _isAutoRenew = false;
  int _inventoryCount = 1;
  bool _isInstantBook = true;

  String _getCategoryEmoji(String category) {
    final cat = category.toLowerCase();
    if (cat.contains('book')) return '📚';
    if (cat.contains('farm') || cat.contains('agri') || cat == 'seeds' || cat == 'fertilizer') return '🚜';
    if (cat.contains('construction') || cat.contains('tool')) return '🏗️';
    return '📦';
  }

  void _showShareQrDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.qr_code_2, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Scan & Share QR Code', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Share this listing of "${widget.listing.title}" with friends or community groups.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            // Mock QR Code widget
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300, width: 2),
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.all(12),
              child: SizedBox(
                width: 160,
                height: 160,
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 10,
                  ),
                  itemCount: 100,
                  itemBuilder: (context, index) {
                    final isBlack = (index * 7 + index % 3) % 2 == 0 ||
                        (index < 30 && index % 10 < 3) || 
                        (index < 30 && index % 10 >= 7) || 
                        (index >= 70 && index % 10 < 3); 
                    return Container(color: isBlack ? Colors.black : Colors.white);
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'borrow.app/listing/' + 'id-928374',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blue),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  void _showBoostDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.rocket_launch, color: Colors.amber),
            SizedBox(width: 8),
            Text('Boost Listing', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'Boost your listing to place it at the top of the search results for 7 days. This will generate up to 5x more views from renters nearby.',
          style: TextStyle(fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('📈 Listing Boosted successfully!')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Boost Now'),
          ),
        ],
      ),
    );
  }

  void _showAnalyticsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => ListingAnalyticsSheet(
        title: widget.listing.title,
        category: widget.listing.category,
        views: widget.listing.views,
        favoritesCount: widget.listing.savedBy.length,
        bookingsCount: widget.listing.bookingsCount,
        price: widget.listing.price,
      ),
    );
  }

  void _showRentalCalendar() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.calendar_month, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Rental Calendar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Green dates indicate available rental windows. Red dates are booked.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            // Custom Calendar drawing
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 6,
                crossAxisSpacing: 6,
              ),
              itemCount: 28,
              itemBuilder: (context, index) {
                final day = index + 1;
                // mock booked dates (e.g. 5, 6, 7, 18, 19)
                final isBooked = [5, 6, 7, 18, 19].contains(day);
                return Container(
                  decoration: BoxDecoration(
                    color: isBooked ? Colors.red.shade100 : AppColors.success,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isBooked ? Colors.red.shade300 : AppColors.success,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$day',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isBooked ? Colors.red.shade900 : AppColors.primary,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final image = widget.listing.imageUrls.isNotEmpty ? widget.listing.imageUrls.first : 'assets/logo.jpg';
    final hasSaleOption = widget.listing.salePrice != null && widget.listing.salePrice! > 0;
    
    // Status color
    Color badgeColor;
    String badgeText;
    IconData badgeIcon;
    final cleanStatus = widget.listing.status.toLowerCase();

    if (cleanStatus == 'published' || cleanStatus == 'available') {
      badgeColor = AppColors.primary;
      badgeText = 'Available';
      badgeIcon = Icons.check_circle_outline;
    } else if (cleanStatus == 'booked') {
      badgeColor = Colors.blue;
      badgeText = 'Booked';
      badgeIcon = Icons.event_available;
    } else if (cleanStatus == 'rented') {
      badgeColor = Colors.indigo;
      badgeText = 'Rented';
      badgeIcon = Icons.autorenew_outlined;
    } else if (cleanStatus == 'sold') {
      badgeColor = Colors.grey;
      badgeText = 'Sold';
      badgeIcon = Icons.done_all;
    } else if (cleanStatus == 'expired') {
      badgeColor = Colors.red;
      badgeText = 'Expired';
      badgeIcon = Icons.warning_amber_rounded;
    } else if (cleanStatus == 'draft') {
      badgeColor = Colors.orange;
      badgeText = 'Draft';
      badgeIcon = Icons.edit_note;
    } else if (cleanStatus == 'hidden') {
      badgeColor = Colors.grey.shade600;
      badgeText = 'Paused';
      badgeIcon = Icons.pause_circle_outline;
    } else {
      badgeColor = AppColors.primary;
      badgeText = 'Available';
      badgeIcon = Icons.check_circle_outline;
    }

    final postedDateFormatted = '${widget.listing.createdAt.day}/${widget.listing.createdAt.month}/${widget.listing.createdAt.year}';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: 0.04),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ──────────────────────────────────────────────────────────────────
          // SECTION 1: Image, Category Badge, Status Badge
          // ──────────────────────────────────────────────────────────────────
          Stack(
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  child: buildSmartImage(image, fit: BoxFit.cover),
                ),
              ),
              // Category Overlay
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_getCategoryEmoji(widget.listing.category)),
                      const SizedBox(width: 4),
                      Text(
                        widget.listing.category,
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
              // Status Badge Overlay
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: badgeColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 8, offset: const Offset(0, 2)),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(badgeIcon, size: 12, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(
                        badgeText,
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
              // Verification badge overlay
              Positioned(
                bottom: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified, color: Colors.blue, size: 12),
                      const SizedBox(width: 4),
                      Text('Verified', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.blue)),
                    ],
                  ),
                ),
              ),
            ],
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ──────────────────────────────────────────────────────────────
                // SECTION 2: Title, Location, Posted Date, Rating
                // ──────────────────────────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        widget.listing.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          widget.listing.rating.toStringAsFixed(1),
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              widget.listing.location,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Posted: $postedDateFormatted',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Price display
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '₹${widget.listing.price.toStringAsFixed(0)}/day',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary,
                      ),
                    ),
                    if (hasSaleOption)
                      Text(
                        'Buy: ₹${widget.listing.salePrice!.toStringAsFixed(0)}',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.orange.shade800),
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                // ──────────────────────────────────────────────────────────────
                // SECTION 3: Status Information Chips (Wrap layout to avoid overflow)
                // ──────────────────────────────────────────────────────────────
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    if (widget.listing.productId.isNotEmpty)
                      _buildMaterialChip(
                        widget.listing.productId,
                        Icons.copy_all_rounded,
                        AppColors.primary,
                        onTap: () {
                          ProductIdService.instance.copyToClipboard(context, widget.listing.productId);
                        },
                      ),
                    _buildMaterialChip(widget.listing.condition, Icons.handyman_outlined, Colors.grey.shade700),
                    _buildMaterialChip('Qty $_inventoryCount', Icons.shopping_bag_outlined, Colors.blue.shade700, onTap: () {
                      _showQuantityEditDialog();
                    }),
                    _buildMaterialChip(_isAutoRenew ? 'Auto-Renew' : 'Manual', Icons.autorenew_rounded, _isAutoRenew ? AppColors.primary : Colors.grey.shade600, onTap: () {
                      setState(() => _isAutoRenew = !_isAutoRenew);
                    }),
                    if (_isInstantBook)
                      _buildMaterialChip('Instant Book', Icons.bolt, Colors.amber.shade900, onTap: () {
                        setState(() => _isInstantBook = !_isInstantBook);
                      }),
                  ],
                ),
                const Divider(height: 24),

                // ──────────────────────────────────────────────────────────────
                // SECTION 4: Statistics (3 Equal Cards Row)
                // ──────────────────────────────────────────────────────────────
                Row(
                  children: [
                    Expanded(child: _buildMetricCard('Views', '${widget.listing.views}', Icons.visibility_outlined, Colors.blue)),
                    const SizedBox(width: 8),
                    Expanded(child: _buildMetricCard('Saves', '${widget.listing.savedBy.length}', Icons.favorite_border, Colors.pink)),
                    const SizedBox(width: 8),
                    Expanded(child: _buildMetricCard('Requests', '${widget.listing.bookingsCount}', Icons.calendar_month_outlined, AppColors.primary)),
                  ],
                ),
                const Divider(height: 24),

                // ──────────────────────────────────────────────────────────────
                // SECTION 5: Owner Actions
                // ──────────────────────────────────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showManageListingBottomSheet(cleanStatus),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          minimumSize: const Size(0, 48),
                        ),
                        icon: const Icon(Icons.settings_outlined, size: 18),
                        label: const Text('Manage Listing', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: widget.onEdit,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        minimumSize: const Size(48, 48),
                        padding: EdgeInsets.zero,
                      ),
                      child: const Icon(Icons.edit_outlined, size: 20),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: widget.onDelete,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: BorderSide(color: Colors.red.shade200),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        minimumSize: const Size(48, 48),
                        padding: EdgeInsets.zero,
                      ),
                      child: const Icon(Icons.delete_outline_rounded, size: 20),
                    ),
                    const SizedBox(width: 8),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert_rounded, color: Colors.black87),
                      onSelected: (val) {
                        if (val == 'share') _showShareQrDialog();
                        if (val == 'boost') _showBoostDialog();
                        if (val == 'calendar') _showRentalCalendar();
                        if (val == 'analytics') _showAnalyticsSheet();
                        if (val == 'pause') widget.onPauseResume();
                        if (val == 'images') _showManageImagesSheet();
                        if (val == 'duplicate') widget.onDuplicate();
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 'share', child: Row(children: [Icon(Icons.qr_code_2, size: 18), SizedBox(width: 8), Text('Share QR')])),
                        const PopupMenuItem(value: 'boost', child: Row(children: [Icon(Icons.rocket_launch_outlined, size: 18), SizedBox(width: 8), Text('Boost listing')])),
                        const PopupMenuItem(value: 'calendar', child: Row(children: [Icon(Icons.calendar_month_outlined, size: 18), SizedBox(width: 8), Text('Calendar')])),
                        const PopupMenuItem(value: 'analytics', child: Row(children: [Icon(Icons.bar_chart_outlined, size: 18), SizedBox(width: 8), Text('Analytics')])),
                        const PopupMenuItem(value: 'images', child: Row(children: [Icon(Icons.image_outlined, size: 18), SizedBox(width: 8), Text('Manage Images')])),
                        PopupMenuItem(value: 'pause', child: Row(children: [Icon(cleanStatus == 'hidden' ? Icons.play_arrow_outlined : Icons.pause_outlined, size: 18), const SizedBox(width: 8), Text(cleanStatus == 'hidden' ? 'Resume' : 'Pause')])),
                        const PopupMenuItem(value: 'duplicate', child: Row(children: [Icon(Icons.copy_outlined, size: 18), SizedBox(width: 8), Text('Duplicate')])),
                      ],
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

  Widget _buildMaterialChip(String label, IconData icon, Color color, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9F8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBECAB9).withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  void _showQuantityEditDialog() {
    final ctrl = TextEditingController(text: '$_inventoryCount');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Update Quantity', style: TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Available quantity'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final val = int.tryParse(ctrl.text.trim()) ?? 1;
              setState(() => _inventoryCount = val);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showManageListingBottomSheet(String cleanStatus) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
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
              'Manage Listing',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.edit_outlined, color: Colors.blue),
              title: const Text('Edit Listing details'),
              onTap: () {
                Navigator.pop(ctx);
                widget.onEdit();
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_month_outlined, color: AppColors.primary),
              title: const Text('View Rental Calendar'),
              onTap: () {
                Navigator.pop(ctx);
                _showRentalCalendar();
              },
            ),
            ListTile(
              leading: const Icon(Icons.bar_chart_outlined, color: Colors.teal),
              title: const Text('View Performance Analytics'),
              onTap: () {
                Navigator.pop(ctx);
                _showAnalyticsSheet();
              },
            ),
            ListTile(
              leading: const Icon(Icons.image_outlined, color: AppColors.success),
              title: const Text('Manage listing photos'),
              onTap: () {
                Navigator.pop(ctx);
                _showManageImagesSheet();
              },
            ),
            ListTile(
              leading: Icon(
                cleanStatus == 'hidden' ? Icons.play_arrow_outlined : Icons.pause_circle_outline,
                color: Colors.indigo,
              ),
              title: Text(cleanStatus == 'hidden' ? 'Resume Listing' : 'Pause Listing'),
              onTap: () {
                Navigator.pop(ctx);
                widget.onPauseResume();
              },
            ),
            ListTile(
              leading: const Icon(Icons.rocket_launch_outlined, color: Colors.orange),
              title: const Text('Boost Visibility'),
              onTap: () {
                Navigator.pop(ctx);
                _showBoostDialog();
              },
            ),
            ListTile(
              leading: const Icon(Icons.qr_code_2, color: AppColors.success),
              title: const Text('Share QR Code'),
              onTap: () {
                Navigator.pop(ctx);
                _showShareQrDialog();
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy_outlined, color: Colors.purple),
              title: const Text('Duplicate Listing'),
              onTap: () {
                Navigator.pop(ctx);
                widget.onDuplicate();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded, color: Colors.red),
              title: const Text('Delete Listing', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(ctx);
                widget.onDelete();
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _showManageImagesSheet() {
    List<BorrowImageItem> currentImages = widget.listing.imageUrls.map((url) => BorrowImageItem(remoteUrl: url)).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
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
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Manage Photos', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.textPrimary)),
                  const SizedBox(height: 4),
                  Text('The first image is the cover photo. Reorder or delete images below.', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                  const SizedBox(height: 16),

                  // Image picker container
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
                        Navigator.pop(ctx); // pop sheet
                        
                        // Show loading popup
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (context) => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                        );

                        try {
                          final List<String> finalUrls = [];
                          final CloudinaryService cloudinary = CloudinaryService();

                          for (var img in currentImages) {
                            if (img.isLocal) {
                              final secureUrl = await cloudinary.uploadImage(img.localFile!);
                              finalUrls.add(secureUrl);
                            } else {
                              finalUrls.add(img.remoteUrl!);
                            }
                          }

                          await FirebaseFirestore.instance.collection('equipment').doc(widget.listing.id).update({
                            'imageUrls': finalUrls,
                          });

                          if (context.mounted) {
                            Navigator.pop(context); // pop loader
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Listing photos updated successfully.')),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            Navigator.pop(context); // pop loader
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error updating photos: $e')),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('Save Images', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
}
