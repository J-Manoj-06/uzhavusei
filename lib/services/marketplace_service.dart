import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/marketplace_booking_model.dart';
import '../models/marketplace_equipment_model.dart';

class MarketplaceService {
  MarketplaceService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Stream<List<MarketplaceEquipmentModel>> watchEquipments({
    String? category,
    bool? onlyAvailable,
  }) {
    Query<Map<String, dynamic>> query = _firestore
        .collection('equipments')
        .orderBy('createdAt', descending: true);

    if (category != null && category.isNotEmpty && category.toLowerCase() != 'all') {
      query = query.where('category', isEqualTo: category);
    }

    if (onlyAvailable == true) {
      query = query.where('availability', isEqualTo: true);
    }

    return query.snapshots().map(
          (snapshot) => snapshot.docs
              .map(MarketplaceEquipmentModel.fromDoc)
              .toList(growable: false),
        );
  }

  Stream<List<MarketplaceEquipmentModel>> watchEquipmentsByOwner(String ownerId) {
    return _firestore
        .collection('equipments')
        .where('ownerId', isEqualTo: ownerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(MarketplaceEquipmentModel.fromDoc)
              .toList(growable: false),
        );
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
    final doc = _firestore.collection('equipments').doc();
    await doc.set(
      equipment.toMap()
        ..['equipmentId'] = doc.id
        ..['createdAt'] = FieldValue.serverTimestamp(),
    );
    return doc.id;
  }

  Future<void> updateEquipment({
    required String equipmentId,
    required Map<String, dynamic> updates,
  }) {
    return _firestore.collection('equipments').doc(equipmentId).update(updates);
  }

  Future<void> deleteEquipment(String equipmentId) {
    return _firestore.collection('equipments').doc(equipmentId).delete();
  }

  Future<void> createBooking({
    required String equipmentId,
    required String ownerId,
    required String userId,
    required String equipmentName,
    required String location,
    required DateTime startDate,
    required DateTime endDate,
    required String bookingType,
    required double totalPrice,
    required String paymentId,
  }) async {
    final doc = _firestore.collection('bookings').doc();
    await doc.set({
      'bookingId': doc.id,
      'equipmentId': equipmentId,
      'ownerId': ownerId,
      'userId': userId,
      'equipmentName': equipmentName,
      'location': location,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'bookingType': bookingType,
      'totalPrice': totalPrice,
      'paymentId': paymentId,
      'status': 'confirmed',
      'paymentStatus': 'completed',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
