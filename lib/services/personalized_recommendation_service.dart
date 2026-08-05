import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/marketplace_equipment_model.dart';
import '../models/borrow_request_model.dart';

class PersonalizedRecommendationService {
  PersonalizedRecommendationService._({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  static final PersonalizedRecommendationService instance = PersonalizedRecommendationService._();
  final FirebaseFirestore _firestore;

  /// Streams "Because You Borrowed [Book Title]" recommendations.
  Stream<Map<String, List<MarketplaceEquipmentModel>>> watchBecauseYouBorrowed(String userId) {
    if (userId.isEmpty) return Stream.value({});

    return _firestore
        .collection('borrow_requests')
        .where('borrowerId', isEqualTo: userId)
        .snapshots()
        .asyncMap((reqSnap) async {
      final requests = reqSnap.docs.map((doc) => BorrowRequestModel.fromDoc(doc)).toList();
      if (requests.isEmpty) return {};

      // Sort by recent
      requests.sort((a, b) => b.requestedAt.compareTo(a.requestedAt));
      final lastReq = requests.first;

      final equipSnap = await _firestore.collection('equipment').get();
      final allItems = equipSnap.docs.map((doc) => MarketplaceEquipmentModel.fromDoc(doc)).toList();

      try {
        final booksSnap = await _firestore.collection('books').get();
        allItems.addAll(booksSnap.docs.map((doc) => MarketplaceEquipmentModel.fromDoc(doc)));
      } catch (_) {}

      final Map<String, MarketplaceEquipmentModel> unique = {};
      for (final item in allItems) {
        unique[item.equipmentId] = item;
      }

      final recommendations = unique.values.where((item) {
        return item.equipmentId != lastReq.listingId &&
            (item.category.toLowerCase() == lastReq.category.toLowerCase() ||
                item.category.toLowerCase().contains('book'));
      }).take(6).toList();

      return {
        lastReq.listingTitle: recommendations,
      };
    });
  }

  /// Streams "Recommended for You" based on top rated books and favorite categories.
  Stream<List<MarketplaceEquipmentModel>> watchPersonalizedRecommendations(String userId) {
    return _firestore.collection('equipment').snapshots().asyncMap((equipSnap) async {
      final List<MarketplaceEquipmentModel> books = [];

      for (final doc in equipSnap.docs) {
        final item = MarketplaceEquipmentModel.fromDoc(doc);
        if (item.category.toLowerCase().contains('book') && item.status.toLowerCase() == 'published') {
          books.add(item);
        }
      }

      try {
        final booksSnap = await _firestore.collection('books').get();
        for (final doc in booksSnap.docs) {
          final item = MarketplaceEquipmentModel.fromDoc(doc);
          if (item.status.toLowerCase() == 'published') {
            books.add(item);
          }
        }
      } catch (_) {}

      final Map<String, MarketplaceEquipmentModel> unique = {};
      for (final b in books) {
        unique[b.equipmentId] = b;
      }

      final list = unique.values.toList()..sort((a, b) => b.rating.compareTo(a.rating));
      return list.take(10).toList();
    });
  }
}
