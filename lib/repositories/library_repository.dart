import 'package:cloud_firestore/cloud_firestore.dart';

class LibraryRepository {
  final FirebaseFirestore _firestore;

  LibraryRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  static final LibraryRepository instance = LibraryRepository();

  /// Stream raw snapshots from borrow_requests collection
  Stream<QuerySnapshot<Map<String, dynamic>>> watchBorrowRequests() {
    return _firestore.collection('borrow_requests').snapshots();
  }

  /// Stream raw snapshots from transactions collection
  Stream<QuerySnapshot<Map<String, dynamic>>> watchTransactions() {
    return _firestore.collection('transactions').snapshots();
  }
}
