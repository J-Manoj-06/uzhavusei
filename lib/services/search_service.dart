import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/marketplace_equipment_model.dart';
import '../models/search_result_model.dart';
import 'distance_service.dart';

class SearchService {
  SearchService._();
  static final SearchService instance = SearchService._();

  double calculateRelevance(MarketplaceEquipmentModel item, String query) {
    if (query.isEmpty) return 1.0;

    final lowerQuery = query.toLowerCase();
    double score = 0.0;

    final name = item.equipmentName.toLowerCase();
    final category = item.category.toLowerCase();
    final description = item.description.toLowerCase();
    final specs = item.machineSpecs.toLowerCase();
    final city = item.city.toLowerCase();
    final area = item.area.toLowerCase();
    final state = item.state.toLowerCase();
    final owner = item.ownerName.toLowerCase();

    // Exact matches
    if (name == lowerQuery) score += 10.0;
    if (category == lowerQuery) score += 8.0;

    // Prefix/Substring matches
    if (name.contains(lowerQuery)) score += 5.0;
    if (category.contains(lowerQuery)) score += 4.0;
    if (description.contains(lowerQuery)) score += 2.0;
    if (specs.contains(lowerQuery)) score += 2.0;
    if (city.contains(lowerQuery) || area.contains(lowerQuery) || state.contains(lowerQuery)) score += 3.0;
    if (owner.contains(lowerQuery)) score += 1.0;

    // Author/Brand exact match fallbacks inside specs
    if (specs.contains('author:') && specs.contains(lowerQuery)) score += 4.0;
    if (specs.contains('brand:') && specs.contains(lowerQuery)) score += 4.0;

    // Tags matching
    for (final tag in item.tags) {
      final lowerTag = tag.toLowerCase();
      if (lowerTag == lowerQuery) {
        score += 4.0;
      } else if (lowerTag.contains(lowerQuery)) {
        score += 2.0;
      }
    }

    return score;
  }

  Future<List<SearchResultModel>> searchListings({
    required String query,
    required double userLat,
    required double userLng,
    String? category,
    String? condition,
    bool? onlyAvailable,
    String? city,
    String? state,
    double? maxDistanceKm,
    String sortBy = 'Relevance',
  }) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('equipment')
        .where('status', isEqualTo: 'published')
        .get();

    final List<SearchResultModel> results = [];
    final lowerQuery = query.trim().toLowerCase();

    for (final doc in snapshot.docs) {
      final item = MarketplaceEquipmentModel.fromDoc(doc);

      // Filters
      if (category != null && category != 'All' && item.category.toLowerCase() != category.toLowerCase()) {
        continue;
      }

      if (condition != null && condition != 'All' && item.condition.toLowerCase() != condition.toLowerCase()) {
        continue;
      }

      if (onlyAvailable == true && !item.availability) {
        continue;
      }

      if (city != null && city.trim().isNotEmpty && item.city.toLowerCase() != city.trim().toLowerCase()) {
        continue;
      }

      if (state != null && state.trim().isNotEmpty && item.state.toLowerCase() != state.trim().toLowerCase()) {
        continue;
      }

      // Calculate distance
      final distInfo = DistanceService.instance.getDistanceInfo(userLat, userLng, item.latitude, item.longitude);
      final enriched = item.copyWithDistance(distInfo);

      if (maxDistanceKm != null && distInfo != null && (distInfo.meters / 1000.0) > maxDistanceKm) {
        continue;
      }

      final relevance = calculateRelevance(enriched, lowerQuery);
      if (lowerQuery.isNotEmpty && relevance == 0.0) {
        continue; // Doesn't match query
      }

      results.add(SearchResultModel(listing: enriched, relevanceScore: relevance));
    }

    // Sorting
    switch (sortBy) {
      case 'Relevance':
        results.sort((a, b) => b.relevanceScore.compareTo(a.relevanceScore));
        break;
      case 'Newest':
        results.sort((a, b) => b.listing.createdAt.compareTo(a.listing.createdAt));
        break;
      case 'Nearest':
        results.sort((a, b) {
          final distA = a.listing.distanceInfo?.meters ?? double.infinity;
          final distB = b.listing.distanceInfo?.meters ?? double.infinity;
          return distA.compareTo(distB);
        });
        break;
      case 'Highest Rated':
        results.sort((a, b) => b.listing.rating.compareTo(a.listing.rating));
        break;
      case 'Most Requested':
        results.sort((a, b) => b.listing.bookingsCount.compareTo(a.listing.bookingsCount));
        break;
    }

    return results;
  }
}
