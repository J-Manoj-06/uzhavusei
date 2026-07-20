import 'package:flutter/material.dart';
import 'package:UzhavuSei/models/borrow_request_model.dart';
import 'package:UzhavuSei/services/borrow_request_repository.dart';
import 'widgets/details/details_theme.dart';
import 'widgets/borrow_request/borrow_request_card.dart';
import 'borrow_details_page.dart';

class BorrowHistoryPage extends StatefulWidget {
  const BorrowHistoryPage({
    super.key,
    required this.userId,
  });

  final String userId;

  @override
  State<BorrowHistoryPage> createState() => _BorrowHistoryPageState();
}

class _BorrowHistoryPageState extends State<BorrowHistoryPage> {
  final BorrowRequestRepository _repository = BorrowRequestRepository();
  late Stream<List<BorrowRequestModel>> _requestsStream;

  String _searchQuery = '';
  String _selectedCategory = 'All';
  String _sortBy = 'Newest';

  @override
  void initState() {
    super.initState();
    _requestsStream = _repository.watchOwnerRequests(widget.userId);
  }

  void _openFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Filter Borrow History',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: DetailsTheme.text,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  const Text(
                    'Category',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: ['All', 'Books', 'Equipment', 'Surplus'].map((cat) {
                      final isSelected = _selectedCategory == cat;
                      return ChoiceChip(
                        label: Text(cat),
                        selected: isSelected,
                        onSelected: (val) {
                          if (val) {
                            setState(() => _selectedCategory = cat);
                            setModalState(() {});
                          }
                        },
                        selectedColor: DetailsTheme.primary,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : DetailsTheme.text,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Sort By',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: ['Newest', 'Oldest'].map((opt) {
                      final isSelected = _sortBy == opt;
                      return ChoiceChip(
                        label: Text(opt),
                        selected: isSelected,
                        onSelected: (val) {
                          if (val) {
                            setState(() => _sortBy = opt);
                            setModalState(() {});
                          }
                        },
                        selectedColor: DetailsTheme.primary,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : DetailsTheme.text,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: DetailsTheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Apply Filters'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
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
        title: const Text(
          'Borrow History',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: DetailsTheme.text,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            onPressed: _openFilterBottomSheet,
            tooltip: 'Filter',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Header
          Container(
            color: DetailsTheme.surface,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: 'Search by title, ID, category, or borrower...',
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                isDense: true,
                filled: true,
                fillColor: DetailsTheme.background,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: DetailsTheme.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: DetailsTheme.border),
                ),
              ),
            ),
          ),

          // Stream Results
          Expanded(
            child: StreamBuilder<List<BorrowRequestModel>>(
              stream: _requestsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(color: DetailsTheme.primary));
                }

                final all = snapshot.data ?? [];
                var completedList = all.where((r) {
                  final s = r.status.trim().toLowerCase();
                  final isCompleted = s == 'completed' || s == 'returned';
                  if (!isCompleted) return false;

                  if (_selectedCategory != 'All' &&
                      r.category.toLowerCase() != _selectedCategory.toLowerCase()) {
                    return false;
                  }

                  if (_searchQuery.trim().isEmpty) return true;
                  final q = _searchQuery.trim().toLowerCase();
                  return r.listingTitle.toLowerCase().contains(q) ||
                      r.borrowerName.toLowerCase().contains(q) ||
                      r.category.toLowerCase().contains(q) ||
                      r.requestId.toLowerCase().contains(q);
                }).toList();

                if (_sortBy == 'Oldest') {
                  completedList = completedList.reversed.toList();
                }

                if (completedList.isEmpty) {
                  return _buildEmptyHistoryState();
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(DetailsTheme.outerPadding),
                  itemCount: completedList.length,
                  itemBuilder: (context, index) {
                    final req = completedList[index];
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
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyHistoryState() {
    return Center(
      child: Padding(
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
                Icons.history_rounded,
                size: 56,
                color: DetailsTheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No Completed Transactions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: DetailsTheme.text,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'When borrow requests are completed and returned, they will appear in history.',
              textAlign: TextAlign.center,
              style: DetailsTheme.captionStyle,
            ),
          ],
        ),
      ),
    );
  }
}
