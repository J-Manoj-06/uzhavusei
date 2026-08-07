import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/book_model.dart';
import '../models/marketplace_equipment_model.dart';

class SearchRepository {
  final FirebaseFirestore _firestore;

  SearchRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  static final SearchRepository instance = SearchRepository();

  /// Fetch all books from Firestore for in-memory indexing & search
  Future<List<BookModel>> fetchBooks() async {
    final snap = await _firestore.collection('books').get();
    return snap.docs
        .map((doc) => BookModel.fromDoc(doc))
        .where((book) => !book.isArchived)
        .toList();
  }

  /// Fetch all equipments / marketplace items from Firestore
  Future<List<MarketplaceEquipmentModel>> fetchEquipments() async {
    final snap = await _firestore.collection('equipment').get();
    return snap.docs
        .map((doc) => MarketplaceEquipmentModel.fromDoc(doc))
        .toList();
  }

  /// Fetch newest 10 books sorted by createdAt descending
  Future<List<BookModel>> fetchTrendingBooks({int limit = 10}) async {
    try {
      final snap = await _firestore
          .collection('books')
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      if (snap.docs.isNotEmpty) {
        return snap.docs
            .map((doc) => BookModel.fromDoc(doc))
            .where((b) => !b.isArchived)
            .toList();
      }
    } catch (_) {
      // Fallback if index not ready
    }

    final snap = await _firestore.collection('books').limit(limit * 2).get();
    final list = snap.docs.map((doc) => BookModel.fromDoc(doc)).toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list.take(limit).toList();
  }
}
