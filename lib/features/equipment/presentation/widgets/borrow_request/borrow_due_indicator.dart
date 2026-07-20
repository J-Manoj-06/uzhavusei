import 'package:flutter/material.dart';

class BorrowDueIndicator extends StatelessWidget {
  const BorrowDueIndicator({
    super.key,
    required this.dueDate,
    this.isCompleted = false,
  });

  final DateTime dueDate;
  final bool isCompleted;

  @override
  Widget build(BuildContext context) {
    if (isCompleted) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_outline, size: 14, color: Colors.grey),
            SizedBox(width: 4),
            Text(
              'Returned',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(dueDate.year, dueDate.month, dueDate.day);
    final diffDays = target.difference(today).inDays;

    String label;
    Color bg;
    Color fg;
    IconData icon;

    if (diffDays < 0) {
      final abs = diffDays.abs();
      label = abs == 1 ? 'Overdue by 1 Day' : 'Overdue by $abs Days';
      bg = Colors.red.shade50;
      fg = Colors.red.shade700;
      icon = Icons.warning_amber_rounded;
    } else if (diffDays == 0) {
      label = 'Due Today';
      bg = Colors.amber.shade50;
      fg = Colors.amber.shade900;
      icon = Icons.access_time_rounded;
    } else if (diffDays <= 2) {
      label = '$diffDays ${diffDays == 1 ? 'Day' : 'Days'} Left';
      bg = Colors.amber.shade50;
      fg = Colors.amber.shade900;
      icon = Icons.timer_outlined;
    } else {
      label = '$diffDays Days Left';
      bg = Colors.green.shade50;
      fg = Colors.green.shade700;
      icon = Icons.event_available_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: fg.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}
