import 'package:flutter/material.dart';
import 'package:UzhavuSei/models/borrow_request_model.dart';
import 'package:UzhavuSei/services/borrow_request_repository.dart';
import 'widgets/details/details_theme.dart';
import 'widgets/borrow_request/borrow_request_card.dart';
import 'borrow_details_page.dart';
import 'borrow_history_page.dart';

class BorrowDashboardPage extends StatefulWidget {
  const BorrowDashboardPage({
    super.key,
    required this.userId,
    this.isOwnerView = true,
  });

  final String userId;
  final bool isOwnerView;

  @override
  State<BorrowDashboardPage> createState() => _BorrowDashboardPageState();
}

class _BorrowDashboardPageState extends State<BorrowDashboardPage>
    with SingleTickerProviderStateMixin {
  final BorrowRequestRepository _repository = BorrowRequestRepository();
  late Stream<List<BorrowRequestModel>> _requestsStream;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _requestsStream = widget.isOwnerView
        ? _repository.watchOwnerRequests(widget.userId)
        : _repository.watchBorrowerRequests(widget.userId);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DetailsTheme.background,
      appBar: AppBar(
        backgroundColor: DetailsTheme.surface,
        foregroundColor: DetailsTheme.text,
        elevation: 0.5,
        title: Text(
          widget.isOwnerView ? 'Owner Borrow Dashboard' : 'My Borrows',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: DetailsTheme.text,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BorrowHistoryPage(userId: widget.userId),
                ),
              );
            },
            tooltip: 'Borrow History',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: DetailsTheme.primary,
          unselectedLabelColor: DetailsTheme.secondaryText,
          indicatorColor: DetailsTheme.primary,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'Current'),
            Tab(text: 'Pending'),
            Tab(text: 'Completed'),
          ],
        ),
      ),
      body: StreamBuilder<List<BorrowRequestModel>>(
        stream: _requestsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: DetailsTheme.primary));
          }

          final allRequests = snapshot.data ?? [];

          final currentBorrows = allRequests.where((r) {
            final s = r.status.trim().toLowerCase();
            return s == 'borrowed' || s == 'picked up';
          }).toList();

          final pendingRequests = allRequests.where((r) {
            final s = r.status.trim().toLowerCase();
            return s == 'pending' || s == 'requested';
          }).toList();

          final completedBorrows = allRequests.where((r) {
            final s = r.status.trim().toLowerCase();
            return s == 'completed' || s == 'returned';
          }).toList();

          return Column(
            children: [
              // Summary Statistics Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildSummaryCard(
                        label: 'Active',
                        count: currentBorrows.length,
                        color: Colors.orange.shade800,
                        icon: Icons.timer_outlined,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildSummaryCard(
                        label: 'Pending',
                        count: pendingRequests.length,
                        color: DetailsTheme.primary,
                        icon: Icons.pending_actions_rounded,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildSummaryCard(
                        label: 'Completed',
                        count: completedBorrows.length,
                        color: DetailsTheme.success,
                        icon: Icons.task_alt_rounded,
                      ),
                    ),
                  ],
                ),
              ),

              // Tab Views
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Tab 1: Current Active Borrows
                    _buildRequestList(
                      requests: currentBorrows,
                      emptyMessage: 'No active borrows.',
                    ),
                    // Tab 2: Pending Requests
                    _buildRequestList(
                      requests: pendingRequests,
                      emptyMessage: 'No pending requests.',
                    ),
                    // Tab 3: Completed Borrows
                    _buildRequestList(
                      requests: completedBorrows,
                      emptyMessage: 'No completed transactions.',
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard({
    required String label,
    required int count,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: DetailsTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: DetailsTheme.border),
        boxShadow: DetailsTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, size: 20, color: color),
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: DetailsTheme.captionStyle,
          ),
        ],
      ),
    );
  }

  Widget _buildRequestList({
    required List<BorrowRequestModel> requests,
    required String emptyMessage,
  }) {
    if (requests.isEmpty) {
      return Center(
        child: Text(
          emptyMessage,
          style: DetailsTheme.captionStyle,
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(DetailsTheme.outerPadding),
      itemCount: requests.length,
      itemBuilder: (context, index) {
        final req = requests[index];
        return BorrowRequestCard(
          request: req,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BorrowDetailsPage(request: req),
              ),
            );
          },
        );
      },
    );
  }
}
