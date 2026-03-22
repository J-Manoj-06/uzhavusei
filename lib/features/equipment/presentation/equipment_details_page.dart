import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/marketplace_equipment_model.dart';
import '../../../providers/locale_provider.dart';
import '../../../widgets/image_loader.dart';
import 'booking_payment_page.dart';

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
  @override
  Widget build(BuildContext context) {
    final item = widget.equipment;
    final languageCode = context.watch<LocaleProvider>().languageCode;
    final title = item.titleForLanguage(languageCode);
    final category = item.categoryForLanguage(languageCode);
    final description = item.descriptionForLanguage(languageCode);
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
            title,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(category, style: TextStyle(color: Colors.grey.shade700)),
          const SizedBox(height: 8),
          Text(description),
          const SizedBox(height: 12),
          _line('Owner', item.ownerName),
          _line('Location', item.location),
          _line('Rating', item.rating.toStringAsFixed(1)),
          _line('Price/hour', '₹${item.pricePerHour.toStringAsFixed(2)}'),
          _line('Price/day', '₹${item.pricePerDay.toStringAsFixed(2)}'),
          _line(
              'Availability', item.availability ? 'Available' : 'Unavailable'),
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
            onPressed: item.availability
                ? () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BookingPaymentPage(
                          equipment: widget.equipment,
                          userId: widget.userId,
                          userName: widget.userName,
                          userEmail: widget.userEmail,
                          userPhone: widget.userPhone,
                        ),
                      ),
                    )
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Book Equipment',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
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
}
