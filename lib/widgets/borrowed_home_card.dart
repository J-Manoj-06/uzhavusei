import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'image_loader.dart';
import '../theme/app_theme.dart';

class BorrowedHomeCard extends StatelessWidget {
  final Map<String, dynamic>? activeTransaction;
  final VoidCallback onViewMyLibrary;

  const BorrowedHomeCard({
    super.key,
    required this.activeTransaction,
    required this.onViewMyLibrary,
  });

  @override
  Widget build(BuildContext context) {
    if (activeTransaction == null) {
      return const SizedBox.shrink();
    }

    final tx = activeTransaction!;
    final title = (tx['bookTitle'] ?? tx['listingTitle'] ?? tx['equipmentName'] ?? 'Borrowed Book').toString();
    final cover = (tx['bookCover'] ?? tx['listingImage'] ?? tx['imageUrl'] ?? '').toString();

    DateTime issueDate = DateTime.now();
    final iVal = tx['borrowedAt'] ?? tx['issueDate'] ?? tx['createdAt'];
    if (iVal is Timestamp) issueDate = iVal.toDate();
    final issueDateStr = DateFormat('MMM d, yyyy').format(issueDate);

    DateTime dueDate = DateTime.now().add(const Duration(days: 7));
    if (tx['dueDate'] is Timestamp) {
      dueDate = (tx['dueDate'] as Timestamp).toDate();
    } else if (tx['borrowUntil'] is Timestamp) {
      dueDate = (tx['borrowUntil'] as Timestamp).toDate();
    }
    final dueDateStr = DateFormat('MMM d, yyyy').format(dueDate);

    final daysRemaining = dueDate.difference(DateTime.now()).inDays;
    final isOverdue = daysRemaining <= 0 || DateTime.now().isAfter(dueDate);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isOverdue
              ? [const Color(0xFF991B1B), const Color(0xFFDC2626)]
              : [const Color(0xFF1E3A8A), const Color(0xFF2563EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (isOverdue ? Colors.red : Colors.blue).withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onViewMyLibrary,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      isOverdue ? Icons.warning_rounded : Icons.bookmark_added_rounded,
                      size: 16,
                      color: isOverdue ? const Color(0xFFFCA5A5) : const Color(0xFF60A5FA),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isOverdue ? 'OVERDUE BORROWED BOOK' : 'Currently Borrowed',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isOverdue ? const Color(0xFFFECACA) : const Color(0xFF93C5FD),
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: SizedBox(
                        width: 52,
                        height: 70,
                        child: buildSmartImage(
                          cover,
                          fit: BoxFit.cover,
                          isBook: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Issued: $issueDateStr',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Return Date: $dueDateStr',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.95),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isOverdue ? Colors.red.shade400 : Colors.green.shade400,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              isOverdue
                                  ? 'OVERDUE'
                                  : '$daysRemaining ${daysRemaining == 1 ? "day" : "days"} left',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: onViewMyLibrary,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'View My Library',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
