import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/borrow_request_model.dart';

class BorrowStatusState {
  final BorrowRequestModel? approvedRequest;
  final Map<String, dynamic>? activeTransaction;
  final bool hasApprovedRequest;
  final bool hasActiveTransaction;

  const BorrowStatusState({
    this.approvedRequest,
    this.activeTransaction,
    this.hasApprovedRequest = false,
    this.hasActiveTransaction = false,
  });
}

class BorrowStatusService {
  BorrowStatusService._();
  static final BorrowStatusService instance = BorrowStatusService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Realtime stream watching approved requests and active transactions for currentUser
  Stream<BorrowStatusState> watchBorrowStatus(String uid) {
    if (uid.isEmpty) return Stream.value(const BorrowStatusState());

    return _firestore.collection('borrow_requests').snapshots().asyncMap((reqSnap) async {
      BorrowRequestModel? approvedReq;

      for (final doc in reqSnap.docs) {
        final data = doc.data();
        final studentUid = (data['requestedBy'] ?? data['studentUid'] ?? data['borrowerId'] ?? data['userId'] ?? '').toString();
        final status = (data['status'] ?? '').toString().trim().toLowerCase();

        if (studentUid == uid && (status == 'approved' || status == 'accepted' || status == 'confirmed')) {
          approvedReq = BorrowRequestModel.fromMap(data, doc.id);
          break;
        }
      }

      // Check active issued transactions in Firestore transactions collection
      final txSnap = await _firestore.collection('transactions').get();
      Map<String, dynamic>? activeTx;

      for (final doc in txSnap.docs) {
        final data = doc.data();
        final studentUid = (data['studentUid'] ?? data['borrowerId'] ?? data['userId'] ?? '').toString();
        final status = (data['status'] ?? '').toString().trim().toLowerCase();
        final returnedAt = data['returnedAt'];

        if (studentUid == uid && (status == 'issued' || status == 'borrowed') && returnedAt == null) {
          activeTx = {'id': doc.id, ...data};
          break;
        }
      }

      // If active issued transaction exists, request has been fulfilled/issued by librarian
      final hasTx = activeTx != null;
      final finalApprovedReq = hasTx ? null : approvedReq;

      return BorrowStatusState(
        approvedRequest: finalApprovedReq,
        activeTransaction: activeTx,
        hasApprovedRequest: finalApprovedReq != null,
        hasActiveTransaction: hasTx,
      );
    });
  }
}
