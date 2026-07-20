import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:UzhavuSei/models/marketplace_equipment_model.dart';
import 'availability_calendar_modal.dart';
import 'details_theme.dart';

class AvailabilityCard extends StatelessWidget {
  const AvailabilityCard({
    super.key,
    required this.equipment,
    required this.selectedStartDay,
    required this.selectedEndDay,
    required this.onDatesSelected,
    required this.onRequestToBorrow,
  });

  final MarketplaceEquipmentModel equipment;
  final DateTime? selectedStartDay;
  final DateTime? selectedEndDay;
  final Function(DateTime? start, DateTime? end) onDatesSelected;
  final VoidCallback onRequestToBorrow;

  String _formatDate(DateTime? dt) {
    if (dt == null) return 'Flexible';
    return DateFormat('MMM d, yyyy').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final fromStr = _formatDate(equipment.availabilityFrom);
    final toStr = _formatDate(equipment.availabilityTo);
    final pickupOption = equipment.location.isNotEmpty
        ? equipment.location
        : 'Direct Pickup';

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
                Icon(Icons.calendar_month_outlined,
                    color: DetailsTheme.primary, size: 22),
                SizedBox(width: 8),
                Text(
                  'Availability & Window',
                  style: DetailsTheme.sectionHeadingStyle,
                ),
              ],
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    label: 'Available From',
                    value: fromStr,
                    icon: Icons.event_available_outlined,
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    label: 'Available Until',
                    value: toStr,
                    icon: Icons.event_busy_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    label: 'Max Duration',
                    value: '7 Days / Flexible',
                    icon: Icons.timelapse_rounded,
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    label: 'Pickup Option',
                    value: pickupOption,
                    icon: Icons.local_shipping_outlined,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            const Divider(height: 1, color: DetailsTheme.border),
            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _openCalendarModal(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: DetailsTheme.primary,
                  side: const BorderSide(color: DetailsTheme.primary, width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.date_range_rounded, size: 20),
                label: Text(
                  selectedStartDay != null
                      ? 'Dates Selected (${_calculateDays()} d) - Edit Calendar'
                      : 'View Availability Calendar',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _calculateDays() {
    if (selectedStartDay == null) return 0;
    final end = selectedEndDay ?? selectedStartDay!;
    return end.difference(selectedStartDay!).inDays + 1;
  }

  Widget _buildInfoItem({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: DetailsTheme.secondaryText),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: DetailsTheme.captionStyle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                value,
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
    );
  }

  void _openCalendarModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AvailabilityCalendarModal(
        equipment: equipment,
        selectedStartDay: selectedStartDay,
        selectedEndDay: selectedEndDay,
        onDatesSelected: onDatesSelected,
        onRequestToBorrow: onRequestToBorrow,
      ),
    );
  }
}
