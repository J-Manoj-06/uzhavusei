import 'package:flutter/material.dart';
import '../../../../../models/marketplace_equipment_model.dart';
import '../../../../../widgets/image_loader.dart';

class EquipmentListingCard extends StatelessWidget {
  const EquipmentListingCard({
    super.key,
    required this.equipment,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final MarketplaceEquipmentModel equipment;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final image = equipment.imageUrls.isNotEmpty ? equipment.imageUrls.first : 'assets/logo.jpg';
    
    // Determine status badge
    Color badgeColor;
    String badgeText;
    IconData badgeIcon;

    switch (equipment.status.toLowerCase()) {
      case 'published':
      case 'available':
        badgeColor = const Color(0xFF4CAF50);
        badgeText = 'Available';
        badgeIcon = Icons.check_circle;
        break;
      case 'booked':
        badgeColor = const Color(0xFF2196F3);
        badgeText = 'Booked';
        badgeIcon = Icons.event_available;
        break;
      case 'pending':
        badgeColor = const Color(0xFFFFC107);
        badgeText = 'Pending Request';
        badgeIcon = Icons.hourglass_empty;
        break;
      case 'completed':
        badgeColor = const Color(0xFF9E9E9E);
        badgeText = 'Completed';
        badgeIcon = Icons.task_alt;
        break;
      case 'expired':
        badgeColor = const Color(0xFFF44336);
        badgeText = 'Expired';
        badgeIcon = Icons.error_outline;
        break;
      default:
        badgeColor = const Color(0xFF4CAF50);
        badgeText = 'Available';
        badgeIcon = Icons.check_circle;
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
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SizedBox(
                          width: 90,
                          height: 90,
                          child: buildSmartImage(image, fit: BoxFit.cover),
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.8),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.favorite_border, size: 16, color: Colors.red),
                        ),
                      ),
                    ],
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
                                // Handle other actions like pause, share, promote
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(value: 'edit', child: Text('Edit')),
                                const PopupMenuItem(value: 'pause', child: Text('Pause Listing')),
                                const PopupMenuItem(value: 'share', child: Text('Share Listing')),
                                const PopupMenuItem(value: 'promote', child: Text('Promote Listing')),
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
                          equipment.equipmentName,
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
                          equipment.category,
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
                                equipment.location,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF6F7A6B),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              '₹${equipment.pricePerDay.toStringAsFixed(0)}/day',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF006E1C),
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
            
            // Analytics Bottom Bar (Mocked for now as requested)
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
                  _buildMetric(Icons.visibility, '${equipment.views}', 'Views'),
                  _buildMetric(Icons.favorite, '${equipment.savedBy.length}', 'Saves'),
                  _buildMetric(Icons.calendar_month, '${equipment.bookingsCount}', 'Bookings'),
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
