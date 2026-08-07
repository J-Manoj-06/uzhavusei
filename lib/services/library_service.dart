import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/library_activity_model.dart';
import '../repositories/library_repository.dart';

class LibraryService {
  LibraryService._();
  static final LibraryService instance = LibraryService._();

  final LibraryRepository _repository = LibraryRepository.instance;

  /// Unified realtime activity stream for student UID combining borrow_requests and transactions
  Stream<List<LibraryActivityModel>> watchStudentLibraryActivities(String uid) {
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
        reqSub = _repository.watchBorrowRequests().listen(
          (snap) {
            latestReqSnap = snap;
            notify();
          },
          onError: (err) {
            if (!controller.isClosed) controller.addError(err);
          },
        );

        txSub = _repository.watchTransactions().listen(
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
    final Set<String> processedRequestIds = {};
    final Set<String> processedBookIds = {};

    // 1. Process transactions first (Borrowed & Returned) - Highest authority for active borrowings & returns
    if (txSnap != null) {
      for (final doc in txSnap.docs) {
        final data = doc.data();
        final studentUid = (data['studentUid'] ?? data['borrowerId'] ?? data['userId'] ?? '').toString();
        if (studentUid != uid) continue;

        final model = LibraryActivityModel.fromTransactionDoc(doc);
        if (model.requestId.isNotEmpty) processedRequestIds.add(model.requestId);
        if (model.bookId.isNotEmpty && model.status == LibraryActivityStatus.borrowed) {
          processedBookIds.add(model.bookId);
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

        // SYNC RULE: If a transaction already exists for this requestId or doc.id, skip borrow_request
        if (processedRequestIds.contains(doc.id) || (data['requestId'] != null && processedRequestIds.contains(data['requestId'].toString()))) {
          continue;
        }

        final model = LibraryActivityModel.fromBorrowRequestDoc(doc);

        // SYNC RULE: If an active borrowed transaction exists for this bookId, hide duplicate approved/pending request
        if (processedBookIds.contains(model.bookId) && (model.status == LibraryActivityStatus.approved || model.status == LibraryActivityStatus.pending)) {
          continue;
        }

        activities.add(model);
      }
    }

    // Default sorting: Newest First by updatedAt
    activities.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return activities;
  }

  /// Realtime stream of student's active Approved request (waiting for collection)
  Stream<LibraryActivityModel?> watchActiveApprovedRequest(String uid) {
    return watchStudentLibraryActivities(uid).map((list) {
      return list.cast<LibraryActivityModel?>().firstWhere(
        (item) => item?.status == LibraryActivityStatus.approved,
        orElse: () => null,
      );
    });
  }

  /// Realtime stream of student's active Borrowed book
  Stream<LibraryActivityModel?> watchActiveBorrowedBook(String uid) {
    return watchStudentLibraryActivities(uid).map((list) {
      return list.cast<LibraryActivityModel?>().firstWhere(
        (item) => item?.status == LibraryActivityStatus.borrowed,
        orElse: () => null,
      );
    });
  }
}
