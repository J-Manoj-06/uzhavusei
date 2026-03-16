import 'package:cloud_firestore/cloud_firestore.dart';

class BookingModel {
  const BookingModel({
    required this.bookingId,
    required this.machineryId,
    required this.userId,
    required this.startDate,
    required this.endDate,
    required this.bookingType,
    required this.status,
    required this.totalPrice,
    this.hours,
    this.days,
    this.startHour,
    this.paymentId,
    this.createdAt,
  });

  final String bookingId;
  final String machineryId;
  final String userId;
  final DateTime startDate;
  final DateTime endDate;
  final String bookingType;
  final String status;
  final int? hours;
  final int? days;
  final int? startHour;
  final double totalPrice;
  final String? paymentId;
  final DateTime? createdAt;

  bool get blocksAvailability {
    const nonBlocking = {'cancelled', 'rejected', 'failed', 'expired'};
    return !nonBlocking.contains(status.toLowerCase());
  }

  factory BookingModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return BookingModel(
      bookingId: (data['bookingId'] ?? doc.id).toString(),
      machineryId: (data['machineryId'] ?? '').toString(),
      userId: (data['userId'] ?? '').toString(),
      startDate: _toDate(data['startDate']),
      endDate: _toDate(data['endDate']),
      bookingType: (data['bookingType'] ?? 'daily').toString(),
      status: (data['status'] ?? 'pending').toString(),
      hours: _toNullableInt(data['hours'] ?? data['durationHours']),
      days: _toNullableInt(data['days']),
      startHour: _toNullableInt(data['startHour']),
      totalPrice: _toDouble(data['totalPrice']),
      paymentId: data['paymentId']?.toString(),
      createdAt: data['createdAt'] == null ? null : _toDate(data['createdAt']),
    );
  }

  bool overlapsDate(DateTime day) {
    final target = _dayOnly(day);
    final start = _dayOnly(startDate);
    final end = _dayOnly(endDate);
    return !target.isBefore(start) && !target.isAfter(end);
  }

  bool overlapsDateRange(DateTime rangeStart, DateTime rangeEnd) {
    final aStart = _dayOnly(rangeStart);
    final aEnd = _dayOnly(rangeEnd);
    final bStart = _dayOnly(startDate);
    final bEnd = _dayOnly(endDate);
    return !aEnd.isBefore(bStart) && !aStart.isAfter(bEnd);
  }

  bool overlapsHourlySlot({
    required DateTime day,
    required int selectedStartHour,
    required int selectedHours,
  }) {
    if (!overlapsDate(day)) return false;

    if (bookingType.toLowerCase() != 'hourly') {
      return true;
    }

    final existingStart = startHour;
    final existingHours = hours;
    if (existingStart == null || existingHours == null) {
      return true;
    }

    final selectedEnd = selectedStartHour + selectedHours;
    final existingEnd = existingStart + existingHours;
    return selectedStartHour < existingEnd && selectedEnd > existingStart;
  }
}

DateTime _toDate(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
  if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
  return DateTime.now();
}

double _toDouble(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0;
  return 0;
}

int? _toNullableInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

DateTime _dayOnly(DateTime date) => DateTime(date.year, date.month, date.day);
