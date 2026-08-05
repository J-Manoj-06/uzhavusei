import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/borrow_request_model.dart';

class CirculationNotificationService {
  CirculationNotificationService._({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  static final CirculationNotificationService instance = CirculationNotificationService._();
  final FirebaseFirestore _firestore;

  /// Realtime stream emitting status notification events for a student borrower.
  Stream<String> watchCirculationAlerts(String studentId) {
    if (studentId.isEmpty) return const Stream.empty();

    return _firestore
        .collection('borrow_requests')
        .where('borrowerId', isEqualTo: studentId)
        .snapshots()
        .map((snapshot) {
      for (final doc in snapshot.docChanges) {
        if (doc.type == DocumentChangeType.modified) {
          final req = BorrowRequestModel.fromDoc(doc.doc);
          final s = req.status;
          if (s == 'Accepted') {
            return 'Your borrow request for "${req.listingTitle}" was APPROVED by the librarian!';
          } else if (s == 'Declined') {
            return 'Your request for "${req.listingTitle}" was declined.';
          } else if (s == 'Borrowed') {
            return '"${req.listingTitle}" has been issued to you. Due in ${req.daysRemaining} days.';
          } else if (s == 'Overdue') {
            return 'ATTENTION: Your loan for "${req.listingTitle}" is OVERDUE!';
          }
        }
      }
      return '';
    }).where((msg) => msg.isNotEmpty);
  }
}
