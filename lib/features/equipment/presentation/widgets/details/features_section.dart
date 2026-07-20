import 'package:flutter/material.dart';
import 'package:UzhavuSei/models/marketplace_equipment_model.dart';
import 'details_theme.dart';

class FeaturesSection extends StatelessWidget {
  const FeaturesSection({
    super.key,
    required this.equipment,
  });

  final MarketplaceEquipmentModel equipment;

  @override
  Widget build(BuildContext context) {
    final features = _extractFeatures(equipment);

    // Hide section completely if there are no features or tags
    if (features.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DetailsTheme.outerPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Features',
            style: DetailsTheme.sectionHeadingStyle,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: features.map((feature) {
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: DetailsTheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: DetailsTheme.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      size: 16,
                      color: DetailsTheme.success,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      feature,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: DetailsTheme.text,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  List<String> _extractFeatures(MarketplaceEquipmentModel item) {
    final List<String> list = [];

    for (var tag in item.tags) {
      final trimmed = tag.trim();
      if (trimmed.isNotEmpty && !list.contains(trimmed)) {
        list.add(trimmed);
      }
    }

    // Also check if machineSpecs has comma-separated feature flags
    if (item.machineSpecs.isNotEmpty && !item.machineSpecs.contains(':')) {
      final parts = item.machineSpecs.split(',');
      for (var p in parts) {
        final trimmed = p.trim();
        if (trimmed.isNotEmpty && !list.contains(trimmed)) {
          list.add(trimmed);
        }
      }
    }

    return list;
  }
}
