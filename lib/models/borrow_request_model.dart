import 'package:cloud_firestore/cloud_firestore.dart';

class BorrowRequestModel {
  final String requestId;
  final String listingId;
  final String listingTitle;
  final String listingImage;
  final String category;
  final String ownerId;
  final String borrowerId;
  final String borrowerName;
  final DateTime borrowFrom;
  final DateTime borrowUntil;
  final int borrowDuration;
  final String status;
  final DateTime requestedAt;
  final DateTime updatedAt;
  final DateTime? borrowedAt;

  BorrowRequestModel({
    required this.requestId,
    required this.listingId,
    required this.listingTitle,
    required this.listingImage,
    required this.category,
    required this.ownerId,
    required this.borrowerId,
    this.borrowerName = 'Borrower',
    required this.borrowFrom,
    required this.borrowUntil,
    required this.borrowDuration,
    this.status = 'Requested',
    required this.requestedAt,
    required this.updatedAt,
    this.borrowedAt,
  });

  factory BorrowRequestModel.fromMap(Map<String, dynamic> map, String id) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    DateTime? parseNullableDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    return BorrowRequestModel(
      requestId: id.isNotEmpty ? id : (map['requestId'] ?? ''),
      listingId: map['listingId'] ?? map['equipmentId'] ?? '',
      listingTitle: map['listingTitle'] ?? map['equipmentName'] ?? '',
      listingImage: map['listingImage'] ?? map['imageUrl'] ?? '',
      category: map['category'] ?? '',
      ownerId: map['ownerId'] ?? '',
      borrowerId: map['borrowerId'] ?? map['userId'] ?? '',
      borrowerName: map['borrowerName'] ?? map['userName'] ?? 'Borrower',
      borrowFrom: parseDate(map['borrowFrom'] ?? map['startDate']),
      borrowUntil: parseDate(map['borrowUntil'] ?? map['endDate']),
      borrowDuration: (map['borrowDuration'] as num?)?.toInt() ?? 1,
      status: map['status'] != null
          ? _capitalizeStatus(map['status'].toString())
          : 'Requested',
      requestedAt: parseDate(map['requestedAt'] ?? map['createdAt']),
      updatedAt: parseDate(map['updatedAt'] ?? map['createdAt']),
      borrowedAt: parseNullableDate(map['borrowedAt'] ?? map['borrowStartDate']),
    );
  }

  factory BorrowRequestModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    return BorrowRequestModel.fromMap(doc.data() ?? {}, doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'requestId': requestId,
      'listingId': listingId,
      'listingTitle': listingTitle,
      'listingImage': listingImage,
      'category': category,
      'ownerId': ownerId,
      'borrowerId': borrowerId,
      'borrowerName': borrowerName,
      'borrowFrom': Timestamp.fromDate(borrowFrom),
      'borrowUntil': Timestamp.fromDate(borrowUntil),
      'borrowDuration': borrowDuration,
      'status': status,
      'requestedAt': Timestamp.fromDate(requestedAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      if (borrowedAt != null) 'borrowedAt': Timestamp.fromDate(borrowedAt!),
    };
  }

  BorrowRequestModel copyWith({
    String? status,
    DateTime? updatedAt,
    DateTime? borrowedAt,
  }) {
    return BorrowRequestModel(
      requestId: requestId,
      listingId: listingId,
      listingTitle: listingTitle,
      listingImage: listingImage,
      category: category,
      ownerId: ownerId,
      borrowerId: borrowerId,
      borrowerName: borrowerName,
      borrowFrom: borrowFrom,
      borrowUntil: borrowUntil,
      borrowDuration: borrowDuration,
      status: status ?? this.status,
      requestedAt: requestedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      borrowedAt: borrowedAt ?? this.borrowedAt,
    );
  }

  static String _capitalizeStatus(String rawStatus) {
    final s = rawStatus.trim().toLowerCase();
    if (s == 'requested' || s == 'pending') return 'Requested';
    if (s == 'accepted' || s == 'approved' || s == 'confirmed') return 'Accepted';
    if (s == 'borrowed' || s == 'picked up') return 'Borrowed';
    if (s == 'declined' || s == 'rejected') return 'Declined';
    if (s == 'cancelled' || s == 'canceled') return 'Cancelled';
    if (s == 'completed' || s == 'returned') return 'Completed';
    return 'Requested';
  }
}
