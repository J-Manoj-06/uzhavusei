import 'package:cloud_firestore/cloud_firestore.dart';

import '../utils/localized_text.dart';

class MarketplaceEquipmentModel {
  const MarketplaceEquipmentModel({
    required this.equipmentId,
    required this.ownerId,
    required this.equipmentName,
    required this.category,
    required this.description,
    required this.titleLocalized,
    required this.categoryLocalized,
    required this.descriptionLocalized,
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
    this.videoUrl = '',
    this.updatedAt,
    this.availabilityFrom,
    this.availabilityTo,
    this.condition = 'New',
    this.documents = const <String>[],
    this.imagePublicIds = const <String>[],
    this.minRentalDuration = 1,
    this.minRentalDurationType = 'hours',
    this.priceType = 'hour',
    this.status = 'published',
    this.tags = const <String>[],
  });

  final String equipmentId;
  final String ownerId;
  final String equipmentName;
  final String category;
  final String description;
  final Map<String, String> titleLocalized;
  final Map<String, String> categoryLocalized;
  final Map<String, String> descriptionLocalized;
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
  final String videoUrl;
  final DateTime? updatedAt;
  final DateTime? availabilityFrom;
  final DateTime? availabilityTo;
  final String condition;
  final List<String> documents;
  final List<String> imagePublicIds;
  final double minRentalDuration;
  final String minRentalDurationType;
  final String priceType;
  final String status;
  final List<String> tags;

  String titleForLanguage(String languageCode) =>
      getLocalizedText(titleLocalized, languageCode);

  String categoryForLanguage(String languageCode) =>
      getLocalizedText(categoryLocalized, languageCode);

  String descriptionForLanguage(String languageCode) =>
      getLocalizedText(descriptionLocalized, languageCode);

  factory MarketplaceEquipmentModel.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    final now = DateTime.now();
    final availabilityRaw = data['availability'];
    final hasAvailabilityWindow = availabilityRaw is Map<String, dynamic>;
    final availabilityFrom =
        hasAvailabilityWindow ? _toDateOrNull((availabilityRaw)['from']) : null;
    final availabilityTo =
        hasAvailabilityWindow ? _toDateOrNull((availabilityRaw)['to']) : null;
    final availability = hasAvailabilityWindow
        ? _isWithinAvailabilityWindow(
            from: availabilityFrom,
            to: availabilityTo,
            now: now,
          )
        : (data['availability'] as bool?) ?? true;
    final priceType = (data['price_type'] ?? 'hour').toString().toLowerCase();
    final rawPrice = _toDouble(data['price']);
    final legacyHourPrice = _toDouble(data['pricePerHour']);
    final legacyDayPrice = _toDouble(data['pricePerDay']);

    var resolvedHourPrice = priceType == 'hour'
        ? (rawPrice > 0 ? rawPrice : legacyHourPrice)
        : legacyHourPrice;
    var resolvedDayPrice = priceType == 'day'
        ? (rawPrice > 0 ? rawPrice : legacyDayPrice)
        : legacyDayPrice;

    if (resolvedHourPrice <= 0 && rawPrice > 0) {
      resolvedHourPrice = rawPrice;
    }
    if (resolvedDayPrice <= 0 && rawPrice > 0) {
      resolvedDayPrice = rawPrice;
    }
    if (resolvedHourPrice <= 0 && resolvedDayPrice > 0) {
      resolvedHourPrice = resolvedDayPrice;
    }
    if (resolvedDayPrice <= 0 && resolvedHourPrice > 0) {
      resolvedDayPrice = resolvedHourPrice;
    }

    final titleLocalized = normalizeLocalizedField(
      data['title'],
      fallback: (data['equipmentName'] ?? 'Equipment').toString(),
    );
    final categoryLocalized = normalizeLocalizedField(
      data['category'],
      fallback: 'General',
    );
    final descriptionLocalized = normalizeLocalizedField(
      data['description'],
      fallback: '',
    );

    return MarketplaceEquipmentModel(
      equipmentId: (data['equipmentId'] ?? doc.id).toString(),
      ownerId: (data['owner_user_id'] ?? data['ownerId'] ?? '').toString(),
      equipmentName: titleLocalized['en'] ?? 'Equipment',
      category: categoryLocalized['en'] ?? 'General',
      description: descriptionLocalized['en'] ?? '',
      titleLocalized: titleLocalized,
      categoryLocalized: categoryLocalized,
      descriptionLocalized: descriptionLocalized,
      pricePerHour: resolvedHourPrice,
      pricePerDay: resolvedDayPrice,
      location: (data['location'] ?? 'Unknown').toString(),
      latitude: _toDouble(data['latitude']),
      longitude: _toDouble(data['longitude']),
      imageUrls: _toStringList(data['images'] ?? data['imageUrls']),
      availability: availability,
      rating: _toDouble(data['rating']),
      createdAt: _toDate(data['created_at'] ?? data['createdAt']),
      ownerName: (data['ownerName'] ?? 'Owner').toString(),
      machineSpecs:
          (data['machineSpecs'] ?? data['condition'] ?? '').toString(),
      videoUrl: (data['videoUrl'] ?? data['video_url'] ?? '').toString(),
      updatedAt: _toDateOrNull(data['updated_at'] ?? data['updatedAt']),
      availabilityFrom: availabilityFrom,
      availabilityTo: availabilityTo,
      condition: (data['condition'] ?? 'New').toString(),
      documents: _toStringList(data['documents']),
      imagePublicIds: _toStringList(data['image_public_ids']),
      minRentalDuration: _toDouble(data['min_rental_duration']),
      minRentalDurationType:
          (data['min_rental_duration_type'] ?? 'hours').toString(),
      priceType: (data['price_type'] ?? 'hour').toString(),
      status: (data['status'] ?? 'published').toString(),
      tags: _toStringList(data['tags']),
    );
  }

  Map<String, dynamic> toMap() {
    final availabilityStart = availabilityFrom ?? DateTime.now();
    final availabilityEnd =
        availabilityTo ?? availabilityStart.add(const Duration(days: 365));
    final normalizedPriceType =
        priceType.trim().isEmpty ? 'hour' : priceType.trim().toLowerCase();
    final normalizedPrice =
        normalizedPriceType == 'day' ? pricePerDay : pricePerHour;

    return {
      'equipmentId': equipmentId,
      'owner_user_id': ownerId,
      'ownerId': ownerId,
      'title': titleLocalized,
      'equipmentName': equipmentName,
      'category': categoryLocalized,
      'description': descriptionLocalized,
      'condition': condition,
      'documents': documents,
      'image_public_ids': imagePublicIds,
      'images': imageUrls,
      'pricePerHour': pricePerHour,
      'pricePerDay': pricePerDay,
      'price': normalizedPrice,
      'price_type': normalizedPriceType,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'imageUrls': imageUrls,
      'availability': {
        'from': availabilityStart.toIso8601String(),
        'to': availabilityEnd.toIso8601String(),
      },
      'availability_bool': availability,
      'min_rental_duration': minRentalDuration,
      'min_rental_duration_type': minRentalDurationType,
      'rating': rating,
      'status': status,
      'tags': tags,
      'created_at': Timestamp.fromDate(createdAt),
      'createdAt': Timestamp.fromDate(createdAt),
      'updated_at': Timestamp.fromDate(updatedAt ?? createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt ?? createdAt),
      'ownerName': ownerName,
      'machineSpecs': machineSpecs,
      'videoUrl': videoUrl,
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

DateTime? _toDateOrNull(dynamic value) {
  if (value == null) return null;
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
  return null;
}

bool _isWithinAvailabilityWindow({
  required DateTime? from,
  required DateTime? to,
  required DateTime now,
}) {
  if (from != null && now.isBefore(from)) return false;
  if (to != null && now.isAfter(to)) return false;
  return true;
}

List<String> _toStringList(dynamic value) {
  if (value is List) {
    return value.map((e) => e.toString()).toList(growable: false);
  }
  return const [];
}
