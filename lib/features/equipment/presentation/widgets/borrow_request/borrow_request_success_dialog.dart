import 'package:flutter/material.dart';
import 'package:UzhavuSei/features/equipment/presentation/my_borrow_requests_screen.dart';
import '../details/details_theme.dart';

class BorrowRequestSuccessDialog extends StatelessWidget {
  const BorrowRequestSuccessDialog({
    super.key,
    required this.borrowerId,
  });

  final String borrowerId;

  static void show(BuildContext context, {required String borrowerId}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => BorrowRequestSuccessDialog(borrowerId: borrowerId),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: DetailsTheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Success Icon Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: DetailsTheme.success.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: DetailsTheme.success,
                size: 56,
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'Request Sent!',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: DetailsTheme.text,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Borrow request sent successfully.',
              textAlign: TextAlign.center,
              style: DetailsTheme.captionStyle,
            ),

            const SizedBox(height: 24),

            // Actions
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MyBorrowRequestsScreen(borrowerId: borrowerId),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: DetailsTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'View My Requests',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
            ),

            const SizedBox(height: 10),

            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  foregroundColor: DetailsTheme.secondaryText,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text(
                  'Continue Browsing',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
