import 'booking_model.dart';

class BookingDraft {
  const BookingDraft({
    required this.machineryId,
    required this.startDate,
    required this.endDate,
    required this.bookingType,
    required this.totalPrice,
    this.hours,
    this.days,
    this.startHour,
  });

  final String machineryId;
  final DateTime startDate;
  final DateTime endDate;
  final String bookingType;
  final int? hours;
  final int? days;
  final int? startHour;
  final double totalPrice;

  bool overlapsAny(List<BookingModel> bookings) {
    for (final booking in bookings) {
      if (!booking.blocksAvailability) continue;
      if (bookingType == 'daily') {
        if (booking.overlapsDateRange(startDate, endDate)) return true;
      } else {
        final slotHours = hours ?? 0;
        final slotStart = startHour ?? 0;
        if (booking.overlapsHourlySlot(
          day: startDate,
          selectedStartHour: slotStart,
          selectedHours: slotHours,
        )) {
          return true;
        }
      }
    }
    return false;
  }
}
