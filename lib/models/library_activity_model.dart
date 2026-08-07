import 'package:cloud_firestore/cloud_firestore.dart';

enum LibraryActivityStatus {
  pending,
  approved,
  borrowed,
  returned,
  rejected,
  cancelled,
}

class LibraryStatusInfo {
  final LibraryActivityStatus status;
  final String label;
  final String stageMessage;
  final String badgeColorHex;

  const LibraryStatusInfo({
    required this.status,
    required this.label,
    required this.stageMessage,
    required this.badgeColorHex,
  });
}

/// Single source of truth function for converting Firestore document fields to LibraryStatusInfo
LibraryStatusInfo getCurrentLibraryStatus(Map<String, dynamic> data) {
  final statusStr = (data['status'] ?? '').toString().trim().toLowerCase();
  final returnedAt = data['returnedAt'];
  final approvedAt = data['approvedAt'] ?? data['acceptedAt'];
  final issuedAt = data['borrowedAt'] ?? data['issueDate'] ?? data['issuedAt'];

  if (statusStr == 'returned' || statusStr == 'completed' || returnedAt != null) {
    return const LibraryStatusInfo(
      status: LibraryActivityStatus.returned,
      label: 'Returned',
      stageMessage: 'Returned',
      badgeColorHex: '475569',
    );
  }

  if (statusStr == 'issued' || statusStr == 'borrowed' || (issuedAt != null && returnedAt == null)) {
    return const LibraryStatusInfo(
      status: LibraryActivityStatus.borrowed,
      label: 'Borrowed',
      stageMessage: 'Currently Borrowed',
      badgeColorHex: '15803D',
    );
  }

  if (statusStr == 'approved' || statusStr == 'accepted' || statusStr == 'confirmed' || (approvedAt != null && statusStr != 'rejected' && statusStr != 'cancelled')) {
    return const LibraryStatusInfo(
      status: LibraryActivityStatus.approved,
      label: 'Approved',
      stageMessage: 'Ready for Collection',
      badgeColorHex: '1D4ED8',
    );
  }

  if (statusStr == 'rejected' || statusStr == 'declined') {
    final reason = (data['rejectionReason'] ?? data['reason'] ?? '').toString().trim();
    return LibraryStatusInfo(
      status: LibraryActivityStatus.rejected,
      label: 'Rejected',
      stageMessage: reason.isNotEmpty ? 'Rejected: $reason' : 'Request Rejected',
      badgeColorHex: 'DC2626',
    );
  }

  if (statusStr == 'cancelled') {
    return const LibraryStatusInfo(
      status: LibraryActivityStatus.cancelled,
      label: 'Cancelled',
      stageMessage: 'Cancelled',
      badgeColorHex: '334155',
    );
  }

  return const LibraryStatusInfo(
    status: LibraryActivityStatus.pending,
    label: 'Pending',
    stageMessage: 'Waiting for librarian approval',
    badgeColorHex: 'C2410C',
  );
}

class LibraryActivityModel {
  final String id;
  final String requestId;
  final String? transactionId;
  final String bookId;
  final String studentUid;
  final String bookTitle;
  final String bookCover;
  final String author;
  final LibraryActivityStatus status;
  final String statusLabel;
  final String stageMessage;
  final DateTime requestDate;
  final DateTime? approvalDate;
  final DateTime? issueDate;
  final DateTime? returnDate;
  final DateTime? dueDate;
  final int daysRemaining;
  final int totalDurationDays;
  final DateTime updatedAt;
  final Map<String, dynamic> rawData;

  const LibraryActivityModel({
    required this.id,
    required this.requestId,
    this.transactionId,
    required this.bookId,
    required this.studentUid,
    required this.bookTitle,
    required this.bookCover,
    required this.author,
    required this.status,
    required this.statusLabel,
    required this.stageMessage,
    required this.requestDate,
    this.approvalDate,
    this.issueDate,
    this.returnDate,
    this.dueDate,
    this.daysRemaining = 0,
    this.totalDurationDays = 0,
    required this.updatedAt,
    required this.rawData,
  });

  factory LibraryActivityModel.fromBorrowRequestDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    final docId = doc.id;
    final statusInfo = getCurrentLibraryStatus(data);

    final bookId = (data['bookId'] ?? data['listingId'] ?? '').toString();
    final studentUid = (data['requestedBy'] ?? data['studentUid'] ?? data['borrowerId'] ?? data['userId'] ?? '').toString();
    final bookTitle = (data['bookTitle'] ?? data['listingTitle'] ?? data['equipmentName'] ?? 'Library Book').toString();
    final bookCover = (data['bookCover'] ?? data['listingImage'] ?? data['imageUrl'] ?? '').toString();
    final author = (data['author'] ?? 'College Library').toString();

    DateTime requestDate = DateTime.now();
    final rVal = data['requestedAt'] ?? data['createdAt'];
    if (rVal is Timestamp) requestDate = rVal.toDate();

    DateTime updatedAt = requestDate;
    final uVal = data['updatedAt'] ?? data['approvedAt'];
    if (uVal is Timestamp) updatedAt = uVal.toDate();

    DateTime? approvalDate;
    final aVal = data['approvedAt'] ?? data['acceptedAt'];
    if (aVal is Timestamp) approvalDate = aVal.toDate();

    return LibraryActivityModel(
      id: docId,
      requestId: docId,
      bookId: bookId,
      studentUid: studentUid,
      bookTitle: bookTitle,
      bookCover: bookCover,
      author: author,
      status: statusInfo.status,
      statusLabel: statusInfo.label,
      stageMessage: statusInfo.stageMessage,
      requestDate: requestDate,
      approvalDate: approvalDate,
      updatedAt: updatedAt,
      rawData: data,
    );
  }

  factory LibraryActivityModel.fromTransactionDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    final txId = doc.id;
    final statusInfo = getCurrentLibraryStatus(data);
    final returnedAt = data['returnedAt'];

    final reqId = (data['requestId'] ?? txId).toString();
    final bookId = (data['bookId'] ?? data['listingId'] ?? '').toString();
    final studentUid = (data['studentUid'] ?? data['borrowerId'] ?? data['userId'] ?? '').toString();
    final bookTitle = (data['bookTitle'] ?? data['listingTitle'] ?? data['equipmentName'] ?? 'Library Book').toString();
    final bookCover = (data['bookCover'] ?? data['listingImage'] ?? data['imageUrl'] ?? '').toString();
    final author = (data['author'] ?? 'College Library').toString();

    DateTime issueDate = DateTime.now();
    final iVal = data['borrowedAt'] ?? data['issueDate'] ?? data['createdAt'];
    if (iVal is Timestamp) issueDate = iVal.toDate();

    DateTime? returnDate;
    if (returnedAt is Timestamp) returnDate = returnedAt.toDate();

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

    int totalDurationDays = 0;
    if (returnDate != null) {
      final diff = returnDate.difference(issueDate).inDays;
      totalDurationDays = diff <= 0 ? 1 : diff;
    }

    DateTime updatedAt = issueDate;
    final uVal = returnedAt ?? data['updatedAt'];
    if (uVal is Timestamp) updatedAt = uVal.toDate();

    return LibraryActivityModel(
      id: txId,
      requestId: reqId,
      transactionId: txId,
      bookId: bookId,
      studentUid: studentUid,
      bookTitle: bookTitle,
      bookCover: bookCover,
      author: author,
      status: statusInfo.status,
      statusLabel: statusInfo.label,
      stageMessage: statusInfo.stageMessage,
      requestDate: issueDate,
      issueDate: issueDate,
      returnDate: returnDate,
      dueDate: dueDate,
      daysRemaining: daysRemaining,
      totalDurationDays: totalDurationDays,
      updatedAt: updatedAt,
      rawData: data,
    );
  }
}
