import 'marketplace_equipment_model.dart';

class SearchResultModel {
  final MarketplaceEquipmentModel listing;
  final double relevanceScore;

  SearchResultModel({
    required this.listing,
    required this.relevanceScore,
  });
}
