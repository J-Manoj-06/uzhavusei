import 'package:flutter/material.dart';
import 'package:UzhavuSei/theme/app_theme.dart';

class RecentSearchSection extends StatelessWidget {
  final List<String> recentSearches;
  final ValueChanged<String> onSelectQuery;
  final ValueChanged<String> onDeleteQuery;
  final VoidCallback onClearAll;

  const RecentSearchSection({
    super.key,
    required this.recentSearches,
    required this.onSelectQuery,
    required this.onDeleteQuery,
    required this.onClearAll,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Searches',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            if (recentSearches.isNotEmpty)
              TextButton(
                onPressed: onClearAll,
                child: const Text('Clear All', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (recentSearches.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.history_rounded, size: 20, color: Colors.grey.shade400),
                const SizedBox(width: 12),
                const Text(
                  'No recent searches',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: recentSearches.map((term) {
              return InputChip(
                label: Text(term),
                onPressed: () => onSelectQuery(term),
                onDeleted: () => onDeleteQuery(term),
                deleteIcon: const Icon(Icons.close_rounded, size: 14),
                backgroundColor: Colors.grey.shade100,
                labelStyle: const TextStyle(fontSize: 12, color: AppColors.textPrimary, fontWeight: FontWeight.w500),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              );
            }).toList(),
          ),
      ],
    );
  }
}
