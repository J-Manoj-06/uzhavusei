import '../models/marketplace_equipment_model.dart';

class ListingContextService {
  ListingContextService._();
  static final ListingContextService instance = ListingContextService._();

  MarketplaceEquipmentModel? _cachedListing;

  void cacheListing(MarketplaceEquipmentModel listing) {
    _cachedListing = listing;
  }

  MarketplaceEquipmentModel? get cachedListing => _cachedListing;

  void clearContext() {
    _cachedListing = null;
  }

  /// Builds a detailed context prompt about the listing for the LLM system prompt.
  String? buildContextPrompt() {
    final item = _cachedListing;
    if (item == null) return null;

    final String distanceStr = item.distanceInfo?.formattedString ?? 'Unknown distance';

    return '''
You are currently helping the user analyze a specific listing on the Borrow marketplace.
Here are the official details of the listing under discussion:
- Product ID: ${item.productId.isNotEmpty ? item.productId : 'N/A'}
- Category: ${item.category}
- Title: ${item.equipmentName}
- Description: ${item.description}
- Condition: ${item.condition}
- Rating of Owner: ${item.rating}
- Status: ${item.status}
- Location: ${item.location}
- Distance: $distanceStr
- Availability: ${item.availability ? 'Available' : 'Unavailable'}
- Coordinates: Latitude: ${item.latitude}, Longitude: ${item.longitude}

Guidelines:
1. Rely strictly on the listing information above to answer details about it.
2. If the user asks for information not present in the listing details, respond with: "This information isn't available in the listing."
3. Do not make assumptions or hallucinate missing details. Keep explanations concise, helpful, and tailored to borrowing/sharing.
''';
  }
}
