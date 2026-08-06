import 'package:cloud_firestore/cloud_firestore.dart';

class BorrowEligibilityState {
  final bool eligible;
  final String? activeBookTitle;
  final String? activeBookCover;
  final DateTime? dueDate;
  final String? transactionId;
  final String? bookId;
  final int daysRemaining;
  final String reason;
  final Map<String, dynamic>? activeTransactionData;

  const BorrowEligibilityState({
    required this.eligible,
    this.activeBookTitle,
    this.activeBookCover,
    this.dueDate,
    this.transactionId,
    this.bookId,
    this.daysRemaining = 0,
    this.reason = '',
    this.activeTransactionData,
  });

  factory BorrowEligibilityState.eligibleState() {
    return const BorrowEligibilityState(eligible: true);
  }

  factory BorrowEligibilityState.ineligible({
    required String transactionId,
    required String bookTitle,
    required String bookCover,
    required DateTime dueDate,
    required String bookId,
    String reason = 'You already have an active library request or borrowed book. Return or complete your current borrowing process before requesting another book.',
    Map<String, dynamic>? rawData,
  }) {
    final diff = dueDate.difference(DateTime.now()).inDays;
    return BorrowEligibilityState(
      eligible: false,
      transactionId: transactionId,
      activeBookTitle: bookTitle,
      activeBookCover: bookCover,
      dueDate: dueDate,
      bookId: bookId,
      daysRemaining: diff < 0 ? 0 : diff,
      reason: reason,
      activeTransactionData: rawData,
    );
  }
}

class BorrowEligibilityService {
  BorrowEligibilityService._();
  static final BorrowEligibilityService instance = BorrowEligibilityService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Async check: One Active Library Book Policy validation.
  /// Returns true ONLY if student has NO pending request, NO approved request, and NO issued transaction.
  Future<bool> canBorrowBooks(String uid) async {
    if (uid.isEmpty) return true;

    // 1. Check Pending or Approved requests
    final reqSnap = await _firestore.collection('borrow_requests').get();
    final hasActiveReq = reqSnap.docs.any((doc) {
      final data = doc.data();
      final studentUid = (data['requestedBy'] ?? data['studentUid'] ?? data['borrowerId'] ?? data['userId'] ?? '').toString();
      final status = (data['status'] ?? '').toString().trim().toLowerCase();

      final isUser = studentUid == uid;
      final isActive = status == 'pending' || status == 'requested' || status == 'approved' || status == 'accepted' || status == 'confirmed';
      return isUser && isActive;
    });

    if (hasActiveReq) return false;

    // 2. Check active issued transactions
    final txSnap = await _firestore.collection('transactions').get();
    final hasActiveTx = txSnap.docs.any((doc) {
      final data = doc.data();
      final studentUid = (data['studentUid'] ?? data['borrowerId'] ?? data['userId'] ?? '').toString();
      final status = (data['status'] ?? '').toString().trim().toLowerCase();
      final returnedAt = data['returnedAt'];

      final isUser = studentUid == uid;
      final isIssued = (status == 'issued' || status == 'borrowed') && returnedAt == null;
      return isUser && isIssued;
    });

    return !hasActiveTx;
  }

  /// Stream of boolean eligibility for a student UID.
  Stream<bool> watchCanBorrowBooks(String uid) {
    return watchEligibility(uid).map((state) => state.eligible);
  }

  /// Realtime stream of BorrowEligibilityState for a given student UID.
  /// Evaluates pending requests, approved requests, and active issued transactions.
  Stream<BorrowEligibilityState> watchEligibility(String uid) {
    if (uid.isEmpty) {
      return Stream.value(BorrowEligibilityState.eligibleState());
    }

    return _firestore.collection('borrow_requests').snapshots().asyncMap((reqSnap) async {
      // 1. Check for Pending or Approved borrow request
      for (final doc in reqSnap.docs) {
        final data = doc.data();
        final studentUid = (data['requestedBy'] ?? data['studentUid'] ?? data['borrowerId'] ?? data['userId'] ?? '').toString();
        final status = (data['status'] ?? '').toString().trim().toLowerCase();

        if (studentUid == uid) {
          if (status == 'pending' || status == 'requested' || status == 'approved' || status == 'accepted' || status == 'confirmed') {
            final title = (data['bookTitle'] ?? data['listingTitle'] ?? 'Book Request').toString();
            final cover = (data['bookCover'] ?? data['listingImage'] ?? '').toString();
            final bookId = (data['bookId'] ?? data['listingId'] ?? '').toString();
            return BorrowEligibilityState.ineligible(
              transactionId: doc.id,
              bookTitle: title,
              bookCover: cover,
              dueDate: DateTime.now().add(const Duration(days: 7)),
              bookId: bookId,
              reason: 'You already have an active library request or borrowed book. Return or complete your current borrowing process before requesting another book.',
              rawData: data,
            );
          }
        }
      }

      // 2. Check for active issued transaction
      final txSnap = await _firestore.collection('transactions').get();
      for (final doc in txSnap.docs) {
        final data = doc.data();
        final studentUid = (data['studentUid'] ?? data['borrowerId'] ?? data['userId'] ?? '').toString();
        final status = (data['status'] ?? '').toString().trim().toLowerCase();
        final returnedAt = data['returnedAt'];

        if (studentUid == uid && (status == 'issued' || status == 'borrowed') && returnedAt == null) {
          DateTime dueDate = DateTime.now().add(const Duration(days: 7));
          if (data['dueDate'] is Timestamp) {
            dueDate = (data['dueDate'] as Timestamp).toDate();
          } else if (data['borrowUntil'] is Timestamp) {
            dueDate = (data['borrowUntil'] as Timestamp).toDate();
          }

          final title = (data['bookTitle'] ?? data['listingTitle'] ?? 'Borrowed Book').toString();
          final cover = (data['bookCover'] ?? data['listingImage'] ?? '').toString();
          final bookId = (data['bookId'] ?? data['listingId'] ?? '').toString();

          return BorrowEligibilityState.ineligible(
            transactionId: doc.id,
            bookTitle: title,
            bookCover: cover,
            dueDate: dueDate,
            bookId: bookId,
            reason: 'You already have an active library request or borrowed book. Return or complete your current borrowing process before requesting another book.',
            rawData: data,
          );
        }
      }

      return BorrowEligibilityState.eligibleState();
    });
  }
}
