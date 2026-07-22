import 'package:flutter/material.dart';
import 'package:UzhavuSei/models/marketplace_equipment_model.dart';
import 'details_theme.dart';

class SpecificationGrid extends StatelessWidget {
  const SpecificationGrid({
    super.key,
    required this.equipment,
  });

  final MarketplaceEquipmentModel equipment;

  @override
  Widget build(BuildContext context) {
    final specs = _extractSpecs(equipment);

    // Hide section completely if there are no specifications or attributes to display
    if (specs.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DetailsTheme.outerPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Specifications',
            style: DetailsTheme.sectionHeadingStyle,
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final double cardWidth = constraints.maxWidth > 500
                  ? (constraints.maxWidth - DetailsTheme.cardSpacing * 2) / 3
                  : (constraints.maxWidth - DetailsTheme.cardSpacing) / 2;

              return Wrap(
                spacing: DetailsTheme.cardSpacing,
                runSpacing: DetailsTheme.cardSpacing,
                children: specs.map((spec) {
                  return SizedBox(
                    width: cardWidth,
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: DetailsTheme.surface,
                        borderRadius:
                            BorderRadius.circular(DetailsTheme.cardRadius),
                        border: Border.all(color: DetailsTheme.border),
                        boxShadow: DetailsTheme.cardShadow,
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: DetailsTheme.primaryContainer,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(spec.icon,
                                size: 18, color: DetailsTheme.primary),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  spec.label,
                                  style: DetailsTheme.captionStyle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  spec.value,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: DetailsTheme.text,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  /// Category-agnostic parser extracting key-value pairs dynamically
  List<_SpecItem> _extractSpecs(MarketplaceEquipmentModel item) {
    final List<_SpecItem> list = [];

    if (item.condition.trim().isNotEmpty) {
      list.add(_SpecItem(
        icon: Icons.verified_outlined,
        label: 'Condition',
        value: item.condition.trim(),
      ));
    }

    if (item.category.trim().isNotEmpty) {
      list.add(_SpecItem(
        icon: Icons.category_outlined,
        label: 'Category',
        value: item.category.trim(),
      ));
    }

    // Parse machineSpecs dynamically without hardcoding category strings
    if (item.machineSpecs.trim().isNotEmpty) {
      final parts = item.machineSpecs.split(',');
      for (var p in parts) {
        final kv = p.split(':');
        if (kv.length == 2 && kv[0].trim().isNotEmpty && kv[1].trim().isNotEmpty) {
          list.add(_SpecItem(
            icon: Icons.settings_outlined,
            label: kv[0].trim(),
            value: kv[1].trim(),
          ));
        } else if (p.trim().isNotEmpty) {
          list.add(_SpecItem(
            icon: Icons.tune_rounded,
            label: 'Feature',
            value: p.trim(),
          ));
        }
      }
    }

    for (var tag in item.tags) {
      if (tag.trim().isNotEmpty) {
        list.add(_SpecItem(
          icon: Icons.label_outline_rounded,
          label: 'Tag',
          value: tag.trim(),
        ));
      }
    }

    return list;
  }
}

class _SpecItem {
  final IconData icon;
  final String label;
  final String value;

  _SpecItem({
    required this.icon,
    required this.label,
    required this.value,
  });
}
