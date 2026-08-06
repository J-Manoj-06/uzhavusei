import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../models/borrow_request_model.dart';
import '../../../../services/library_service.dart';
import '../../../../widgets/image_loader.dart';
import '../../../../theme/app_theme.dart';
import '../../../../features/equipment/presentation/book_details_page.dart';
import '../../../../models/marketplace_equipment_model.dart';

class ApprovedTab extends StatelessWidget {
  final String userId;

  const ApprovedTab({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<BorrowRequestModel>>(
      stream: LibraryService.instance.watchApprovedRequests(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }

        final approvedList = snapshot.data ?? [];

        if (approvedList.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: approvedList.length,
          itemBuilder: (context, index) {
            final request = approvedList[index];
            return _buildApprovedCard(context, request);
          },
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
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check_circle_outline_rounded, size: 48, color: Colors.green.shade600),
            ),
            const SizedBox(height: 16),
            const Text(
              'No approved requests.',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 6),
            const Text(
              'Approved requests awaiting collection will be shown here.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApprovedCard(BuildContext context, BorrowRequestModel request) {
    final dateStr = DateFormat('MMM d, yyyy • h:mm a').format(request.updatedAt);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.green.shade300, width: 1.2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    width: 62,
                    height: 84,
                    child: buildSmartImage(
                      request.listingImage,
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
                              request.listingTitle,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDCFCE7),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFF86EFAC)),
                            ),
                            child: const Text(
                              'Approved',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF15803D)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Approved: $dateStr',
                        style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Your request has been approved.',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF16A34A)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Large collection banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFF0FDF4), Color(0xFFECFDF5)],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: const [
                  Text('📚', style: TextStyle(fontSize: 22)),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Please collect your book from the library.',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF14532D)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      _openBookDetails(context, request);
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(color: Colors.green.shade400),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text(
                      'View Details',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF15803D)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please visit the library to collect your book.'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF16A34A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Dismiss', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _openBookDetails(BuildContext context, BorrowRequestModel request) {
    final itemModel = MarketplaceEquipmentModel(
      equipmentId: request.listingId,
      ownerId: 'library',
      equipmentName: request.listingTitle,
      category: 'Books',
      description: 'Approved library book request. Ready for collection at library.',
      titleLocalized: {},
      categoryLocalized: {},
      descriptionLocalized: {},
      pricePerHour: 0,
      pricePerDay: 0,
      location: 'Main Library',
      latitude: 0,
      longitude: 0,
      imageUrls: [request.listingImage],
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
