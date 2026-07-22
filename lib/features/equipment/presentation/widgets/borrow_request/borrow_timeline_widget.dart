import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:UzhavuSei/models/borrow_request_model.dart';
import '../details/details_theme.dart';

class BorrowTimelineWidget extends StatelessWidget {
  const BorrowTimelineWidget({
    super.key,
    required this.request,
  });

  final BorrowRequestModel request;

  int _getStepIndex() {
    final status = request.status.trim().toLowerCase();
    switch (status) {
      case 'completed':
      case 'returned':
        return 4;
      case 'borrowed':
      case 'picked up':
        return 2;
      case 'accepted':
      case 'approved':
        return 1;
      case 'requested':
      case 'pending':
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentStep = _getStepIndex();
    final dateFormat = DateFormat('MMM d, h:mm a');

    final steps = [
      _TimelineStep(
        title: 'Requested',
        subtitle: 'Request sent to owner',
        time: dateFormat.format(request.requestedAt),
      ),
      _TimelineStep(
        title: 'Accepted',
        subtitle: 'Owner approved request',
        time: currentStep >= 1 ? 'Approved' : 'Pending',
      ),
      _TimelineStep(
        title: 'Borrow Started',
        subtitle: 'Item handed over',
        time: request.borrowedAt != null
            ? dateFormat.format(request.borrowedAt!)
            : (currentStep >= 2 ? 'In Progress' : 'Pending'),
      ),
      _TimelineStep(
        title: 'Returned',
        subtitle: 'Item returned to owner',
        time: currentStep >= 4 ? 'Returned' : 'Pending',
      ),
      _TimelineStep(
        title: 'Completed',
        subtitle: 'Borrow transaction complete',
        time: currentStep >= 4 ? 'Completed' : 'Pending',
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DetailsTheme.surface,
        borderRadius: BorderRadius.circular(DetailsTheme.cardRadius),
        border: Border.all(color: DetailsTheme.border),
        boxShadow: DetailsTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Borrow Timeline',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: DetailsTheme.text,
            ),
          ),
          const SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: steps.length,
            itemBuilder: (context, index) {
              final isPassed = index <= currentStep;
              final isLast = index == steps.length - 1;
              final step = steps[index];

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: isPassed
                              ? DetailsTheme.primary
                              : Colors.grey.shade200,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isPassed
                              ? Icons.check_rounded
                              : Icons.radio_button_unchecked_rounded,
                          size: 14,
                          color: isPassed ? Colors.white : Colors.grey,
                        ),
                      ),
                      if (!isLast)
                        Container(
                          width: 2,
                          height: 36,
                          color: isPassed && index < currentStep
                              ? DetailsTheme.primary
                              : Colors.grey.shade200,
                        ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  step.title,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: isPassed
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: isPassed
                                        ? DetailsTheme.text
                                        : DetailsTheme.secondaryText,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  step.subtitle,
                                  style: DetailsTheme.captionStyle,
                                ),
                              ],
                            ),
                          ),
                          Text(
                            step.time,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isPassed
                                  ? DetailsTheme.primary
                                  : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _TimelineStep {
  final String title;
  final String subtitle;
  final String time;

  _TimelineStep({
    required this.title,
    required this.subtitle,
    required this.time,
  });
}
