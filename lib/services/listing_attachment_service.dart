import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/marketplace_equipment_model.dart';
import 'search_service.dart';
import 'listing_context_service.dart';

class ListingAttachmentService {
  ListingAttachmentService._();
  static final ListingAttachmentService instance = ListingAttachmentService._();

  MarketplaceEquipmentModel? get activeAttachment => ListingContextService.instance.cachedListing;

  void attachListing(MarketplaceEquipmentModel listing) {
    ListingContextService.instance.cacheListing(listing);
  }

  void removeListing() {
    ListingContextService.instance.clearContext();
  }

  bool get hasAttachment => activeAttachment != null;

  /// Fetches all public published listings for browsing.
  Future<List<MarketplaceEquipmentModel>> fetchAllListings() async {
    try {
      final List<MarketplaceEquipmentModel> items = [];

      final snapshot = await FirebaseFirestore.instance
          .collection('equipment')
          .where('status', isEqualTo: 'published')
          .get();
      items.addAll(snapshot.docs.map((doc) => MarketplaceEquipmentModel.fromDoc(doc)));

      try {
        final booksSnap = await FirebaseFirestore.instance.collection('books').get();
        items.addAll(booksSnap.docs.map((doc) => MarketplaceEquipmentModel.fromDoc(doc)));
      } catch (_) {}

      try {
        final copiesSnap = await FirebaseFirestore.instance.collection('bookCopies').get();
        items.addAll(copiesSnap.docs.map((doc) => MarketplaceEquipmentModel.fromDoc(doc)));
      } catch (_) {}

      final Map<String, MarketplaceEquipmentModel> uniqueMap = {};
      for (final item in items) {
        uniqueMap[item.equipmentId] = item;
      }

      return uniqueMap.values.toList();
    } catch (e) {
      throw Exception('Failed to fetch listings: $e');
    }
  }

  /// Searches listings by Product ID, Title, Category, or Keywords.
  Future<List<MarketplaceEquipmentModel>> searchListings(String query) async {
    try {
      final cleanQuery = query.trim().toLowerCase();
      if (cleanQuery.isEmpty) {
        return fetchAllListings();
      }

      // Check if it's an exact search by Product ID first
      final idSnapshot = await FirebaseFirestore.instance
          .collection('equipment')
          .where('status', isEqualTo: 'published')
          .where('productIdLower', isEqualTo: cleanQuery)
          .limit(1)
          .get();

      if (idSnapshot.docs.isNotEmpty) {
        return [MarketplaceEquipmentModel.fromDoc(idSnapshot.docs.first)];
      }

      // Fall back to ranking all published public listings client-side using relevance calculations
      final all = await fetchAllListings();
      final List<MapEntry<MarketplaceEquipmentModel, double>> scored = [];

      for (final item in all) {
        final score = SearchService.instance.calculateRelevance(item, query);
        if (score > 0) {
          scored.add(MapEntry(item, score));
        }
      }

      scored.sort((a, b) => b.value.compareTo(a.value));
      return scored.map((e) => e.key).toList();
    } catch (e) {
      throw Exception('Search failed: $e');
    }
  }
}
