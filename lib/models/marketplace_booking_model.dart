import 'package:cloud_firestore/cloud_firestore.dart';

class MarketplaceBookingModel {
  const MarketplaceBookingModel({
    required this.bookingId,
    required this.equipmentId,
    required this.ownerId,
    required this.userId,
    required this.startDate,
    required this.endDate,
    required this.bookingType,
    required this.totalPrice,
    required this.paymentId,
    required this.status,
    required this.createdAt,
    required this.equipmentName,
    required this.location,
  });

  final String bookingId;
  final String equipmentId;
  final String ownerId;
  final String userId;
  final DateTime startDate;
  final DateTime endDate;
  final String bookingType;
  final double totalPrice;
  final String paymentId;
  final String status;
  final DateTime createdAt;
  final String equipmentName;
  final String location;

  factory MarketplaceBookingModel.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    return MarketplaceBookingModel(
      bookingId: (data['bookingId'] ?? doc.id).toString(),
      equipmentId: (data['equipmentId'] ?? '').toString(),
      ownerId: (data['ownerId'] ?? '').toString(),
      userId: (data['userId'] ?? '').toString(),
      startDate: _toDate(data['startDate']),
      endDate: _toDate(data['endDate']),
      bookingType: (data['bookingType'] ?? 'daily').toString(),
      totalPrice: _toDouble(data['totalPrice']),
      paymentId: (data['paymentId'] ?? '-').toString(),
      status: (data['status'] ?? 'pending').toString(),
      createdAt: _toDate(data['createdAt']),
      equipmentName: (data['equipmentName'] ?? 'Equipment').toString(),
      location: (data['location'] ?? 'Unknown').toString(),
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
