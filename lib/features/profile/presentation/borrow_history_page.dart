import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../models/app_user_model.dart';
import '../../../models/marketplace_booking_model.dart';
import '../../../services/marketplace_service.dart';
import '../../../widgets/image_loader.dart';
import 'package:UzhavuSei/theme/app_theme.dart';

class BorrowHistoryPage extends StatefulWidget {
  const BorrowHistoryPage({
    super.key,
    required this.currentUser,
  });

  final AppUserModel currentUser;

  @override
  State<BorrowHistoryPage> createState() => _BorrowHistoryPageState();
}

class _BorrowHistoryPageState extends State<BorrowHistoryPage> {
  final MarketplaceService _service = MarketplaceService();
  String _searchQuery = '';
  String _dateFilter = 'all'; // all, this_month, last_month, this_year

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Borrow History', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: StreamBuilder<List<MarketplaceBookingModel>>(
        stream: _service.watchUserBookings(widget.currentUser.userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Unable to load history.'));
          }

          final allBookings = snapshot.data ?? [];
          final completedBookings = allBookings.where((b) => b.status == 'completed').toList();

          // Apply filters
          final now = DateTime.now();
          final filtered = completedBookings.where((b) {
            // Search filter
            final matchQuery = b.equipmentName.toLowerCase().contains(_searchQuery.toLowerCase());
            if (!matchQuery) return false;

            // Date filter
            if (_dateFilter == 'this_month') {
              return b.startDate.year == now.year && b.startDate.month == now.month;
            } else if (_dateFilter == 'last_month') {
              final lastMonth = now.month == 1 ? 12 : now.month - 1;
              final lastMonthYear = now.month == 1 ? now.year - 1 : now.year;
              return b.startDate.year == lastMonthYear && b.startDate.month == lastMonth;
            } else if (_dateFilter == 'this_year') {
              return b.startDate.year == now.year;
            }
            return true;
          }).toList();

          // Sort newest first
          filtered.sort((a, b) => b.startDate.compareTo(a.startDate));

          return Column(
            children: [
              // Search & Filter controls
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  children: [
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'Search borrow history',
                        prefixIcon: const Icon(Icons.search, size: 20),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        filled: true,
                        fillColor: const Color(0xFFF1F3F4),
                        contentPadding: EdgeInsets.zero,
                      ),
                      onChanged: (val) => setState(() => _searchQuery = val),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _buildFilterChip('All Time', 'all'),
                        const SizedBox(width: 8),
                        _buildFilterChip('This Month', 'this_month'),
                        const SizedBox(width: 8),
                        _buildFilterChip('Last Month', 'last_month'),
                        const SizedBox(width: 8),
                        _buildFilterChip('This Year', 'this_year'),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? _buildEmptyState()
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final item = filtered[index];
                          final dateStr = '${DateFormat('MMM d, yyyy').format(item.startDate)} - ${DateFormat('MMM d, yyyy').format(item.endDate)}';
                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFEBEFF0)),
                            ),
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    width: 72,
                                    height: 72,
                                    color: AppColors.primaryContainer,
                                    child: const Icon(Icons.swap_horiz_outlined, size: 36, color: AppColors.primary),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.equipmentName,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '📍 ${item.location}',
                                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        dateStr,
                                        style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: AppColors.successContainer,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: const Text(
                                              'Returned',
                                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary),
                                            ),
                                          ),
                                          const Spacer(),
                                          const Icon(Icons.star, color: Colors.amber, size: 16),
                                          const SizedBox(width: 4),
                                          const Text('5.0', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final active = _dateFilter == value;
    return ChoiceChip(
      label: Text(label, style: TextStyle(fontSize: 12, color: active ? Colors.white : Colors.grey.shade700, fontWeight: FontWeight.bold)),
      selected: active,
      onSelected: (sel) {
        if (sel) setState(() => _dateFilter = value);
      },
      selectedColor: AppColors.primary,
      backgroundColor: const Color(0xFFF1F3F4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide.none),
      showCheckmark: false,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.history_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'No completed exchanges.',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              'Once you borrow or share items and successfully return them, they will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // back to profile / home
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Browse Resources'),
            ),
          ],
        ),
      ),
    );
  }
}
