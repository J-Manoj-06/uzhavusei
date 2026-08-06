import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../../services/library_service.dart';
import '../../../../widgets/image_loader.dart';
import '../../../../theme/app_theme.dart';

class HistoryTab extends StatelessWidget {
  final String userId;

  const HistoryTab({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: LibraryService.instance.watchReturnedTransactions(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildSkeletonLoader();
        }

        if (snapshot.hasError) {
          return _buildEmptyState();
        }

        final historyList = snapshot.data ?? [];

        if (historyList.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: historyList.length,
          itemBuilder: (context, index) {
            final item = historyList[index];
            return _buildHistoryCard(item);
          },
        );
      },
    );
  }

  Widget _buildSkeletonLoader() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 3,
      itemBuilder: (context, index) {
        return Card(
          elevation: 1,
          margin: const EdgeInsets.only(bottom: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 58,
                  height: 78,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(width: 130, height: 14, color: Colors.grey.shade200),
                      const SizedBox(height: 8),
                      Container(width: 90, height: 11, color: Colors.grey.shade200),
                      const SizedBox(height: 8),
                      Container(width: 110, height: 11, color: Colors.grey.shade200),
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
                color: Colors.purple.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.history_rounded, size: 48, color: Colors.purple.shade600),
            ),
            const SizedBox(height: 16),
            const Text(
              'No borrowing history.',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 6),
            const Text(
              'Your completed book returns will be recorded here.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> item) {
    final title = (item['bookTitle'] ?? item['listingTitle'] ?? item['equipmentName'] ?? 'Borrowed Book').toString();
    final cover = (item['bookCover'] ?? item['listingImage'] ?? item['imageUrl'] ?? '').toString();
    final author = (item['author'] ?? 'College Library').toString();

    DateTime borrowedDate = DateTime.now();
    final bVal = item['borrowedAt'] ?? item['borrowFrom'] ?? item['issueDate'] ?? item['createdAt'];
    if (bVal is Timestamp) borrowedDate = bVal.toDate();
    final borrowedStr = DateFormat('MMM d, yyyy').format(borrowedDate);

    DateTime returnedDate = DateTime.now();
    final rVal = item['returnedAt'] ?? item['updatedAt'];
    if (rVal is Timestamp) returnedDate = rVal.toDate();
    final returnedStr = DateFormat('MMM d, yyyy').format(returnedDate);

    final totalDays = returnedDate.difference(borrowedDate).inDays;
    final displayDays = totalDays <= 0 ? 1 : totalDays;

    return Card(
      elevation: 1.5,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.green.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 58,
                height: 78,
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
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF86EFAC)),
                        ),
                        child: const Text(
                          'Returned',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF15803D)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Author: $author',
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined, size: 12, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        'Borrowed: $borrowedStr',
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.assignment_turned_in_outlined, size: 12, color: Colors.green),
                      const SizedBox(width: 4),
                      Text(
                        'Returned: $returnedStr',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.green),
                      ),
                      const Spacer(),
                      Text(
                        '$displayDays ${displayDays == 1 ? "day" : "days"} total',
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
