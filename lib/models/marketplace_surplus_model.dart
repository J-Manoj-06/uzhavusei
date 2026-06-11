import 'package:cloud_firestore/cloud_firestore.dart';

import '../utils/localized_text.dart';

class MarketplaceSurplusModel {
  const MarketplaceSurplusModel({
    required this.surplusId,
    required this.ownerId,
    required this.ownerName,
    required this.titleLocalized,
    required this.categoryLocalized,
    required this.descriptionLocalized,
    required this.pricePerUnit,
    required this.quantity,
    required this.unit,
    required this.qualityGrade,
    required this.isOrganic,
    required this.location,
    required this.latitude,
    required this.longitude,
    required this.deliveryAvailable,
    required this.deliveryRadius,
    required this.imageUrls,
    required this.imagePublicIds,
    required this.tags,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    this.harvestDate,
  });

  final String surplusId;
  final String ownerId;
  final String ownerName;
  final Map<String, String> titleLocalized;
  final Map<String, String> categoryLocalized;
  final Map<String, String> descriptionLocalized;
  
  final double pricePerUnit;
  final double quantity;
  final String unit; // Kg, Ton, Litre, etc.
  final String qualityGrade; // Grade A, B, etc.
  final bool isOrganic;
  final DateTime? harvestDate;

  final String location;
  final double latitude;
  final double longitude;
  
  final bool deliveryAvailable;
  final double deliveryRadius; // In km

  final List<String> imageUrls;
  final List<String> imagePublicIds;
  final List<String> tags;
  final String status;

  final DateTime createdAt;
  final DateTime? updatedAt;

  String titleForLanguage(String languageCode) =>
      getLocalizedText(titleLocalized, languageCode);

  String categoryForLanguage(String languageCode) =>
      getLocalizedText(categoryLocalized, languageCode);

  String descriptionForLanguage(String languageCode) =>
      getLocalizedText(descriptionLocalized, languageCode);

  factory MarketplaceSurplusModel.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    
    final titleLocalized = normalizeLocalizedField(
      data['title'],
      fallback: (data['surplusName'] ?? 'Product').toString(),
    );
    final categoryLocalized = normalizeLocalizedField(
      data['category'],
      fallback: 'General',
    );
    final descriptionLocalized = normalizeLocalizedField(
      data['description'],
      fallback: '',
    );

    return MarketplaceSurplusModel(
      surplusId: (data['surplusId'] ?? doc.id).toString(),
      ownerId: (data['ownerId'] ?? '').toString(),
      ownerName: (data['ownerName'] ?? 'Farmer').toString(),
      titleLocalized: titleLocalized,
      categoryLocalized: categoryLocalized,
      descriptionLocalized: descriptionLocalized,
      pricePerUnit: _toDouble(data['pricePerUnit']),
      quantity: _toDouble(data['quantity']),
      unit: (data['unit'] ?? 'Kg').toString(),
      qualityGrade: (data['qualityGrade'] ?? 'Standard').toString(),
      isOrganic: data['isOrganic'] as bool? ?? false,
      harvestDate: _toDateOrNull(data['harvestDate']),
      location: (data['location'] ?? 'Unknown').toString(),
      latitude: _toDouble(data['latitude']),
      longitude: _toDouble(data['longitude']),
      deliveryAvailable: data['deliveryAvailable'] as bool? ?? false,
      deliveryRadius: _toDouble(data['deliveryRadius']),
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      imagePublicIds: List<String>.from(data['imagePublicIds'] ?? []),
      tags: List<String>.from(data['tags'] ?? []),
      status: (data['status'] ?? 'published').toString(),
      createdAt: _toDate(data['createdAt']),
      updatedAt: _toDateOrNull(data['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'surplusId': surplusId,
      'ownerId': ownerId,
      'ownerName': ownerName,
      'title': titleLocalized,
      'category': categoryLocalized,
      'description': descriptionLocalized,
      'pricePerUnit': pricePerUnit,
      'quantity': quantity,
      'unit': unit,
      'qualityGrade': qualityGrade,
      'isOrganic': isOrganic,
      'harvestDate': harvestDate != null ? Timestamp.fromDate(harvestDate!) : null,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'deliveryAvailable': deliveryAvailable,
      'deliveryRadius': deliveryRadius,
      'imageUrls': imageUrls,
      'imagePublicIds': imagePublicIds,
      'tags': tags,
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
