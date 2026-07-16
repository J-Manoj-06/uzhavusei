import 'package:flutter/material.dart';
import '../../../../../widgets/image_loader.dart';
import 'unified_listing.dart';
import 'listing_analytics_sheet.dart';

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
            Icon(Icons.qr_code_2, color: Color(0xFF2E7D32)),
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
              style: const TextStyle(fontSize: 12, color: Color(0xFF6F7A6B)),
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
            child: const Text('Close', style: TextStyle(color: Color(0xFF2E7D32))),
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
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF6F7A6B))),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('📈 Listing Boosted successfully!')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
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
            Icon(Icons.calendar_month, color: Color(0xFF2E7D32)),
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
                    color: isBooked ? Colors.red.shade100 : Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isBooked ? Colors.red.shade300 : Colors.green.shade300,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$day',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isBooked ? Colors.red.shade900 : const Color(0xFF2E7D32),
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
            child: const Text('Close', style: TextStyle(color: Color(0xFF2E7D32))),
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
      badgeColor = const Color(0xFF2E7D32);
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
      badgeColor = const Color(0xFF2E7D32);
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
          // Upper Layout: Large Image + Badge Overlay
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                child: SizedBox(
                  height: 180,
                  width: double.infinity,
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
                    children: [
                      Icon(Icons.verified, color: Colors.blue, size: 12),
                      SizedBox(width: 4),
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
                // Title & Condition / Rating
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
                          color: Color(0xFF1A1A1A),
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          widget.listing.rating.toStringAsFixed(1),
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                // Location & Posted Date
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF6F7A6B)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        widget.listing.location,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, color: Color(0xFF6F7A6B)),
                      ),
                    ),
                    Text(
                      'Posted: $postedDateFormatted',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Prices, Condition
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Price Row
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '₹${widget.listing.price.toStringAsFixed(0)}/day',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF2E7D32),
                          ),
                        ),
                        if (hasSaleOption)
                          Text(
                            'Buy: ₹${widget.listing.salePrice!.toStringAsFixed(0)}',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.orange.shade800),
                          ),
                      ],
                    ),
                    // Condition badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Text(
                        'Condition: ${widget.listing.condition}',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),

                // Features: Inventory / AutoRenew / InstantBook / Calendar
                Row(
                  children: [
                    // Inventory Counter
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline, size: 18),
                      onPressed: () {
                        if (_inventoryCount > 1) {
                          setState(() => _inventoryCount--);
                        }
                      },
                    ),
                    Text('Qty: $_inventoryCount', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline, size: 18),
                      onPressed: () {
                        setState(() => _inventoryCount++);
                      },
                    ),
                    const Spacer(),
                    // Auto-Renew switch
                    Tooltip(
                      message: 'Auto-Renew listing when expired',
                      child: TextButton.icon(
                        icon: Icon(
                          _isAutoRenew ? Icons.autorenew : Icons.autorenew,
                          size: 16,
                          color: _isAutoRenew ? const Color(0xFF2E7D32) : Colors.grey,
                        ),
                        label: Text(
                          _isAutoRenew ? 'Auto-Renew' : 'Manual',
                          style: TextStyle(fontSize: 11, color: _isAutoRenew ? const Color(0xFF2E7D32) : Colors.grey),
                        ),
                        onPressed: () => setState(() => _isAutoRenew = !_isAutoRenew),
                      ),
                    ),
                    const SizedBox(width: 4),
                    // Instant Book indicator
                    Tooltip(
                      message: 'Instant booking toggle',
                      child: IconButton(
                        icon: Icon(
                          _isInstantBook ? Icons.bolt : Icons.offline_bolt_outlined,
                          size: 20,
                          color: _isInstantBook ? Colors.amber : Colors.grey,
                        ),
                        onPressed: () => setState(() => _isInstantBook = !_isInstantBook),
                      ),
                    ),
                    // Calendar trigger
                    IconButton(
                      icon: const Icon(Icons.calendar_month, color: Color(0xFF2E7D32), size: 20),
                      onPressed: _showRentalCalendar,
                      tooltip: 'View Rental Calendar',
                    ),
                  ],
                ),
                
                const Divider(height: 16),
                
                // Analytics indicators row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildQuickMetric(Icons.visibility_outlined, '${widget.listing.views}', 'Views'),
                    _buildQuickMetric(Icons.favorite_border, '${widget.listing.savedBy.length}', 'Saves'),
                    _buildQuickMetric(Icons.calendar_month_outlined, '${widget.listing.bookingsCount}', 'Bookings'),
                  ],
                ),
                const Divider(height: 16),

                // QUICK ACTIONS (Edit, Share, Boost, Pause, Duplicate, Analytics, Delete)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Edit
                    _circleQuickButton(
                      icon: Icons.edit_outlined,
                      tooltip: 'Edit',
                      onPressed: widget.onEdit,
                      color: Colors.blue,
                    ),
                    // Share
                    _circleQuickButton(
                      icon: Icons.share_outlined,
                      tooltip: 'Share QR',
                      onPressed: _showShareQrDialog,
                      color: Colors.green,
                    ),
                    // Boost
                    _circleQuickButton(
                      icon: Icons.rocket_launch_outlined,
                      tooltip: 'Boost',
                      onPressed: _showBoostDialog,
                      color: Colors.orange,
                    ),
                    // Pause/Resume
                    _circleQuickButton(
                      icon: cleanStatus == 'hidden' ? Icons.play_arrow_outlined : Icons.pause_outlined,
                      tooltip: cleanStatus == 'hidden' ? 'Resume' : 'Pause',
                      onPressed: widget.onPauseResume,
                      color: Colors.indigo,
                    ),
                    // Duplicate
                    _circleQuickButton(
                      icon: Icons.copy_outlined,
                      tooltip: 'Duplicate',
                      onPressed: widget.onDuplicate,
                      color: Colors.purple,
                    ),
                    // View Analytics
                    _circleQuickButton(
                      icon: Icons.bar_chart_outlined,
                      tooltip: 'Analytics',
                      onPressed: _showAnalyticsSheet,
                      color: Colors.teal,
                    ),
                    // Delete
                    _circleQuickButton(
                      icon: Icons.delete_outline_rounded,
                      tooltip: 'Delete',
                      onPressed: widget.onDelete,
                      color: Colors.red,
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

  Widget _buildQuickMetric(IconData icon, String value, String label) {
    return Row(
      children: [
        Icon(icon, size: 14, color: const Color(0xFF6F7A6B)),
        const SizedBox(width: 4),
        Text(
          '$value $label',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF3F4A3C)),
        ),
      ],
    );
  }

  Widget _circleQuickButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return Tooltip(
      message: tooltip,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          shape: BoxShape.circle,
        ),
        child: IconButton(
          icon: Icon(icon, color: color, size: 18),
          onPressed: onPressed,
        ),
      ),
    );
  }
}
