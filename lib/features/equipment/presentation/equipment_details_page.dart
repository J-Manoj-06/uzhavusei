import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';

import '../../../models/marketplace_equipment_model.dart';
import '../../../providers/locale_provider.dart';
import '../../../services/marketplace_service.dart';
import '../../../services/deep_link_handler.dart';
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
  final MarketplaceService _service = MarketplaceService();
  
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedStartDay;
  DateTime? _selectedEndDay;

  int _currentImageIndex = 0;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Increment views when the page is opened
    _service.incrementEquipmentViews(widget.equipment.equipmentId);
  }

  Future<void> _launchYouTubeSearch(String query) async {
    final encodedQuery = Uri.encodeComponent(query);
    final url = 'https://www.youtube.com/results?search_query=$encodedQuery';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch YouTube.')),
        );
      }
    }
  }

  Future<void> _toggleSave(MarketplaceEquipmentModel item) async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      await _service.toggleSaveEquipment(widget.userId, item.equipmentId);
    } catch (e, stacktrace) {
      print('Save Error: $e');
      print(stacktrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save listing: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _shareListing(MarketplaceEquipmentModel item) async {
    final url = 'https://uzhavusei-a8be3.web.app/equipment/${item.equipmentId}';
    final text = 'Check out this ${item.equipmentName} available for rent on UzhavuSei!\n📍 ${item.location}\n💰 ₹${item.pricePerDay.toStringAsFixed(0)}/day\n\n$url';
    
    // Log analytics
    DeepLinkHandler.logShareEvent(item.equipmentId, widget.userId);
    
    // Native share sheet
    await Share.share(text);
  }

  bool _isDateAvailable(DateTime day, MarketplaceEquipmentModel item) {
    final start = item.availabilityFrom;
    final end = item.availabilityTo;

    if (!item.availability) return false;
    
    // Normalize dates to midnight
    final normDay = DateTime(day.year, day.month, day.day);
    
    if (start != null) {
      final normStart = DateTime(start.year, start.month, start.day);
      if (normDay.isBefore(normStart)) return false;
    }
    if (end != null) {
      final normEnd = DateTime(end.year, end.month, end.day);
      if (normDay.isAfter(normEnd)) return false;
    }

    // You would ideally check against actual booked dates here
    return true;
  }

  double _calculateTotal(MarketplaceEquipmentModel item) {
    if (_selectedStartDay == null) return 0;
    
    final endDay = _selectedEndDay ?? _selectedStartDay!;
    final diff = endDay.difference(_selectedStartDay!).inDays + 1; // inclusive
    
    return diff * item.pricePerDay;
  }

  void _openFullscreenImage(String imageUrl) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (ctx) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: Center(
          child: InteractiveViewer(
            panEnabled: false,
            boundaryMargin: const EdgeInsets.all(100),
            minScale: 0.5,
            maxScale: 2,
            child: buildSmartImage(imageUrl, fit: BoxFit.contain),
          ),
        ),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final languageCode = context.watch<LocaleProvider>().languageCode;

    return StreamBuilder<MarketplaceEquipmentModel>(
      stream: _service.watchEquipmentById(widget.equipment.equipmentId),
      initialData: widget.equipment,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Scaffold(body: Center(child: Text('Something went wrong')));
        }
        if (!snapshot.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final item = snapshot.data!;
        final title = item.titleForLanguage(languageCode);
        final category = item.categoryForLanguage(languageCode);
        final description = item.descriptionForLanguage(languageCode);
        final isSaved = item.savedBy.contains(widget.userId);
        final images = item.imageUrls.isEmpty ? ['assets/logo.jpg'] : item.imageUrls;

        return Scaffold(
          backgroundColor: const Color(0xFFF7F8FA),
          body: Stack(
            children: [
              SafeArea(
                bottom: false,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                  children: [
                    _buildPremiumImageGallery(item, images, isSaved),
                    const SizedBox(height: 24),
                    _buildTitleAndStatus(item, title, category),
                    const SizedBox(height: 24),
                    _buildOwnerCard(item),
                    const SizedBox(height: 24),
                    _buildSocialProof(item),
                    const SizedBox(height: 24),
                    _buildDetailsCard(item, description),
                    const SizedBox(height: 24),
                    _buildSpecifications(item),
                    const SizedBox(height: 24),
                    _buildTutorialButton(item),
                    const SizedBox(height: 24),
                    _buildModernCalendar(item),
                    const SizedBox(height: 24),
                    _buildPriceCalculator(item),
                    const SizedBox(height: 24),
                    _buildRelatedEquipment(item, category),
                  ],
                ),
              ),
              _buildBottomActionBar(item),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPremiumImageGallery(MarketplaceEquipmentModel item, List<String> images, bool isSaved) {
    return AspectRatio(
      aspectRatio: 4 / 3,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            fit: StackFit.expand,
            children: [
              PageView.builder(
                itemCount: images.length,
                onPageChanged: (index) {
                  setState(() => _currentImageIndex = index);
                },
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () => _openFullscreenImage(images[index]),
                    child: buildSmartImage(images[index], fit: BoxFit.cover),
                  );
                },
              ),
              // Top Left: Back Button
              Positioned(
                top: 16,
                left: 16,
                child: _buildGlassButton(
                  icon: Icons.arrow_back,
                  onTap: () => Navigator.pop(context),
                ),
              ),
              // Top Right: Share & Save
              Positioned(
                top: 16,
                right: 16,
                child: Row(
                  children: [
                    _buildGlassButton(
                      icon: Icons.share,
                      size: 20,
                      onTap: () => _shareListing(item),
                    ),
                    const SizedBox(width: 8),
                    _buildGlassButton(
                      icon: isSaved ? Icons.favorite : Icons.favorite_border,
                      color: isSaved ? Colors.red : Colors.black87,
                      size: 22,
                      onTap: () => _toggleSave(item),
                    ),
                  ],
                ),
              ),
              // Bottom: Photo Counter & Dots
              if (images.length > 1)
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Photo Counter
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.photo_camera, color: Colors.white, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              '${_currentImageIndex + 1} / ${images.length}',
                              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      // Dots
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(images.length, (index) {
                          final isActive = _currentImageIndex == index;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: isActive ? 20 : 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(3),
                              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 2)],
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlassButton({required IconData icon, required VoidCallback onTap, Color color = Colors.black87, double size = 24}) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.8),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: size),
          ),
        ),
      ),
    );
  }

  Widget _buildTitleAndStatus(MarketplaceEquipmentModel item, String title, String category) {
    final bool isAvailable = item.availability;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1A1A1A),
                  height: 1.2,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isAvailable ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isAvailable ? const Color(0xFF4CAF50) : const Color(0xFFF44336),
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isAvailable ? Icons.check_circle : Icons.do_not_disturb_alt,
                    size: 14,
                    color: isAvailable ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isAvailable ? 'Available Now' : 'Currently Rented',
                    style: TextStyle(
                      color: isAvailable ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F8E9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                category,
                style: const TextStyle(
                  color: Color(0xFF006E1C),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Icon(Icons.location_on, size: 16, color: Color(0xFF6F7A6B)),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                item.location,
                style: const TextStyle(color: Color(0xFF6F7A6B), fontSize: 14, fontWeight: FontWeight.w500),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOwnerCard(MarketplaceEquipmentModel item) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: const Color(0xFFE8F5E9),
            child: Text(
              item.ownerName.isNotEmpty ? item.ownerName[0].toUpperCase() : 'O',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF006E1C)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      item.ownerName,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.verified, color: Colors.blue, size: 18),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.workspace_premium, size: 14, color: Color(0xFF006E1C)),
                    const SizedBox(width: 4),
                    const Text(
                      'Trusted Equipment Owner',
                      style: TextStyle(color: Color(0xFF6F7A6B), fontSize: 12, fontWeight: FontWeight.w600),
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

  Widget _buildSocialProof(MarketplaceEquipmentModel item) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildStatColumn(Icons.visibility, '${item.views}', 'Views'),
        Container(width: 1, height: 30, color: const Color(0xFFE0E0E0)),
        _buildStatColumn(Icons.favorite, '${item.savedBy.length}', 'Saved'),
        Container(width: 1, height: 30, color: const Color(0xFFE0E0E0)),
        _buildStatColumn(Icons.calendar_month, '${item.bookingsCount}', 'Rentals'),
        Container(width: 1, height: 30, color: const Color(0xFFE0E0E0)),
        _buildStatColumn(Icons.star_rounded, item.rating > 0 ? item.rating.toStringAsFixed(1) : 'New', 'Rating', iconColor: Colors.amber),
      ],
    );
  }

  Widget _buildStatColumn(IconData icon, String value, String label, {Color? iconColor}) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: iconColor ?? const Color(0xFF6F7A6B)),
            const SizedBox(width: 4),
            Text(
              value,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF1A1A1A)),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Color(0xFF6F7A6B), fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildDetailsCard(MarketplaceEquipmentModel item, String description) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.description_outlined, color: Color(0xFF006E1C), size: 22),
                  SizedBox(width: 8),
                  Text(
                    'About this Equipment',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF4A4A4A),
                  height: 1.6,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSpecifications(MarketplaceEquipmentModel item) {
    final List<String> specs = [];
    specs.add('Condition: ${item.condition}');
    if (item.machineSpecs.isNotEmpty) {
      specs.addAll(item.machineSpecs.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty));
    }
    specs.addAll(item.tags);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Specifications & Features',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A)),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 12,
          children: specs.map((spec) => _buildSpecChip(spec)).toList(),
        ),
      ],
    );
  }

  Widget _buildSpecChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.flash_on, size: 14, color: Colors.orange),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF3F4A3C),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTutorialButton(MarketplaceEquipmentModel item) {
    return InkWell(
      onTap: () {
        final query = '${item.equipmentName} Tutorial';
        _launchYouTubeSearch(query);
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFEBEE), Color(0xFFFFCDD2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
              child: const Icon(Icons.play_arrow, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Watch Tutorial',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFC62828)),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Learn how to operate this equipment.',
                    style: TextStyle(fontSize: 12, color: Color(0xFFB71C1C)),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.red, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildModernCalendar(MarketplaceEquipmentModel item) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select Rental Dates',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A)),
          ),
          const SizedBox(height: 16),
          TableCalendar(
            firstDay: DateTime.now(),
            lastDay: DateTime.now().add(const Duration(days: 365)),
            focusedDay: _focusedDay,
            rangeSelectionMode: RangeSelectionMode.toggledOn,
            rangeStartDay: _selectedStartDay,
            rangeEndDay: _selectedEndDay,
            onDaySelected: (selectedDay, focusedDay) {
              if (!_isDateAvailable(selectedDay, item)) return;
              setState(() {
                _selectedStartDay = selectedDay;
                _selectedEndDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            onRangeSelected: (start, end, focusedDay) {
              setState(() {
                _selectedStartDay = start;
                _selectedEndDay = end;
                _focusedDay = focusedDay;
              });
            },
            enabledDayPredicate: (day) => _isDateAvailable(day, item),
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              leftChevronIcon: Icon(Icons.chevron_left, color: Color(0xFF006E1C)),
              rightChevronIcon: Icon(Icons.chevron_right, color: Color(0xFF006E1C)),
            ),
            calendarStyle: CalendarStyle(
              rangeHighlightColor: const Color(0xFFE8F5E9),
              rangeStartDecoration: const BoxDecoration(color: Color(0xFF006E1C), shape: BoxShape.circle),
              rangeEndDecoration: const BoxDecoration(color: Color(0xFF006E1C), shape: BoxShape.circle),
              withinRangeTextStyle: const TextStyle(color: Color(0xFF006E1C), fontWeight: FontWeight.w600),
              selectedDecoration: const BoxDecoration(color: Color(0xFF006E1C), shape: BoxShape.circle),
              todayDecoration: BoxDecoration(
                color: Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF006E1C), width: 2),
              ),
              todayTextStyle: const TextStyle(color: Color(0xFF006E1C), fontWeight: FontWeight.bold),
              disabledTextStyle: TextStyle(color: Colors.grey.shade400, decoration: TextDecoration.lineThrough),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _legendDot(const Color(0xFFE8F5E9), const Color(0xFF4CAF50), 'Available'),
              const SizedBox(width: 16),
              _legendDot(Colors.red.shade50, Colors.red, 'Booked'),
              const SizedBox(width: 16),
              _legendDot(Colors.grey.shade100, Colors.grey.shade400, 'Unavailable'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color bgColor, Color fgColor, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: fgColor, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(color: Colors.grey.shade700, fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildPriceCalculator(MarketplaceEquipmentModel item) {
    if (_selectedStartDay == null) return const SizedBox.shrink();

    final endDay = _selectedEndDay ?? _selectedStartDay!;
    final days = endDay.difference(_selectedStartDay!).inDays + 1;
    final total = _calculateTotal(item);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F8E9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFC8E6C9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Booking Summary',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('₹${item.pricePerDay.toStringAsFixed(0)} x $days Days', style: const TextStyle(color: Color(0xFF3F4A3C), fontSize: 15)),
              Text('₹${total.toStringAsFixed(0)}', style: const TextStyle(color: Color(0xFF1A1A1A), fontSize: 15, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 8),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Security Deposit (Refundable)', style: TextStyle(color: Color(0xFF3F4A3C), fontSize: 15)),
              Text('₹500', style: TextStyle(color: Color(0xFF1A1A1A), fontSize: 15, fontWeight: FontWeight.w600)),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: Color(0xFFC8E6C9)),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Estimate', style: TextStyle(color: Color(0xFF1A1A1A), fontSize: 18, fontWeight: FontWeight.bold)),
              Text('₹${(total + 500).toStringAsFixed(0)}', style: const TextStyle(color: Color(0xFF006E1C), fontSize: 20, fontWeight: FontWeight.w900)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRelatedEquipment(MarketplaceEquipmentModel item, String category) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Similar Equipment Nearby',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A)),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 220,
          child: StreamBuilder<List<MarketplaceEquipmentModel>>(
            stream: _service.watchRelatedEquipment(category: category, currentEquipmentId: item.equipmentId),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                  child: Text(
                    'No similar equipment found.',
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
                );
              }
              final related = snapshot.data!;
              return ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: related.length,
                itemBuilder: (context, index) {
                  final rel = related[index];
                  return Container(
                    width: 160,
                    margin: const EdgeInsets.only(right: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: InkWell(
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => EquipmentDetailsPage(
                              equipment: rel,
                              userId: widget.userId,
                              userName: widget.userName,
                              userEmail: widget.userEmail,
                              userPhone: widget.userPhone,
                            ),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                            child: SizedBox(
                              height: 100,
                              width: 160,
                              child: buildSmartImage(
                                rel.imageUrls.isNotEmpty ? rel.imageUrls.first : 'assets/logo.jpg',
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  rel.equipmentName,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.star_rounded, size: 14, color: Colors.amber),
                                    Text(
                                      rel.rating > 0 ? rel.rating.toStringAsFixed(1) : 'New',
                                      style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '₹${rel.pricePerDay.toStringAsFixed(0)}/day',
                                  style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF006E1C), fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBottomActionBar(MarketplaceEquipmentModel item) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 24,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: Row(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Price',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.w600),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₹${item.pricePerDay.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(bottom: 4, left: 2),
                      child: Text('/day', style: TextStyle(color: Color(0xFF6F7A6B), fontSize: 14)),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4CAF50).withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: item.availability
                      ? () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => BookingPaymentPage(
                                equipment: item,
                                userId: widget.userId,
                                userName: widget.userName,
                                userEmail: widget.userEmail,
                                userPhone: widget.userPhone,
                              ),
                            ),
                          );
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text(
                    'Rent Now',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
