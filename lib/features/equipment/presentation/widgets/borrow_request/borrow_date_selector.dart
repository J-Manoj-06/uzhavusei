import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../details/details_theme.dart';

class BorrowDateSelector extends StatelessWidget {
  const BorrowDateSelector({
    super.key,
    required this.startDate,
    required this.endDate,
    required this.onStartDateSelected,
    required this.onEndDateSelected,
  });

  final DateTime? startDate;
  final DateTime? endDate;
  final ValueChanged<DateTime> onStartDateSelected;
  final ValueChanged<DateTime> onEndDateSelected;

  Future<void> _pickDate({
    required BuildContext context,
    required bool isStart,
    required DateTime initialDate,
  }) async {
    final now = DateTime.now();
    final firstAllowedDate = isStart
        ? now
        : (startDate ?? now);

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate.isBefore(firstAllowedDate) ? firstAllowedDate : initialDate,
      firstDate: firstAllowedDate,
      lastDate: now.add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: DetailsTheme.primary,
              onPrimary: Colors.white,
              onSurface: DetailsTheme.text,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      if (isStart) {
        onStartDateSelected(picked);
      } else {
        onEndDateSelected(picked);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Borrow From Field
        Expanded(
          child: _buildDateField(
            context: context,
            label: 'Borrow From',
            date: startDate,
            icon: Icons.calendar_today_rounded,
            onTap: () => _pickDate(
              context: context,
              isStart: true,
              initialDate: startDate ?? DateTime.now(),
            ),
          ),
        ),

        const SizedBox(width: DetailsTheme.cardSpacing),

        // Borrow Until Field
        Expanded(
          child: _buildDateField(
            context: context,
            label: 'Borrow Until',
            date: endDate,
            icon: Icons.event_available_rounded,
            onTap: () => _pickDate(
              context: context,
              isStart: false,
              initialDate: endDate ?? (startDate ?? DateTime.now()),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateField({
    required BuildContext context,
    required String label,
    required DateTime? date,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final isSet = date != null;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: DetailsTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSet ? DetailsTheme.primary : DetailsTheme.border,
            width: isSet ? 1.5 : 1.0,
          ),
          boxShadow: isSet
              ? [
                  BoxShadow(
                    color: DetailsTheme.primary.withValues(alpha: 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : DetailsTheme.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: isSet ? DetailsTheme.primary : DetailsTheme.secondaryText,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: DetailsTheme.captionStyle,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              isSet ? DateFormat('MMM d, yyyy').format(date) : 'Select Date',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: isSet ? DetailsTheme.text : DetailsTheme.secondaryText,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
