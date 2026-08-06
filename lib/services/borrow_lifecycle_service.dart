import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/borrow_request_model.dart';

enum BorrowRestrictionType {
  none,
  pendingRequest,
  approvedRequest,
  issuedBook,
}

class BorrowLifecycleState {
  final bool isEligible;
  final BorrowRestrictionType restrictionType;
  final String restrictionReason;
  final BorrowRequestModel? activeRequest;
  final Map<String, dynamic>? activeTransaction;
  final Map<String, dynamic>? lastReturnedTransaction;

  const BorrowLifecycleState({
    required this.isEligible,
    this.restrictionType = BorrowRestrictionType.none,
    this.restrictionReason = '',
    this.activeRequest,
    this.activeTransaction,
    this.lastReturnedTransaction,
  });

  factory BorrowLifecycleState.eligible() {
    return const BorrowLifecycleState(isEligible: true);
  }
}

class BorrowLifecycleService {
  BorrowLifecycleService._();
  static final BorrowLifecycleService instance = BorrowLifecycleService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Stream evaluating student borrowing lifecycle strictly from Firestore
  Stream<BorrowLifecycleState> watchStudentLifecycle(String uid) {
    if (uid.isEmpty) return Stream.value(BorrowLifecycleState.eligible());

    return _firestore.collection('borrow_requests').snapshots().asyncMap((reqSnap) async {
      BorrowRequestModel? pendingReq;
      BorrowRequestModel? approvedReq;

      for (final doc in reqSnap.docs) {
        final data = doc.data();
        final studentUid = (data['requestedBy'] ?? data['studentUid'] ?? data['borrowerId'] ?? data['userId'] ?? '').toString();
        final status = (data['status'] ?? '').toString().trim().toLowerCase();

        if (studentUid == uid) {
          if (status == 'pending' || status == 'requested') {
            pendingReq = BorrowRequestModel.fromMap(data, doc.id);
          } else if (status == 'approved' || status == 'accepted' || status == 'confirmed') {
            approvedReq = BorrowRequestModel.fromMap(data, doc.id);
          }
        }
      }

      // Check active and returned transactions in Firestore
      final txSnap = await _firestore.collection('transactions').get();
      Map<String, dynamic>? activeTx;
      Map<String, dynamic>? recentlyReturnedTx;

      final userTxs = txSnap.docs.map((doc) => {'id': doc.id, ...doc.data()}).where((data) {
        final studentUid = (data['studentUid'] ?? data['borrowerId'] ?? data['userId'] ?? '').toString();
        return studentUid == uid;
      }).toList();

      for (final data in userTxs) {
        final status = (data['status'] ?? '').toString().trim().toLowerCase();
        final returnedAt = data['returnedAt'];

        if ((status == 'issued' || status == 'borrowed') && returnedAt == null) {
          activeTx = data;
          break;
        } else if (returnedAt != null || status == 'returned' || status == 'completed') {
          recentlyReturnedTx ??= data;
        }
      }

      // Single active book restriction enforcement
      if (activeTx != null) {
        return BorrowLifecycleState(
          isEligible: false,
          restrictionType: BorrowRestrictionType.issuedBook,
          restrictionReason: 'You currently have an active borrowed library book.',
          activeTransaction: activeTx,
          lastReturnedTransaction: recentlyReturnedTx,
        );
      }

      if (approvedReq != null) {
        return BorrowLifecycleState(
          isEligible: false,
          restrictionType: BorrowRestrictionType.approvedRequest,
          restrictionReason: 'You have an approved request ready for collection at the library.',
          activeRequest: approvedReq,
          lastReturnedTransaction: recentlyReturnedTx,
        );
      }

      if (pendingReq != null) {
        return BorrowLifecycleState(
          isEligible: false,
          restrictionType: BorrowRestrictionType.pendingRequest,
          restrictionReason: 'You already have a pending borrow request awaiting approval.',
          activeRequest: pendingReq,
          lastReturnedTransaction: recentlyReturnedTx,
        );
      }

      return BorrowLifecycleState(
        isEligible: true,
        lastReturnedTransaction: recentlyReturnedTx,
      );
    });
  }
}
