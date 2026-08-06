import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/library_activity_model.dart';

class LibraryActivityService {
  LibraryActivityService._();
  static final LibraryActivityService instance = LibraryActivityService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Unified realtime stream of library activities for a student UID.
  /// Listens to single stream per collection and merges in-memory sorted by timestamp descending (newest first).
  Stream<List<LibraryActivityModel>> watchStudentActivities(String uid) {
    if (uid.isEmpty) return Stream.value([]);

    late StreamController<List<LibraryActivityModel>> controller;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? reqSub;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? txSub;

    QuerySnapshot<Map<String, dynamic>>? latestReqSnap;
    QuerySnapshot<Map<String, dynamic>>? latestTxSnap;

    void notify() {
      try {
        final list = _mergeActivities(
          uid: uid,
          reqSnap: latestReqSnap,
          txSnap: latestTxSnap,
        );
        if (!controller.isClosed) controller.add(list);
      } catch (e) {
        if (!controller.isClosed) controller.addError(e);
      }
    }

    controller = StreamController<List<LibraryActivityModel>>.broadcast(
      onListen: () {
        reqSub = _firestore.collection('borrow_requests').snapshots().listen(
          (snap) {
            latestReqSnap = snap;
            notify();
          },
          onError: (err) {
            if (!controller.isClosed) controller.addError(err);
          },
        );

        txSub = _firestore.collection('transactions').snapshots().listen(
          (snap) {
            latestTxSnap = snap;
            notify();
          },
          onError: (err) {
            if (!controller.isClosed) controller.addError(err);
          },
        );
      },
      onCancel: () {
        reqSub?.cancel();
        txSub?.cancel();
      },
    );

    return controller.stream;
  }

  List<LibraryActivityModel> _mergeActivities({
    required String uid,
    QuerySnapshot<Map<String, dynamic>>? reqSnap,
    QuerySnapshot<Map<String, dynamic>>? txSnap,
  }) {
    final List<LibraryActivityModel> activities = [];
    final Set<String> activeIssuedBookIds = {};

    // 1. Process transactions (Issued & Returned books)
    if (txSnap != null) {
      for (final doc in txSnap.docs) {
        final data = doc.data();
        final studentUid = (data['studentUid'] ?? data['borrowerId'] ?? data['userId'] ?? '').toString();
        if (studentUid != uid) continue;

        final model = LibraryActivityModel.fromTransactionDoc(doc);
        if (model.activityType == LibraryActivityType.issuedBook) {
          if (model.bookId.isNotEmpty) activeIssuedBookIds.add(model.bookId);
        }
        activities.add(model);
      }
    }

    // 2. Process borrow requests (Pending, Approved, Rejected, Cancelled)
    if (reqSnap != null) {
      for (final doc in reqSnap.docs) {
        final data = doc.data();
        final studentUid = (data['requestedBy'] ?? data['studentUid'] ?? data['borrowerId'] ?? data['userId'] ?? '').toString();
        if (studentUid != uid) continue;

        final model = LibraryActivityModel.fromRequestDoc(doc);
        // Avoid duplicate entries if an approved request has already transitioned to an issued transaction
        if (model.activityType == LibraryActivityType.approvedRequest && activeIssuedBookIds.contains(model.bookId)) {
          continue;
        }
        activities.add(model);
      }
    }

    // Sort by updatedAt / timestamp descending (newest first)
    activities.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return activities;
  }
}
