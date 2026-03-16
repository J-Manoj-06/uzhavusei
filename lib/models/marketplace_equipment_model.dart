import 'package:cloud_firestore/cloud_firestore.dart';

class MarketplaceEquipmentModel {
  const MarketplaceEquipmentModel({
    required this.equipmentId,
    required this.ownerId,
    required this.equipmentName,
    required this.category,
    required this.description,
    required this.pricePerHour,
    required this.pricePerDay,
    required this.location,
    required this.latitude,
    required this.longitude,
    required this.imageUrls,
    required this.availability,
    required this.rating,
    required this.createdAt,
    required this.ownerName,
    required this.machineSpecs,
  });

  final String equipmentId;
  final String ownerId;
  final String equipmentName;
  final String category;
  final String description;
  final double pricePerHour;
  final double pricePerDay;
  final String location;
  final double latitude;
  final double longitude;
  final List<String> imageUrls;
  final bool availability;
  final double rating;
  final DateTime createdAt;
  final String ownerName;
  final String machineSpecs;

  factory MarketplaceEquipmentModel.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    return MarketplaceEquipmentModel(
      equipmentId: (data['equipmentId'] ?? doc.id).toString(),
      ownerId: (data['ownerId'] ?? '').toString(),
      equipmentName: (data['equipmentName'] ?? 'Equipment').toString(),
      category: (data['category'] ?? 'General').toString(),
      description: (data['description'] ?? '').toString(),
      pricePerHour: _toDouble(data['pricePerHour']),
      pricePerDay: _toDouble(data['pricePerDay']),
      location: (data['location'] ?? 'Unknown').toString(),
      latitude: _toDouble(data['latitude']),
      longitude: _toDouble(data['longitude']),
      imageUrls: _toStringList(data['imageUrls']),
      availability: (data['availability'] as bool?) ?? true,
      rating: _toDouble(data['rating']),
      createdAt: _toDate(data['createdAt']),
      ownerName: (data['ownerName'] ?? 'Owner').toString(),
      machineSpecs: (data['machineSpecs'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'equipmentId': equipmentId,
      'ownerId': ownerId,
      'equipmentName': equipmentName,
      'category': category,
      'description': description,
      'pricePerHour': pricePerHour,
      'pricePerDay': pricePerDay,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'imageUrls': imageUrls,
      'availability': availability,
      'rating': rating,
      'createdAt': Timestamp.fromDate(createdAt),
      'ownerName': ownerName,
      'machineSpecs': machineSpecs,
    };
  }
}

double _toDouble(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0;
  return 0;
}

DateTime _toDate(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
  return DateTime.now();
}

List<String> _toStringList(dynamic value) {
  if (value is List) {
    return value.map((e) => e.toString()).toList(growable: false);
  }
  return const [];
}
