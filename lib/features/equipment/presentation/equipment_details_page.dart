import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../config.dart';
import '../../../models/marketplace_equipment_model.dart';
import '../../../services/marketplace_service.dart';
import '../../../services/razorpay_checkout_service.dart';
import '../../../widgets/image_loader.dart';

class EquipmentDetailsPage extends StatefulWidget {
  const EquipmentDetailsPage({
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
  State<EquipmentDetailsPage> createState() => _EquipmentDetailsPageState();
}

class _EquipmentDetailsPageState extends State<EquipmentDetailsPage> {
  final _marketplaceService = MarketplaceService();
  late final RazorpayCheckoutService _paymentService;

  @override
  void initState() {
    super.initState();
    _paymentService = RazorpayCheckoutService();
  }

  @override
  void dispose() {
    _paymentService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.equipment;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Equipment Details'),
        backgroundColor: const Color(0xFF4CAF50),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SizedBox(
            height: 230,
            child: PageView.builder(
              itemCount: item.imageUrls.isEmpty ? 1 : item.imageUrls.length,
              itemBuilder: (context, index) {
                final imageUrl = item.imageUrls.isEmpty
                    ? 'assets/logo.jpg'
                    : item.imageUrls[index];
                return ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: buildSmartImage(imageUrl, fit: BoxFit.cover),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Text(
            item.equipmentName,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(item.category, style: TextStyle(color: Colors.grey.shade700)),
          const SizedBox(height: 8),
          Text(item.description),
          const SizedBox(height: 12),
          _line('Owner', item.ownerName),
          _line('Location', item.location),
          _line('Rating', item.rating.toStringAsFixed(1)),
          _line('Price/hour', '₹${item.pricePerHour.toStringAsFixed(2)}'),
          _line('Price/day', '₹${item.pricePerDay.toStringAsFixed(2)}'),
          _line('Availability', item.availability ? 'Available' : 'Unavailable'),
          const SizedBox(height: 8),
          if (item.machineSpecs.trim().isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('Specs: ${item.machineSpecs}'),
            ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: item.availability ? _openBookingPanel : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: const Text('Book Equipment'),
          ),
        ],
      ),
    );
  }

  Widget _line(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 95,
            child: Text(label, style: TextStyle(color: Colors.grey.shade700)),
          ),
          const Text(': '),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Future<void> _openBookingPanel() async {
    String type = 'daily';
    DateTime start = DateTime.now();
    int days = 1;
    int hours = 2;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final total = type == 'daily'
                ? widget.equipment.pricePerDay * days
                : widget.equipment.pricePerHour * hours;
            final end = type == 'daily'
                ? start.add(Duration(days: days - 1))
                : start;

            return Padding(
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
                    const Text(
                      'Booking Panel',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 10),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'hourly', label: Text('Hourly')),
                        ButtonSegment(value: 'daily', label: Text('Daily')),
                      ],
                      selected: {type},
                      onSelectionChanged: (s) {
                        setSheetState(() {
                          type = s.first;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Start Date'),
                      subtitle: Text(DateFormat('dd MMM yyyy').format(start)),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                          initialDate: start,
                        );
                        if (picked == null) return;
                        setSheetState(() {
                          start = picked;
                        });
                      },
                    ),
                    if (type == 'daily') ...[
                      _stepper(
                        label: 'Number of Days',
                        value: days,
                        min: 1,
                        max: 30,
                        onChanged: (v) => setSheetState(() => days = v),
                      ),
                    ] else ...[
                      _stepper(
                        label: 'Hours',
                        value: hours,
                        min: 1,
                        max: 12,
                        onChanged: (v) => setSheetState(() => hours = v),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Text('End: ${DateFormat('dd MMM yyyy').format(end)}'),
                    const SizedBox(height: 8),
                    Text(
                      'Total: ₹${total.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Color(0xFF2E7D32),
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(context);
                          await _proceedPayment(
                            bookingType: type,
                            startDate: start,
                            endDate: end,
                            total: total,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4CAF50),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Proceed to Payment'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _stepper({
    required String label,
    required int value,
    required int min,
    required int max,
    required ValueChanged<int> onChanged,
  }) {
    return Row(
      children: [
        Expanded(child: Text(label)),
        IconButton(
          onPressed: value > min ? () => onChanged(value - 1) : null,
          icon: const Icon(Icons.remove_circle_outline),
        ),
        Text('$value'),
        IconButton(
          onPressed: value < max ? () => onChanged(value + 1) : null,
          icon: const Icon(Icons.add_circle_outline),
        ),
      ],
    );
  }

  Future<void> _proceedPayment({
    required String bookingType,
    required DateTime startDate,
    required DateTime endDate,
    required double total,
  }) async {
    final result = await _paymentService.startPayment(
      PaymentRequest(
        key: Config.razorpayKey,
        amountInPaise: (total * 100).round(),
        machineName: widget.equipment.equipmentName,
        bookingDate: DateFormat('dd MMM yyyy').format(startDate),
        userName: widget.userName,
        userEmail: widget.userEmail,
        userPhone: widget.userPhone,
      ),
    );

    if (!mounted) return;

    if (result.status != PaymentStatus.success || result.paymentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.errorMessage ?? 'Payment failed/cancelled'),
        ),
      );
      return;
    }

    try {
      await _marketplaceService.createBooking(
        equipmentId: widget.equipment.equipmentId,
        ownerId: widget.equipment.ownerId,
        userId: widget.userId,
        equipmentName: widget.equipment.equipmentName,
        location: widget.equipment.location,
        startDate: startDate,
        endDate: endDate,
        bookingType: bookingType,
        totalPrice: total,
        paymentId: result.paymentId!,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking created successfully')), 
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Booking save failed: $error')),
      );
    }
  }
}
