import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../config.dart';
import '../../../models/marketplace_equipment_model.dart';
import '../../../services/marketplace_service.dart';
import '../../../services/razorpay_checkout_service.dart';
import '../../../widgets/image_loader.dart';

class BookingPaymentPage extends StatefulWidget {
  const BookingPaymentPage({
    super.key,
    required this.equipment,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.userPhone,
  });

  final MarketplaceEquipmentModel equipment;
  final String userId;
  final String userName;
  final String userEmail;
  final String userPhone;

  @override
  State<BookingPaymentPage> createState() => _BookingPaymentPageState();
}

class _BookingPaymentPageState extends State<BookingPaymentPage> {
  static const _green = Color(0xFF4CAF50);
  static const _darkGreen = Color(0xFF2E7D32);
  static const _lightGreen = Color(0xFFE8F5E9);
  static const _bgColor = Color(0xFFF7F8FA);

  final _service = MarketplaceService();
  late final RazorpayCheckoutService _paymentService;

  DateTime? _startDate;
  TimeOfDay? _startTime;
  DateTime? _endDate;
  TimeOfDay? _endTime;

  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _paymentService = RazorpayCheckoutService();
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, now.day);
    _startTime = TimeOfDay(hour: now.hour, minute: 0);
    _endDate = DateTime(now.year, now.month, now.day + 1);
    _endTime = TimeOfDay(hour: now.hour, minute: 0);
  }

  @override
  void dispose() {
    _paymentService.dispose();
    super.dispose();
  }

  // ── Computed helpers ──────────────────────────────────────────────────────

  DateTime get _startDT {
    final d = _startDate!;
    final t = _startTime!;
    return DateTime(d.year, d.month, d.day, t.hour, t.minute);
  }

  DateTime get _endDT {
    final d = _endDate!;
    final t = _endTime!;
    return DateTime(d.year, d.month, d.day, t.hour, t.minute);
  }

  bool get _datesReady =>
      _startDate != null &&
      _startTime != null &&
      _endDate != null &&
      _endTime != null;

  bool get _isValidRange => _datesReady && _endDT.isAfter(_startDT);

  Duration get _duration =>
      _isValidRange ? _endDT.difference(_startDT) : Duration.zero;

  bool get _isHourly => _duration.inHours < 24;

  double get _totalPrice {
    if (!_isValidRange) return 0;
    if (_isHourly) {
      return widget.equipment.pricePerHour * (_duration.inMinutes / 60.0);
    }
    return widget.equipment.pricePerDay * (_duration.inMinutes / (60.0 * 24.0));
  }

  String get _durationLabel {
    final d = _duration;
    final days = d.inDays;
    final hrs = d.inHours % 24;
    final mins = d.inMinutes % 60;
    if (days > 0 && hrs > 0) {
      return '$days day${days > 1 ? 's' : ''} $hrs hr${hrs > 1 ? 's' : ''}';
    }
    if (days > 0) return '$days day${days > 1 ? 's' : ''}';
    if (hrs > 0 && mins > 0) return '$hrs hr${hrs > 1 ? 's' : ''} $mins min';
    if (hrs > 0) return '$hrs hr${hrs > 1 ? 's' : ''}';
    return '$mins min';
  }

  String get _rateLabel => _isHourly
      ? '₹${widget.equipment.pricePerHour.toStringAsFixed(0)} / hour'
      : '₹${widget.equipment.pricePerDay.toStringAsFixed(0)} / day';

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        title: const Text(
          'Book Equipment',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        backgroundColor: _green,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildEquipmentCard(),
                const SizedBox(height: 24),
                _sectionTitle('Date & Time'),
                const SizedBox(height: 10),
                _buildDateTimeGrid(),
                AnimatedSize(
                  duration: const Duration(milliseconds: 200),
                  child: _datesReady && !_isValidRange
                      ? _buildValidationError()
                      : const SizedBox.shrink(),
                ),
                const SizedBox(height: 24),
                _sectionTitle('Pricing Breakdown'),
                const SizedBox(height: 10),
                _buildPricingCard(),
                const SizedBox(height: 16),
                _buildCancellationPolicy(),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildStickyButton(),
          ),
        ],
      ),
    );
  }

  // ── Section title ─────────────────────────────────────────────────────────

  Widget _sectionTitle(String text) => Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: Color(0xFF1A1A1A),
        ),
      );

  // ── Equipment card ────────────────────────────────────────────────────────

  Widget _buildEquipmentCard() {
    final item = widget.equipment;
    final imageUrl =
        item.imageUrls.isNotEmpty ? item.imageUrls.first : 'assets/logo.jpg';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: SizedBox(
              height: 180,
              width: double.infinity,
              child: buildSmartImage(imageUrl, fit: BoxFit.cover),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.equipmentName,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.category,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _availabilityBadge(item.availability),
                  ],
                ),
                if (item.description.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    item.description,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade700,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 12),
                _infoRow(Icons.location_on_outlined, item.location),
                const SizedBox(height: 4),
                _infoRow(Icons.person_outline, item.ownerName),
                if (item.machineSpecs.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  _infoRow(Icons.settings_outlined, item.machineSpecs),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    _priceBadge(
                        '₹${item.pricePerHour.toStringAsFixed(0)}/hr', false),
                    const SizedBox(width: 8),
                    _priceBadge(
                        '₹${item.pricePerDay.toStringAsFixed(0)}/day', true),
                    const Spacer(),
                    if (item.rating > 0)
                      Row(
                        children: [
                          const Icon(Icons.star_rounded,
                              size: 16, color: Color(0xFFFFA000)),
                          const SizedBox(width: 3),
                          Text(
                            item.rating.toStringAsFixed(1),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _availabilityBadge(bool available) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: available ? _lightGreen : Colors.red.shade50,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: available ? _green : Colors.red.shade300,
          ),
        ),
        child: Text(
          available ? 'Available' : 'Unavailable',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: available ? _darkGreen : Colors.red.shade700,
          ),
        ),
      );

  Widget _infoRow(IconData icon, String text) => Row(
        children: [
          Icon(icon, size: 15, color: Colors.grey.shade500),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );

  Widget _priceBadge(String text, bool isPrimary) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: isPrimary ? _green : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isPrimary ? Colors.white : Colors.grey.shade800,
          ),
        ),
      );

  // ── Date & time grid ──────────────────────────────────────────────────────

  Widget _buildDateTimeGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _inputCard(
                label: 'Start Date',
                value: _startDate != null
                    ? DateFormat('dd MMM yyyy').format(_startDate!)
                    : 'Pick date',
                icon: Icons.calendar_today_outlined,
                onTap: _pickStartDate,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _inputCard(
                label: 'Start Time',
                value: _startTime != null ? _fmt(_startTime!) : 'Pick time',
                icon: Icons.access_time_outlined,
                onTap: _pickStartTime,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _inputCard(
                label: 'End Date',
                value: _endDate != null
                    ? DateFormat('dd MMM yyyy').format(_endDate!)
                    : 'Pick date',
                icon: Icons.event_outlined,
                onTap: _pickEndDate,
                error: _datesReady && !_isValidRange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _inputCard(
                label: 'End Time',
                value: _endTime != null ? _fmt(_endTime!) : 'Pick time',
                icon: Icons.schedule_outlined,
                onTap: _pickEndTime,
                error: _datesReady && !_isValidRange,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _inputCard({
    required String label,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
    bool error = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: error ? Colors.red.shade300 : Colors.grey.shade200,
            width: error ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 14, color: error ? Colors.red : _green),
                const SizedBox(width: 5),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: error ? Colors.red.shade400 : Colors.grey.shade500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: error ? Colors.red.shade700 : const Color(0xFF1A1A1A),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildValidationError() => Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.red.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.warning_amber_rounded,
                  size: 16, color: Colors.red.shade700),
              const SizedBox(width: 8),
              Text(
                'End date & time must be after start.',
                style: TextStyle(fontSize: 12, color: Colors.red.shade700),
              ),
            ],
          ),
        ),
      );

  // ── Pricing card ──────────────────────────────────────────────────────────

  Widget _buildPricingCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _priceRow('Rate', _rateLabel),
          const SizedBox(height: 10),
          _priceRow('Duration', _isValidRange ? _durationLabel : '—'),
          const SizedBox(height: 10),
          _priceRow(
            'Type',
            _isValidRange
                ? (_isHourly ? 'Hourly rental' : 'Daily rental')
                : '—',
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Divider(height: 1, thickness: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Amount',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, anim) => FadeTransition(
                    opacity: anim,
                    child: ScaleTransition(scale: anim, child: child)),
                child: Text(
                  _isValidRange ? '₹${_totalPrice.toStringAsFixed(0)}' : '₹ —',
                  key: ValueKey(_isValidRange
                      ? _totalPrice.toStringAsFixed(0)
                      : 'invalid'),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: _darkGreen,
                  ),
                ),
              ),
            ],
          ),
          if (_isValidRange) ...[
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'inclusive of all charges',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _priceRow(String label, String value) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1A1A1A),
            ),
          ),
        ],
      );

  Widget _buildCancellationPolicy() => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF8E1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFFE082)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.info_outline, size: 16, color: Color(0xFFF57F17)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Free cancellation up to 24 hours before booking starts. '
                'After that, a 20% cancellation fee applies.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.brown.shade700,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      );

  // ── Sticky button ─────────────────────────────────────────────────────────

  Widget _buildStickyButton() {
    final canProceed =
        _isValidRange && !_isProcessing && widget.equipment.availability;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: canProceed ? _proceedPayment : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: _green,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey.shade300,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
            child: _isProcessing
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.lock_outline_rounded, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        _isValidRange
                            ? 'Pay ₹${_totalPrice.toStringAsFixed(0)} via Razorpay'
                            : 'Select valid dates to continue',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  // ── Pickers ───────────────────────────────────────────────────────────────

  Future<void> _pickStartDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      builder: _pickerTheme,
    );
    if (picked == null || !mounted) return;
    setState(() {
      _startDate = picked;
      if (_endDate != null && !_endDT.isAfter(_startDT)) {
        _endDate = picked.add(const Duration(days: 1));
      }
    });
  }

  Future<void> _pickStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime ?? TimeOfDay.now(),
      builder: _pickerTheme,
    );
    if (picked == null || !mounted) return;
    setState(() => _startTime = picked);
  }

  Future<void> _pickEndDate() async {
    final earliest = _startDate ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? earliest.add(const Duration(days: 1)),
      firstDate: earliest,
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: _pickerTheme,
    );
    if (picked == null || !mounted) return;
    setState(() => _endDate = picked);
  }

  Future<void> _pickEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _endTime ?? TimeOfDay.now(),
      builder: _pickerTheme,
    );
    if (picked == null || !mounted) return;
    setState(() => _endTime = picked);
  }

  Widget _pickerTheme(BuildContext ctx, Widget? child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: _green,
            onPrimary: Colors.white,
            onSurface: Color(0xFF1A1A1A),
          ),
        ),
        child: child!,
      );

  String _fmt(TimeOfDay t) {
    final h = t.hour == 0 ? 12 : (t.hour > 12 ? t.hour - 12 : t.hour);
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m ${t.hour < 12 ? 'AM' : 'PM'}';
  }

  // ── Payment flow ──────────────────────────────────────────────────────────

  Future<void> _proceedPayment() async {
    if (!_isValidRange) return;
    if (!widget.equipment.availability) {
      _showError('This equipment is currently unavailable.');
      return;
    }

    setState(() => _isProcessing = true);

    // Recalculate server-side price — do not trust UI display alone
    final hours = _duration.inMinutes / 60.0;
    final totalPrice = _isHourly
        ? widget.equipment.pricePerHour * hours
        : widget.equipment.pricePerDay * (_duration.inMinutes / (60.0 * 24.0));

    if (totalPrice <= 0) {
      setState(() => _isProcessing = false);
      _showError('Booking amount must be greater than 0.');
      return;
    }

    final result = await _paymentService.startPayment(
      PaymentRequest(
        key: Config.razorpayKey,
        amountInPaise: (totalPrice * 100).round(),
        machineName: widget.equipment.equipmentName,
        bookingDate: DateFormat('dd MMM yyyy').format(_startDT),
        userName: widget.userName,
        userEmail: widget.userEmail,
        userPhone: widget.userPhone,
      ),
    );

    if (!mounted) return;

    if (result.status == PaymentStatus.success && result.paymentId != null) {
      await _saveBooking(result.paymentId!, totalPrice);
    } else {
      setState(() => _isProcessing = false);
      final msg = result.status == PaymentStatus.cancelled
          ? 'Payment was cancelled.'
          : (result.errorMessage ?? 'Payment failed. Please try again.');
      _showError(msg);
    }
  }

  Future<void> _saveBooking(String paymentId, double totalPrice) async {
    try {
      final imageUrl = widget.equipment.imageUrls.isNotEmpty
          ? widget.equipment.imageUrls.first
          : '';

      await _service.createBooking(
        equipmentId: widget.equipment.equipmentId,
        ownerId: widget.equipment.ownerId,
        userId: widget.userId,
        equipmentName: widget.equipment.equipmentName,
        imageUrl: imageUrl,
        ownerName: widget.equipment.ownerName,
        location: widget.equipment.location,
        startDateTime: _startDT,
        endDateTime: _endDT,
        bookingType: _isHourly ? 'hourly' : 'daily',
        duration: _durationLabel,
        totalPrice: totalPrice,
        paymentId: paymentId,
      );

      if (!mounted) return;
      setState(() => _isProcessing = false);
      _showSuccessDialog(paymentId, totalPrice);
    } catch (error) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      _showError('Booking save failed: $error');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ── Success dialog ────────────────────────────────────────────────────────

  void _showSuccessDialog(String paymentId, double totalPrice) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _SuccessDialog(
        equipmentName: widget.equipment.equipmentName,
        startDT: _startDT,
        endDT: _endDT,
        startTime: _startTime!,
        endTime: _endTime!,
        durationLabel: _durationLabel,
        totalPrice: totalPrice,
        paymentId: paymentId,
        fmtTime: _fmt,
        onContinue: () {
          Navigator.of(ctx).pop();
          Navigator.of(context).pop();
        },
      ),
    );
  }
}

// ── Success dialog widget ─────────────────────────────────────────────────────

class _SuccessDialog extends StatelessWidget {
  const _SuccessDialog({
    required this.equipmentName,
    required this.startDT,
    required this.endDT,
    required this.startTime,
    required this.endTime,
    required this.durationLabel,
    required this.totalPrice,
    required this.paymentId,
    required this.fmtTime,
    required this.onContinue,
  });

  final String equipmentName;
  final DateTime startDT;
  final DateTime endDT;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final String durationLabel;
  final double totalPrice;
  final String paymentId;
  final String Function(TimeOfDay) fmtTime;
  final VoidCallback onContinue;

  static const _green = Color(0xFF4CAF50);
  static const _darkGreen = Color(0xFF2E7D32);
  static const _lightGreen = Color(0xFFE8F5E9);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                  color: _lightGreen, shape: BoxShape.circle),
              child: const Icon(Icons.check_circle_rounded,
                  color: _green, size: 46),
            ),
            const SizedBox(height: 16),
            const Text(
              'Booking Confirmed!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '$equipmentName has been successfully booked.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13, color: Colors.grey.shade600, height: 1.4),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _lightGreen,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  _row('Equipment', equipmentName),
                  const SizedBox(height: 6),
                  _row(
                    'Start',
                    '${DateFormat('dd MMM yyyy').format(startDT)} · ${fmtTime(startTime)}',
                  ),
                  const SizedBox(height: 6),
                  _row(
                    'End',
                    '${DateFormat('dd MMM yyyy').format(endDT)} · ${fmtTime(endTime)}',
                  ),
                  const SizedBox(height: 6),
                  _row('Duration', durationLabel),
                  const Divider(height: 18, thickness: 1),
                  _row(
                    'Amount Paid',
                    '₹${totalPrice.toStringAsFixed(0)}',
                    bold: true,
                    green: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Payment ID: $paymentId',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onContinue,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                ),
                child: const Text(
                  'Done',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value,
          {bool bold = false, bool green = false}) =>
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: bold ? 15 : 13,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                color: green ? _darkGreen : const Color(0xFF1A1A1A),
              ),
            ),
          ),
        ],
      );
}
