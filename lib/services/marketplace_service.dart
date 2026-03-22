import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/marketplace_booking_model.dart';
import '../models/marketplace_equipment_model.dart';

class MarketplaceService {
  MarketplaceService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  static const String _equipmentCollection = 'equipment';

  Stream<List<MarketplaceEquipmentModel>> watchEquipments({
    String? category,
    bool? onlyAvailable,
  }) {
    final query = _firestore.collection(_equipmentCollection);
    final categoryQuery = category?.trim().toLowerCase() ?? '';

    return query.snapshots().map((snapshot) {
      final items = snapshot.docs
          .map(MarketplaceEquipmentModel.fromDoc)
          .where((item) {
            if (categoryQuery.isEmpty || categoryQuery == 'all') return true;
            final values = <String>{
              item.category.toLowerCase(),
              item.categoryLocalized['en']?.toLowerCase() ?? '',
              item.categoryLocalized['ta']?.toLowerCase() ?? '',
              item.categoryLocalized['hi']?.toLowerCase() ?? '',
            };
            return values.contains(categoryQuery);
          })
          .where((item) => item.status.toLowerCase() == 'published')
          .where((item) => onlyAvailable == true ? item.availability : true)
          .toList(growable: false)
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return items;
    });
  }

  Stream<List<MarketplaceEquipmentModel>> watchEquipmentsByOwner(
      String ownerId) {
    return _firestore
        .collection(_equipmentCollection)
        .where('owner_user_id', isEqualTo: ownerId)
        .snapshots()
        .map((snapshot) {
      final items = snapshot.docs
          .map(MarketplaceEquipmentModel.fromDoc)
          .toList(growable: false)
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return items;
    });
  }

  Stream<List<MarketplaceBookingModel>> watchUserBookings(String userId) {
    return _firestore
        .collection('bookings')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(MarketplaceBookingModel.fromDoc)
              .toList(growable: false),
        );
  }

  Stream<List<MarketplaceBookingModel>> watchOwnerBookings(String ownerId) {
    return _firestore
        .collection('bookings')
        .where('ownerId', isEqualTo: ownerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(MarketplaceBookingModel.fromDoc)
              .toList(growable: false),
        );
  }

  Future<String> addEquipment(MarketplaceEquipmentModel equipment) async {
    return addEquipmentRecord(equipment.toMap());
  }

  Future<String> addEquipmentRecord(Map<String, dynamic> equipmentData) async {
    final doc = _firestore.collection(_equipmentCollection).doc();
    await doc.set(
      equipmentData
        ..['equipmentId'] = doc.id
        ..['created_at'] =
            (equipmentData['created_at'] ?? FieldValue.serverTimestamp())
        ..['updated_at'] =
            (equipmentData['updated_at'] ?? FieldValue.serverTimestamp()),
    );
    return doc.id;
  }

  Future<void> updateEquipment({
    required String equipmentId,
    required Map<String, dynamic> updates,
  }) {
    return _firestore.collection(_equipmentCollection).doc(equipmentId).update(
          updates
            ..['updated_at'] = FieldValue.serverTimestamp()
            ..['updatedAt'] = FieldValue.serverTimestamp(),
        );
  }

  Future<void> deleteEquipment(String equipmentId) {
    return _firestore
        .collection(_equipmentCollection)
        .doc(equipmentId)
        .delete();
  }

  Future<void> createBooking({
    required String equipmentId,
    required String ownerId,
    required String userId,
    required String equipmentName,
    required String imageUrl,
    required String ownerName,
    required String location,
    required DateTime startDateTime,
    required DateTime endDateTime,
    required String bookingType,
    required String duration,
    required double totalPrice,
    required String paymentId,
  }) async {
    final doc = _firestore.collection('bookings').doc();
    await doc.set({
      'bookingId': doc.id,
      // Equipment identifiers — dual-written so both marketplace and
      // TransactionsPage (which reads machineryId / machineryName) work.
      'equipmentId': equipmentId,
      'machineryId': equipmentId,
      'ownerId': ownerId,
      'userId': userId,
      'equipmentName': equipmentName,
      'machineryName': equipmentName,
      'imageUrl': imageUrl,
      'machineryImageUrl': imageUrl,
      'ownerName': ownerName,
      'location': location,
      'startDate': Timestamp.fromDate(startDateTime),
      'endDate': Timestamp.fromDate(endDateTime),
      'bookingType': bookingType,
      'duration': duration,
      'totalPrice': totalPrice,
      'paymentId': paymentId,
      'paymentMethod': 'Razorpay',
      'paymentStatus': 'completed',
      'status': 'confirmed',
      'bookingStatus': 'confirmed',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
