import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/library_activity_model.dart';
import '../../theme/app_theme.dart';
import '../../widgets/image_loader.dart';

class LibraryActivityDetailsPage extends StatelessWidget {
  final LibraryActivityModel item;

  const LibraryActivityDetailsPage({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final statusStyle = _getStatusStyle(item.status);
    final requestDateStr = DateFormat('MMM d, yyyy • h:mm a').format(item.requestDate);
    final approvalDateStr = item.approvalDate != null ? DateFormat('MMM d, yyyy • h:mm a').format(item.approvalDate!) : null;
    final issueDateStr = item.issueDate != null ? DateFormat('MMM d, yyyy • h:mm a').format(item.issueDate!) : null;
    final returnDateStr = item.returnDate != null ? DateFormat('MMM d, yyyy • h:mm a').format(item.returnDate!) : null;
    final dueDateStr = item.dueDate != null ? DateFormat('MMM d, yyyy').format(item.dueDate!) : null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0.5,
        title: const Text(
          'Library Activity Details',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          // Header Card with Cover & Core Info
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: SizedBox(
                        width: 120,
                        height: 165,
                        child: buildSmartImage(
                          item.bookCover,
                          fit: BoxFit.cover,
                          isBook: true,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    item.bookTitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Author: ${item.author}',
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusStyle.bgColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: statusStyle.borderColor),
                    ),
                    child: Text(
                      item.statusLabel,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: statusStyle.textColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    item.stageMessage,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: statusStyle.textColor,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Activity Timeline Card (Strictly synchronized with Firestore status)
          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'TIMELINE & STAGE HISTORY',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 14),

                  // Stage 1: Request Submitted
                  _buildTimelineTile(
                    title: 'Request Submitted',
                    subtitle: requestDateStr,
                    icon: Icons.assignment_turned_in_outlined,
                    color: Colors.orange,
                    isCompleted: true,
                    isLast: item.status == LibraryActivityStatus.pending,
                  ),

                  // Stage 2: Approved (If Status is Approved, Borrowed, or Returned)
                  if (item.status == LibraryActivityStatus.approved ||
                      item.status == LibraryActivityStatus.borrowed ||
                      item.status == LibraryActivityStatus.returned)
                    _buildTimelineTile(
                      title: item.status == LibraryActivityStatus.approved
                          ? 'Librarian Approved — Ready for Collection'
                          : 'Librarian Approved',
                      subtitle: approvalDateStr ?? 'Approved by College Librarian',
                      icon: Icons.check_circle_outline_rounded,
                      color: Colors.blue,
                      isCompleted: true,
                      isLast: item.status == LibraryActivityStatus.approved,
                    ),

                  // Stage 3: Borrowed (If Status is Borrowed or Returned)
                  if (item.status == LibraryActivityStatus.borrowed ||
                      item.status == LibraryActivityStatus.returned)
                    _buildTimelineTile(
                      title: 'Book Issued for Borrowing',
                      subtitle: issueDateStr ?? 'Issued by Librarian',
                      icon: Icons.bookmark_added_outlined,
                      color: Colors.green,
                      isCompleted: true,
                      isLast: item.status == LibraryActivityStatus.borrowed,
                    ),

                  // Stage 4: Returned (If Status is Returned)
                  if (item.status == LibraryActivityStatus.returned)
                    _buildTimelineTile(
                      title: 'Book Returned to Library',
                      subtitle: '$returnDateStr (${item.totalDurationDays} days total)',
                      icon: Icons.assignment_return_outlined,
                      color: Colors.blueGrey,
                      isCompleted: true,
                      isLast: true,
                    ),

                  // Rejected Terminal State
                  if (item.status == LibraryActivityStatus.rejected)
                    _buildTimelineTile(
                      title: 'Request Rejected',
                      subtitle: item.stageMessage,
                      icon: Icons.cancel_outlined,
                      color: Colors.red,
                      isCompleted: true,
                      isLast: true,
                    ),

                  // Cancelled Terminal State
                  if (item.status == LibraryActivityStatus.cancelled)
                    _buildTimelineTile(
                      title: 'Request Cancelled',
                      subtitle: 'Cancelled by student.',
                      icon: Icons.remove_circle_outline_rounded,
                      color: Colors.grey,
                      isCompleted: true,
                      isLast: true,
                    ),
                ],
              ),
            ),
          ),

          if (dueDateStr != null) ...[
            const SizedBox(height: 16),
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.event_outlined, color: AppColors.primary, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Return Due Date', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          Text(
                            dueDateStr,
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          ),
                        ],
                      ),
                    ),
                    if (item.status == LibraryActivityStatus.borrowed)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: item.daysRemaining <= 0 ? Colors.red.shade50 : Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          item.daysRemaining <= 0 ? 'OVERDUE' : '${item.daysRemaining} days left',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: item.daysRemaining <= 0 ? Colors.red : Colors.blue,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimelineTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isCompleted,
    bool isLast = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 28,
                color: Colors.grey.shade300,
              ),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 14),
            ],
          ),
        ),
      ],
    );
  }

  _StatusStyle _getStatusStyle(LibraryActivityStatus status) {
    switch (status) {
      case LibraryActivityStatus.pending:
        return const _StatusStyle(
          bgColor: Color(0xFFFFF7ED),
          textColor: Color(0xFFC2410C),
          borderColor: Color(0xFFFFEDD5),
        );
      case LibraryActivityStatus.approved:
        return const _StatusStyle(
          bgColor: Color(0xFFEFF6FF),
          textColor: Color(0xFF1D4ED8),
          borderColor: Color(0xFFDBEAFE),
        );
      case LibraryActivityStatus.borrowed:
        return const _StatusStyle(
          bgColor: Color(0xFFF0FDF4),
          textColor: Color(0xFF15803D),
          borderColor: Color(0xFFDCFCE7),
        );
      case LibraryActivityStatus.returned:
        return const _StatusStyle(
          bgColor: Color(0xFFF8FAFC),
          textColor: Color(0xFF475569),
          borderColor: Color(0xFFE2E8F0),
        );
      case LibraryActivityStatus.rejected:
        return const _StatusStyle(
          bgColor: Color(0xFFFEF2F2),
          textColor: Color(0xFFDC2626),
          borderColor: Color(0xFFFEE2E2),
        );
      case LibraryActivityStatus.cancelled:
        return const _StatusStyle(
          bgColor: Color(0xFFF1F5F9),
          textColor: Color(0xFF334155),
          borderColor: Color(0xFFCBD5E1),
        );
    }
  }
}

class _StatusStyle {
  final Color bgColor;
  final Color textColor;
  final Color borderColor;

  const _StatusStyle({
    required this.bgColor,
    required this.textColor,
    required this.borderColor,
  });
}
