import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../../services/library_service.dart';
import '../../../../widgets/image_loader.dart';
import '../../../../theme/app_theme.dart';
import '../../../../features/equipment/presentation/book_details_page.dart';
import '../../../../models/marketplace_equipment_model.dart';

class BorrowedTab extends StatelessWidget {
  final String userId;

  const BorrowedTab({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: LibraryService.instance.watchIssuedTransactions(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildSkeletonLoader();
        }

        if (snapshot.hasError) {
          return _buildEmptyState();
        }

        final issuedList = snapshot.data ?? [];

        if (issuedList.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: issuedList.length,
          itemBuilder: (context, index) {
            final tx = issuedList[index];
            return _buildBorrowedCard(context, tx);
          },
        );
      },
    );
  }

  Widget _buildSkeletonLoader() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 2,
      itemBuilder: (context, index) {
        return Card(
          elevation: 1,
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  width: 68,
                  height: 92,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(width: 140, height: 16, color: Colors.grey.shade200),
                      const SizedBox(height: 8),
                      Container(width: 90, height: 12, color: Colors.grey.shade200),
                      const SizedBox(height: 8),
                      Container(width: 110, height: 12, color: Colors.grey.shade200),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.bookmark_border_rounded, size: 48, color: Colors.blue.shade600),
            ),
            const SizedBox(height: 16),
            const Text(
              'No books currently borrowed.',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 6),
            const Text(
              'Books currently issued to you will be displayed here.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBorrowedCard(BuildContext context, Map<String, dynamic> tx) {
    final title = (tx['bookTitle'] ?? tx['listingTitle'] ?? tx['equipmentName'] ?? 'Borrowed Book').toString();
    final cover = (tx['bookCover'] ?? tx['listingImage'] ?? tx['imageUrl'] ?? '').toString();
    final author = (tx['author'] ?? 'College Library').toString();
    final bookId = (tx['bookId'] ?? tx['listingId'] ?? 'book-id').toString();

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

    final days = dueDate.difference(DateTime.now()).inDays;
    final daysRemaining = days < 0 ? 0 : days;
    final isOverdue = days <= 0 || DateTime.now().isAfter(dueDate);

    final cardBorderColor = isOverdue ? Colors.red.shade400 : Colors.blue.shade300;
    final statusBgColor = isOverdue ? const Color(0xFFFEE2E2) : const Color(0xFFDBEAFE);
    final statusTextColor = isOverdue ? const Color(0xFFDC2626) : const Color(0xFF1D4ED8);

    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: cardBorderColor, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 68,
                    height: 92,
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
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: statusBgColor,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              isOverdue ? 'OVERDUE' : 'Issued',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusTextColor),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Author: $author',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Issue Date: $issueDateStr',
                        style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Due Date: $dueDateStr',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isOverdue ? Colors.red : AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: isOverdue ? Colors.red.shade50 : Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isOverdue ? Colors.red.shade200 : Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    isOverdue ? Icons.warning_rounded : Icons.timer_outlined,
                    color: isOverdue ? Colors.red : Colors.blue,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isOverdue
                          ? 'This book is overdue! Please return it to the library immediately.'
                          : 'Due in $daysRemaining ${daysRemaining == 1 ? "day" : "days"}.',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isOverdue ? Colors.red.shade900 : Colors.blue.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  _openBookDetails(context, bookId, title, cover, dueDateStr);
                },
                icon: const Icon(Icons.menu_book_rounded, size: 18),
                label: const Text('View Book Details', style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openBookDetails(BuildContext context, String bookId, String title, String cover, String dueDateStr) {
    final itemModel = MarketplaceEquipmentModel(
      equipmentId: bookId,
      ownerId: 'library',
      equipmentName: title,
      category: 'Books',
      description: 'Currently borrowed library book. Due date: $dueDateStr',
      titleLocalized: {},
      categoryLocalized: {},
      descriptionLocalized: {},
      pricePerHour: 0,
      pricePerDay: 0,
      location: 'Main Library',
      latitude: 0,
      longitude: 0,
      imageUrls: [cover],
      availability: false,
      rating: 5.0,
      createdAt: DateTime.now(),
      ownerName: 'Library Administration',
      machineSpecs: '',
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BookDetailsPage(
          initialItem: itemModel,
          userId: userId,
          userName: 'Student',
          userEmail: '',
          userPhone: '',
        ),
      ),
    );
  }
}
