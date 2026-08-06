import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/borrow_request_model.dart';
import 'image_loader.dart';
import '../theme/app_theme.dart';

class ApprovalPopup extends StatelessWidget {
  final BorrowRequestModel request;
  final VoidCallback onDismiss;
  final VoidCallback onViewInMyLibrary;

  const ApprovalPopup({
    super.key,
    required this.request,
    required this.onDismiss,
    required this.onViewInMyLibrary,
  });

  static Future<void> show({
    required BuildContext context,
    required BorrowRequestModel request,
    required VoidCallback onDismiss,
    required VoidCallback onViewInMyLibrary,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => ApprovalPopup(
        request: request,
        onDismiss: () {
          onDismiss();
          Navigator.pop(ctx);
        },
        onViewInMyLibrary: () {
          Navigator.pop(ctx);
          onViewInMyLibrary();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final approvalDateStr = DateFormat('MMM d, yyyy • h:mm a').format(request.updatedAt);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header Icon & Title
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFFDCFCE7),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.local_library_rounded, size: 36, color: Color(0xFF15803D)),
            ),
            const SizedBox(height: 14),
            const Text(
              '📚 Your Book is Ready!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            const Text(
              'Your request has been approved by the librarian.',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            // Book Details Card inside Dialog
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: SizedBox(
                      width: 54,
                      height: 72,
                      child: buildSmartImage(
                        request.listingImage,
                        fit: BoxFit.cover,
                        isBook: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          request.listingTitle,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Author: College Library',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Approved: $approvalDateStr',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF16A34A),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
            const Text(
              'Please visit the library to collect your book.',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // Action Buttons
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onViewInMyLibrary,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF16A34A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'View in My Library',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onDismiss,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: BorderSide(color: Colors.grey.shade300),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "I'll Collect Later",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
