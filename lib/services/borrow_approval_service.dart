import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/borrow_request_model.dart';

class BorrowApprovalService {
  BorrowApprovalService._();
  static final BorrowApprovalService instance = BorrowApprovalService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Track session-dismissed request IDs in memory
  final Set<String> _dismissedRequestIdsInSession = {};

  /// Stream approved borrow requests for currentUser where status is "Approved" or "Accepted"
  /// and popup has not been dismissed in the current app session.
  Stream<BorrowRequestModel?> watchApprovedRequest(String uid) {
    if (uid.isEmpty) return Stream.value(null);

    return _firestore
        .collection('borrow_requests')
        .snapshots()
        .map((snapshot) {
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final requestedBy = (data['requestedBy'] ?? data['studentUid'] ?? data['borrowerId'] ?? data['userId'] ?? '').toString();
        final status = (data['status'] ?? '').toString().trim().toLowerCase();

        final isUser = requestedBy == uid;
        final isApproved = status == 'approved' || status == 'accepted' || status == 'confirmed';

        if (isUser && isApproved) {
          final request = BorrowRequestModel.fromMap(data, doc.id);
          // Check if dismissed in this app session
          if (!_dismissedRequestIdsInSession.contains(request.requestId)) {
            return request;
          }
        }
      }
      return null;
    });
  }

  void dismissForSession(String requestId) {
    if (requestId.isNotEmpty) {
      _dismissedRequestIdsInSession.add(requestId);
    }
  }

  bool isDismissed(String requestId) {
    return _dismissedRequestIdsInSession.contains(requestId);
  }
}
