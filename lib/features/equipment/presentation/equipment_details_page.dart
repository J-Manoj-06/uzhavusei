import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:url_launcher/url_launcher.dart';

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
  DateTime _focusedDay = DateTime.now();

  Future<void> _launchTutorial(String url) async {
    if (url.trim().isEmpty) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch tutorial video.')),
        );
      }
    }
  }

  bool _isDateAvailable(DateTime day) {
    final start = widget.equipment.availabilityFrom;
    final end = widget.equipment.availabilityTo;

    // If both are null, assume available.
    if (start == null && end == null) return widget.equipment.availability;

    // Normalize all times to midnight to just compare dates
    final normDay = DateTime(day.year, day.month, day.day);
    final normStart = start != null ? DateTime(start.year, start.month, start.day) : null;
    final normEnd = end != null ? DateTime(end.year, end.month, end.day) : null;

    if (normStart != null && normDay.isBefore(normStart)) return false;
    if (normEnd != null && normDay.isAfter(normEnd)) return false;

    return widget.equipment.availability;
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.equipment;
    final languageCode = context.watch<LocaleProvider>().languageCode;
    final title = item.titleForLanguage(languageCode);
    final category = item.categoryForLanguage(languageCode);
    final description = item.descriptionForLanguage(languageCode);

    final start = item.availabilityFrom;
    final end = item.availabilityTo;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // 1. Image Header
              SliverAppBar(
                expandedHeight: 280,
                pinned: true,
                backgroundColor: const Color(0xFF4CAF50),
                foregroundColor: Colors.white,
                flexibleSpace: FlexibleSpaceBar(
                  background: PageView.builder(
                    itemCount: item.imageUrls.isEmpty ? 1 : item.imageUrls.length,
                    itemBuilder: (context, index) {
                      final imageUrl = item.imageUrls.isEmpty
                          ? 'assets/logo.jpg'
                          : item.imageUrls[index];
                      return Stack(
                        fit: StackFit.expand,
                        children: [
                          buildSmartImage(imageUrl, fit: BoxFit.cover),
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.black.withValues(alpha: 0.5),
                                  Colors.transparent,
                                  Colors.black.withValues(alpha: 0.1),
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 2. Name and Category
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: const TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF1A1A1A),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        category,
                                        style: const TextStyle(
                                          color: Color(0xFF4CAF50),
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Icon(Icons.location_on, size: 16, color: Colors.grey.shade500),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        item.location,
                                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          if (item.rating > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.amber.shade200),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.star_rounded, size: 18, color: Colors.amber),
                                  const SizedBox(width: 4),
                                  Text(
                                    item.rating.toStringAsFixed(1),
                                    style: TextStyle(fontWeight: FontWeight.w700, color: Colors.amber.shade900),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // 3. Details Section & Tutorial Button
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Details',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              description,
                              style: TextStyle(color: Colors.grey.shade700, height: 1.5),
                            ),
                            if (item.machineSpecs.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              const Text(
                                'Specifications',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item.machineSpecs,
                                style: TextStyle(color: Colors.grey.shade700),
                              ),
                            ],
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: item.videoUrl.isNotEmpty
                                    ? () => _launchTutorial(item.videoUrl)
                                    : null,
                                icon: const Icon(Icons.play_circle_fill, color: Colors.red),
                                label: const Text('Watch Tutorial Video'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  side: BorderSide(color: Colors.grey.shade300),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // 4. Availability Dates & Calendar
                      const Text(
                        'Availability',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Explicit Dates
                            Row(
                              children: [
                                const Icon(Icons.date_range, color: Color(0xFF4CAF50)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    start != null && end != null
                                        ? '${DateFormat('MMM d, yyyy').format(start)} - ${DateFormat('MMM d, yyyy').format(end)}'
                                        : 'Always Available',
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                                  ),
                                ),
                              ],
                            ),
                            if (start != null && end != null) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.access_time, color: Colors.grey, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${DateFormat('hh:mm a').format(start)} to ${DateFormat('hh:mm a').format(end)}',
                                    style: TextStyle(color: Colors.grey.shade600),
                                  ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 16),
                            const Divider(),
                            const SizedBox(height: 8),
                            // Informational Calendar
                            TableCalendar(
                              firstDay: DateTime.now().subtract(const Duration(days: 30)),
                              lastDay: DateTime.now().add(const Duration(days: 365)),
                              focusedDay: _focusedDay,
                              headerStyle: const HeaderStyle(
                                formatButtonVisible: false,
                                titleCentered: true,
                              ),
                              calendarStyle: CalendarStyle(
                                outsideDaysVisible: false,
                                disabledTextStyle: TextStyle(color: Colors.grey.shade400),
                              ),
                              enabledDayPredicate: _isDateAvailable,
                              onPageChanged: (focusedDay) {
                                _focusedDay = focusedDay;
                              },
                              calendarBuilders: CalendarBuilders(
                                defaultBuilder: (context, day, focusedDay) {
                                  final isAvailable = _isDateAvailable(day);
                                  return Container(
                                    margin: const EdgeInsets.all(6),
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: isAvailable ? const Color(0xFFE8F5E9) : Colors.grey.shade100,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Text(
                                      '${day.day}',
                                      style: TextStyle(
                                        color: isAvailable ? const Color(0xFF4CAF50) : Colors.grey.shade500,
                                        fontWeight: isAvailable ? FontWeight.w600 : FontWeight.normal,
                                      ),
                                    ),
                                  );
                                },
                                disabledBuilder: (context, day, focusedDay) {
                                  return Container(
                                    margin: const EdgeInsets.all(6),
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade200,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Text(
                                      '${day.day}',
                                      style: TextStyle(color: Colors.grey.shade400),
                                    ),
                                  );
                                },
                                todayBuilder: (context, day, focusedDay) {
                                  final isAvailable = _isDateAvailable(day);
                                  return Container(
                                    margin: const EdgeInsets.all(6),
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: isAvailable ? const Color(0xFF4CAF50) : Colors.grey.shade400,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Text(
                                      '${day.day}',
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _legendItem(const Color(0xFFE8F5E9), const Color(0xFF4CAF50), 'Available'),
                                const SizedBox(width: 16),
                                _legendItem(Colors.grey.shade200, Colors.grey.shade500, 'Unavailable'),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // 5. Price Breakdown
                      const Text(
                        'Pricing Breakdown',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _priceCard('Hourly Rate', '₹${item.pricePerHour.toStringAsFixed(0)}'),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _priceCard('Daily Rate', '₹${item.pricePerDay.toStringAsFixed(0)}'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Note: Final amount is calculated dynamically based on chosen duration.',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // 6. Sticky Rent Now Button
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
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
                child: Row(
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'From',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                        ),
                        Text(
                          '₹${item.pricePerHour.toStringAsFixed(0)}/hr',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: ElevatedButton(
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
                            disabledBackgroundColor: Colors.grey.shade300,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Rent Now',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendItem(Color bg, Color fg, String text) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(text, style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _priceCard(String title, String amount) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Text(title, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          const SizedBox(height: 8),
          Text(
            amount,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF4CAF50)),
          ),
        ],
      ),
    );
  }
}
