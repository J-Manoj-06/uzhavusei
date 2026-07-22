import 'package:flutter/material.dart';
import '../details/details_theme.dart';

class BorrowDurationCard extends StatelessWidget {
  const BorrowDurationCard({
    super.key,
    required this.startDate,
    required this.endDate,
  });

  final DateTime? startDate;
  final DateTime? endDate;

  @override
  Widget build(BuildContext context) {
    if (startDate == null || endDate == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: DetailsTheme.background,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: DetailsTheme.border),
        ),
        child: const Row(
          children: [
            Icon(Icons.info_outline_rounded,
                size: 18, color: DetailsTheme.secondaryText),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Please select start and end dates to calculate duration.',
                style: DetailsTheme.captionStyle,
              ),
            ),
          ],
        ),
      );
    }

    // Check date validity
    final isInvalidRange = endDate!.isBefore(startDate!);
    if (isInvalidRange) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.amber.shade50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.amber.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.warning_amber_rounded,
                size: 18, color: Colors.amber.shade900),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Borrow Until date must be on or after Borrow From date.',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.amber.shade900,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final durationDays = endDate!.difference(startDate!).inDays + 1;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: DetailsTheme.primaryContainer.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DetailsTheme.primaryContainer),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Row(
            children: [
              Icon(Icons.timelapse_rounded,
                  color: DetailsTheme.primary, size: 20),
              SizedBox(width: 8),
              Text(
                'Borrow Duration',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: DetailsTheme.text,
                ),
              ),
            ],
          ),
          Text(
            '$durationDays ${durationDays == 1 ? "Day" : "Days"}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: DetailsTheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}
