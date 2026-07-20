import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:UzhavuSei/models/borrow_request_model.dart';
import 'package:UzhavuSei/widgets/image_loader.dart';
import 'widgets/details/details_theme.dart';
import 'widgets/borrow_request/borrow_due_indicator.dart';
import 'widgets/borrow_request/borrow_timeline_widget.dart';

class BorrowDetailsPage extends StatelessWidget {
  const BorrowDetailsPage({
    super.key,
    required this.request,
  });

  final BorrowRequestModel request;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEE, MMM d, yyyy');
    final fromStr = dateFormat.format(request.borrowFrom);
    final toStr = dateFormat.format(request.borrowUntil);
    final isCompleted = request.status.trim().toLowerCase() == 'completed';

    return Scaffold(
      backgroundColor: DetailsTheme.background,
      appBar: AppBar(
        backgroundColor: DetailsTheme.surface,
        foregroundColor: DetailsTheme.text,
        elevation: 0.5,
        title: const Text(
          'Borrow Details',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: DetailsTheme.text,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(DetailsTheme.outerPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Header Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: DetailsTheme.surface,
                borderRadius: BorderRadius.circular(DetailsTheme.cardRadius),
                border: Border.all(color: DetailsTheme.border),
                boxShadow: DetailsTheme.cardShadow,
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: SizedBox(
                      width: 72,
                      height: 72,
                      child: buildSmartImage(
                        request.listingImage.isNotEmpty
                            ? request.listingImage
                            : 'assets/logo.jpg',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          request.listingTitle,
                          style: DetailsTheme.cardHeadingStyle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            if (request.category.isNotEmpty) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: DetailsTheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  request.category,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: DetailsTheme.primary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            BorrowDueIndicator(
                              dueDate: request.borrowUntil,
                              isCompleted: isCompleted,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Borrower & Owner Info Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: DetailsTheme.surface,
                borderRadius: BorderRadius.circular(DetailsTheme.cardRadius),
                border: Border.all(color: DetailsTheme.border),
                boxShadow: DetailsTheme.cardShadow,
              ),
              child: Column(
                children: [
                  _buildMetaRow(
                    icon: Icons.person_outline_rounded,
                    label: 'Borrower',
                    value: request.borrowerName,
                  ),
                  const Divider(height: 20, color: DetailsTheme.border),
                  _buildMetaRow(
                    icon: Icons.calendar_today_rounded,
                    label: 'Start Date',
                    value: fromStr,
                  ),
                  const Divider(height: 20, color: DetailsTheme.border),
                  _buildMetaRow(
                    icon: Icons.event_rounded,
                    label: 'Expected Return',
                    value: toStr,
                  ),
                  const Divider(height: 20, color: DetailsTheme.border),
                  _buildMetaRow(
                    icon: Icons.timelapse_rounded,
                    label: 'Total Duration',
                    value: '${request.borrowDuration} ${request.borrowDuration == 1 ? "Day" : "Days"}',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Timeline Widget
            BorrowTimelineWidget(request: request),
          ],
        ),
      ),
    );
  }

  Widget _buildMetaRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: DetailsTheme.primary),
        const SizedBox(width: 10),
        Text(
          label,
          style: DetailsTheme.captionStyle,
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: DetailsTheme.text,
          ),
        ),
      ],
    );
  }
}
