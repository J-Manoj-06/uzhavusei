import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import 'config.dart';
import 'models/booking_draft.dart';
import 'models/booking_model.dart';
import 'models/machinery_model.dart';
import 'providers/user_profile_provider.dart';
import 'services/firebase_bootstrap.dart';
import 'services/firestore_booking_repository.dart';
import 'services/razorpay_checkout_service.dart';
import 'widgets/image_loader.dart';

class Calendar extends StatefulWidget {
  const Calendar({super.key});

  @override
  State<Calendar> createState() => _CalendarState();
}

class _CalendarState extends State<Calendar> {
  static const Color _primaryGreen = Color(0xFF4CAF50);

  final DateTime _today = DateTime.now();
  FirestoreBookingRepository? _bookingRepository;
  late final RazorpayCheckoutService _paymentService;

  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  String? _selectedMachineryId;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (FirebaseBootstrap.initialized) {
      _bookingRepository = FirestoreBookingRepository();
    }
    _paymentService = RazorpayCheckoutService();
  }

  @override
  void dispose() {
    _paymentService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!FirebaseBootstrap.initialized) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Machinery Booking'),
          backgroundColor: _primaryGreen,
          foregroundColor: Colors.white,
        ),
        body: _buildFirebaseSetupState(),
      );
    }

    final bookingRepository =
        _bookingRepository ??= FirestoreBookingRepository();

    final firstDay = DateTime(_today.year, _today.month, _today.day);
    final lastDay = DateTime(_today.year + 2, 12, 31);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Machinery Booking'),
        backgroundColor: _primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<MachineryModel>>(
        stream: bookingRepository.watchActiveMachineries(),
        builder: (context, machinerySnapshot) {
          if (machinerySnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (machinerySnapshot.hasError) {
            return _buildErrorState(
              'Unable to load machinery list. Check network or Firestore rules.',
            );
          }

          final machineries =
              machinerySnapshot.data ?? const <MachineryModel>[];
          if (machineries.isEmpty) {
            return _buildEmptyState('No active machinery available right now.');
          }

          if (!_containsMachinery(machineries, _selectedMachineryId)) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              setState(() {
                _selectedMachineryId = machineries.first.id;
                _selectedDay = null;
              });
            });
          }

          final selectedMachinery =
              _findById(machineries, _selectedMachineryId) ?? machineries.first;

          return StreamBuilder<List<BookingModel>>(
            stream: bookingRepository
                .watchBookingsForMachinery(selectedMachinery.id),
            builder: (context, bookingSnapshot) {
              final loadingBookings =
                  bookingSnapshot.connectionState == ConnectionState.waiting;
              final bookings = bookingSnapshot.data ?? const <BookingModel>[];

              if (bookingSnapshot.hasError) {
                return _buildErrorState(
                  'Could not load bookings for ${selectedMachinery.name}.',
                );
              }

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
                    if (loadingBookings)
                      const Padding(
                        padding: EdgeInsets.only(top: 12),
                        child: LinearProgressIndicator(minHeight: 3),
                      ),
                    const SizedBox(height: 14),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.green.shade100),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(10),
                      child: TableCalendar<dynamic>(
                        firstDay: firstDay,
                        lastDay: lastDay,
                        focusedDay: _focusedDay,
                        selectedDayPredicate: (day) =>
                            _sameDate(_selectedDay, day),
                        calendarFormat: CalendarFormat.month,
                        headerStyle: const HeaderStyle(
                          titleCentered: true,
                          formatButtonVisible: false,
                          titleTextStyle: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                          ),
                          leftChevronIcon:
                              Icon(Icons.chevron_left, color: _primaryGreen),
                          rightChevronIcon:
                              Icon(Icons.chevron_right, color: _primaryGreen),
                        ),
                        enabledDayPredicate: (day) {
                          if (_isBeforeToday(day)) return false;
                          return !_isDayBlocked(day, bookings);
                        },
                        onDaySelected: (selectedDay, focusedDay) {
                          final normalized = _dateOnly(selectedDay);
                          if (_isBeforeToday(normalized)) {
                            _showMessage('Past dates cannot be booked.');
                            return;
                          }
                          if (_isDayBlocked(normalized, bookings)) {
                            _showMessage('This date is already booked.');
                            return;
                          }

                          setState(() {
                            _selectedDay = normalized;
                            _focusedDay = focusedDay;
                          });

                          _openBookingBottomSheet(
                            machinery: selectedMachinery,
                            selectedDate: normalized,
                            bookings: bookings,
                          );
                        },
                        onPageChanged: (focusedDay) {
                          setState(() {
                            _focusedDay = focusedDay;
                          });
                        },
                        calendarBuilders: CalendarBuilders(
                          defaultBuilder: (context, day, focusedDay) =>
                              _buildDayCell(
                            day: day,
                            isToday: _sameDate(day, _today),
                            isSelected: _sameDate(day, _selectedDay),
                            isBlocked: _isDayBlocked(day, bookings),
                            isPast: _isBeforeToday(day),
                          ),
                          todayBuilder: (context, day, focusedDay) =>
                              _buildDayCell(
                            day: day,
                            isToday: true,
                            isSelected: _sameDate(day, _selectedDay),
                            isBlocked: _isDayBlocked(day, bookings),
                            isPast: _isBeforeToday(day),
                          ),
                          selectedBuilder: (context, day, focusedDay) =>
                              _buildDayCell(
                            day: day,
                            isToday: _sameDate(day, _today),
                            isSelected: true,
                            isBlocked: _isDayBlocked(day, bookings),
                            isPast: _isBeforeToday(day),
                          ),
                          disabledBuilder: (context, day, focusedDay) =>
                              _buildDayCell(
                            day: day,
                            isToday: _sameDate(day, _today),
                            isSelected: _sameDate(day, _selectedDay),
                            isBlocked: _isDayBlocked(day, bookings),
                            isPast: _isBeforeToday(day),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _buildLegend(),
                    const SizedBox(height: 10),
                    Text(
                      'Select an available date to continue with booking.',
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
    required List<MachineryModel> machineries,
    required String selectedId,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: selectedId,
      decoration: InputDecoration(
        labelText: 'Select Machinery',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _primaryGreen, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.green.shade200),
        ),
        filled: true,
        fillColor: Colors.green.shade50.withValues(alpha: 0.35),
      ),
      items: machineries
          .map(
            (machine) => DropdownMenuItem<String>(
              value: machine.id,
              child: Row(
                children: [
                  _buildMachineThumb(machine.imageUrl, 34),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          machine.name,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          machine.category,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
      onChanged: (value) {
        if (value == null) return;
        setState(() {
          _selectedMachineryId = value;
          _selectedDay = null;
        });
      },
    );
  }

  Widget _buildSelectedMachineryCard(MachineryModel machine) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.green.shade100),
      ),
      child: Row(
        children: [
          _buildMachineThumb(machine.imageUrl, 54),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  machine.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  machine.category,
                  style: TextStyle(color: Colors.grey.shade700),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _pill('Hourly: ${_currency(machine.pricePerHour)}'),
                    _pill('Daily: ${_currency(machine.pricePerDay)}'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _pill(String text) {
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

  Widget _buildDayCell({
    required DateTime day,
    required bool isToday,
    required bool isSelected,
    required bool isBlocked,
    required bool isPast,
  }) {
    Color fill = Colors.white;
    Color border = Colors.grey.shade300;
    Color textColor = Colors.black87;
    FontWeight weight = FontWeight.w600;
    Widget marker = const SizedBox(height: 10);

    if (isPast) {
      fill = Colors.grey.shade100;
      textColor = Colors.grey.shade400;
    }

    if (isBlocked) {
      fill = const Color(0xFFFFEBEE);
      border = const Color(0xFFE57373);
      textColor = const Color(0xFFC62828);
      marker = const Icon(Icons.block, size: 12, color: Color(0xFFC62828));
    }

    if (isToday) {
      border = const Color(0xFF42A5F5);
      if (!isBlocked && !isPast) {
        fill = const Color(0xFFE3F2FD);
      }
      weight = FontWeight.w700;
    }

    if (isSelected) {
      fill = const Color(0xFFE8F5E9);
      border = _primaryGreen;
      textColor = _primaryGreen;
      weight = FontWeight.w800;
    }

    return Container(
      margin: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${day.day}',
            style: TextStyle(
              color: textColor,
              fontWeight: weight,
            ),
          ),
          const SizedBox(height: 1),
          marker,
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return const Wrap(
      spacing: 12,
      runSpacing: 8,
      children: [
        _LegendDot('Available', Color(0xFFFFFFFF), Color(0xFFBDBDBD)),
        _LegendDot('Booked', Color(0xFFFFEBEE), Color(0xFFE57373)),
        _LegendDot('Selected', Color(0xFFE8F5E9), Color(0xFF4CAF50)),
        _LegendDot('Today', Color(0xFFE3F2FD), Color(0xFF42A5F5)),
      ],
    );
  }

  Future<void> _openBookingBottomSheet({
    required MachineryModel machinery,
    required DateTime selectedDate,
    required List<BookingModel> bookings,
  }) async {
    BookingMode mode = BookingMode.daily;
    int days = 1;
    int hours = 2;
    int startHour = 8;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setBottomSheetState) {
            final total = mode == BookingMode.daily
                ? days * machinery.pricePerDay
                : hours * machinery.pricePerHour;

            final draft = _buildDraft(
              machineryId: machinery.id,
              selectedDate: selectedDate,
              mode: mode,
              days: days,
              hours: hours,
              startHour: startHour,
              total: total,
            );

            final validationError = _validateDraft(
              draft: draft,
              selectedDate: selectedDate,
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
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Confirm Booking',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _machineSummaryInSheet(machinery, selectedDate),
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
                        selected: {mode},
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
                            icon: Icon(Icons.schedule),
                            label: Text('Hourly'),
                          ),
                          ButtonSegment<BookingMode>(
                            value: BookingMode.daily,
                            icon: Icon(Icons.event),
                            label: Text('Daily'),
                          ),
                        ],
                        onSelectionChanged: (set) {
                          setBottomSheetState(() {
                            mode = set.first;
                          });
                        },
                      ),
                      const SizedBox(height: 14),
                      if (mode == BookingMode.daily) ...[
                        _stepperField(
                          label: 'Number of Days',
                          value: days,
                          min: 1,
                          max: 30,
                          onChanged: (value) {
                            setBottomSheetState(() {
                              days = value;
                            });
                          },
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'End Date: ${DateFormat('EEE, d MMM yyyy').format(draft.endDate)}',
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                      ] else ...[
                        _stepperField(
                          label: 'Number of Hours',
                          value: hours,
                          min: 1,
                          max: 12,
                          onChanged: (value) {
                            setBottomSheetState(() {
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
                            setBottomSheetState(() {
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
                      _pricePreview(
                        machinery: machinery,
                        mode: mode,
                        hours: hours,
                        days: days,
                        total: total,
                      ),
                      const SizedBox(height: 10),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: validationError != null
                            ? _validationCard(validationError)
                            : _availabilityCard(),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: (_isSubmitting || validationError != null)
                              ? null
                              : () async {
                                  Navigator.of(context).pop();
                                  await _confirmAndPay(
                                    machinery: machinery,
                                    draft: draft,
                                    bookings: bookings,
                                  );
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primaryGreen,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text(
                            _isSubmitting ? 'Processing...' : 'Continue to Pay',
                          ),
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

  Widget _machineSummaryInSheet(
      MachineryModel machinery, DateTime selectedDate) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.green.shade50,
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        children: [
          _buildMachineThumb(machinery.imageUrl, 54),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  machinery.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                Text(
                  machinery.category,
                  style: TextStyle(color: Colors.grey.shade700),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('EEE, d MMM yyyy').format(selectedDate),
                  style: const TextStyle(color: _primaryGreen),
                ),
              ],
            ),
          ),
        ],
      ),
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
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
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
            '$value',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          IconButton(
            onPressed: value < max ? () => onChanged(value + 1) : null,
            icon: const Icon(Icons.add_circle_outline),
          ),
        ],
      ),
    );
  }

  Widget _pricePreview({
    required MachineryModel machinery,
    required BookingMode mode,
    required int hours,
    required int days,
    required double total,
  }) {
    final details = mode == BookingMode.daily
        ? '${_currency(machinery.pricePerDay)} x $days day(s)'
        : '${_currency(machinery.pricePerHour)} x $hours hour(s)';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Price Preview',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(details, style: TextStyle(color: Colors.grey.shade700)),
          const SizedBox(height: 4),
          Text(
            'Total: ${_currency(total)}',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: _primaryGreen,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _validationCard(String message) {
    return Container(
      key: const ValueKey<String>('validation-error'),
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Text(message, style: TextStyle(color: Colors.red.shade800)),
    );
  }

  Widget _availabilityCard() {
    return Container(
      key: const ValueKey<String>('validation-ok'),
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: const Text('Selected slot is available.'),
    );
  }

  Future<void> _confirmAndPay({
    required MachineryModel machinery,
    required BookingDraft draft,
    required List<BookingModel> bookings,
  }) async {
    if (_isSubmitting) return;

    final validationError = _validateDraft(
      draft: draft,
      selectedDate: draft.startDate,
      bookings: bookings,
    );

    if (validationError != null) {
      _showMessage(validationError);
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final profile = context.read<UserProfileProvider>().userData;
      final name = (profile['name'] ?? 'UzhavuSei User').toString();
      final email = (profile['email'] ?? 'user@example.com').toString();
      final phone = (profile['phone'] ?? '').toString().replaceAll(' ', '');
      final userId = _resolveUserId(profile, email);

      final paymentResult = await _paymentService.startPayment(
        PaymentRequest(
          key: Config.razorpayKey,
          amountInPaise: (draft.totalPrice * 100).round(),
          machineName: machinery.name,
          bookingDate: DateFormat('d MMM yyyy').format(draft.startDate),
          userName: name,
          userEmail: email,
          userPhone: phone,
        ),
      );

      if (!mounted) return;

      if (paymentResult.status != PaymentStatus.success ||
          paymentResult.paymentId == null) {
        _showPaymentFailedDialog(
          paymentResult.status == PaymentStatus.cancelled
              ? 'Payment was cancelled by user.'
              : (paymentResult.errorMessage ?? 'Payment failed. Try again.'),
        );
        return;
      }

      final bookingRepository =
          _bookingRepository ??= FirestoreBookingRepository();

      await bookingRepository.createBooking(
        draft: draft,
        userId: userId,
        paymentId: paymentResult.paymentId!,
      );

      if (!mounted) return;

      _showMessage('Booking confirmed and saved successfully.');
    } catch (error) {
      if (!mounted) return;
      _showPaymentFailedDialog('Unable to complete booking: $error');
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  String _resolveUserId(Map<String, dynamic> profile, String email) {
    final profileUserId = profile['userId']?.toString();
    if (profileUserId != null && profileUserId.trim().isNotEmpty) {
      return profileUserId;
    }

    if (email.trim().isNotEmpty) {
      return email.toLowerCase().replaceAll('@', '_').replaceAll('.', '_');
    }

    return 'guest_${DateTime.now().millisecondsSinceEpoch}';
  }

  BookingDraft _buildDraft({
    required String machineryId,
    required DateTime selectedDate,
    required BookingMode mode,
    required int days,
    required int hours,
    required int startHour,
    required double total,
  }) {
    if (mode == BookingMode.daily) {
      return BookingDraft(
        machineryId: machineryId,
        startDate: _dateOnly(selectedDate),
        endDate: _dateOnly(selectedDate).add(Duration(days: days - 1)),
        bookingType: 'daily',
        days: days,
        totalPrice: total,
      );
    }

    return BookingDraft(
      machineryId: machineryId,
      startDate: _dateOnly(selectedDate),
      endDate: _dateOnly(selectedDate),
      bookingType: 'hourly',
      hours: hours,
      startHour: startHour,
      totalPrice: total,
    );
  }

  String? _validateDraft({
    required BookingDraft draft,
    required DateTime selectedDate,
    required List<BookingModel> bookings,
  }) {
    if (_selectedMachineryId == null || _selectedMachineryId!.trim().isEmpty) {
      return 'Please select machinery first.';
    }

    if (_isDayBlocked(selectedDate, bookings)) {
      return 'Selected date is unavailable.';
    }

    if (draft.bookingType == 'daily') {
      if ((draft.days ?? 0) <= 0) {
        return 'Enter a valid number of days.';
      }
      if (draft.overlapsAny(bookings)) {
        return 'Selected days overlap an existing booking.';
      }
      return null;
    }

    if ((draft.hours ?? 0) <= 0) {
      return 'Enter valid hourly duration.';
    }

    final startHour = draft.startHour ?? -1;
    final hours = draft.hours ?? 0;
    final endHourExclusive = startHour + hours;
    if (startHour < 0 || startHour > 23) {
      return 'Choose a valid start time.';
    }
    if (endHourExclusive > 24) {
      return 'Hourly slot cannot cross midnight.';
    }
    if (draft.overlapsAny(bookings)) {
      return 'Selected hourly slot overlaps an existing booking.';
    }
    return null;
  }

  bool _isDayBlocked(DateTime day, List<BookingModel> bookings) {
    final normalized = _dateOnly(day);
    for (final booking in bookings) {
      if (!booking.blocksAvailability) continue;
      if (booking.overlapsDate(normalized)) return true;
    }
    return false;
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
          style: const TextStyle(fontSize: 16),
          textAlign: TextAlign.center,
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
                color: Colors.red, size: 44),
            const SizedBox(height: 12),
            Text(
              message,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFirebaseSetupState() {
    final rawReason = FirebaseBootstrap.initError ??
        'Firebase is not configured for this build variant.';
    final reason = _friendlyFirebaseError(rawReason);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 48, color: Colors.orange),
            const SizedBox(height: 12),
            const Text(
              'Firebase Setup Needed',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              reason,
              style: const TextStyle(fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'Add a valid google-services.json for Android and rebuild the app. '
              'After setup, this calendar page will automatically use Firestore data.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _friendlyFirebaseError(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('failed to load firebaseoptions')) {
      return 'Android Firebase configuration is missing or invalid for this app.';
    }
    if (lower.contains('no firebase app')) {
      return 'Firebase app is not initialized for this build.';
    }
    final condensed = message.split('\n').first.trim();
    return condensed.isEmpty
        ? 'Firebase setup is incomplete for this build.'
        : condensed;
  }

  void _showPaymentFailedDialog(String message) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Payment Failed'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  String _currency(double value) {
    return NumberFormat.currency(
      locale: 'en_IN',
      symbol: 'Rs.',
      decimalDigits: value % 1 == 0 ? 0 : 2,
    ).format(value);
  }

  String _hourLabel(int hour) {
    final date = DateTime(2000, 1, 1, hour % 24);
    return DateFormat('h a').format(date);
  }

  bool _sameDate(DateTime? a, DateTime? b) {
    if (a == null || b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  DateTime _dateOnly(DateTime day) => DateTime(day.year, day.month, day.day);

  bool _isBeforeToday(DateTime day) =>
      _dateOnly(day).isBefore(_dateOnly(_today));

  bool _containsMachinery(List<MachineryModel> list, String? id) {
    return _findById(list, id) != null;
  }

  MachineryModel? _findById(List<MachineryModel> list, String? id) {
    if (id == null) return null;
    for (final machine in list) {
      if (machine.id == id) return machine;
    }
    return null;
  }
}

enum BookingMode { hourly, daily }

class _LegendDot extends StatelessWidget {
  const _LegendDot(this.label, this.color, this.borderColor);

  final String label;
  final Color color;
  final Color borderColor;

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
        Text(label),
      ],
    );
  }
}
