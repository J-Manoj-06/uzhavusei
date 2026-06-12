import 'package:flutter/material.dart';
import '../../../../../models/farm_surplus_exchange_model.dart';
import '../../../../../widgets/image_loader.dart';

class SurplusListingCard extends StatelessWidget {
  const SurplusListingCard({
    super.key,
    required this.surplus,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final FarmSurplusExchangeModel surplus;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final image = surplus.imageUrls.isNotEmpty ? surplus.imageUrls.first : 'assets/logo.jpg';
    
    // Determine badge and colors based on listingType and status
    Color badgeColor;
    String badgeText;
    IconData badgeIcon;

    if (surplus.status.toLowerCase() == 'sold') {
      badgeColor = const Color(0xFF9E9E9E);
      badgeText = 'Sold';
      badgeIcon = Icons.remove_shopping_cart;
    } else if (surplus.status.toLowerCase() == 'exchanged') {
      badgeColor = const Color(0xFF9E9E9E);
      badgeText = 'Exchanged';
      badgeIcon = Icons.swap_horiz;
    } else if (surplus.listingType == 'donate') {
      badgeColor = const Color(0xFFE91E63);
      badgeText = 'Community Giveaway';
      badgeIcon = Icons.favorite;
    } else if (surplus.listingType == 'exchange') {
      badgeColor = const Color(0xFF9C27B0);
      badgeText = 'Exchange Only';
      badgeIcon = Icons.compare_arrows;
    } else {
      badgeColor = const Color(0xFF4CAF50);
      badgeText = 'Surplus Resource';
      badgeIcon = Icons.eco;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.05),
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      width: 90,
                      height: 90,
                      child: buildSmartImage(image, fit: BoxFit.cover),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: badgeColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(badgeIcon, size: 12, color: badgeColor),
                                  const SizedBox(width: 4),
                                  Text(
                                    badgeText,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: badgeColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert, color: Color(0xFF6F7A6B)),
                              onSelected: (value) {
                                if (value == 'edit') onEdit();
                                if (value == 'delete') onDelete();
                                // Handle other actions like mark as sold, exchanged
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(value: 'edit', child: Text('Edit')),
                                const PopupMenuItem(value: 'mark_sold', child: Text('Mark as Sold')),
                                const PopupMenuItem(value: 'mark_exchanged', child: Text('Mark as Exchanged')),
                                const PopupMenuItem(value: 'share', child: Text('Share')),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Text('Delete', style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          surplus.productName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1A1A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${surplus.category} • ${surplus.quantity} ${surplus.unitType}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6F7A6B),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.location_on, size: 14, color: Color(0xFF6F7A6B)),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                surplus.location,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF6F7A6B),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (surplus.price > 0 && surplus.listingType != 'donate')
                              Text(
                                '₹${surplus.price.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF006E1C),
                                ),
                              ),
                            if (surplus.listingType == 'donate')
                              const Text(
                                'FREE',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFFE91E63),
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
            
            // Analytics Bottom Bar (Mocked)
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF9F9F8),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                border: Border(top: BorderSide(color: const Color(0xFFBECAB9).withValues(alpha: 0.2))),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildMetric(Icons.visibility, '${surplus.views}', 'Views'),
                  _buildMetric(Icons.favorite, '${surplus.savedBy.length}', 'Saves'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetric(IconData icon, String value, String label) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: const Color(0xFF6F7A6B)),
            const SizedBox(width: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF3F4A3C),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: Color(0xFF6F7A6B),
          ),
        ),
      ],
    );
  }
}
