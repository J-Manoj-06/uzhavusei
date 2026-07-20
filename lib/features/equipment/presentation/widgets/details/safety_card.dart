import 'package:flutter/material.dart';
import 'details_theme.dart';

class SafetyCard extends StatelessWidget {
  const SafetyCard({super.key});

  @override
  Widget build(BuildContext context) {
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
                Icon(Icons.verified_user_outlined,
                    color: DetailsTheme.success, size: 22),
                SizedBox(width: 8),
                Text(
                  'Borrow Safely',
                  style: DetailsTheme.sectionHeadingStyle,
                ),
              ],
            ),
            const SizedBox(height: 14),

            _buildSafetyItem(
              icon: Icons.search_rounded,
              text: 'Verify item condition before borrowing',
            ),
            const SizedBox(height: 10),
            _buildSafetyItem(
              icon: Icons.event_available_rounded,
              text: 'Return item promptly on agreed date',
            ),
            const SizedBox(height: 10),
            _buildSafetyItem(
              icon: Icons.report_problem_outlined,
              text: 'Report any damaged or missing equipment immediately',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSafetyItem({required IconData icon, required String text}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: DetailsTheme.success.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_rounded,
            size: 14,
            color: DetailsTheme.success,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: DetailsTheme.text,
            ),
          ),
        ),
      ],
    );
  }
}
