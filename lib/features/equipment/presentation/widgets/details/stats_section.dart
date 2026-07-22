import 'package:flutter/material.dart';
import 'package:UzhavuSei/models/marketplace_equipment_model.dart';
import 'details_theme.dart';

class StatsSection extends StatelessWidget {
  const StatsSection({
    super.key,
    required this.equipment,
  });

  final MarketplaceEquipmentModel equipment;

  @override
  Widget build(BuildContext context) {
    final ratingText = equipment.rating > 0
        ? equipment.rating.toStringAsFixed(1)
        : 'New';

    final items = [
      _StatData(
        icon: Icons.visibility_outlined,
        value: '${equipment.views}',
        label: 'Views',
        iconColor: DetailsTheme.primary,
      ),
      _StatData(
        icon: Icons.favorite_border_rounded,
        value: '${equipment.savedBy.length}',
        label: 'Saved',
        iconColor: Colors.pink.shade400,
      ),
      _StatData(
        icon: Icons.handshake_outlined,
        value: '${equipment.bookingsCount}',
        label: 'Borrows',
        iconColor: DetailsTheme.secondary,
      ),
      _StatData(
        icon: Icons.star_rounded,
        value: ratingText,
        label: 'Rating',
        iconColor: Colors.amber.shade700,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DetailsTheme.outerPadding),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isSmallScreen = constraints.maxWidth < 360;

          if (isSmallScreen) {
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 2.2,
                crossAxisSpacing: DetailsTheme.cardSpacing,
                mainAxisSpacing: DetailsTheme.cardSpacing,
              ),
              itemBuilder: (context, index) => _buildStatCard(items[index]),
            );
          }

          return Row(
            children: items.map((stat) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: _buildStatCard(stat),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  Widget _buildStatCard(_StatData stat) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      decoration: BoxDecoration(
        color: DetailsTheme.surface,
        borderRadius: BorderRadius.circular(DetailsTheme.cardRadius),
        border: Border.all(color: DetailsTheme.border),
        boxShadow: DetailsTheme.cardShadow,
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(stat.icon, size: 20, color: stat.iconColor),
            const SizedBox(height: 4),
            Text(
              stat.value,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: DetailsTheme.text,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              stat.label,
              style: DetailsTheme.captionStyle,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatData {
  final IconData icon;
  final String value;
  final String label;
  final Color iconColor;

  _StatData({
    required this.icon,
    required this.value,
    required this.label,
    required this.iconColor,
  });
}
