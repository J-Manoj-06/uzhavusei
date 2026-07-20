import '../../../../../models/marketplace_equipment_model.dart';
import '../../../../../models/farm_surplus_exchange_model.dart';

class UnifiedListing {
  UnifiedListing({
    required this.id,
    required this.ownerId,
    required this.ownerName,
    required this.title,
    required this.category,
    required this.description,
    required this.price,
    this.salePrice,
    required this.condition,
    required this.location,
    required this.latitude,
    required this.longitude,
    required this.imageUrls,
    required this.status,
    required this.views,
    required this.savedBy,
    required this.bookingsCount,
    required this.createdAt,
    required this.rating,
    this.productId = '',
    this.originalEquipment,
    this.originalExchange,
  });

  final String id;
  final String ownerId;
  final String ownerName;
  final String title;
  final String category;
  final String description;
  final double price; // rent price per day or sale price
  final double? salePrice;
  final String condition;
  final String location;
  final double latitude;
  final double longitude;
  final List<String> imageUrls;
  final String status;
  final int views;
  final List<String> savedBy;
  final int bookingsCount;
  final DateTime createdAt;
  final double rating;
  final String productId;
  final MarketplaceEquipmentModel? originalEquipment;
  final FarmSurplusExchangeModel? originalExchange;

  bool get isEquipment => originalEquipment != null;
  bool get isExchange => originalExchange != null;
}
