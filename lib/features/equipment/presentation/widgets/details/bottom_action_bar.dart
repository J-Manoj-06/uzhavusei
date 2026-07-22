import 'package:flutter/material.dart';
import 'package:UzhavuSei/models/marketplace_equipment_model.dart';
import 'details_theme.dart';

class BottomActionBar extends StatelessWidget {
  const BottomActionBar({
    super.key,
    required this.equipment,
    required this.isOwner,
    this.hasActiveRequest = false,
    required this.onRequestToBorrow,
    required this.onEditListing,
    required this.onManageListing,
    required this.onViewRequests,
  });

  final MarketplaceEquipmentModel equipment;
  final bool isOwner;
  final bool hasActiveRequest;
  final VoidCallback onRequestToBorrow;
  final VoidCallback onEditListing;
  final VoidCallback onManageListing;
  final VoidCallback onViewRequests;

  @override
  Widget build(BuildContext context) {
    final bool isAvailable = equipment.availability;

    return Container(
      padding: EdgeInsets.fromLTRB(
        DetailsTheme.outerPadding,
        12,
        DetailsTheme.outerPadding,
        MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: DetailsTheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: isOwner
          ? _buildOwnerActionBar()
          : _buildBorrowerActionBar(isAvailable),
    );
  }

  Widget _buildBorrowerActionBar(bool isAvailable) {
    final bool canRequest = isAvailable && !hasActiveRequest;
    final String buttonText = hasActiveRequest
        ? 'Already Requested'
        : (isAvailable ? 'Request to Borrow' : 'Currently Unavailable');

    return Row(
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isAvailable
                        ? DetailsTheme.success
                        : const Color(0xFFEF4444),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  isAvailable ? 'Available' : 'On Loan',
                  style: TextStyle(
                    color: isAvailable
                        ? DetailsTheme.success
                        : const Color(0xFFEF4444),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            const Text(
              'Free community borrow',
              style: DetailsTheme.captionStyle,
            ),
          ],
        ),

        const SizedBox(width: 12),

        Expanded(
          child: SizedBox(
            height: 48,
            child: ElevatedButton.icon(
              onPressed: canRequest ? onRequestToBorrow : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: canRequest
                    ? DetailsTheme.primary
                    : DetailsTheme.border,
                foregroundColor: Colors.white,
                disabledBackgroundColor: DetailsTheme.border,
                disabledForegroundColor: DetailsTheme.secondaryText,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                elevation: canRequest ? 2 : 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: Icon(
                canRequest
                    ? Icons.handshake_rounded
                    : (hasActiveRequest
                        ? Icons.check_circle_outline_rounded
                        : Icons.lock_clock_outlined),
                size: 18,
              ),
              label: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  buttonText,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOwnerActionBar() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Owner Restriction Badge
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 8),
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: DetailsTheme.primaryContainer.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: DetailsTheme.primaryContainer),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.info_outline_rounded,
                  size: 16, color: DetailsTheme.primary),
              SizedBox(width: 6),
              Text(
                'This is your listing',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: DetailsTheme.primary,
                ),
              ),
            ],
          ),
        ),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onEditListing,
                style: OutlinedButton.styleFrom(
                  foregroundColor: DetailsTheme.primary,
                  side: const BorderSide(color: DetailsTheme.primary),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text(
                  'Edit',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onManageListing,
                style: OutlinedButton.styleFrom(
                  foregroundColor: DetailsTheme.primary,
                  side: const BorderSide(color: DetailsTheme.primary),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.settings_outlined, size: 18),
                label: const Text(
                  'Manage',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          height: 46,
          child: ElevatedButton.icon(
            onPressed: onViewRequests,
            style: ElevatedButton.styleFrom(
              backgroundColor: DetailsTheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.notifications_active_outlined, size: 18),
            label: const Text(
              'View Borrow Requests',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }
}
