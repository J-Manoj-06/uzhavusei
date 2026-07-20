import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:UzhavuSei/models/borrow_request_model.dart';
import 'package:UzhavuSei/widgets/image_loader.dart';
import '../details/details_theme.dart';

class BorrowRequestCard extends StatelessWidget {
  const BorrowRequestCard({
    super.key,
    required this.request,
    this.onTap,
    this.onAcceptTap,
    this.onRejectTap,
    this.onStartBorrowTap,
    this.onMarkReturnedTap,
    this.onRateReviewTap,
  });

  final BorrowRequestModel request;
  final VoidCallback? onTap;
  final VoidCallback? onAcceptTap;
  final VoidCallback? onRejectTap;
  final VoidCallback? onStartBorrowTap;
  final VoidCallback? onMarkReturnedTap;
  final VoidCallback? onRateReviewTap;

  bool get _isPending {
    final s = request.status.trim().toLowerCase();
    return s == 'pending' || s == 'requested';
  }

  bool get _isAccepted {
    final s = request.status.trim().toLowerCase();
    return s == 'accepted' || s == 'approved';
  }

  bool get _isBorrowed {
    final s = request.status.trim().toLowerCase();
    return s == 'borrowed' || s == 'picked up';
  }

  bool get _isCompleted {
    final s = request.status.trim().toLowerCase();
    return s == 'completed' || s == 'returned';
  }

  String _formatBorrowTimer(DateTime? startDate) {
    if (startDate == null) return 'Borrow Started: Today';
    final now = DateTime.now();
    final diff = now.difference(startDate);
    if (diff.inDays == 0) {
      return 'Borrow Started: Today';
    } else if (diff.inDays == 1) {
      return 'Borrowing since 1 day ago';
    } else {
      return 'Borrowing since ${diff.inDays} days ago';
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy');
    final fromStr = dateFormat.format(request.borrowFrom);
    final toStr = dateFormat.format(request.borrowUntil);

    return Container(
      margin: const EdgeInsets.only(bottom: DetailsTheme.cardSpacing),
      decoration: BoxDecoration(
        color: DetailsTheme.surface,
        borderRadius: BorderRadius.circular(DetailsTheme.cardRadius),
        border: Border.all(color: DetailsTheme.border),
        boxShadow: DetailsTheme.cardShadow,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DetailsTheme.cardRadius),
        child: Padding(
          padding: const EdgeInsets.all(DetailsTheme.cardSpacing),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Borrower Profile Row & Status Badge
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: DetailsTheme.primaryContainer,
                    child: Text(
                      request.borrowerName.isNotEmpty
                          ? request.borrowerName[0].toUpperCase()
                          : 'B',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: DetailsTheme.primary,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          request.borrowerName,
                          style: DetailsTheme.cardHeadingStyle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _isBorrowed
                              ? _formatBorrowTimer(request.borrowedAt ?? request.borrowFrom)
                              : (_isCompleted
                                  ? 'Returned ${DateFormat.MMMd().format(request.updatedAt)}'
                                  : 'Requested ${DateFormat.MMMd().add_jm().format(request.requestedAt)}'),
                          style: DetailsTheme.captionStyle,
                        ),
                      ],
                    ),
                  ),
                  _buildStatusBadge(request.status),
                ],
              ),

              const SizedBox(height: 14),
              const Divider(height: 1, color: DetailsTheme.border),
              const SizedBox(height: 14),

              // Product Info Row
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      width: 58,
                      height: 58,
                      child: buildSmartImage(
                        request.listingImage.isNotEmpty
                            ? request.listingImage
                            : 'assets/logo.jpg',
                        fit: BoxFit.cover,
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
                            color: DetailsTheme.text,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
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
                            Expanded(
                              child: Text(
                                '$fromStr - $toStr',
                                style: DetailsTheme.captionStyle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Duration: ${request.borrowDuration} ${request.borrowDuration == 1 ? "Day" : "Days"}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: DetailsTheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // PENDING ACTIONS (Reject / Accept)
              if (_isPending && onAcceptTap != null && onRejectTap != null) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onRejectTap,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red.shade700,
                          side: BorderSide(color: Colors.red.shade300),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.close_rounded, size: 18),
                        label: const Text(
                          'Reject',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onAcceptTap,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: DetailsTheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          elevation: 1,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.check_rounded, size: 18),
                        label: const Text(
                          'Accept',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              // ACCEPTED ACTIONS (Start Borrow)
              if (_isAccepted && onStartBorrowTap != null) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton.icon(
                    onPressed: onStartBorrowTap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: DetailsTheme.primary,
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.play_arrow_rounded, size: 20),
                    label: const Text(
                      'Start Borrow',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],

              // BORROWED ACTIONS (Active "Mark as Returned" Button)
              if (_isBorrowed && onMarkReturnedTap != null) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton.icon(
                    onPressed: onMarkReturnedTap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: DetailsTheme.success,
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.assignment_turned_in_rounded, size: 20),
                    label: const Text(
                      'Mark as Returned',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],

              // COMPLETED ACTIONS (Rate & Review)
              if (_isCompleted && onRateReviewTap != null) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 40,
                  child: OutlinedButton.icon(
                    onPressed: onRateReviewTap,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: DetailsTheme.primary,
                      side: const BorderSide(color: DetailsTheme.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.star_outline_rounded, size: 18),
                    label: const Text(
                      'Rate & Review',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color fg;

    switch (status.trim().toLowerCase()) {
      case 'accepted':
      case 'approved':
        bg = DetailsTheme.success.withValues(alpha: 0.15);
        fg = DetailsTheme.success;
        break;
      case 'borrowed':
      case 'picked up':
        bg = Colors.orange.shade50;
        fg = Colors.orange.shade800;
        break;
      case 'returned':
      case 'completed':
        bg = DetailsTheme.success.withValues(alpha: 0.15);
        fg = DetailsTheme.success;
        break;
      case 'declined':
      case 'rejected':
        bg = Colors.red.shade50;
        fg = Colors.red.shade700;
        break;
      case 'requested':
      case 'pending':
      default:
        bg = DetailsTheme.primaryContainer;
        fg = DetailsTheme.primary;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: fg,
        ),
      ),
    );
  }
}
