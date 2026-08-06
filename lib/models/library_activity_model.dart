import 'package:cloud_firestore/cloud_firestore.dart';

enum LibraryActivityType {
  pendingRequest,
  approvedRequest,
  issuedBook,
  returnedBook,
  rejectedRequest,
  cancelledRequest,
}

class LibraryActivityModel {
  final String id;
  final String bookId;
  final String bookTitle;
  final String bookCover;
  final String author;
  final LibraryActivityType activityType;
  final String statusLabel;
  final String stageMessage;
  final DateTime timestamp;
  final DateTime? dueDate;
  final DateTime? borrowedDate;
  final DateTime? returnedDate;
  final int daysRemaining;
  final Map<String, dynamic> rawData;

  LibraryActivityModel({
    required this.id,
    required this.bookId,
    required this.bookTitle,
    required this.bookCover,
    required this.author,
    required this.activityType,
    required this.statusLabel,
    required this.stageMessage,
    required this.timestamp,
    this.dueDate,
    this.borrowedDate,
    this.returnedDate,
    this.daysRemaining = 0,
    required this.rawData,
  });

  factory LibraryActivityModel.fromRequestDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final statusStr = (data['status'] ?? '').toString().trim().toLowerCase();
    final bookId = (data['bookId'] ?? data['listingId'] ?? '').toString();
    final title = (data['bookTitle'] ?? data['listingTitle'] ?? 'Library Request').toString();
    final cover = (data['bookCover'] ?? data['listingImage'] ?? '').toString();
    final author = (data['author'] ?? 'College Library').toString();

    DateTime time = DateTime.now();
    final tsVal = data['updatedAt'] ?? data['requestedAt'] ?? data['createdAt'];
    if (tsVal is Timestamp) time = tsVal.toDate();

    LibraryActivityType type = LibraryActivityType.pendingRequest;
    String label = 'Pending';
    String stage = 'Pending Approval';

    if (statusStr == 'approved' || statusStr == 'accepted' || statusStr == 'confirmed') {
      type = LibraryActivityType.approvedRequest;
      label = 'Approved';
      stage = 'Approved - Ready for Collection';
    } else if (statusStr == 'rejected' || statusStr == 'declined') {
      type = LibraryActivityType.rejectedRequest;
      label = 'Rejected';
      stage = 'Request Rejected';
    } else if (statusStr == 'cancelled') {
      type = LibraryActivityType.cancelledRequest;
      label = 'Cancelled';
      stage = 'Cancelled';
    }

    return LibraryActivityModel(
      id: doc.id,
      bookId: bookId,
      bookTitle: title,
      bookCover: cover,
      author: author,
      activityType: type,
      statusLabel: label,
      stageMessage: stage,
      timestamp: time,
      rawData: data,
    );
  }

  factory LibraryActivityModel.fromTransactionDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final statusStr = (data['status'] ?? '').toString().trim().toLowerCase();
    final returnedAt = data['returnedAt'];
    final bookId = (data['bookId'] ?? data['listingId'] ?? '').toString();
    final title = (data['bookTitle'] ?? data['listingTitle'] ?? data['equipmentName'] ?? 'Library Book').toString();
    final cover = (data['bookCover'] ?? data['listingImage'] ?? data['imageUrl'] ?? '').toString();
    final author = (data['author'] ?? 'College Library').toString();

    DateTime time = DateTime.now();
    final tsVal = returnedAt ?? data['updatedAt'] ?? data['borrowedAt'] ?? data['issueDate'] ?? data['createdAt'];
    if (tsVal is Timestamp) time = tsVal.toDate();

    DateTime? borrowedDate;
    final bVal = data['borrowedAt'] ?? data['issueDate'] ?? data['createdAt'];
    if (bVal is Timestamp) borrowedDate = bVal.toDate();

    DateTime? returnedDate;
    if (returnedAt is Timestamp) returnedDate = returnedAt.toDate();

    DateTime? dueDate;
    if (data['dueDate'] is Timestamp) {
      dueDate = (data['dueDate'] as Timestamp).toDate();
    } else if (data['borrowUntil'] is Timestamp) {
      dueDate = (data['borrowUntil'] as Timestamp).toDate();
    }

    int daysRemaining = 0;
    if (dueDate != null) {
      final diff = dueDate.difference(DateTime.now()).inDays;
      daysRemaining = diff < 0 ? 0 : diff;
    }

    final isIssued = (statusStr == 'issued' || statusStr == 'borrowed') && returnedAt == null;

    final type = isIssued ? LibraryActivityType.issuedBook : LibraryActivityType.returnedBook;
    final label = isIssued ? 'Issued' : 'Returned';
    final stage = isIssued ? 'Currently Borrowed' : 'Returned';

    return LibraryActivityModel(
      id: doc.id,
      bookId: bookId,
      bookTitle: title,
      bookCover: cover,
      author: author,
      activityType: type,
      statusLabel: label,
      stageMessage: stage,
      timestamp: time,
      dueDate: dueDate,
      borrowedDate: borrowedDate,
      returnedDate: returnedDate,
      daysRemaining: daysRemaining,
      rawData: data,
    );
  }
}
