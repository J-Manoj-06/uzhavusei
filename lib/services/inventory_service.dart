import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/book_model.dart';

class InventoryService {
  InventoryService._({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  static final InventoryService instance = InventoryService._();

  final FirebaseFirestore _firestore;
  static const String _bookCopiesCollection = 'bookCopies';

  Map<String, BookInventoryModel> _cachedInventory = {};

  /// Streams all book copies and groups inventory calculations by `bookId` in real time.
  Stream<Map<String, BookInventoryModel>> watchAllInventory() {
    return _firestore.collection(_bookCopiesCollection).snapshots().map((snapshot) {
      final Map<String, List<BookCopyModel>> groupedCopies = {};

      for (final doc in snapshot.docs) {
        try {
          final copy = BookCopyModel.fromDoc(doc);
          if (copy.bookId.isNotEmpty) {
            groupedCopies.putIfAbsent(copy.bookId, () => []).add(copy);
          }
        } catch (_) {}
      }

      final Map<String, BookInventoryModel> inventoryMap = {};
      groupedCopies.forEach((bookId, copiesList) {
        inventoryMap[bookId] = BookInventoryModel.fromCopies(bookId, copiesList);
      });

      _cachedInventory = inventoryMap;
      return inventoryMap;
    });
  }

  /// Streams inventory breakdown for a specific book ID.
  Stream<BookInventoryModel> watchBookInventory(String bookId) {
    return _firestore
        .collection(_bookCopiesCollection)
        .where('bookId', isEqualTo: bookId)
        .snapshots()
        .map((snapshot) {
      final copies = snapshot.docs.map(BookCopyModel.fromDoc).toList();
      final inventory = BookInventoryModel.fromCopies(bookId, copies);
      _cachedInventory[bookId] = inventory;
      return inventory;
    });
  }

  /// Synchronously fetches cached inventory or returns fallback calculation.
  BookInventoryModel getCachedOrFallback(String bookId, {int fallbackTotal = 1}) {
    if (_cachedInventory.containsKey(bookId)) {
      return _cachedInventory[bookId]!;
    }
    return BookInventoryModel.fromCopies(bookId, const [], fallbackTotal: fallbackTotal);
  }

  /// One-time fetch of inventory for a specific book ID.
  Future<BookInventoryModel> getInventoryForBook(String bookId, {int fallbackTotal = 1}) async {
    try {
      final snapshot = await _firestore
          .collection(_bookCopiesCollection)
          .where('bookId', isEqualTo: bookId)
          .get();

      final copies = snapshot.docs.map(BookCopyModel.fromDoc).toList();
      final inventory = BookInventoryModel.fromCopies(bookId, copies, fallbackTotal: fallbackTotal);
      _cachedInventory[bookId] = inventory;
      return inventory;
    } catch (_) {
      return BookInventoryModel.fromCopies(bookId, const [], fallbackTotal: fallbackTotal);
    }
  }
}
