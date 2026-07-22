import 'package:flutter/material.dart';
import 'package:UzhavuSei/models/borrow_request_model.dart';
import 'package:UzhavuSei/models/review_model.dart';
import 'package:UzhavuSei/services/borrow_request_repository.dart';
import 'package:UzhavuSei/services/review_repository.dart';
import 'widgets/details/details_theme.dart';
import 'widgets/borrow_request/borrow_request_card.dart';
import 'widgets/safety/rating_dialog.dart';

class OwnerBorrowRequestsScreen extends StatefulWidget {
  const OwnerBorrowRequestsScreen({
    super.key,
    required this.ownerId,
  });

  final String ownerId;

  @override
  State<OwnerBorrowRequestsScreen> createState() =>
      _OwnerBorrowRequestsScreenState();
}

class _OwnerBorrowRequestsScreenState extends State<OwnerBorrowRequestsScreen> {
  final BorrowRequestRepository _repository = BorrowRequestRepository();
  final ReviewRepository _reviewRepository = ReviewRepository();
  late Stream<List<BorrowRequestModel>> _requestsStream;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _loadStream();
  }

  void _loadStream() {
    _requestsStream = _repository.watchOwnerRequests(widget.ownerId);
  }

  /// Handles Accept flow with confirmation modal, pre-validation & Firestore update
  Future<void> _handleAcceptRequest(BorrowRequestModel request) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Accept Borrow Request?',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'The borrower will be informed that their request has been accepted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(color: DetailsTheme.secondaryText)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: DetailsTheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Accept'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isProcessing = true);

    try {
      await _repository.acceptBorrowRequest(
        requestId: request.requestId,
        listingId: request.listingId,
        ownerId: widget.ownerId,
      );

      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  '✓ Request Accepted for ${request.borrowerName}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            backgroundColor: DetailsTheme.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        final errorMessage = e.toString().replaceAll('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  /// Handles Reject flow with confirmation modal & Firestore update
  Future<void> _handleRejectRequest(BorrowRequestModel request) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Reject Borrow Request?',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'This action will notify the borrower that the request has been declined.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(color: DetailsTheme.secondaryText)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isProcessing = true);

    try {
      await _repository.rejectBorrowRequest(
        requestId: request.requestId,
        ownerId: widget.ownerId,
      );

      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.cancel_rounded, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  '✓ Request Rejected for ${request.borrowerName}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        final errorMessage = e.toString().replaceAll('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  /// Handles Start Borrow handover flow with confirmation modal, pre-validation & Firestore update
  Future<void> _handleStartBorrow(BorrowRequestModel request) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Start Borrow?',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Confirm that you have handed over the item to the borrower.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(color: DetailsTheme.secondaryText)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: DetailsTheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Start Borrow'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isProcessing = true);

    try {
      await _repository.startBorrow(
        request: request,
        ownerId: widget.ownerId,
      );

      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.play_circle_fill_rounded, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  '✓ Borrowing Started for ${request.borrowerName}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            backgroundColor: DetailsTheme.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        final errorMessage = e.toString().replaceAll('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  /// Handles Complete Borrow (Mark as Returned) flow with confirmation modal & atomic Firestore update
  Future<void> _handleCompleteBorrow(BorrowRequestModel request) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Complete Borrow?',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Confirm that the equipment has been returned safely.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(color: DetailsTheme.secondaryText)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: DetailsTheme.success,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Complete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isProcessing = true);

    try {
      await _repository.completeBorrow(
        request: request,
        ownerId: widget.ownerId,
      );

      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.task_alt_rounded, color: Colors.white),
                SizedBox(width: 8),
                Text(
                  '✓ Borrow Completed & Item Available Again',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            backgroundColor: DetailsTheme.success,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        final errorMessage = e.toString().replaceAll('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  /// Opens RatingDialog for completed borrows
  void _handleRateReview(BorrowRequestModel request) {
    showDialog(
      context: context,
      builder: (ctx) => RatingDialog(
        request: request,
        revieweeName: request.borrowerName,
        onSubmit: (rating, comment) async {
          try {
            await _reviewRepository.createReview(
              ReviewModel(
                reviewId: '',
                requestId: request.requestId,
                listingId: request.listingId,
                reviewerId: widget.ownerId,
                revieweeId: request.borrowerId,
                rating: rating,
                comment: comment,
                createdAt: DateTime.now(),
              ),
            );
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✓ Review Submitted Successfully!'),
                  backgroundColor: DetailsTheme.primary,
                ),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to submit review: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DetailsTheme.background,
      appBar: AppBar(
        backgroundColor: DetailsTheme.surface,
        foregroundColor: DetailsTheme.text,
        elevation: 0.5,
        toolbarHeight: 84,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Borrow Requests',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 22,
                color: DetailsTheme.text,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Manage requests received for your shared resources.',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.normal,
                color: DetailsTheme.secondaryText,
              ),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          StreamBuilder<List<BorrowRequestModel>>(
            stream: _requestsStream,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return _buildErrorState(snapshot.error.toString());
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return _buildSkeletonLoading();
              }

              final requests = snapshot.data ?? [];

              if (requests.isEmpty) {
                return _buildEmptyState(context);
              }

              return ListView.builder(
                padding: const EdgeInsets.all(DetailsTheme.outerPadding),
                itemCount: requests.length,
                itemBuilder: (context, index) {
                  final request = requests[index];
                  return BorrowRequestCard(
                    request: request,
                    onAcceptTap: () => _handleAcceptRequest(request),
                    onRejectTap: () => _handleRejectRequest(request),
                    onStartBorrowTap: () => _handleStartBorrow(request),
                    onMarkReturnedTap: () => _handleCompleteBorrow(request),
                    onRateReviewTap: () => _handleRateReview(request),
                  );
                },
              );
            },
          ),

          // Processing Overlay Spinner
          if (_isProcessing)
            Container(
              color: Colors.black26,
              child: const Center(
                child: CircularProgressIndicator(color: DetailsTheme.primary),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSkeletonLoading() {
    return ListView.builder(
      padding: const EdgeInsets.all(DetailsTheme.outerPadding),
      itemCount: 4,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: DetailsTheme.cardSpacing),
          padding: const EdgeInsets.all(DetailsTheme.cardSpacing),
          decoration: BoxDecoration(
            color: DetailsTheme.surface,
            borderRadius: BorderRadius.circular(DetailsTheme.cardRadius),
            border: Border.all(color: DetailsTheme.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 120,
                          height: 14,
                          color: Colors.grey.shade200,
                        ),
                        const SizedBox(height: 6),
                        Container(
                          width: 80,
                          height: 10,
                          color: Colors.grey.shade200,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 70,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(height: 1, color: DetailsTheme.border),
              const SizedBox(height: 14),
              Row(
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 160,
                          height: 14,
                          color: Colors.grey.shade200,
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: 100,
                          height: 12,
                          color: Colors.grey.shade200,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: DetailsTheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.inbox_outlined,
                size: 64,
                color: DetailsTheme.primary,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No Borrow Requests',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: DetailsTheme.text,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'When someone requests your listings, they will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: DetailsTheme.secondaryText,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: DetailsTheme.primary,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.arrow_back_rounded, size: 18),
              label: const Text(
                'Back to My Listings',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wifi_off_rounded, size: 56, color: Colors.red.shade400),
            const SizedBox(height: 16),
            const Text(
              'Unable to Load Requests',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: DetailsTheme.text,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              error.replaceAll('Exception: ', ''),
              textAlign: TextAlign.center,
              style: DetailsTheme.captionStyle,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => setState(() => _loadStream()),
              style: ElevatedButton.styleFrom(
                backgroundColor: DetailsTheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
