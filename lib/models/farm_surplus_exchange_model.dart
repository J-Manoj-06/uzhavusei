import 'package:cloud_firestore/cloud_firestore.dart';

class FarmSurplusExchangeModel {
  const FarmSurplusExchangeModel({
    required this.exchangeId,
    required this.ownerId,
    required this.ownerName,
    required this.productName,
    required this.brandName,
    required this.description,
    required this.category,
    required this.quantity,
    required this.unitType,
    required this.reasonForSurplus,
    required this.condition,
    required this.expiryDate,
    required this.listingType,
    required this.price,
    required this.exchangeRequirement,
    required this.location,
    required this.latitude,
    required this.longitude,
    required this.imageUrls,
    required this.imagePublicIds,
    required this.status,
    required this.createdAt,
    this.updatedAt,
  });

  final String exchangeId;
  final String ownerId;
  final String ownerName;

  final String productName;
  final String brandName;
  final String description;
  final String category; // Seeds, Fertilizers, Pesticides, Bio-Fertilizers, Organic Inputs

  final double quantity;
  final String unitType; // Kg, Bag, Packet, Bottle, Litre
  final String reasonForSurplus; // Leftover Stock, Bought Extra, Season End, etc.
  final String condition; // Unopened, Opened but Unused, Partially Used, Near Expiry
  final DateTime? expiryDate;

  final String listingType; // Sell Surplus, Exchange, Community Giveaway
  final double price; // Only used if listingType is 'Sell Surplus'
  final String exchangeRequirement; // Only used if listingType is 'Exchange'

  final String location;
  final double latitude;
  final double longitude;

  final List<String> imageUrls;
  final List<String> imagePublicIds;
  final String status;

  final DateTime createdAt;
  final DateTime? updatedAt;

  bool get isCommunityGiveaway => listingType == 'Community Giveaway';
  bool get isNearExpiry => condition == 'Near Expiry';

  factory FarmSurplusExchangeModel.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    return FarmSurplusExchangeModel(
      exchangeId: (data['exchangeId'] ?? doc.id).toString(),
      ownerId: (data['ownerId'] ?? '').toString(),
      ownerName: (data['ownerName'] ?? 'Farmer').toString(),
      productName: (data['productName'] ?? 'Product').toString(),
      brandName: (data['brandName'] ?? '').toString(),
      description: (data['description'] ?? '').toString(),
      category: (data['category'] ?? 'Seeds').toString(),
      quantity: _toDouble(data['quantity']),
      unitType: (data['unitType'] ?? 'Kg').toString(),
      reasonForSurplus: (data['reasonForSurplus'] ?? 'Leftover Stock').toString(),
      condition: (data['condition'] ?? 'Unopened').toString(),
      expiryDate: _toDateOrNull(data['expiryDate']),
      listingType: (data['listingType'] ?? 'Sell Surplus').toString(),
      price: _toDouble(data['price']),
      exchangeRequirement: (data['exchangeRequirement'] ?? '').toString(),
      location: (data['location'] ?? 'Unknown').toString(),
      latitude: _toDouble(data['latitude']),
      longitude: _toDouble(data['longitude']),
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      imagePublicIds: List<String>.from(data['imagePublicIds'] ?? []),
      status: (data['status'] ?? 'published').toString(),
      createdAt: _toDate(data['createdAt']),
      updatedAt: _toDateOrNull(data['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'exchangeId': exchangeId,
      'ownerId': ownerId,
      'ownerName': ownerName,
      'productName': productName,
      'brandName': brandName,
      'description': description,
      'category': category,
      'quantity': quantity,
      'unitType': unitType,
      'reasonForSurplus': reasonForSurplus,
      'condition': condition,
      'expiryDate': expiryDate != null ? Timestamp.fromDate(expiryDate!) : null,
      'listingType': listingType,
      'price': price,
      'exchangeRequirement': exchangeRequirement,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'imageUrls': imageUrls,
      'imagePublicIds': imagePublicIds,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : FieldValue.serverTimestamp(),
    };
  }

  static double _toDouble(dynamic val) {
    if (val == null) return 0.0;
    if (val is int) return val.toDouble();
    if (val is double) return val;
    if (val is String) return double.tryParse(val) ?? 0.0;
    return 0.0;
  }

  static DateTime _toDate(dynamic val) {
    if (val is Timestamp) return val.toDate();
    if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
    return DateTime.now();
  }

  static DateTime? _toDateOrNull(dynamic val) {
    if (val is Timestamp) return val.toDate();
    if (val is String) return DateTime.tryParse(val);
    return null;
  }
}
