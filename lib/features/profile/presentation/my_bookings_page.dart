import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../localization/app_localizations.dart';
import '../../../models/app_user_model.dart';
import '../../../widgets/image_loader.dart';

class MyBookingsPage extends StatefulWidget {
  const MyBookingsPage({
    super.key,
    required this.currentUser,
  });

  final AppUserModel currentUser;

  @override
  State<MyBookingsPage> createState() => _MyBookingsPageState();
}

class _MyBookingsPageState extends State<MyBookingsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  DateTime _toDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    return DateTime.now();
  }

  Future<void> _updateBookingStatus(String bookingId, Map<String, dynamic> updates) async {
    await FirebaseFirestore.instance.collection('bookings').doc(bookingId).update(updates);
  }

  void _showAcceptDialog(BuildContext context, String bookingId) {
    String selectedOption = 'exact_address';
    final landmarkCtrl = TextEditingController();
    final instructionsCtrl = TextEditingController();
    final contactCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text('Accept Borrow Request', style: TextStyle(fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Choose Location Sharing Option:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: selectedOption,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'exact_address', child: Text('Share Exact Pickup Address')),
                        DropdownMenuItem(value: 'approximate_area', child: Text('Share Approximate Pickup Area')),
                        DropdownMenuItem(value: 'chat_first', child: Text('Chat First')),
                        DropdownMenuItem(value: 'decide_later', child: Text('Decide Later')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setModalState(() => selectedOption = val);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text('Pickup Landmark:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: landmarkCtrl,
                      decoration: InputDecoration(
                        hintText: 'e.g. Near Bus Stand, College Gate...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Pickup Instructions / Time:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: instructionsCtrl,
                      decoration: InputDecoration(
                        hintText: 'e.g. Collect tomorrow between 10am-12pm...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Contact Information (Optional):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: contactCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        hintText: 'e.g. Phone or WhatsApp number...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await _updateBookingStatus(bookingId, {
                      'status': 'approved',
                      'shareOption': selectedOption,
                      'landmark': landmarkCtrl.text.trim(),
                      'pickupTime': instructionsCtrl.text.trim(),
                      'specialInstructions': instructionsCtrl.text.trim(),
                      'contactInfo': contactCtrl.text.trim(),
                    });
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Borrow request approved and details shared!')),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Approve', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showSuggestDatesDialog(BuildContext context, String bookingId) {
    final messageCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Suggest Different Dates', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Send a message suggesting other availability dates:', style: TextStyle(fontSize: 13)),
              const SizedBox(height: 12),
              TextField(
                controller: messageCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'e.g. Next Monday works better...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await _updateBookingStatus(bookingId, {
                  'status': 'pending',
                  'suggestedMessage': messageCtrl.text.trim(),
                });
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Date suggestions sent to borrower!')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Send Suggestions', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBorrowerCard(Map<String, dynamic> data) {
    final bookingId = (data['bookingId'] ?? '').toString();
    final imageUrl = (data['imageUrl'] ?? data['machineryImageUrl'] ?? 'assets/logo.jpg').toString();
    final start = _toDate(data['startDate']);
    final end = _toDate(data['endDate']);
    final status = (data['status'] ?? 'pending').toString().toLowerCase();
    final rawLocation = (data['location'] ?? 'Unknown').toString();
    
    // Privacy options
    final shareOption = (data['shareOption'] ?? '').toString();
    final landmark = (data['landmark'] ?? '').toString();
    final instructions = (data['pickupTime'] ?? data['specialInstructions'] ?? '').toString();
    final contactInfo = (data['contactInfo'] ?? '').toString();
    final readyToReturn = data['readyToReturn'] == true;

    String resolvedLocation = 'Pickup details will become available once the owner shares them.';
    if (status == 'approved') {
      if (shareOption == 'exact_address') {
        resolvedLocation = rawLocation;
      } else if (shareOption == 'approximate_area') {
        resolvedLocation = 'Approximate Area: Near Velachery';
      } else if (shareOption == 'chat_first') {
        resolvedLocation = 'Coordinate exact location inside Chat';
      } else if (shareOption == 'decide_later') {
        resolvedLocation = 'Owner will share pickup location later';
      }
    }

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFEBEFF0)),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 64,
                    height: 64,
                    child: buildSmartImage(imageUrl, fit: BoxFit.cover),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (data['equipmentName'] ?? data['machineryName'] ?? 'Equipment').toString(),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1A1A1A)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${DateFormat('dd MMM').format(start)} - ${DateFormat('dd MMM yyyy').format(end)}',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24, color: Color(0xFFEBEFF0)),

            // Status Badge
            Row(
              children: [
                const Text('Status: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                _buildStatusBadge(status),
              ],
            ),
            const SizedBox(height: 12),

            // Pickup Info Block
            if (status == 'approved') ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F8E9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFC8E6C9)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.location_on, color: Color(0xFF2E7D32), size: 16),
                        SizedBox(width: 6),
                        Text('Pickup Location', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF1B5E20))),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(resolvedLocation, style: const TextStyle(fontSize: 12, color: Colors.black87)),
                    if (landmark.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text('Landmark: $landmark', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                    if (instructions.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text('Instructions: $instructions', style: const TextStyle(fontSize: 12)),
                    ],
                    if (contactInfo.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text('Owner Contact: $contactInfo', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (!readyToReturn)
                SizedBox(
                  width: double.infinity,
                  height: 40,
                  child: ElevatedButton(
                    onPressed: () => _updateBookingStatus(bookingId, {'readyToReturn': true}),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Mark Ready to Return', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  alignment: Alignment.center,
                  child: Text('Waiting for owner return confirmation 🔄', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.orange.shade700)),
                ),
            ] else if (status == 'pending') ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.lock_outline, color: Colors.grey, size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Pickup details will become available once the owner shares them.',
                        style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (status == 'completed') ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle_outline, color: Color(0xFF2E7D32), size: 16),
                    SizedBox(width: 8),
                    Text('Item Returned successfully!', style: TextStyle(fontSize: 12, color: Color(0xFF1B5E20), fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOwnerRequestCard(Map<String, dynamic> data) {
    final bookingId = (data['bookingId'] ?? '').toString();
    final imageUrl = (data['imageUrl'] ?? data['machineryImageUrl'] ?? 'assets/logo.jpg').toString();
    final start = _toDate(data['startDate']);
    final end = _toDate(data['endDate']);
    final status = (data['status'] ?? 'pending').toString().toLowerCase();
    final borrowerName = (data['userName'] ?? 'Borrower').toString();
    final readyToReturn = data['readyToReturn'] == true;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFEBEFF0)),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 64,
                    height: 64,
                    child: buildSmartImage(imageUrl, fit: BoxFit.cover),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (data['equipmentName'] ?? data['machineryName'] ?? 'Equipment').toString(),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1A1A1A)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Requested by: $borrowerName',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
                      ),
                      Text(
                        '${DateFormat('dd MMM').format(start)} - ${DateFormat('dd MMM yyyy').format(end)}',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (data['borrowMessage'] != null && (data['borrowMessage'] as String).isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.grey.shade500.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(8)),
                child: Text('Message: "${data['borrowMessage']}"', style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic)),
              ),
            ],
            const Divider(height: 24, color: Color(0xFFEBEFF0)),

            if (status == 'pending') ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _updateBookingStatus(bookingId, {'status': 'rejected'}),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                        foregroundColor: Colors.red,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Reject', style: TextStyle(fontSize: 11)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _showSuggestDatesDialog(context, bookingId),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF2E7D32)),
                        foregroundColor: const Color(0xFF2E7D32),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Suggest Dates', style: TextStyle(fontSize: 11)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _showAcceptDialog(context, bookingId),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Accept', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                    ),
                  ),
                ],
              ),
            ] else if (status == 'approved') ...[
              if (readyToReturn) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(color: const Color(0xFFFFF3E0), borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.orange.shade800, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Borrower marked this item as returned. Please confirm.',
                          style: TextStyle(fontSize: 11, color: Colors.orange.shade900, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  height: 40,
                  child: ElevatedButton(
                    onPressed: () => _updateBookingStatus(bookingId, {'status': 'completed', 'returned': true}),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Confirm Item Returned', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ] else ...[
                const Center(
                  child: Text('On Loan 🚜 (Awaiting borrower return)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
                ),
              ],
            ] else if (status == 'completed') ...[
              const Center(
                child: Text('Completed 🎉 (Item returned & confirmed)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
              ),
            ] else if (status == 'rejected') ...[
              const Center(
                child: Text('Rejected ❌', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.red)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg = Colors.grey.shade100;
    Color fg = Colors.grey.shade800;
    String label = 'Pending Approval';

    if (status == 'approved') {
      bg = const Color(0xFFE8F5E9);
      fg = const Color(0xFF2E7D32);
      label = 'Approved';
    } else if (status == 'completed') {
      bg = const Color(0xFFE3F2FD);
      fg = Colors.blue.shade700;
      label = 'Completed';
    } else if (status == 'rejected') {
      bg = const Color(0xFFFFEBEE);
      fg = Colors.red;
      label = 'Rejected';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Text(label, style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: Text(l10n.tr('my_bookings_title')),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF2E7D32),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF2E7D32),
          tabs: const [
            Tab(text: 'My Requests'),
            Tab(text: 'Lent Requests'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Outgoing My Requests Tab
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('bookings')
                .where('userId', isEqualTo: widget.currentUser.userId)
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final docs = snapshot.data?.docs ?? const [];
              if (docs.isEmpty) {
                return const Center(child: Text('No borrow requests found.'));
              }
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: docs.length,
                itemBuilder: (context, index) => _buildBorrowerCard(docs[index].data()),
              );
            },
          ),

          // Incoming Lent Requests Tab
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('bookings')
                .where('ownerId', isEqualTo: widget.currentUser.userId)
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final docs = snapshot.data?.docs ?? const [];
              if (docs.isEmpty) {
                return const Center(child: Text('No incoming borrow requests.'));
              }
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: docs.length,
                itemBuilder: (context, index) => _buildOwnerRequestCard(docs[index].data()),
              );
            },
          ),
        ],
      ),
    );
  }
}
