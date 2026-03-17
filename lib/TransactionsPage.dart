import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import 'providers/user_profile_provider.dart';
import 'widgets/image_loader.dart';

class TransactionsPage extends StatefulWidget {
  const TransactionsPage({super.key});

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> {
  static const int _pageSize = 50;
  static const Color _brandGreen = Color(0xFF4CAF50);

  String _searchQuery = '';
  TransactionFilter _activeFilter = TransactionFilter.all;

  final List<BookingTransaction> _olderTransactions = [];
  DocumentSnapshot<Map<String, dynamic>>? _olderCursor;
  bool _hasMoreOlder = true;
  bool _loadingOlder = false;

  @override
  Widget build(BuildContext context) {
    final currentUserId = _resolveCurrentUserId(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
        backgroundColor: _brandGreen,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list_rounded),
            onPressed: _openFilterSheet,
            tooltip: 'Filter',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _bookingsQuery(currentUserId, _pageSize).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildLoadingState();
                }

                if (snapshot.hasError) {
                  return _buildErrorState();
                }

                final docs = snapshot.data?.docs ?? const [];
                final liveTransactions = docs
                    .map(BookingTransaction.fromDoc)
                    .toList(growable: false);

                final latestCursor = docs.isNotEmpty ? docs.last : null;
                final canLoadMoreFromLivePage = docs.length == _pageSize;

                if (!canLoadMoreFromLivePage && _olderTransactions.isEmpty) {
                  _hasMoreOlder = false;
                }

                final merged = _mergeTransactions(
                  live: liveTransactions,
                  older: _olderTransactions,
                );
                final filtered = _applyClientFilters(merged);

                if (filtered.isEmpty) {
                  if (merged.isEmpty) {
                    return _buildEmptyState();
                  }
                  return _buildNoSearchResultState();
                }

                return RefreshIndicator(
                  onRefresh: _onRefresh,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
                    itemCount: filtered.length + 1,
                    itemBuilder: (context, index) {
                      if (index == filtered.length) {
                        final canLoadMore =
                            _hasMoreOlder || canLoadMoreFromLivePage;
                        if (!canLoadMore) {
                          return const SizedBox(height: 12);
                        }

                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Center(
                            child: OutlinedButton.icon(
                              onPressed: _loadingOlder
                                  ? null
                                  : () => _loadOlderTransactions(
                                        userId: currentUserId,
                                        fallbackCursor: latestCursor,
                                      ),
                              icon: _loadingOlder
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    )
                                  : const Icon(Icons.expand_more_rounded),
                              label: Text(
                                  _loadingOlder ? 'Loading...' : 'Load older'),
                            ),
                          ),
                        );
                      }

                      final transaction = filtered[index];
                      return _TransactionCard(
                        transaction: transaction,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => TransactionDetailsPage(
                                transaction: transaction,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search transactions...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isEmpty
              ? null
              : IconButton(
                  onPressed: () {
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                  icon: const Icon(Icons.close),
                ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: Colors.grey.shade100,
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value.trim();
          });
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 20),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Shimmer.fromColors(
              baseColor: Colors.grey.shade300,
              highlightColor: Colors.grey.shade100,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(height: 16, width: 160, color: Colors.white),
                        const SizedBox(height: 8),
                        Container(height: 12, width: 110, color: Colors.white),
                        const SizedBox(height: 8),
                        Container(height: 12, width: 140, color: Colors.white),
                        const SizedBox(height: 12),
                        Container(height: 12, width: 190, color: Colors.white),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                color: Colors.red, size: 44),
            const SizedBox(height: 10),
            const Text(
              'Unable to load transactions.',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            const Text(
              'Please check your connection and try again.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),
            ElevatedButton.icon(
              onPressed: () => setState(() {}),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _brandGreen,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.receipt_long_rounded,
                size: 72, color: Colors.grey.shade400),
            const SizedBox(height: 10),
            const Text(
              'No transactions yet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              'Your machinery bookings will appear here once created.',
              style: TextStyle(color: Colors.grey.shade700),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoSearchResultState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded,
                size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 10),
            const Text(
              'No matching transactions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              'Try another search text or filter option.',
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onRefresh() async {
    setState(() {
      _olderTransactions.clear();
      _olderCursor = null;
      _hasMoreOlder = true;
    });
  }

  Query<Map<String, dynamic>> _bookingsQuery(String userId, int limit) {
    return FirebaseFirestore.instance
        .collection('bookings')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(limit);
  }

  List<BookingTransaction> _mergeTransactions({
    required List<BookingTransaction> live,
    required List<BookingTransaction> older,
  }) {
    final map = <String, BookingTransaction>{};
    for (final item in [...live, ...older]) {
      map[item.bookingId] = item;
    }
    final list = map.values.toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  List<BookingTransaction> _applyClientFilters(
      List<BookingTransaction> source) {
    final query = _searchQuery.toLowerCase();
    return source.where((transaction) {
      final matchesText = query.isEmpty ||
          transaction.machineryName.toLowerCase().contains(query) ||
          transaction.ownerName.toLowerCase().contains(query) ||
          transaction.location.toLowerCase().contains(query);

      final matchesStatus = _activeFilter == TransactionFilter.all ||
          _activeFilter.matches(transaction.paymentStatus);

      return matchesText && matchesStatus;
    }).toList(growable: false);
  }

  Future<void> _loadOlderTransactions({
    required String userId,
    required DocumentSnapshot<Map<String, dynamic>>? fallbackCursor,
  }) async {
    if (_loadingOlder) return;

    final cursor = _olderCursor ?? fallbackCursor;
    if (cursor == null) {
      setState(() {
        _hasMoreOlder = false;
      });
      return;
    }

    setState(() {
      _loadingOlder = true;
    });

    try {
      final query = FirebaseFirestore.instance
          .collection('bookings')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .startAfterDocument(cursor)
          .limit(_pageSize);

      final snapshot = await query.get();
      final docs = snapshot.docs;

      if (!mounted) return;

      setState(() {
        _olderTransactions.addAll(docs.map(BookingTransaction.fromDoc));
        _olderCursor = docs.isNotEmpty ? docs.last : _olderCursor;
        _hasMoreOlder = docs.length == _pageSize;
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to load older transactions.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _loadingOlder = false;
        });
      }
    }
  }

  void _openFilterSheet() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) {
        var selected = _activeFilter;
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Filter by Status',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: TransactionFilter.values
                          .map(
                            (filter) => ChoiceChip(
                              label: Text(filter.label),
                              selected: selected == filter,
                              selectedColor:
                                  _brandGreen.withValues(alpha: 0.18),
                              onSelected: (_) {
                                setModalState(() {
                                  selected = filter;
                                });
                              },
                              labelStyle: TextStyle(
                                color: selected == filter
                                    ? _brandGreen
                                    : Colors.grey.shade800,
                                fontWeight: FontWeight.w600,
                              ),
                              side: BorderSide(color: Colors.grey.shade300),
                            ),
                          )
                          .toList(growable: false),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _activeFilter = selected;
                          });
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _brandGreen,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Apply Filter'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _resolveCurrentUserId(BuildContext context) {
    final authUid = FirebaseAuth.instance.currentUser?.uid;
    if (authUid != null && authUid.trim().isNotEmpty) {
      return authUid;
    }

    final profileData = context.read<UserProfileProvider>().userData;
    final rawUserId = profileData['userId']?.toString();
    if (rawUserId != null && rawUserId.trim().isNotEmpty) {
      return rawUserId;
    }

    final email = (profileData['email'] ?? '').toString().trim().toLowerCase();
    if (email.isNotEmpty) {
      return email.replaceAll('@', '_').replaceAll('.', '_');
    }

    return 'guest';
  }
}

class _TransactionCard extends StatelessWidget {
  const _TransactionCard({
    required this.transaction,
    required this.onTap,
  });

  final BookingTransaction transaction;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final statusStyle = _statusStyle(transaction.paymentStatus);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: SizedBox(
                      width: 84,
                      height: 84,
                      child: buildSmartImage(
                        transaction.machineryImageUrl,
                        width: 84,
                        height: 84,
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
                          transaction.machineryName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${transaction.durationDays} day(s) • ${transaction.location}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: Colors.grey.shade700, fontSize: 13),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusStyle.bg,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(statusStyle.icon,
                                  size: 14, color: statusStyle.fg),
                              const SizedBox(width: 4),
                              Text(
                                statusStyle.label,
                                style: TextStyle(
                                  color: statusStyle.fg,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    NumberFormat.currency(
                      locale: 'en_IN',
                      symbol: '₹',
                      decimalDigits: 2,
                    ).format(transaction.totalPrice),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                ],
              ),
              const Divider(height: 18),
              Text(
                'Owner: ${transaction.ownerName}',
                style: TextStyle(color: Colors.grey.shade700),
              ),
              const SizedBox(height: 2),
              Text(
                'Payment via: ${transaction.paymentMethod}',
                style: TextStyle(color: Colors.grey.shade700),
              ),
              const SizedBox(height: 4),
              Text(
                DateFormat('dd MMM yyyy').format(transaction.startDate),
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TransactionDetailsPage extends StatelessWidget {
  const TransactionDetailsPage({super.key, required this.transaction});

  final BookingTransaction transaction;

  @override
  Widget build(BuildContext context) {
    final statusStyle = _statusStyle(transaction.paymentStatus);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction Details'),
        backgroundColor: const Color(0xFF4CAF50),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                width: double.infinity,
                height: 210,
                child: buildSmartImage(
                  transaction.machineryImageUrl,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              transaction.machineryName,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: statusStyle.bg,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(statusStyle.icon, size: 16, color: statusStyle.fg),
                  const SizedBox(width: 5),
                  Text(
                    statusStyle.label,
                    style: TextStyle(
                        color: statusStyle.fg, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _detail('Owner Name', transaction.ownerName),
            _detail('Location', transaction.location),
            _detail('Booking Type', transaction.bookingType),
            _detail('Duration', '${transaction.durationDays} day(s)'),
            _detail('Start Date',
                DateFormat('dd MMM yyyy').format(transaction.startDate)),
            _detail('End Date',
                DateFormat('dd MMM yyyy').format(transaction.endDate)),
            _detail('Payment Method', transaction.paymentMethod),
            _detail('Payment ID', transaction.paymentId),
            _detail(
              'Amount Paid',
              NumberFormat.currency(
                      locale: 'en_IN', symbol: '₹', decimalDigits: 2)
                  .format(transaction.totalPrice),
              isStrong: true,
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _detail(String label, String value, {bool isStrong = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ),
          const Text(': '),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: isStrong ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class BookingTransaction {
  const BookingTransaction({
    required this.bookingId,
    required this.machineryId,
    required this.machineryName,
    required this.machineryImageUrl,
    required this.ownerName,
    required this.location,
    required this.userId,
    required this.durationDays,
    required this.bookingType,
    required this.startDate,
    required this.endDate,
    required this.totalPrice,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.paymentId,
    required this.createdAt,
  });

  final String bookingId;
  final String machineryId;
  final String machineryName;
  final String machineryImageUrl;
  final String ownerName;
  final String location;
  final String userId;
  final int durationDays;
  final String bookingType;
  final DateTime startDate;
  final DateTime endDate;
  final double totalPrice;
  final String paymentMethod;
  final String paymentStatus;
  final String paymentId;
  final DateTime createdAt;

  factory BookingTransaction.fromDoc(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    final start = _toDate(data['startDate']);
    final end = _toDate(data['endDate']);

    final days = _toInt(data['durationDays']) ??
        _toInt(data['days']) ??
        (end.difference(start).inDays + 1);

    return BookingTransaction(
      bookingId: (data['bookingId'] ?? doc.id).toString(),
      machineryId: (data['machineryId'] ?? '').toString(),
      machineryName:
          (data['machineryName'] ?? data['machineName'] ?? 'Machinery')
              .toString(),
      machineryImageUrl:
          (data['machineryImageUrl'] ?? data['imageUrl'] ?? '').toString(),
      ownerName: (data['ownerName'] ?? 'Unknown Owner').toString(),
      location: (data['location'] ?? 'Unknown').toString(),
      userId: (data['userId'] ?? '').toString(),
      durationDays: days <= 0 ? 1 : days,
      bookingType: (data['bookingType'] ?? 'daily').toString(),
      startDate: start,
      endDate: end,
      totalPrice: _toDouble(data['totalPrice']),
      paymentMethod: (data['paymentMethod'] ?? 'Unknown').toString(),
      paymentStatus:
          (data['paymentStatus'] ?? data['status'] ?? 'pending').toString(),
      paymentId: (data['paymentId'] ?? '-').toString(),
      createdAt: _toDate(data['createdAt']),
    );
  }
}

enum TransactionFilter { all, completed, pending, cancelled }

extension TransactionFilterX on TransactionFilter {
  String get label {
    switch (this) {
      case TransactionFilter.all:
        return 'All';
      case TransactionFilter.completed:
        return 'Completed';
      case TransactionFilter.pending:
        return 'Pending';
      case TransactionFilter.cancelled:
        return 'Cancelled';
    }
  }

  bool matches(String statusRaw) {
    final normalized = statusRaw.trim().toLowerCase();
    switch (this) {
      case TransactionFilter.all:
        return true;
      case TransactionFilter.completed:
        return normalized == 'completed';
      case TransactionFilter.pending:
        return normalized == 'pending';
      case TransactionFilter.cancelled:
        return normalized == 'cancelled';
    }
  }
}

_StatusStyle _statusStyle(String statusRaw) {
  final status = statusRaw.trim().toLowerCase();
  if (status == 'completed') {
    return const _StatusStyle(
      label: 'Completed',
      fg: Color(0xFF2E7D32),
      bg: Color(0xFFE8F5E9),
      icon: Icons.check_circle_rounded,
    );
  }
  if (status == 'cancelled') {
    return const _StatusStyle(
      label: 'Cancelled',
      fg: Color(0xFFC62828),
      bg: Color(0xFFFFEBEE),
      icon: Icons.cancel_rounded,
    );
  }
  return const _StatusStyle(
    label: 'Pending',
    fg: Color(0xFFEF6C00),
    bg: Color(0xFFFFF3E0),
    icon: Icons.schedule_rounded,
  );
}

class _StatusStyle {
  const _StatusStyle({
    required this.label,
    required this.fg,
    required this.bg,
    required this.icon,
  });

  final String label;
  final Color fg;
  final Color bg;
  final IconData icon;
}

DateTime _toDate(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
  if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
  return DateTime.now();
}

double _toDouble(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0;
  return 0;
}

int? _toInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}
