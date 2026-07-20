import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:UzhavuSei/models/marketplace_equipment_model.dart';
import 'details_theme.dart';

class LocationCard extends StatelessWidget {
  const LocationCard({
    super.key,
    required this.equipment,
  });

  final MarketplaceEquipmentModel equipment;

  @override
  Widget build(BuildContext context) {
    final locationName = equipment.location.isNotEmpty
        ? equipment.location
        : (equipment.area.isNotEmpty ? equipment.area : equipment.city);

    // Hide section completely if location is empty or blank
    if (locationName.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    final distanceStr = equipment.distanceInfo != null
        ? '${equipment.distanceInfo!.formattedString} away'
        : 'Nearby location';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DetailsTheme.outerPadding),
      child: Container(
        padding: const EdgeInsets.all(DetailsTheme.cardSpacing),
        decoration: BoxDecoration(
          color: DetailsTheme.surface,
          borderRadius: BorderRadius.circular(DetailsTheme.cardRadius),
          border: Border.all(color: DetailsTheme.border),
          boxShadow: DetailsTheme.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.place_outlined,
                    color: DetailsTheme.primary, size: 22),
                SizedBox(width: 8),
                Text(
                  'Pickup Location',
                  style: DetailsTheme.sectionHeadingStyle,
                ),
              ],
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: DetailsTheme.primaryContainer,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.map_rounded,
                    color: DetailsTheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        locationName,
                        style: DetailsTheme.cardHeadingStyle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        distanceStr,
                        style: DetailsTheme.captionStyle,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: locationName));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Address copied to clipboard!'),
                          behavior: SnackBarBehavior.floating,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: DetailsTheme.text,
                      side: const BorderSide(color: DetailsTheme.border),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.copy_rounded, size: 16),
                    label: const Text(
                      'Copy Address',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Opening Navigation...'),
                          behavior: SnackBarBehavior.floating,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: DetailsTheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.near_me_rounded, size: 16),
                    label: const Text(
                      'Navigate',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
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
}
