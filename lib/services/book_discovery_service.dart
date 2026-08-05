import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/marketplace_equipment_model.dart';

class BookDiscoveryService {
  BookDiscoveryService._({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  static final BookDiscoveryService instance = BookDiscoveryService._();
  final FirebaseFirestore _firestore;

  /// Streams dynamic book & listing counts grouped per category.
  Stream<Map<String, int>> watchCategoryCounts() {
    return _firestore.collection('equipment').snapshots().asyncMap((equipSnap) async {
      final List<DocumentSnapshot<Map<String, dynamic>>> allDocs = [...equipSnap.docs];

      try {
        final booksSnap = await _firestore.collection('books').get();
        allDocs.addAll(booksSnap.docs);
      } catch (_) {}

      try {
        final copiesSnap = await _firestore.collection('bookCopies').get();
        allDocs.addAll(copiesSnap.docs);
      } catch (_) {}

      final Map<String, int> counts = {'All': 0};
      final Set<String> processedIds = {};

      for (final doc in allDocs) {
        try {
          final item = MarketplaceEquipmentModel.fromDoc(doc);
          if (processedIds.contains(item.equipmentId)) continue;
          processedIds.add(item.equipmentId);

          if (item.status.toLowerCase() == 'published') {
            counts['All'] = (counts['All'] ?? 0) + 1;
            final cat = item.category.trim();
            if (cat.isNotEmpty) {
              counts[cat] = (counts[cat] ?? 0) + 1;
            }
          }
        } catch (_) {}
      }

      return counts;
    });
  }

  /// Returns realtime autocomplete search suggestions (titles, authors, categories, ISBNs).
  Future<List<String>> getSuggestions(String query) async {
    final clean = query.trim().toLowerCase();
    if (clean.isEmpty) return const [];

    final Set<String> suggestions = {};

    try {
      final equipSnap = await _firestore
          .collection('equipment')
          .where('status', isEqualTo: 'published')
          .limit(25)
          .get();

      final booksSnap = await _firestore.collection('books').limit(25).get();
      final allDocs = [...equipSnap.docs, ...booksSnap.docs];

      for (final doc in allDocs) {
        final item = MarketplaceEquipmentModel.fromDoc(doc);
        final title = item.equipmentName.trim();
        final author = item.machineSpecs.trim();
        final category = item.category.trim();
        final isbn = item.productId.trim();

        if (title.toLowerCase().contains(clean)) suggestions.add(title);
        if (author.toLowerCase().contains(clean) && author.isNotEmpty) suggestions.add(author);
        if (category.toLowerCase().contains(clean) && category.isNotEmpty) suggestions.add(category);
        if (isbn.toLowerCase().contains(clean) && isbn.isNotEmpty) suggestions.add(isbn);
      }
    } catch (_) {}

    return suggestions.take(6).toList();
  }

  /// Streams top-rated or recently published books for discovery carousels.
  Stream<List<MarketplaceEquipmentModel>> watchTrendingBooks() {
    return _firestore.collection('equipment').snapshots().asyncMap((equipSnap) async {
      final List<MarketplaceEquipmentModel> items = [];

      for (final doc in equipSnap.docs) {
        final item = MarketplaceEquipmentModel.fromDoc(doc);
        if (item.category.toLowerCase().contains('book') && item.status.toLowerCase() == 'published') {
          items.add(item);
        }
      }

      try {
        final booksSnap = await _firestore.collection('books').get();
        for (final doc in booksSnap.docs) {
          final item = MarketplaceEquipmentModel.fromDoc(doc);
          if (item.status.toLowerCase() == 'published') {
            items.add(item);
          }
        }
      } catch (_) {}

      final Map<String, MarketplaceEquipmentModel> unique = {};
      for (final i in items) {
        unique[i.equipmentId] = i;
      }

      final list = unique.values.toList()..sort((a, b) => b.rating.compareTo(a.rating));
      return list.take(10).toList();
    });
  }
}
