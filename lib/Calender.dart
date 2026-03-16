import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import 'widgets/image_loader.dart';

class Calendar extends StatefulWidget {
  const Calendar({super.key});

  @override
  State<Calendar> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<Calendar> {
  final DateTime _today = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  String? _selectedMachineryId;

  static const Color _primaryGreen = Color(0xFF4CAF50);

  Stream<List<Machinery>> _machineriesStream() {
    return FirebaseFirestore.instance
        .collection('machineries')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(Machinery.fromDoc)
              .where((m) => m.name.trim().isNotEmpty)
              .toList(),
        );
  }

  Stream<List<BookingEntry>> _bookingsStream(String machineryId) {
    return FirebaseFirestore.instance
        .collection('bookings')
        .where('machineryId', isEqualTo: machineryId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(BookingEntry.fromDoc).toList());
  }

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(_today.year, _today.month, _today.day);
    final lastDay = DateTime(_today.year + 2, 12, 31);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking Calendar'),
        backgroundColor: _primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<Machinery>>(
        stream: _machineriesStream(),
        builder: (context, machinerySnapshot) {
          if (machinerySnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (machinerySnapshot.hasError) {
            return _buildErrorState(
              'Unable to load machinery list. Please try again.',
            );
          }

          final machineries = machinerySnapshot.data ?? const <Machinery>[];

          if (machineries.isEmpty) {
            return _buildEmptyState('No active machineries found.');
          }

          if (!_hasMachinery(machineries, _selectedMachineryId)) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              setState(() {
                _selectedMachineryId = machineries.first.id;
                _selectedDay = null;
              });
            });
          }

          final selectedMachinery =
              _findMachineryById(machineries, _selectedMachineryId) ??
                  machineries.first;

          return StreamBuilder<List<BookingEntry>>(
            stream: _bookingsStream(selectedMachinery.id),
            builder: (context, bookingSnapshot) {
              final isLoadingBookings =
                  bookingSnapshot.connectionState == ConnectionState.waiting;

              if (bookingSnapshot.hasError) {
                return _buildErrorState(
                  'Unable to load bookings for ${selectedMachinery.name}.',
                );
              }

              final bookings = bookingSnapshot.data ?? const <BookingEntry>[];

              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildMachineryDropdown(
                      machineries: machineries,
                      selectedId: selectedMachinery.id,
                    ),
                    const SizedBox(height: 12),
                    _buildSelectedMachineryCard(selectedMachinery),
                    const SizedBox(height: 16),
                    if (isLoadingBookings)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: LinearProgressIndicator(minHeight: 3),
                      ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.green.shade100),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(12),
                      child: TableCalendar<dynamic>(
                        firstDay: firstDay,
                        lastDay: lastDay,
                        focusedDay: _focusedDay,
                        selectedDayPredicate: (day) =>
                            _isSameDate(_selectedDay, day),
                        calendarFormat: CalendarFormat.month,
                        headerStyle: const HeaderStyle(
                          titleCentered: true,
                          formatButtonVisible: false,
                          titleTextStyle: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                          leftChevronIcon:
                              Icon(Icons.chevron_left, color: _primaryGreen),
                          rightChevronIcon: Icon(
                            Icons.chevron_right,
                            color: _primaryGreen,
                          ),
                        ),
                        daysOfWeekStyle: DaysOfWeekStyle(
                          weekdayStyle: TextStyle(color: Colors.grey.shade700),
                          weekendStyle: TextStyle(color: Colors.grey.shade700),
                        ),
                        enabledDayPredicate: (day) {
                          if (_isBeforeToday(day)) return false;
                          return !_isDateBooked(day, bookings);
                        },
                        onDaySelected: (selectedDay, focusedDay) {
                          if (_isBeforeToday(selectedDay)) {
                            _showMessage(
                                'Past dates are unavailable for booking.');
                            return;
                          }
                          if (_isDateBooked(selectedDay, bookings)) {
                            _showMessage(
                                'This date is already booked. Choose another date.');
                            return;
                          }

                          setState(() {
                            _selectedDay = _dateOnly(selectedDay);
                            _focusedDay = focusedDay;
                          });

                          _openBookingBottomSheet(
                            machinery: selectedMachinery,
                            selectedDate: _dateOnly(selectedDay),
                            bookings: bookings,
                          );
                        },
                        onPageChanged: (focusedDay) {
                          setState(() {
                            _focusedDay = focusedDay;
                          });
                        },
                        calendarBuilders: CalendarBuilders(
                          defaultBuilder: (context, day, focusedDay) {
                            return _buildDayCell(
                              day: day,
                              isToday: _isSameDate(day, _today),
                              isSelected: _isSameDate(day, _selectedDay),
                              isBooked: _isDateBooked(day, bookings),
                              isPast: _isBeforeToday(day),
                            );
                          },
                          todayBuilder: (context, day, focusedDay) {
                            return _buildDayCell(
                              day: day,
                              isToday: true,
                              isSelected: _isSameDate(day, _selectedDay),
                              isBooked: _isDateBooked(day, bookings),
                              isPast: _isBeforeToday(day),
                            );
                          },
                          selectedBuilder: (context, day, focusedDay) {
                            return _buildDayCell(
                              day: day,
                              isToday: _isSameDate(day, _today),
                              isSelected: true,
                              isBooked: _isDateBooked(day, bookings),
                              isPast: _isBeforeToday(day),
                            );
                          },
                          disabledBuilder: (context, day, focusedDay) {
                            return _buildDayCell(
                              day: day,
                              isToday: _isSameDate(day, _today),
                              isSelected: _isSameDate(day, _selectedDay),
                              isBooked: _isDateBooked(day, bookings),
                              isPast: _isBeforeToday(day),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _buildLegend(),
                    const SizedBox(height: 8),
                    Text(
                      'Tap an available date to configure booking details.',
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildMachineryDropdown({
    required List<Machinery> machineries,
    required String selectedId,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: selectedId,
      icon: const Icon(Icons.keyboard_arrow_down_rounded),
      decoration: InputDecoration(
        labelText: 'Select Machinery',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.green.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _primaryGreen, width: 1.5),
        ),
        filled: true,
        fillColor: Colors.green.shade50.withValues(alpha: 0.35),
      ),
      items: machineries.map((machinery) {
        return DropdownMenuItem<String>(
          value: machinery.id,
          child: Row(
            children: [
              _buildMachineThumb(machinery.imageUrl, 34),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      machinery.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      machinery.category,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
      onChanged: (value) {
        if (value == null) return;
        setState(() {
          _selectedMachineryId = value;
          _selectedDay = null;
        });
      },
    );
  }

  Widget _buildSelectedMachineryCard(Machinery machinery) {
    final perHour = _currency(machinery.pricePerHour);
    final perDay = _currency(machinery.pricePerDay);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.green.shade100),
      ),
      child: Row(
        children: [
          _buildMachineThumb(machinery.imageUrl, 54),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  machinery.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  machinery.category,
                  style: TextStyle(color: Colors.grey.shade700),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _buildPriceChip('Hourly: $perHour'),
                    _buildPriceChip('Daily: $perDay'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: _primaryGreen,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return const Wrap(
      spacing: 12,
      runSpacing: 8,
      children: [
        _LegendDot(
            color: Color(0xFFFFFFFF),
            borderColor: Color(0xFFBDBDBD),
            text: 'Available'),
        _LegendDot(
            color: Color(0xFFFFEBEE),
            borderColor: Color(0xFFE57373),
            text: 'Booked'),
        _LegendDot(
            color: Color(0xFFE8F5E9),
            borderColor: Color(0xFF4CAF50),
            text: 'Selected'),
        _LegendDot(
            color: Color(0xFFE3F2FD),
            borderColor: Color(0xFF42A5F5),
            text: 'Today'),
      ],
    );
  }

  Widget _buildDayCell({
    required DateTime day,
    required bool isToday,
    required bool isSelected,
    required bool isBooked,
    required bool isPast,
  }) {
    Color fillColor = Colors.white;
    Color borderColor = Colors.grey.shade300;
    Color textColor = Colors.black87;
    FontWeight fontWeight = FontWeight.w500;
    Widget? marker;

    if (isPast) {
      fillColor = Colors.grey.shade100;
      textColor = Colors.grey.shade400;
    }

    if (isBooked) {
      fillColor = const Color(0xFFFFEBEE);
      borderColor = const Color(0xFFE57373);
      textColor = const Color(0xFFC62828);
      marker = const Icon(Icons.block, size: 12, color: Color(0xFFC62828));
    }

    if (isToday) {
      borderColor = const Color(0xFF42A5F5);
      if (!isBooked && !isPast) {
        fillColor = const Color(0xFFE3F2FD);
      }
      fontWeight = FontWeight.w700;
    }

    if (isSelected) {
      fillColor = const Color(0xFFE8F5E9);
      borderColor = _primaryGreen;
      textColor = _primaryGreen;
      fontWeight = FontWeight.w800;
    }

    return Container(
      margin: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: fillColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            day.day.toString(),
            style: TextStyle(
              color: textColor,
              fontWeight: fontWeight,
            ),
          ),
          const SizedBox(height: 2),
          marker ?? const SizedBox(height: 12),
        ],
      ),
    );
  }

  Future<void> _openBookingBottomSheet({
    required Machinery machinery,
    required DateTime selectedDate,
    required List<BookingEntry> bookings,
  }) async {
    BookingMode mode = BookingMode.daily;
    int days = 1;
    int hours = 2;
    int startHour = 8;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setBottomState) {
            final estimate = mode == BookingMode.daily
                ? machinery.pricePerDay * days
                : machinery.pricePerHour * hours;

            final validationMessage = _validateBookingInput(
              mode: mode,
              selectedDate: selectedDate,
              days: days,
              hours: hours,
              startHour: startHour,
              bookings: bookings,
            );

            return SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  8,
                  16,
                  16 + MediaQuery.of(context).viewInsets.bottom,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Booking Details',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.close_rounded),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _infoRow('Machine', machinery.name),
                      _infoRow('Category', machinery.category),
                      _infoRow(
                        'Selected Date',
                        DateFormat('EEE, d MMM yyyy').format(selectedDate),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Booking Type',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SegmentedButton<BookingMode>(
                        style: ButtonStyle(
                          backgroundColor: WidgetStateProperty.resolveWith(
                            (states) => states.contains(WidgetState.selected)
                                ? _primaryGreen.withValues(alpha: 0.12)
                                : Colors.white,
                          ),
                        ),
                        segments: const [
                          ButtonSegment<BookingMode>(
                            value: BookingMode.hourly,
                            label: Text('Hourly'),
                            icon: Icon(Icons.schedule),
                          ),
                          ButtonSegment<BookingMode>(
                            value: BookingMode.daily,
                            label: Text('Daily'),
                            icon: Icon(Icons.event),
                          ),
                        ],
                        selected: {mode},
                        onSelectionChanged: (selection) {
                          setBottomState(() {
                            mode = selection.first;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      if (mode == BookingMode.daily) ...[
                        _stepperField(
                          label: 'Number of Days',
                          value: days,
                          min: 1,
                          max: 30,
                          onChanged: (value) {
                            setBottomState(() {
                              days = value;
                            });
                          },
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Booking range: ${DateFormat('d MMM').format(selectedDate)} - '
                          '${DateFormat('d MMM').format(selectedDate.add(Duration(days: days - 1)))}',
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                      ] else ...[
                        _stepperField(
                          label: 'Number of Hours',
                          value: hours,
                          min: 1,
                          max: 12,
                          onChanged: (value) {
                            setBottomState(() {
                              hours = value;
                            });
                          },
                        ),
                        const SizedBox(height: 10),
                        DropdownButtonFormField<int>(
                          initialValue: startHour,
                          decoration: InputDecoration(
                            labelText: 'Start Time',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          items: List.generate(16, (index) => 6 + index)
                              .map(
                                (hour) => DropdownMenuItem<int>(
                                  value: hour,
                                  child: Text(_hourLabel(hour)),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value == null) return;
                            setBottomState(() {
                              startHour = value;
                            });
                          },
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Slot: ${_hourLabel(startHour)} - ${_hourLabel(startHour + hours)}',
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                      ],
                      const SizedBox(height: 14),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.green.shade50,
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Estimated Cost',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _currency(estimate),
                              style: const TextStyle(
                                color: _primaryGreen,
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              mode == BookingMode.daily
                                  ? '${_currency(machinery.pricePerDay)} x $days day(s)'
                                  : '${_currency(machinery.pricePerHour)} x $hours hour(s)',
                              style: TextStyle(color: Colors.grey.shade700),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (validationMessage != null)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: Colors.red.shade50,
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Text(
                            validationMessage,
                            style: TextStyle(color: Colors.red.shade800),
                          ),
                        )
                      else
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: Colors.blue.shade50,
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: const Text(
                            'Selected slot is available. You can continue to the next step.',
                          ),
                        ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: validationMessage == null
                              ? () {
                                  Navigator.of(context).pop();
                                  _showMessage(
                                    'Selection saved. Next step: payment integration.',
                                  );
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primaryGreen,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text('Continue'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _stepperField({
    required String label,
    required int value,
    required int min,
    required int max,
    required ValueChanged<int> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade800,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            onPressed: value > min ? () => onChanged(value - 1) : null,
            icon: const Icon(Icons.remove_circle_outline),
          ),
          Text(
            value.toString(),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          IconButton(
            onPressed: value < max ? () => onChanged(value + 1) : null,
            icon: const Icon(Icons.add_circle_outline),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 105,
            child: Text(
              '$label:',
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMachineThumb(String imageUrl, double size) {
    if (imageUrl.trim().isEmpty) {
      return _fallbackThumb(size);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: size,
        height: size,
        child: buildSmartImage(
          imageUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _fallbackThumb(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(Icons.agriculture_rounded, color: Colors.grey.shade600),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                color: Colors.red, size: 42),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  bool _isDateBooked(DateTime day, List<BookingEntry> bookings) {
    final normalizedDay = _dateOnly(day);
    for (final booking in bookings) {
      if (!booking.blocksCalendar) continue;
      if (booking.overlapsDate(normalizedDay)) {
        return true;
      }
    }
    return false;
  }

  String? _validateBookingInput({
    required BookingMode mode,
    required DateTime selectedDate,
    required int days,
    required int hours,
    required int startHour,
    required List<BookingEntry> bookings,
  }) {
    if (_selectedMachineryId == null || _selectedMachineryId!.trim().isEmpty) {
      return 'Please select a machinery first.';
    }

    if (_isDateBooked(selectedDate, bookings)) {
      return 'Selected date is already booked.';
    }

    if (mode == BookingMode.daily) {
      if (days <= 0) {
        return 'Enter a valid number of days.';
      }
      final end = selectedDate.add(Duration(days: days - 1));
      for (final booking in bookings) {
        if (!booking.blocksCalendar) continue;
        if (booking.overlapsRange(selectedDate, end)) {
          return 'One or more selected days overlap an existing booking.';
        }
      }
      return null;
    }

    if (hours <= 0) {
      return 'Enter a valid number of hours.';
    }

    if (startHour < 0 || startHour > 23) {
      return 'Choose a valid start time.';
    }

    final endHourExclusive = startHour + hours;
    if (endHourExclusive > 24) {
      return 'Hourly booking cannot cross midnight. Reduce hours or start earlier.';
    }

    for (final booking in bookings) {
      if (!booking.blocksCalendar) continue;
      if (booking.overlapsHourly(
        day: selectedDate,
        startHour: startHour,
        durationHours: hours,
      )) {
        return 'The selected hourly slot overlaps an existing booking.';
      }
    }

    return null;
  }

  Machinery? _findMachineryById(List<Machinery> machineries, String? id) {
    if (id == null) return null;
    for (final machinery in machineries) {
      if (machinery.id == id) return machinery;
    }
    return null;
  }

  bool _hasMachinery(List<Machinery> machineries, String? id) {
    return _findMachineryById(machineries, id) != null;
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _currency(double value) {
    return NumberFormat.currency(
      locale: 'en_IN',
      symbol: 'Rs.',
      decimalDigits: value % 1 == 0 ? 0 : 2,
    ).format(value);
  }

  String _hourLabel(int hour) {
    final wrappedHour = hour % 24;
    final date = DateTime(2000, 1, 1, wrappedHour);
    return DateFormat('h a').format(date);
  }

  bool _isBeforeToday(DateTime day) =>
      _dateOnly(day).isBefore(_dateOnly(_today));

  DateTime _dateOnly(DateTime dateTime) {
    return DateTime(dateTime.year, dateTime.month, dateTime.day);
  }

  bool _isSameDate(DateTime? a, DateTime? b) {
    if (a == null || b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

enum BookingMode { hourly, daily }

class Machinery {
  const Machinery({
    required this.id,
    required this.name,
    required this.category,
    required this.imageUrl,
    required this.pricePerHour,
    required this.pricePerDay,
    required this.isActive,
  });

  final String id;
  final String name;
  final String category;
  final String imageUrl;
  final double pricePerHour;
  final double pricePerDay;
  final bool isActive;

  factory Machinery.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return Machinery(
      id: data['id']?.toString() ?? doc.id,
      name: data['name']?.toString() ?? 'Unnamed Machinery',
      category: data['category']?.toString() ?? 'General',
      imageUrl: data['imageUrl']?.toString() ?? '',
      pricePerHour: _parseToDouble(data['pricePerHour']),
      pricePerDay: _parseToDouble(data['pricePerDay']),
      isActive: (data['isActive'] as bool?) ?? true,
    );
  }
}

class BookingEntry {
  const BookingEntry({
    required this.bookingId,
    required this.machineryId,
    required this.startDate,
    required this.endDate,
    required this.bookingType,
    required this.status,
    this.startHour,
    this.durationHours,
  });

  final String bookingId;
  final String machineryId;
  final DateTime startDate;
  final DateTime endDate;
  final String bookingType;
  final String status;
  final int? startHour;
  final int? durationHours;

  bool get blocksCalendar {
    const nonBlocking = {'cancelled', 'rejected', 'expired'};
    return !nonBlocking.contains(status.toLowerCase());
  }

  factory BookingEntry.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    final parsedStart = _parseDate(data['startDate']);
    final parsedEnd = _parseDate(data['endDate']);
    return BookingEntry(
      bookingId: data['bookingId']?.toString() ?? doc.id,
      machineryId: data['machineryId']?.toString() ?? '',
      startDate: parsedStart,
      endDate: parsedEnd,
      bookingType: data['bookingType']?.toString() ?? 'daily',
      status: data['status']?.toString() ?? 'pending',
      startHour: _parseNullableInt(data['startHour'] ?? data['slotStartHour']),
      durationHours: _parseNullableInt(
        data['durationHours'] ?? data['hours'] ?? data['slotDurationHours'],
      ),
    );
  }

  bool overlapsDate(DateTime day) {
    final d = DateTime(day.year, day.month, day.day);
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day);
    return !d.isBefore(start) && !d.isAfter(end);
  }

  bool overlapsRange(DateTime start, DateTime end) {
    final aStart = DateTime(start.year, start.month, start.day);
    final aEnd = DateTime(end.year, end.month, end.day);
    final bStart = DateTime(startDate.year, startDate.month, startDate.day);
    final bEnd = DateTime(endDate.year, endDate.month, endDate.day);
    return !aEnd.isBefore(bStart) && !aStart.isAfter(bEnd);
  }

  bool overlapsHourly({
    required DateTime day,
    required int startHour,
    required int durationHours,
  }) {
    final normalizedDay = DateTime(day.year, day.month, day.day);

    if (!overlapsDate(normalizedDay)) {
      return false;
    }

    if (bookingType.toLowerCase() != 'hourly') {
      return true;
    }

    final existingStart = this.startHour;
    final existingDuration = this.durationHours;

    if (existingStart == null || existingDuration == null) {
      return true;
    }

    final existingEndExclusive = existingStart + existingDuration;
    final selectedEndExclusive = startHour + durationHours;

    return startHour < existingEndExclusive &&
        selectedEndExclusive > existingStart;
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({
    required this.color,
    required this.borderColor,
    required this.text,
  });

  final Color color;
  final Color borderColor;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: borderColor),
          ),
        ),
        const SizedBox(width: 6),
        Text(text),
      ],
    );
  }
}

DateTime _parseDate(dynamic value) {
  if (value is Timestamp) {
    return value.toDate();
  }
  if (value is DateTime) {
    return value;
  }
  if (value is int) {
    return DateTime.fromMillisecondsSinceEpoch(value);
  }
  if (value is String) {
    return DateTime.tryParse(value) ?? DateTime.now();
  }
  return DateTime.now();
}

double _parseToDouble(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0;
  return 0;
}

int? _parseNullableInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}
