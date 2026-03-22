import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/booking_draft.dart';
import '../models/booking_model.dart';
import '../models/machinery_model.dart';
import '../utils/localized_text.dart';

class FirestoreBookingRepository {
  FirestoreBookingRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Stream<List<MachineryModel>> watchActiveMachineries() {
    return _firestore
        .collection('machineries')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .asyncMap((snapshot) async {
      final machineries = snapshot.docs
          .map(MachineryModel.fromDoc)
          .where((m) => m.name.trim().isNotEmpty)
          .toList();

      if (machineries.isNotEmpty) {
        return machineries;
      }

      final equipmentSnapshot = await _firestore.collection('equipment').get();

      return equipmentSnapshot.docs
          .map(_machineryFromEquipmentDoc)
          .where((m) => m.isActive)
          .where((m) => m.name.trim().isNotEmpty)
          .toList();
    });
  }

  MachineryModel _machineryFromEquipmentDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? const <String, dynamic>{};
    final imageUrls = data['images'] ?? data['imageUrls'];
    final imageUrl = imageUrls is List && imageUrls.isNotEmpty
        ? imageUrls.first.toString()
        : '';
    final availability = data['availability'];
    final isAvailable = _isAvailable(availability);
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
    final title = normalizeLocalizedField(
      data['title'],
      fallback: (data['equipmentName'] ?? data['name'] ?? '').toString(),
    );
    final category = normalizeLocalizedField(
      data['category'],
      fallback: 'General',
    );

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

    return MachineryModel(
      id: (data['equipmentId'] ?? doc.id).toString(),
      name: getLocalizedText(title, 'en'),
      category: getLocalizedText(category, 'en'),
      imageUrl: imageUrl,
      pricePerHour: resolvedHourPrice,
      pricePerDay: resolvedDayPrice,
      isActive: isAvailable,
    );
  }

  Stream<List<BookingModel>> watchBookingsForMachinery(String machineryId) {
    return _firestore
        .collection('bookings')
        .where('machineryId', isEqualTo: machineryId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(BookingModel.fromDoc).toList());
  }

  Future<void> createBooking({
    required BookingDraft draft,
    required String userId,
    required String paymentId,
  }) async {
    final doc = _firestore.collection('bookings').doc();
    await doc.set({
      'bookingId': doc.id,
      'machineryId': draft.machineryId,
      'userId': userId,
      'startDate': Timestamp.fromDate(draft.startDate),
      'endDate': Timestamp.fromDate(draft.endDate),
      'bookingType': draft.bookingType,
      'hours': draft.hours,
      'days': draft.days,
      'startHour': draft.startHour,
      'totalPrice': draft.totalPrice,
      'paymentId': paymentId,
      'status': 'confirmed',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}

double _toDouble(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0;
  return 0;
}

bool _isAvailable(dynamic value) {
  if (value is bool) return value;
  if (value is Map<String, dynamic>) {
    final from = _toDateOrNull(value['from']);
    final to = _toDateOrNull(value['to']);
    final now = DateTime.now();
    if (from != null && now.isBefore(from)) return false;
    if (to != null && now.isAfter(to)) return false;
    return true;
  }
  return true;
}

DateTime? _toDateOrNull(dynamic value) {
  if (value == null) return null;
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
  return null;
}
