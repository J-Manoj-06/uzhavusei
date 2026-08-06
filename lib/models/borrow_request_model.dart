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

  // Student Profile details (Phase 3)
  final String studentUid;
  final String studentName;
  final String registerNumber;
  final String department;
  final String year;
  final String collegeEmail;
  final String phone;
  final String photoUrl;
  final String requestMessage;

  // Aliases for dashboard compatibility
  String get bookId => listingId;
  String get bookTitle => listingTitle;
  String get bookCover => listingImage;
  String get requestedBy => borrowerId;

  BorrowRequestModel({
    required this.requestId,
    required this.listingId,
    required this.listingTitle,
    required this.listingImage,
    required this.category,
    required this.ownerId,
    required this.borrowerId,
    this.borrowerName = 'Student',
    required this.borrowFrom,
    required this.borrowUntil,
    required this.borrowDuration,
    this.status = 'Requested',
    required this.requestedAt,
    required this.updatedAt,
    this.borrowedAt,
    String? studentUid,
    String? studentName,
    this.registerNumber = '',
    this.department = '',
    this.year = '',
    this.collegeEmail = '',
    this.phone = '',
    this.photoUrl = '',
    this.requestMessage = '',
  })  : studentUid = studentUid ?? borrowerId,
        studentName = studentName ?? borrowerName;

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

    final bId = (map['studentUid'] ?? map['requestedBy'] ?? map['borrowerId'] ?? map['userId'] ?? '').toString();
    final bName = (map['studentName'] ?? map['fullName'] ?? map['borrowerName'] ?? map['userName'] ?? 'Student').toString();

    return BorrowRequestModel(
      requestId: id.isNotEmpty ? id : (map['requestId'] ?? '').toString(),
      listingId: (map['bookId'] ?? map['listingId'] ?? map['equipmentId'] ?? '').toString(),
      listingTitle: (map['bookTitle'] ?? map['listingTitle'] ?? map['equipmentName'] ?? '').toString(),
      listingImage: (map['bookCover'] ?? map['listingImage'] ?? map['imageUrl'] ?? '').toString(),
      category: (map['category'] ?? '').toString(),
      ownerId: (map['ownerId'] ?? '').toString(),
      borrowerId: bId,
      borrowerName: bName,
      borrowFrom: parseDate(map['borrowFrom'] ?? map['startDate']),
      borrowUntil: parseDate(map['borrowUntil'] ?? map['endDate']),
      borrowDuration: (map['borrowDuration'] as num?)?.toInt() ?? 1,
      status: map['status'] != null
          ? _capitalizeStatus(map['status'].toString())
          : 'Requested',
      requestedAt: parseDate(map['requestedAt'] ?? map['createdAt']),
      updatedAt: parseDate(map['updatedAt'] ?? map['createdAt']),
      borrowedAt: parseNullableDate(map['borrowedAt'] ?? map['borrowStartDate']),
      studentUid: bId,
      studentName: bName,
      registerNumber: (map['registerNumber'] ?? map['regNo'] ?? '').toString(),
      department: (map['department'] ?? '').toString(),
      year: (map['year'] ?? '').toString(),
      collegeEmail: (map['collegeEmail'] ?? map['email'] ?? '').toString(),
      phone: (map['phone'] ?? map['phoneNumber'] ?? '').toString(),
      photoUrl: (map['photoUrl'] ?? map['profileImage'] ?? '').toString(),
      requestMessage: (map['requestMessage'] ?? map['note'] ?? '').toString(),
    );
  }

  factory BorrowRequestModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    return BorrowRequestModel.fromMap(doc.data() ?? {}, doc.id);
  }

  Map<String, dynamic> toMap() {
    final sName = studentName.isNotEmpty ? studentName : borrowerName;
    return {
      'requestId': requestId,
      'bookId': listingId,
      'listingId': listingId,
      'bookTitle': listingTitle,
      'listingTitle': listingTitle,
      'bookCover': listingImage,
      'listingImage': listingImage,
      'category': category,
      'ownerId': ownerId,
      'requestedBy': borrowerId,
      'studentUid': borrowerId,
      'borrowerId': borrowerId,
      'studentName': sName,
      'borrowerName': sName,
      'fullName': sName,
      'registerNumber': registerNumber,
      'department': department,
      'year': year,
      'collegeEmail': collegeEmail,
      'phone': phone,
      'phoneNumber': phone,
      'photoUrl': photoUrl,
      'profileImage': photoUrl,
      'requestMessage': requestMessage,
      'borrowFrom': Timestamp.fromDate(borrowFrom),
      'borrowUntil': Timestamp.fromDate(borrowUntil),
      'borrowDuration': borrowDuration,
      'status': status,
      'requestedAt': Timestamp.fromDate(requestedAt),
      'createdAt': Timestamp.fromDate(requestedAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      if (borrowedAt != null) 'borrowedAt': Timestamp.fromDate(borrowedAt!),
    };
  }

  BorrowRequestModel copyWith({
    String? status,
    DateTime? updatedAt,
    DateTime? borrowedAt,
    String? registerNumber,
    String? department,
    String? year,
    String? collegeEmail,
    String? phone,
    String? photoUrl,
    String? requestMessage,
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
      studentUid: studentUid,
      studentName: studentName,
      registerNumber: registerNumber ?? this.registerNumber,
      department: department ?? this.department,
      year: year ?? this.year,
      collegeEmail: collegeEmail ?? this.collegeEmail,
      phone: phone ?? this.phone,
      photoUrl: photoUrl ?? this.photoUrl,
      requestMessage: requestMessage ?? this.requestMessage,
    );
  }

  int get daysRemaining {
    final diff = borrowUntil.difference(DateTime.now()).inDays;
    return diff < 0 ? 0 : diff;
  }

  static String _capitalizeStatus(String rawStatus) {
    final s = rawStatus.trim().toLowerCase();
    if (s == 'requested' || s == 'pending') return 'Requested';
    if (s == 'accepted' || s == 'approved' || s == 'confirmed') return 'Accepted';
    if (s == 'borrowed' || s == 'issued' || s == 'picked up') return 'Borrowed';
    if (s == 'reserved') return 'Reserved';
    if (s == 'overdue') return 'Overdue';
    if (s == 'declined' || s == 'rejected') return 'Declined';
    if (s == 'cancelled' || s == 'canceled') return 'Cancelled';
    if (s == 'completed' || s == 'returned') return 'Completed';
    return 'Requested';
  }
}
