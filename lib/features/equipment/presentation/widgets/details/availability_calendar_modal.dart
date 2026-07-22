import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:UzhavuSei/models/marketplace_equipment_model.dart';
import 'details_theme.dart';

class AvailabilityCalendarModal extends StatefulWidget {
  const AvailabilityCalendarModal({
    super.key,
    required this.equipment,
    required this.selectedStartDay,
    required this.selectedEndDay,
    required this.onDatesSelected,
    required this.onRequestToBorrow,
  });

  final MarketplaceEquipmentModel equipment;
  final DateTime? selectedStartDay;
  final DateTime? selectedEndDay;
  final Function(DateTime? start, DateTime? end) onDatesSelected;
  final VoidCallback onRequestToBorrow;

  @override
  State<AvailabilityCalendarModal> createState() =>
      _AvailabilityCalendarModalState();
}

class _AvailabilityCalendarModalState
    extends State<AvailabilityCalendarModal> {
  late DateTime _focusedDay;
  DateTime? _startDay;
  DateTime? _endDay;

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _startDay = widget.selectedStartDay;
    _endDay = widget.selectedEndDay;
  }

  bool _isDateAvailable(DateTime day) {
    final item = widget.equipment;
    if (!item.availability) return false;

    final normDay = DateTime(day.year, day.month, day.day);

    if (item.availabilityFrom != null) {
      final normStart = DateTime(
        item.availabilityFrom!.year,
        item.availabilityFrom!.month,
        item.availabilityFrom!.day,
      );
      if (normDay.isBefore(normStart)) return false;
    }

    if (item.availabilityTo != null) {
      final normEnd = DateTime(
        item.availabilityTo!.year,
        item.availabilityTo!.month,
        item.availabilityTo!.day,
      );
      if (normDay.isAfter(normEnd)) return false;
    }

    return true;
  }

  int _calculateBorrowDays() {
    if (_startDay == null) return 0;
    final end = _endDay ?? _startDay!;
    return end.difference(_startDay!).inDays + 1;
  }

  @override
  Widget build(BuildContext context) {
    final days = _calculateBorrowDays();

    return Container(
      padding: EdgeInsets.only(
        left: DetailsTheme.outerPadding,
        right: DetailsTheme.outerPadding,
        top: DetailsTheme.outerPadding,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: DetailsTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: DetailsTheme.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Select Borrow Dates',
                  style: DetailsTheme.sectionHeadingStyle,
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded,
                      color: DetailsTheme.secondaryText),
                ),
              ],
            ),
            const SizedBox(height: 12),

            TableCalendar(
              firstDay: DateTime.now(),
              lastDay: DateTime.now().add(const Duration(days: 365)),
              focusedDay: _focusedDay,
              rangeSelectionMode: RangeSelectionMode.toggledOn,
              rangeStartDay: _startDay,
              rangeEndDay: _endDay,
              onDaySelected: (selectedDay, focusedDay) {
                if (!_isDateAvailable(selectedDay)) return;
                setState(() {
                  _startDay = selectedDay;
                  _endDay = selectedDay;
                  _focusedDay = focusedDay;
                });
                widget.onDatesSelected(_startDay, _endDay);
              },
              onRangeSelected: (start, end, focusedDay) {
                setState(() {
                  _startDay = start;
                  _endDay = end;
                  _focusedDay = focusedDay;
                });
                widget.onDatesSelected(_startDay, _endDay);
              },
              enabledDayPredicate: _isDateAvailable,
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: DetailsTheme.text,
                ),
                leftChevronIcon:
                    Icon(Icons.chevron_left, color: DetailsTheme.primary),
                rightChevronIcon:
                    Icon(Icons.chevron_right, color: DetailsTheme.primary),
              ),
              calendarStyle: CalendarStyle(
                rangeHighlightColor: DetailsTheme.primaryContainer,
                rangeStartDecoration: const BoxDecoration(
                  color: DetailsTheme.primary,
                  shape: BoxShape.circle,
                ),
                rangeEndDecoration: const BoxDecoration(
                  color: DetailsTheme.primary,
                  shape: BoxShape.circle,
                ),
                withinRangeTextStyle: const TextStyle(
                  color: DetailsTheme.primary,
                  fontWeight: FontWeight.bold,
                ),
                selectedDecoration: const BoxDecoration(
                  color: DetailsTheme.primary,
                  shape: BoxShape.circle,
                ),
                todayDecoration: BoxDecoration(
                  color: Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(color: DetailsTheme.primary, width: 2),
                ),
                todayTextStyle: const TextStyle(
                  color: DetailsTheme.primary,
                  fontWeight: FontWeight.bold,
                ),
                disabledTextStyle: TextStyle(
                  color: Colors.grey.shade300,
                  decoration: TextDecoration.lineThrough,
                ),
              ),
            ),

            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _legendDot(DetailsTheme.primary, 'Available'),
                const SizedBox(width: 20),
                _legendDot(Colors.grey.shade300, 'Unavailable'),
              ],
            ),

            const SizedBox(height: 20),

            if (_startDay != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: DetailsTheme.primaryContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: DetailsTheme.primaryContainer),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Selected Duration',
                          style: DetailsTheme.captionStyle,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$days ${days == 1 ? 'day' : 'days'}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: DetailsTheme.primary,
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        widget.onRequestToBorrow();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: DetailsTheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Confirm & Request'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ],
        ),
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: DetailsTheme.captionStyle,
        ),
      ],
    );
  }
}
