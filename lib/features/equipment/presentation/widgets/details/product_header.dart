import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:UzhavuSei/models/marketplace_equipment_model.dart';
import 'details_theme.dart';

class ProductHeader extends StatelessWidget {
  const ProductHeader({
    super.key,
    required this.equipment,
    required this.title,
    required this.category,
  });

  final MarketplaceEquipmentModel equipment;
  final String title;
  final String category;

  @override
  Widget build(BuildContext context) {
    final locationStr = equipment.distanceInfo != null
        ? equipment.distanceInfo!.formattedString
        : (equipment.area.isNotEmpty
            ? equipment.area
            : equipment.location);

    final productId = equipment.productId.trim().isNotEmpty
        ? equipment.productId.trim()
        : equipment.equipmentId
            .substring(
                0,
                equipment.equipmentId.length > 8
                    ? 8
                    : equipment.equipmentId.length)
            .toUpperCase();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DetailsTheme.outerPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            title.isNotEmpty ? title : 'Item Details',
            style: DetailsTheme.titleStyle,
          ),
          const SizedBox(height: DetailsTheme.chipSpacing),

          // Category, Location, Rating, Borrows Wrap
          Wrap(
            spacing: DetailsTheme.chipSpacing,
            runSpacing: DetailsTheme.chipSpacing,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // Category Chip
              if (category.trim().isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: DetailsTheme.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    category.trim(),
                    style: const TextStyle(
                      color: DetailsTheme.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

              // Location Chip
              if (locationStr.trim().isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: DetailsTheme.border.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 16, color: DetailsTheme.secondaryText),
                      const SizedBox(width: 4),
                      Text(
                        locationStr.trim(),
                        style: DetailsTheme.captionStyle,
                      ),
                    ],
                  ),
                ),

              // Rating Badge
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star_rounded, size: 18, color: Colors.amber),
                  const SizedBox(width: 4),
                  Text(
                    equipment.rating > 0
                        ? equipment.rating.toStringAsFixed(1)
                        : 'New',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: DetailsTheme.text,
                    ),
                  ),
                ],
              ),

              // Borrows Count
              Text(
                '• ${equipment.bookingsCount} borrows',
                style: DetailsTheme.captionStyle,
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Product Unique ID Card with Copy Button wrapped in FittedBox
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: DetailsTheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: DetailsTheme.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.fingerprint_rounded,
                    size: 18,
                    color: DetailsTheme.secondaryText,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Product ID: ',
                    style: DetailsTheme.captionStyle,
                  ),
                  SelectableText(
                    productId,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Monospace',
                      color: DetailsTheme.text,
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: productId));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Row(
                            children: [
                              Icon(Icons.check_circle_rounded,
                                  color: Colors.white, size: 18),
                              SizedBox(width: 8),
                              Text(
                                'Product ID copied',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          backgroundColor: DetailsTheme.text,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: DetailsTheme.primaryContainer,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.copy_rounded,
                        size: 14,
                        color: DetailsTheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
