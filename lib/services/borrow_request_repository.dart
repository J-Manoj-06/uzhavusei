import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/borrow_request_model.dart';
import 'logger_service.dart';

class BorrowRequestRepository {
  final FirebaseFirestore _firestore;

  BorrowRequestRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('borrow_requests');

  /// Creates a new Borrow Request document in Firestore after passing business validations.
  Future<void> createBorrowRequest(BorrowRequestModel request) async {
    try {
      // 1. Business Rule: Owner cannot request their own listing
      if (request.ownerId == request.borrowerId) {
        throw Exception('Owners cannot request to borrow their own listing.');
      }

      // 2. Business Rule: Date validation
      if (request.borrowUntil.isBefore(request.borrowFrom)) {
        throw Exception('Borrow Until date must be on or after Borrow From date.');
      }

      // 3. Business Rule: Check for active duplicate requests
      final isDuplicate = await hasActiveRequest(
        listingId: request.listingId,
        borrowerId: request.borrowerId,
      );
      if (isDuplicate) {
        throw Exception(
          'You already have an active or pending request for this item.',
        );
      }

      // 4. Save to Firestore
      final docRef = _collection.doc(
        request.requestId.isNotEmpty ? request.requestId : null,
      );
      final finalModel = request.copyWith();

      final data = finalModel.toMap();
      data['requestId'] = docRef.id;

      await docRef.set(data);
      LoggerService.debug('Borrow request created successfully: ${docRef.id}');
    } on FirebaseException catch (e) {
      LoggerService.error('Firestore Error on createBorrowRequest: ${e.message}', e);
      if (e.code == 'permission-denied') {
        throw Exception('Permission denied. Please log in and try again.');
      } else if (e.code == 'unavailable') {
        throw Exception('Network unavailable. Please check your internet connection.');
      }
      throw Exception('Failed to create borrow request: ${e.message}');
    } catch (e) {
      LoggerService.error('Error on createBorrowRequest: $e', e);
      rethrow;
    }
  }

  /// Checks if the borrower already has a pending or active request for this listing.
  Future<bool> hasActiveRequest({
    required String listingId,
    required String borrowerId,
  }) async {
    try {
      final query = await _collection
          .where('listingId', isEqualTo: listingId)
          .where('borrowerId', isEqualTo: borrowerId)
          .where('status', whereIn: ['Requested', 'Accepted', 'Pending', 'Borrowed'])
          .limit(1)
          .get();

      return query.docs.isNotEmpty;
    } catch (e) {
      LoggerService.error('Error checking active request: $e', e);
      return false;
    }
  }

  /// Stream of all incoming requests for an equipment owner.
  Stream<List<BorrowRequestModel>> watchOwnerRequests(String ownerId) {
    return _collection
        .where('ownerId', isEqualTo: ownerId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => BorrowRequestModel.fromDoc(doc))
          .toList();
      list.sort((a, b) => b.requestedAt.compareTo(a.requestedAt));
      return list;
    });
  }

  /// Stream of all outgoing requests created by a borrower.
  Stream<List<BorrowRequestModel>> watchBorrowerRequests(String borrowerId) {
    return _collection
        .where('borrowerId', isEqualTo: borrowerId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => BorrowRequestModel.fromDoc(doc))
          .toList();
      list.sort((a, b) => b.requestedAt.compareTo(a.requestedAt));
      return list;
    });
  }

  /// Validates listing existence & request state before accepting.
  Future<void> acceptBorrowRequest({
    required String requestId,
    required String listingId,
    required String ownerId,
  }) async {
    try {
      final doc = await _collection.doc(requestId).get();
      if (!doc.exists) {
        throw Exception('This borrow request no longer exists.');
      }

      final data = doc.data() ?? {};
      final currentStatus = (data['status'] ?? '').toString().toLowerCase();

      if (currentStatus != 'requested' && currentStatus != 'pending') {
        throw Exception('This request has already been processed.');
      }

      final now = DateTime.now();
      await _collection.doc(requestId).update({
        'status': 'Accepted',
        'acceptedAt': Timestamp.fromDate(now),
        'acceptedBy': ownerId,
        'updatedAt': Timestamp.fromDate(now),
      });

      LoggerService.debug('Request $requestId accepted by $ownerId');
    } on FirebaseException catch (e) {
      LoggerService.error('Firestore Error on acceptBorrowRequest: ${e.message}', e);
      if (e.code == 'permission-denied') {
        throw Exception('Permission denied. Only the owner can accept requests.');
      }
      throw Exception('Failed to accept request: ${e.message}');
    } catch (e) {
      LoggerService.error('Error on acceptBorrowRequest: $e', e);
      rethrow;
    }
  }

  /// Validates request state before rejecting.
  Future<void> rejectBorrowRequest({
    required String requestId,
    required String ownerId,
  }) async {
    try {
      final doc = await _collection.doc(requestId).get();
      if (!doc.exists) {
        throw Exception('This borrow request no longer exists.');
      }

      final data = doc.data() ?? {};
      final currentStatus = (data['status'] ?? '').toString().toLowerCase();

      if (currentStatus != 'requested' && currentStatus != 'pending') {
        throw Exception('This request has already been processed.');
      }

      final now = DateTime.now();
      await _collection.doc(requestId).update({
        'status': 'Rejected',
        'rejectedAt': Timestamp.fromDate(now),
        'rejectedBy': ownerId,
        'updatedAt': Timestamp.fromDate(now),
      });

      LoggerService.debug('Request $requestId rejected by $ownerId');
    } on FirebaseException catch (e) {
      LoggerService.error('Firestore Error on rejectBorrowRequest: ${e.message}', e);
      if (e.code == 'permission-denied') {
        throw Exception('Permission denied. Only the owner can reject requests.');
      }
      throw Exception('Failed to reject request: ${e.message}');
    } catch (e) {
      LoggerService.error('Error on rejectBorrowRequest: $e', e);
      rethrow;
    }
  }

  /// Starts borrowing handover process for an accepted request.
  /// 1. Validates listing existence & availability.
  /// 2. Updates borrow_request status to 'Borrowed'.
  /// 3. Updates listing availability to false & status to 'borrowed'.
  /// 4. Creates a borrow_history document.
  Future<void> startBorrow({
    required BorrowRequestModel request,
    required String ownerId,
  }) async {
    try {
      final now = DateTime.now();

      // 1. Validate request state
      final requestDoc = await _collection.doc(request.requestId).get();
      if (!requestDoc.exists) {
        throw Exception('This borrow request no longer exists.');
      }
      final reqData = requestDoc.data() ?? {};
      final reqStatus = (reqData['status'] ?? '').toString().toLowerCase();

      if (reqStatus != 'accepted' && reqStatus != 'approved') {
        throw Exception('Only accepted requests can be started.');
      }

      // 2. Validate listing availability in equipments or exchanges
      DocumentSnapshot<Map<String, dynamic>>? listingDoc;
      String collectionName = 'equipments';

      final equipRef = _firestore.collection('equipments').doc(request.listingId);
      final equipSnap = await equipRef.get();

      if (equipSnap.exists) {
        listingDoc = equipSnap;
        collectionName = 'equipments';
      } else {
        final exRef = _firestore.collection('exchanges').doc(request.listingId);
        final exSnap = await exRef.get();
        if (exSnap.exists) {
          listingDoc = exSnap;
          collectionName = 'exchanges';
        }
      }

      if (listingDoc == null || !listingDoc.exists) {
        throw Exception('This item listing no longer exists.');
      }

      final listingData = listingDoc.data() ?? {};
      final bool availability = listingData['availability'] == true;
      final String listingStatus = (listingData['status'] ?? '').toString().toLowerCase();

      if (!availability || listingStatus == 'borrowed' || listingStatus == 'booked') {
        throw Exception('This item is no longer available.');
      }

      // 3. Atomic writes for consistency
      final batch = _firestore.batch();

      // Update Borrow Request
      batch.update(_collection.doc(request.requestId), {
        'status': 'Borrowed',
        'borrowedAt': Timestamp.fromDate(now),
        'borrowStartDate': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
      });

      // Update Listing availability
      batch.update(_firestore.collection(collectionName).doc(request.listingId), {
        'availability': false,
        'status': 'borrowed',
        'currentBorrowRequestId': request.requestId,
        'currentBorrowerId': request.borrowerId,
        'borrowStartedAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
      });

      // Create Borrow History document
      final historyRef = _firestore.collection('borrow_history').doc();
      batch.set(historyRef, {
        'historyId': historyRef.id,
        'requestId': request.requestId,
        'listingId': request.listingId,
        'listingTitle': request.listingTitle,
        'borrowerId': request.borrowerId,
        'borrowerName': request.borrowerName,
        'ownerId': ownerId,
        'borrowStartDate': Timestamp.fromDate(now),
        'status': 'Borrowed',
        'createdAt': Timestamp.fromDate(now),
      });

      await batch.commit();

      LoggerService.debug('Borrow started successfully for request ${request.requestId}');
    } on FirebaseException catch (e) {
      LoggerService.error('Firestore Error on startBorrow: ${e.message}', e);
      if (e.code == 'permission-denied') {
        throw Exception('Permission denied. Only the owner can start borrowing.');
      }
      throw Exception('Failed to start borrowing: ${e.message}');
    } catch (e) {
      LoggerService.error('Error on startBorrow: $e', e);
      rethrow;
    }
  }

  /// Completes an active borrow request when item is returned.
  /// 1. Validates status is 'Borrowed'.
  /// 2. Updates borrow_request status to 'Completed', sets returnedAt & borrowEndDate.
  /// 3. Restores listing availability to true, status to 'published', increments bookingsCount by 1.
  /// 4. Updates borrow_history record.
  /// 5. Increments user statistics.
  Future<void> completeBorrow({
    required BorrowRequestModel request,
    required String ownerId,
  }) async {
    try {
      final now = DateTime.now();

      // 1. Validate request state
      final requestDoc = await _collection.doc(request.requestId).get();
      if (!requestDoc.exists) {
        throw Exception('This borrow request no longer exists.');
      }
      final reqData = requestDoc.data() ?? {};
      final reqStatus = (reqData['status'] ?? '').toString().toLowerCase();

      if (reqStatus != 'borrowed' && reqStatus != 'picked up') {
        throw Exception('Only currently borrowed items can be marked as returned.');
      }

      // 2. Identify listing doc & collection
      String collectionName = 'equipments';
      final equipRef = _firestore.collection('equipments').doc(request.listingId);
      final equipSnap = await equipRef.get();

      if (equipSnap.exists) {
        collectionName = 'equipments';
      } else {
        collectionName = 'exchanges';
      }

      // 3. Locate history record doc if exists
      final historyQuery = await _firestore
          .collection('borrow_history')
          .where('requestId', isEqualTo: request.requestId)
          .limit(1)
          .get();

      final startDate = request.borrowedAt ?? request.borrowFrom;
      final diffDays = now.difference(startDate).inDays;
      final actualDuration = diffDays <= 0 ? 1 : diffDays;

      // 4. Execute atomic batch write
      final batch = _firestore.batch();

      // Update Borrow Request doc
      batch.update(_collection.doc(request.requestId), {
        'status': 'Completed',
        'returnedAt': Timestamp.fromDate(now),
        'borrowEndDate': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
      });

      // Update Listing doc: set availability = true, status = published, increment bookingsCount
      batch.update(_firestore.collection(collectionName).doc(request.listingId), {
        'availability': true,
        'status': 'published',
        'currentBorrowRequestId': FieldValue.delete(),
        'currentBorrowerId': FieldValue.delete(),
        'borrowStartedAt': FieldValue.delete(),
        'lastReturnedAt': Timestamp.fromDate(now),
        'bookingsCount': FieldValue.increment(1),
        'updatedAt': Timestamp.fromDate(now),
      });

      // Update Borrow History doc if found
      if (historyQuery.docs.isNotEmpty) {
        final historyDocRef = historyQuery.docs.first.reference;
        batch.update(historyDocRef, {
          'status': 'Completed',
          'returnedAt': Timestamp.fromDate(now),
          'actualDuration': actualDuration,
          'updatedAt': Timestamp.fromDate(now),
        });
      }

      // Increment owner completed exchanges count in users collection if exists
      final ownerUserRef = _firestore.collection('users').doc(ownerId);
      batch.set(ownerUserRef, {
        'completedExchangesCount': FieldValue.increment(1),
      }, SetOptions(merge: true));

      // Increment borrower completed borrows count in users collection if exists
      if (request.borrowerId.isNotEmpty) {
        final borrowerUserRef = _firestore.collection('users').doc(request.borrowerId);
        batch.set(borrowerUserRef, {
          'completedBorrowsCount': FieldValue.increment(1),
        }, SetOptions(merge: true));
      }

      await batch.commit();

      LoggerService.debug('Borrow request ${request.requestId} completed successfully.');
    } on FirebaseException catch (e) {
      LoggerService.error('Firestore Error on completeBorrow: ${e.message}', e);
      if (e.code == 'permission-denied') {
        throw Exception('Permission denied. Only the owner can mark items as returned.');
      }
      throw Exception('Failed to complete borrow: ${e.message}');
    } catch (e) {
      LoggerService.error('Error on completeBorrow: $e', e);
      rethrow;
    }
  }

  /// Updates the status of a request (e.g. Accepted, Declined, Cancelled, Completed).
  Future<void> updateRequestStatus({
    required String requestId,
    required String newStatus,
  }) async {
    try {
      final now = DateTime.now();
      await _collection.doc(requestId).update({
        'status': newStatus,
        'updatedAt': Timestamp.fromDate(now),
      });
      LoggerService.debug('Request $requestId status updated to $newStatus');
    } on FirebaseException catch (e) {
      LoggerService.error('Firestore Error on updateRequestStatus: ${e.message}', e);
      throw Exception('Failed to update request status: ${e.message}');
    } catch (e) {
      LoggerService.error('Error on updateRequestStatus: $e', e);
      rethrow;
    }
  }
}
