import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/booking_draft.dart';
import '../models/booking_model.dart';
import '../models/machinery_model.dart';

class FirestoreBookingRepository {
  FirestoreBookingRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Stream<List<MachineryModel>> watchActiveMachineries() {
    return _firestore
        .collection('machineries')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(MachineryModel.fromDoc)
              .where((m) => m.name.trim().isNotEmpty)
              .toList(),
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
