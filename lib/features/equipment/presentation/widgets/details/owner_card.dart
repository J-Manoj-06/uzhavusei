import 'package:flutter/material.dart';
import 'package:UzhavuSei/models/marketplace_equipment_model.dart';
import 'package:UzhavuSei/features/profile/presentation/public_profile_page.dart';
import 'details_theme.dart';

class OwnerCard extends StatelessWidget {
  const OwnerCard({
    super.key,
    required this.equipment,
    required this.currentUserId,
  });

  final MarketplaceEquipmentModel equipment;
  final String currentUserId;

  @override
  Widget build(BuildContext context) {
    final displayName = equipment.ownerName.trim().isNotEmpty
        ? equipment.ownerName.trim()
        : 'Equipment Owner';

    final String ownerInitial = displayName.isNotEmpty
        ? displayName[0].toUpperCase()
        : 'O';
    const int trustScore = 98;
    const int successRate = 100;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: DetailsTheme.outerPadding),
      padding: const EdgeInsets.all(DetailsTheme.cardSpacing),
      decoration: BoxDecoration(
        color: DetailsTheme.surface,
        borderRadius: BorderRadius.circular(DetailsTheme.cardRadius),
        border: Border.all(color: DetailsTheme.border),
        boxShadow: DetailsTheme.cardShadow,
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 26,
                backgroundColor: DetailsTheme.primaryContainer,
                child: Text(
                  ownerInitial,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: DetailsTheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Owner Details Column with Flexible and Ellipsis
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            displayName,
                            style: DetailsTheme.cardHeadingStyle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.verified_rounded,
                          color: DetailsTheme.primary,
                          size: 18,
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Member since 2024 • Verified Owner',
                      style: DetailsTheme.captionStyle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // View Profile Button
              OutlinedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PublicProfilePage(
                        userId: equipment.ownerId,
                        userName: displayName,
                      ),
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: DetailsTheme.primary,
                  side: const BorderSide(color: DetailsTheme.border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'View Profile',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(height: 1, color: DetailsTheme.border),
          const SizedBox(height: 12),

          // Trust Score & Borrow Success Metrics Row wrapped in FittedBox to prevent 1.3px right overflow
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildCompactMetric(
                  icon: Icons.shield_outlined,
                  label: 'Trust Score',
                  value: '$trustScore%',
                  color: DetailsTheme.primary,
                ),
                const SizedBox(width: 16),
                Container(width: 1, height: 20, color: DetailsTheme.border),
                const SizedBox(width: 16),
                _buildCompactMetric(
                  icon: Icons.task_alt_rounded,
                  label: 'Borrow Success',
                  value: '$successRate%',
                  color: DetailsTheme.success,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactMetric({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: DetailsTheme.captionStyle,
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
