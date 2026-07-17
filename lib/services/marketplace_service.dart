import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/marketplace_booking_model.dart';
import '../models/marketplace_equipment_model.dart';
import '../models/marketplace_surplus_model.dart';
import '../models/farm_surplus_exchange_model.dart';

class MarketplaceService {
  MarketplaceService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  static const String _equipmentCollection = 'equipment';
  static const String _surplusCollection = 'marketplace_surplus';
  static const String _exchangeCollection = 'farm_surplus_exchange';

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

  Stream<MarketplaceEquipmentModel> watchEquipmentById(String equipmentId) {
    return _firestore
        .collection(_equipmentCollection)
        .doc(equipmentId)
        .snapshots()
        .map((doc) => MarketplaceEquipmentModel.fromDoc(doc));
  }

  Future<MarketplaceEquipmentModel?> getEquipmentById(String equipmentId) async {
    final doc = await _firestore.collection(_equipmentCollection).doc(equipmentId).get();
    if (!doc.exists) return null;
    return MarketplaceEquipmentModel.fromDoc(doc);
  }

  Stream<List<MarketplaceEquipmentModel>> watchRelatedEquipment({
    required String category,
    required String currentEquipmentId,
  }) {
    return _firestore
        .collection(_equipmentCollection)
        .where('status', isEqualTo: 'published')
        // Firestore can only range query on one field, so we just filter locally if needed
        .snapshots()
        .map((snapshot) {
      final items = snapshot.docs
          .map(MarketplaceEquipmentModel.fromDoc)
          .where((item) => item.equipmentId != currentEquipmentId)
          .where((item) => item.category.toLowerCase() == category.toLowerCase())
          .toList(growable: false)
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return items.take(5).toList();
    });
  }

  void validateNotOwner({required String ownerId, required String userId, required String action}) {
    if (ownerId == userId) {
      if (action.toLowerCase() == 'borrow') {
        throw Exception("You already own this listing. Manage it from My Listings.");
      } else {
        throw Exception("This action isn't available for your own listing.");
      }
    }
  }

  Future<void> submitRating({required String userId, required String equipmentId, required double rating}) async {
    final doc = await _firestore.collection(_equipmentCollection).doc(equipmentId).get();
    if (doc.exists) {
      final ownerId = (doc.data()?['owner_user_id'] ?? doc.data()?['ownerId'] ?? '').toString();
      validateNotOwner(ownerId: ownerId, userId: userId, action: 'rate');
    }
  }

  Future<void> submitReview({required String userId, required String equipmentId, required String reviewText}) async {
    final doc = await _firestore.collection(_equipmentCollection).doc(equipmentId).get();
    if (doc.exists) {
      final ownerId = (doc.data()?['owner_user_id'] ?? doc.data()?['ownerId'] ?? '').toString();
      validateNotOwner(ownerId: ownerId, userId: userId, action: 'review');
    }
  }

  Future<void> createChatRoom({required String userId, required String ownerId}) async {
    validateNotOwner(ownerId: ownerId, userId: userId, action: 'chat');
  }

  Future<void> reportListing({required String userId, required String equipmentId}) async {
    final doc = await _firestore.collection(_equipmentCollection).doc(equipmentId).get();
    if (doc.exists) {
      final ownerId = (doc.data()?['owner_user_id'] ?? doc.data()?['ownerId'] ?? '').toString();
      validateNotOwner(ownerId: ownerId, userId: userId, action: 'report');
    }
  }

  Future<void> incrementEquipmentViews(String equipmentId, {String? userId}) async {
    if (userId != null) {
      final doc = await _firestore.collection(_equipmentCollection).doc(equipmentId).get();
      if (doc.exists) {
        final data = doc.data()!;
        final ownerId = (data['owner_user_id'] ?? data['ownerId'] ?? '').toString();
        if (ownerId == userId) {
          return;
        }
      }
    }
    final docRef = _firestore.collection(_equipmentCollection).doc(equipmentId);
    await docRef.update({
      'views': FieldValue.increment(1),
    });
  }

  Future<void> toggleSaveEquipment(String userId, String equipmentId) async {
    final docRef = _firestore.collection(_equipmentCollection).doc(equipmentId);
    
    return _firestore.runTransaction((transaction) async {
      final doc = await transaction.get(docRef);
      if (!doc.exists) return;
      
      final data = doc.data()!;
      final ownerId = (data['owner_user_id'] ?? data['ownerId'] ?? '').toString();
      validateNotOwner(ownerId: ownerId, userId: userId, action: 'favorite');
      
      final savedBy = List<String>.from(data['savedBy'] ?? []);
      
      if (savedBy.contains(userId)) {
        savedBy.remove(userId);
        transaction.update(docRef, {'savedBy': savedBy});
      } else {
        savedBy.add(userId);
        transaction.update(docRef, {'savedBy': savedBy});
      }
    });
  }

  Stream<List<MarketplaceEquipmentModel>> watchSavedEquipments(String userId) {
    return _firestore
        .collection(_equipmentCollection)
        .where('savedBy', arrayContains: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map(MarketplaceEquipmentModel.fromDoc)
            .toList());
  }

  // ── Surplus Operations ──────────────────────────────────────────

  Stream<List<MarketplaceSurplusModel>> watchSurplus({
    String? category,
  }) {
    final query = _firestore.collection(_surplusCollection);
    final categoryQuery = category?.trim().toLowerCase() ?? '';

    return query.snapshots().map((snapshot) {
      final items = snapshot.docs
          .map(MarketplaceSurplusModel.fromDoc)
          .where((item) {
            if (categoryQuery.isEmpty || categoryQuery == 'all') return true;
            final values = <String>{
              item.categoryLocalized['en']?.toLowerCase() ?? '',
              item.categoryLocalized['ta']?.toLowerCase() ?? '',
              item.categoryLocalized['hi']?.toLowerCase() ?? '',
            };
            return values.contains(categoryQuery);
          })
          .where((item) => item.status.toLowerCase() == 'published')
          .toList(growable: false)
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return items;
    });
  }

  Future<MarketplaceSurplusModel?> getSurplusById(String surplusId) async {
    final doc = await _firestore.collection(_surplusCollection).doc(surplusId).get();
    if (!doc.exists) return null;
    return MarketplaceSurplusModel.fromDoc(doc);
  }

  Stream<List<MarketplaceSurplusModel>> watchSurplusByOwner(String ownerId) {
    return _firestore
        .collection(_surplusCollection)
        .where('ownerId', isEqualTo: ownerId)
        .snapshots()
        .map((snapshot) {
      final items = snapshot.docs
          .map(MarketplaceSurplusModel.fromDoc)
          .toList(growable: false)
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return items;
    });
  }

  Future<String> addSurplusRecord(Map<String, dynamic> surplusData) async {
    final doc = _firestore.collection(_surplusCollection).doc();
    await doc.set(
      surplusData
        ..['surplusId'] = doc.id
        ..['createdAt'] = (surplusData['createdAt'] ?? FieldValue.serverTimestamp())
        ..['updatedAt'] = (surplusData['updatedAt'] ?? FieldValue.serverTimestamp()),
    );
    return doc.id;
  }

  Future<void> updateSurplus({
    required String surplusId,
    required Map<String, dynamic> updates,
  }) {
    return _firestore.collection(_surplusCollection).doc(surplusId).update(
          updates..['updatedAt'] = FieldValue.serverTimestamp(),
        );
  }

  Future<void> deleteSurplus(String surplusId) {
    return _firestore.collection(_surplusCollection).doc(surplusId).delete();
  }

  // ── Farm Surplus Exchange Operations ─────────────────────────────

  Stream<List<FarmSurplusExchangeModel>> watchExchanges({
    String? category,
  }) {
    final query = _firestore.collection(_exchangeCollection);
    final categoryQuery = category?.trim().toLowerCase() ?? '';

    return query.snapshots().map((snapshot) {
      final items = snapshot.docs
          .map(FarmSurplusExchangeModel.fromDoc)
          .where((item) {
            if (categoryQuery.isEmpty || categoryQuery == 'all') return true;
            return item.category.toLowerCase() == categoryQuery;
          })
          .where((item) => item.status.toLowerCase() == 'published')
          .toList(growable: false)
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return items;
    });
  }

  Stream<List<FarmSurplusExchangeModel>> watchExchangesByOwner(String ownerId) {
    return _firestore
        .collection(_exchangeCollection)
        .where('ownerId', isEqualTo: ownerId)
        .snapshots()
        .map((snapshot) {
      final items = snapshot.docs
          .map(FarmSurplusExchangeModel.fromDoc)
          .toList(growable: false)
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return items;
    });
  }

  Future<String> addExchangeRecord(Map<String, dynamic> exchangeData) async {
    final doc = _firestore.collection(_exchangeCollection).doc();
    await doc.set(
      exchangeData
        ..['exchangeId'] = doc.id
        ..['createdAt'] = (exchangeData['createdAt'] ?? FieldValue.serverTimestamp())
        ..['updatedAt'] = (exchangeData['updatedAt'] ?? FieldValue.serverTimestamp()),
    );
    return doc.id;
  }

  Future<void> updateExchange({
    required String exchangeId,
    required Map<String, dynamic> updates,
  }) {
    return _firestore.collection(_exchangeCollection).doc(exchangeId).update(
          updates..['updatedAt'] = FieldValue.serverTimestamp(),
        );
  }

  Future<void> deleteExchange(String exchangeId) {
    return _firestore.collection(_exchangeCollection).doc(exchangeId).delete();
  }

  // ──────────────────────────────────────────────────────────────

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
    validateNotOwner(ownerId: ownerId, userId: userId, action: 'borrow');
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
