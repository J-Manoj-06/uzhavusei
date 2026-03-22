import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../localization/app_localizations.dart';
import '../../../models/app_user_model.dart';
import '../../../widgets/image_loader.dart';

class MyBookingsPage extends StatelessWidget {
  const MyBookingsPage({
    super.key,
    required this.currentUser,
  });

  final AppUserModel currentUser;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.tr('my_bookings_title')),
        backgroundColor: const Color(0xFF4CAF50),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('bookings')
            .where(
              currentUser.isOwner ? 'ownerId' : 'userId',
              isEqualTo: currentUser.userId,
            )
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text(l10n.tr('error_occurred')));
          }

          final docs = snapshot.data?.docs ?? const [];
          if (docs.isEmpty) {
            return Center(child: Text(l10n.tr('no_bookings')));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemBuilder: (context, index) {
              final data = docs[index].data();
              final imageUrl = (data['imageUrl'] ??
                      data['machineryImageUrl'] ??
                      'assets/logo.jpg')
                  .toString();
              final start = _toDate(data['startDate']);
              final end = _toDate(data['endDate']);
              final totalPrice = _toDouble(data['totalPrice']);

              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      width: 56,
                      height: 56,
                      child: buildSmartImage(imageUrl, fit: BoxFit.cover),
                    ),
                  ),
                  title: Text((data['equipmentName'] ??
                          data['machineryName'] ??
                          'Equipment')
                      .toString()),
                  subtitle: Text(
                    '${DateFormat('dd MMM yyyy').format(start)} - ${DateFormat('dd MMM yyyy').format(end)}\n${(data['status'] ?? '').toString()}',
                  ),
                  trailing: Text(
                    '₹${totalPrice.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                  isThreeLine: true,
                ),
              );
            },
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemCount: docs.length,
          );
        },
      ),
    );
  }
}

DateTime _toDate(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
  return DateTime.now();
}

double _toDouble(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0;
  return 0;
}
