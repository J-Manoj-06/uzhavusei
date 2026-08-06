import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/borrow_request_model.dart';
import 'borrow_eligibility_service.dart';

enum LibraryActivityType {
  pending,
  approved,
  borrowed,
  returned,
  rejected,
  cancelled,
}

class LibraryActivityItem {
  final String id;
  final String bookId;
  final String title;
  final String cover;
  final String author;
  final LibraryActivityType type;
  final String statusLabel;
  final String stageMessage;
  final DateTime date;
  final DateTime? dueDate;
  final DateTime? returnedDate;
  final Map<String, dynamic> rawData;

  LibraryActivityItem({
    required this.id,
    required this.bookId,
    required this.title,
    required this.cover,
    required this.author,
    required this.type,
    required this.statusLabel,
    required this.stageMessage,
    required this.date,
    this.dueDate,
    this.returnedDate,
    required this.rawData,
  });
}

class LibraryService {
  LibraryService._();
  static final LibraryService instance = LibraryService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Stream of all unified library activities combining realtime borrow_requests and transactions
  Stream<List<LibraryActivityItem>> watchAllLibraryActivities(String uid) {
    if (uid.isEmpty) return Stream.value([]);

    late StreamController<List<LibraryActivityItem>> controller;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? reqSub;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? txSub;

    QuerySnapshot<Map<String, dynamic>>? latestReqSnap;
    QuerySnapshot<Map<String, dynamic>>? latestTxSnap;

    void update() {
      try {
        final items = _processLibraryActivitySnaps(
          uid: uid,
          reqSnap: latestReqSnap,
          txSnap: latestTxSnap,
        );
        if (!controller.isClosed) controller.add(items);
      } catch (e) {
        if (!controller.isClosed) controller.addError(e);
      }
    }

    controller = StreamController<List<LibraryActivityItem>>.broadcast(
      onListen: () {
        reqSub = _firestore.collection('borrow_requests').snapshots().listen(
          (snap) {
            latestReqSnap = snap;
            update();
          },
          onError: (err) {
            if (!controller.isClosed) controller.addError(err);
          },
        );

        txSub = _firestore.collection('transactions').snapshots().listen(
          (snap) {
            latestTxSnap = snap;
            update();
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

  List<LibraryActivityItem> _processLibraryActivitySnaps({
    required String uid,
    QuerySnapshot<Map<String, dynamic>>? reqSnap,
    QuerySnapshot<Map<String, dynamic>>? txSnap,
  }) {
    List<LibraryActivityItem> items = [];
    final activeTxBookIds = <String>{};

    // 1. Process transactions
    if (txSnap != null) {
      for (final doc in txSnap.docs) {
        final data = doc.data();
        final studentUid = (data['studentUid'] ?? data['borrowerId'] ?? data['userId'] ?? '').toString();
        if (studentUid != uid) continue;

        final statusStr = (data['status'] ?? '').toString().trim().toLowerCase();
        final returnedAt = data['returnedAt'];
        final bookId = (data['bookId'] ?? data['listingId'] ?? '').toString();

        final title = (data['bookTitle'] ?? data['listingTitle'] ?? data['equipmentName'] ?? 'Library Book').toString();
        final cover = (data['bookCover'] ?? data['listingImage'] ?? data['imageUrl'] ?? '').toString();
        final author = (data['author'] ?? 'College Library').toString();

        DateTime date = DateTime.now();
        final bVal = data['borrowedAt'] ?? data['issueDate'] ?? data['createdAt'];
        if (bVal is Timestamp) date = bVal.toDate();

        if ((statusStr == 'issued' || statusStr == 'borrowed') && returnedAt == null) {
          if (bookId.isNotEmpty) activeTxBookIds.add(bookId);
          DateTime? dueDate;
          if (data['dueDate'] is Timestamp) dueDate = (data['dueDate'] as Timestamp).toDate();
          items.add(LibraryActivityItem(
            id: doc.id,
            bookId: bookId,
            title: title,
            cover: cover,
            author: author,
            type: LibraryActivityType.borrowed,
            statusLabel: 'Borrowed',
            stageMessage: 'Currently Borrowed',
            date: date,
            dueDate: dueDate,
            rawData: data,
          ));
        } else if (returnedAt != null || statusStr == 'returned' || statusStr == 'completed') {
          DateTime? retDate;
          if (returnedAt is Timestamp) retDate = returnedAt.toDate();
          items.add(LibraryActivityItem(
            id: doc.id,
            bookId: bookId,
            title: title,
            cover: cover,
            author: author,
            type: LibraryActivityType.returned,
            statusLabel: 'Returned',
            stageMessage: 'Returned',
            date: date,
            returnedDate: retDate,
            rawData: data,
          ));
        }
      }
    }

    // 2. Process borrow requests
    if (reqSnap != null) {
      for (final doc in reqSnap.docs) {
        final data = doc.data();
        final studentUid = (data['requestedBy'] ?? data['studentUid'] ?? data['borrowerId'] ?? data['userId'] ?? '').toString();
        if (studentUid != uid) continue;

        final statusStr = (data['status'] ?? '').toString().trim().toLowerCase();
        final bookId = (data['bookId'] ?? data['listingId'] ?? '').toString();
        final title = (data['bookTitle'] ?? data['listingTitle'] ?? 'Library Request').toString();
        final cover = (data['bookCover'] ?? data['listingImage'] ?? '').toString();

        DateTime date = DateTime.now();
        final rVal = data['requestedAt'] ?? data['createdAt'] ?? data['updatedAt'];
        if (rVal is Timestamp) date = rVal.toDate();

        if (statusStr == 'pending' || statusStr == 'requested') {
          items.add(LibraryActivityItem(
            id: doc.id,
            bookId: bookId,
            title: title,
            cover: cover,
            author: 'College Library',
            type: LibraryActivityType.pending,
            statusLabel: 'Pending',
            stageMessage: 'Pending Approval',
            date: date,
            rawData: data,
          ));
        } else if (statusStr == 'approved' || statusStr == 'accepted' || statusStr == 'confirmed') {
          if (!activeTxBookIds.contains(bookId)) {
            items.add(LibraryActivityItem(
              id: doc.id,
              bookId: bookId,
              title: title,
              cover: cover,
              author: 'College Library',
              type: LibraryActivityType.approved,
              statusLabel: 'Approved',
              stageMessage: 'Approved - Ready for Collection',
              date: date,
              rawData: data,
            ));
          }
        } else if (statusStr == 'rejected' || statusStr == 'declined') {
          items.add(LibraryActivityItem(
            id: doc.id,
            bookId: bookId,
            title: title,
            cover: cover,
            author: 'College Library',
            type: LibraryActivityType.rejected,
            statusLabel: 'Rejected',
            stageMessage: 'Request Rejected',
            date: date,
            rawData: data,
          ));
        } else if (statusStr == 'cancelled') {
          items.add(LibraryActivityItem(
            id: doc.id,
            bookId: bookId,
            title: title,
            cover: cover,
            author: 'College Library',
            type: LibraryActivityType.cancelled,
            statusLabel: 'Cancelled',
            stageMessage: 'Cancelled',
            date: date,
            rawData: data,
          ));
        }
      }
    }

    // Default sorting: Newest First
    items.sort((a, b) => b.date.compareTo(a.date));
    return items;
  }

  /// Realtime Stream of active issued books (status == 'Issued' / 'Borrowed' and returnedAt == null)
  Stream<List<Map<String, dynamic>>> watchIssuedTransactions(String uid) {
    if (uid.isEmpty) return Stream.value([]);
    return _firestore
        .collection('transactions')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).where((data) {
        final studentUid = (data['studentUid'] ?? data['borrowerId'] ?? data['userId'] ?? '').toString();
        final status = (data['status'] ?? '').toString().trim().toLowerCase();
        final returnedAt = data['returnedAt'];

        final isUser = studentUid == uid;
        final isIssued = (status == 'issued' || status == 'borrowed') && returnedAt == null;
        return isUser && isIssued;
      }).toList();
    }).handleError((error) {
      return <Map<String, dynamic>>[];
    });
  }

  /// Realtime Stream of returned books history (status == 'Returned' / 'Completed' or returnedAt != null)
  Stream<List<Map<String, dynamic>>> watchReturnedTransactions(String uid) {
    if (uid.isEmpty) return Stream.value([]);
    return _firestore
        .collection('transactions')
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).where((data) {
        final studentUid = (data['studentUid'] ?? data['borrowerId'] ?? data['userId'] ?? '').toString();
        final status = (data['status'] ?? '').toString().trim().toLowerCase();
        final returnedAt = data['returnedAt'];

        final isUser = studentUid == uid;
        final isReturned = returnedAt != null || status == 'returned' || status == 'completed';
        return isUser && isReturned;
      }).toList();

      // Sort by returnedAt descending
      list.sort((a, b) {
        DateTime dateA = DateTime.now();
        DateTime dateB = DateTime.now();
        final valA = a['returnedAt'] ?? a['updatedAt'] ?? a['createdAt'];
        final valB = b['returnedAt'] ?? b['updatedAt'] ?? b['createdAt'];
        if (valA is Timestamp) dateA = valA.toDate();
        if (valB is Timestamp) dateB = valB.toDate();
        return dateB.compareTo(dateA);
      });

      return list;
    }).handleError((error) {
      return <Map<String, dynamic>>[];
    });
  }

  /// Stream pending borrow requests for student (status == 'Pending' or 'Requested')
  Stream<List<BorrowRequestModel>> watchPendingRequests(String uid) {
    if (uid.isEmpty) return Stream.value([]);
    return _firestore
        .collection('borrow_requests')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => BorrowRequestModel.fromMap(doc.data(), doc.id))
          .where((req) {
        final isUser = req.borrowerId == uid || req.studentUid == uid;
        final s = req.status.trim().toLowerCase();
        final isPending = s == 'requested' || s == 'pending';
        return isUser && isPending;
      }).toList();
    }).handleError((error) {
      return <BorrowRequestModel>[];
    });
  }

  /// Stream approved borrow requests for student (status == 'Approved' or 'Accepted')
  Stream<List<BorrowRequestModel>> watchApprovedRequests(String uid) {
    if (uid.isEmpty) return Stream.value([]);
    return _firestore
        .collection('borrow_requests')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => BorrowRequestModel.fromMap(doc.data(), doc.id))
          .where((req) {
        final isUser = req.borrowerId == uid || req.studentUid == uid;
        final s = req.status.trim().toLowerCase();
        final isApproved = s == 'approved' || s == 'accepted' || s == 'confirmed';
        return isUser && isApproved;
      }).toList();
    }).handleError((error) {
      return <BorrowRequestModel>[];
    });
  }

  /// Stream active borrowed transaction for student (status == 'Issued' or 'Borrowed' and returnedAt == null)
  Stream<BorrowEligibilityState> watchActiveBorrowedBook(String uid) {
    return BorrowEligibilityService.instance.watchEligibility(uid);
  }

  /// Stream borrowing history for student (returned books or status == 'Completed' / 'Returned')
  Stream<List<Map<String, dynamic>>> watchBorrowHistory(String uid) {
    return watchReturnedTransactions(uid);
  }
}
