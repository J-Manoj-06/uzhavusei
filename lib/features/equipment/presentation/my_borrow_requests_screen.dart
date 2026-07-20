import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:UzhavuSei/models/borrow_request_model.dart';
import 'package:UzhavuSei/services/borrow_request_repository.dart';
import 'package:UzhavuSei/widgets/image_loader.dart';
import 'widgets/details/details_theme.dart';

class MyBorrowRequestsScreen extends StatefulWidget {
  const MyBorrowRequestsScreen({
    super.key,
    required this.borrowerId,
  });

  final String borrowerId;

  @override
  State<MyBorrowRequestsScreen> createState() => _MyBorrowRequestsScreenState();
}

class _MyBorrowRequestsScreenState extends State<MyBorrowRequestsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final BorrowRequestRepository _repository = BorrowRequestRepository();

  final List<String> _filters = ['All', 'Pending', 'Accepted', 'Completed'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _filters.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<BorrowRequestModel> _filterRequests(
      List<BorrowRequestModel> requests, String filter) {
    if (filter == 'All') return requests;
    if (filter == 'Pending') {
      return requests.where((r) => r.status.toLowerCase() == 'requested').toList();
    }
    return requests.where((r) => r.status.toLowerCase() == filter.toLowerCase()).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DetailsTheme.background,
      appBar: AppBar(
        title: const Text(
          'My Borrow Requests',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: DetailsTheme.text,
          ),
        ),
        backgroundColor: DetailsTheme.surface,
        foregroundColor: DetailsTheme.text,
        elevation: 0.5,
        bottom: TabBar(
          controller: _tabController,
          labelColor: DetailsTheme.primary,
          unselectedLabelColor: DetailsTheme.secondaryText,
          indicatorColor: DetailsTheme.primary,
          indicatorWeight: 3,
          tabs: _filters.map((f) => Tab(text: f)).toList(),
        ),
      ),
      body: StreamBuilder<List<BorrowRequestModel>>(
        stream: _repository.watchBorrowerRequests(widget.borrowerId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Failed to load requests: ${snapshot.error}',
                style: DetailsTheme.captionStyle,
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: DetailsTheme.primary),
            );
          }

          final allRequests = snapshot.data!;

          return TabBarView(
            controller: _tabController,
            children: _filters.map((filter) {
              final filtered = _filterRequests(allRequests, filter);

              if (filtered.isEmpty) {
                return _buildEmptyState();
              }

              return ListView.builder(
                padding: const EdgeInsets.all(DetailsTheme.outerPadding),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  return _buildBorrowerRequestCard(filtered[index]);
                },
              );
            }).toList(),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.history_outlined,
            size: 64,
            color: DetailsTheme.secondaryText.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 12),
          const Text(
            "You haven't requested any items.",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: DetailsTheme.secondaryText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBorrowerRequestCard(BorrowRequestModel request) {
    final dateFormat = DateFormat('MMM d, yyyy');
    final fromStr = dateFormat.format(request.borrowFrom);
    final toStr = dateFormat.format(request.borrowUntil);

    return Container(
      margin: const EdgeInsets.only(bottom: DetailsTheme.cardSpacing),
      padding: const EdgeInsets.all(DetailsTheme.cardSpacing),
      decoration: BoxDecoration(
        color: DetailsTheme.surface,
        borderRadius: BorderRadius.circular(DetailsTheme.cardRadius),
        border: Border.all(color: DetailsTheme.border),
        boxShadow: DetailsTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Category & Status Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: DetailsTheme.primaryContainer,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  request.category.isNotEmpty ? request.category : 'General',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: DetailsTheme.primary,
                  ),
                ),
              ),
              _buildStatusBadge(request.status),
            ],
          ),

          const SizedBox(height: 12),

          // Listing Thumbnail, Title & Owner info
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 60,
                  height: 60,
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Dates: $fromStr - $toStr',
                      style: DetailsTheme.captionStyle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Duration: ${request.borrowDuration} ${request.borrowDuration == 1 ? 'Day' : 'Days'}',
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
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color fg;

    switch (status.toLowerCase()) {
      case 'accepted':
        bg = DetailsTheme.success.withValues(alpha: 0.15);
        fg = DetailsTheme.success;
        break;
      case 'declined':
        bg = Colors.red.shade50;
        fg = Colors.red.shade700;
        break;
      case 'completed':
        bg = Colors.grey.shade200;
        fg = DetailsTheme.secondaryText;
        break;
      case 'requested':
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
