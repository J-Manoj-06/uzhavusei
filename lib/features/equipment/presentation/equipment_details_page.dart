import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../../../models/marketplace_equipment_model.dart';
import '../../../providers/locale_provider.dart';
import '../../../services/marketplace_service.dart';
import '../../../services/deep_link_handler.dart';
import '../../../widgets/image_loader.dart';
import '../../profile/presentation/public_profile_page.dart';
import '../../../services/logger_service.dart';
import 'create_listing_flow.dart';
import '../../../models/app_user_model.dart';
import '../../profile/presentation/my_listings_page.dart';
import '../../profile/presentation/my_bookings_page.dart';
import 'widgets/borrow_image_picker.dart';
import '../../../services/cloudinary_service.dart';
import 'package:UzhavuSei/theme/app_theme.dart';
import '../../../widgets/borrow_product_id_card.dart';
import '../../../services/listing_context_service.dart';
import '../../explore/presentation/chatbot_page.dart';

class EquipmentDetailsPage extends StatefulWidget {
  const EquipmentDetailsPage({
    super.key,
    required this.equipment,
    required this.userId,
    this.userName = 'User',
    this.userEmail = '',
    this.userPhone = '9000000000',
    this.isPreviewMode = false,
  });

  final MarketplaceEquipmentModel equipment;
  final String userId;
  final String userName;
  final String userEmail;
  final String userPhone;
  final bool isPreviewMode;

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
    // Increment views when the page is opened only if the viewer is not the owner
    if (widget.equipment.ownerId != widget.userId) {
      _service.incrementEquipmentViews(widget.equipment.equipmentId, userId: widget.userId);
    }
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
      LoggerService.error('Save Error', e, stacktrace);
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
    final text = 'Check out this ${item.equipmentName} available to borrow on Borrow!\n📍 ${item.location}\n🌱 Free community sharing\n\n$url';
    
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

  int _calculateBorrowDays() {
    if (_selectedStartDay == null) return 0;
    final endDay = _selectedEndDay ?? _selectedStartDay!;
    return endDay.difference(_selectedStartDay!).inDays + 1;
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

        final bool isOwner = item.ownerId == widget.userId && !widget.isPreviewMode;

        if (isOwner) {
          return _buildOwnerView(item, title, category, description);
        }

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
                    if (item.productId.isNotEmpty) ...[
                      BorrowProductIdCard(productId: item.productId),
                      const SizedBox(height: 24),
                    ],
                    _buildDetailsCard(item, description),
                    const SizedBox(height: 16),
                    _buildAskAiButton(item),
                    const SizedBox(height: 24),
                    _buildSpecifications(item),
                    const SizedBox(height: 24),
                    _buildTutorialButton(item),
                    const SizedBox(height: 24),
                    _buildModernCalendar(item),
                    const SizedBox(height: 24),
                    _buildBorrowSummary(),
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
                    if (item.ownerId != widget.userId) ...[
                      const SizedBox(width: 8),
                      _buildGlassButton(
                        icon: isSaved ? Icons.favorite : Icons.favorite_border,
                        color: isSaved ? Colors.red : Colors.black87,
                        size: 22,
                        onTap: () => _toggleSave(item),
                      ),
                    ],
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
                  color: AppColors.textPrimary,
                  height: 1.2,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isAvailable ? AppColors.primaryContainer : const Color(0xFFFFEBEE),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isAvailable ? AppColors.primary : const Color(0xFFF44336),
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isAvailable ? Icons.check_circle : Icons.do_not_disturb_alt,
                    size: 14,
                    color: isAvailable ? AppColors.primary : const Color(0xFFC62828),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isAvailable ? 'Available Now' : 'Currently On Loan',
                    style: TextStyle(
                      color: isAvailable ? AppColors.primary : const Color(0xFFC62828),
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
             const Icon(Icons.location_on, size: 16, color: AppColors.textSecondary),
             const SizedBox(width: 4),
             Expanded(
               child: Text(
                 '${item.distanceInfo != null ? "${item.distanceInfo!.formattedString} away • " : ""}Near ${item.area.isNotEmpty ? item.area : (item.city.isNotEmpty ? item.city : item.location)}',
                 style: const TextStyle(color: AppColors.textSecondary, fontSize: 14, fontWeight: FontWeight.w500),
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
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PublicProfilePage(
              userId: item.ownerId,
              userName: item.ownerName,
            ),
          ),
        );
      },
      child: Container(
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
            backgroundColor: AppColors.primaryContainer,
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
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
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
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
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
        _buildStatColumn(Icons.calendar_month, '${item.bookingsCount}', 'Borrows'),
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
            Icon(icon, size: 16, color: iconColor ?? AppColors.textSecondary),
            const SizedBox(width: 4),
            Text(
              value,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildAskAiButton(MarketplaceEquipmentModel item) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          ListingContextService.instance.cacheListing(item);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ChatbotPage(isFromListing: true),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: const Icon(Icons.auto_awesome, size: 18),
        label: const Text(
          '✨ Ask Borrow AI',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.2,
          ),
        ),
      ),
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
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
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
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
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
            'Select Borrow Dates',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
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
              rangeHighlightColor: AppColors.primaryContainer,
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
              _legendDot(AppColors.primaryContainer, AppColors.primary, 'Available'),
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

  Widget _buildBorrowSummary() {
    if (_selectedStartDay == null) return const SizedBox.shrink();
    final days = _calculateBorrowDays();
    final start = _selectedStartDay!;
    final end = _selectedEndDay ?? _selectedStartDay!;

    String _fmt(DateTime d) => '${d.day}/${d.month}/${d.year}';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F8E9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryContainer),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.handshake_rounded, color: AppColors.primary, size: 20),
              SizedBox(width: 8),
              Text(
                'Borrow Summary',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('From', style: TextStyle(color: Color(0xFF3F4A3C), fontSize: 14)),
              Text(_fmt(start), style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Until', style: TextStyle(color: Color(0xFF3F4A3C), fontSize: 14)),
              Text(_fmt(end), style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: AppColors.primaryContainer),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Borrow Duration', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
              Text('$days ${days == 1 ? 'day' : 'days'}',
                  style: const TextStyle(color: Color(0xFF006E1C), fontSize: 18, fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: 8),
          const Row(
            children: [
              Icon(Icons.info_outline, size: 14, color: AppColors.textSecondary),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  'This is a free community borrow. No payment required.',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ),
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
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
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
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: rel.availability ? AppColors.primaryContainer : const Color(0xFFFFF3E0),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    rel.availability ? 'Available' : 'On Loan',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: rel.availability ? AppColors.primary : Colors.orange.shade800,
                                      fontSize: 11,
                                    ),
                                  ),
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

  Future<void> _handleEditListing() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
    );
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(widget.userId).get();
      if (!mounted) return;
      Navigator.pop(context); // pop loading
      if (doc.exists) {
        final appUser = AppUserModel.fromDoc(doc);
        final equip = widget.equipment;
        Widget page;
        if (equip.category.toLowerCase().contains('book')) {
          page = BookListingFormPage(
            currentUser: appUser,
            existing: equip,
          );
        } else if (equip.category.toLowerCase().contains('construction')) {
          page = ConstructionEquipmentFormPage(
            currentUser: appUser,
            existing: equip,
          );
        } else {
          page = FarmEquipmentFormPage(
            currentUser: appUser,
            existing: equip,
          );
        }
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => page),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // pop loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profile: $e')),
        );
      }
    }
  }

  Future<void> _handleManageListing() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
    );
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(widget.userId).get();
      if (!mounted) return;
      Navigator.pop(context); // pop loading
      if (doc.exists) {
        final appUser = AppUserModel.fromDoc(doc);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MyListingsPage(
              currentUser: appUser,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // pop loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profile: $e')),
        );
      }
    }
  }

  Future<void> _handleViewRequests() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
    );
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(widget.userId).get();
      if (!mounted) return;
      Navigator.pop(context); // pop loading
      if (doc.exists) {
        final appUser = AppUserModel.fromDoc(doc);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MyBookingsPage(
              currentUser: appUser,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // pop loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profile: $e')),
        );
      }
    }
  }

  Widget _buildBottomActionBar(MarketplaceEquipmentModel item) {
    final bool isSelfOwned = item.ownerId == widget.userId;

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
                  isSelfOwned
                      ? '⭐ Your Asset'
                      : (item.availability ? '🟢 Available' : '🔴 On Loan'),
                  style: TextStyle(
                    color: isSelfOwned
                        ? AppColors.primary
                        : (item.availability ? AppColors.primary : Colors.red.shade700),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  isSelfOwned ? 'Manage or edit listing' : 'Free to borrow',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: isSelfOwned
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _handleEditListing,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.primary,
                                  side: const BorderSide(color: AppColors.primary, width: 1.5),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  minimumSize: const Size(0, 48),
                                ),
                                icon: const Icon(Icons.edit_outlined, size: 18),
                                label: const Text('Edit Listing', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _handleManageListing,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.primary,
                                  side: const BorderSide(color: AppColors.primary, width: 1.5),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  minimumSize: const Size(0, 48),
                                ),
                                icon: const Icon(Icons.settings_outlined, size: 18),
                                label: const Text('Manage', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton.icon(
                            onPressed: _handleViewRequests,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: const Icon(Icons.notifications_active_outlined, size: 18),
                            label: const Text('View Requests', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    )
                  : Container(
                      height: 56,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          colors: item.availability
                              ? [AppColors.primary, AppColors.primary]
                              : [Colors.grey.shade400, Colors.grey.shade600],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: item.availability
                                ? AppColors.primary.withValues(alpha: 0.3)
                                : Colors.grey.withValues(alpha: 0.2),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        onPressed: item.availability ? () => _showBorrowRequestDialog(item) : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        icon: const Icon(Icons.handshake_rounded, color: Colors.white, size: 20),
                        label: Text(
                          item.availability ? 'Request to Borrow' : 'Currently On Loan',
                          style: const TextStyle(
                            fontSize: 15,
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

  void _showBorrowRequestDialog(MarketplaceEquipmentModel item) {
    final purposeCtrl = TextEditingController();
    final messageCtrl = TextEditingController();
    final days = _calculateBorrowDays();
    String selectedPref = 'Chat First';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 32,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  const Icon(Icons.handshake_rounded, color: AppColors.primary, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Request to Borrow',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        Text(
                          item.equipmentName,
                          style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (_selectedStartDay != null) ...
              [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F8E9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primaryContainer),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          const Text('From', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                          Text(
                            '${_selectedStartDay!.day}/${_selectedStartDay!.month}/${_selectedStartDay!.year}',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          ),
                        ],
                      ),
                      const Icon(Icons.arrow_forward, color: AppColors.primary, size: 18),
                      Column(
                        children: [
                          const Text('Until', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                          Text(
                            '${(_selectedEndDay ?? _selectedStartDay!).day}/${(_selectedEndDay ?? _selectedStartDay!).month}/${(_selectedEndDay ?? _selectedStartDay!).year}',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          const Text('Duration', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                          Text(
                            '$days ${days == 1 ? 'day' : 'days'}',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF006E1C)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              StatefulBuilder(
                builder: (context, setModalState) {
                  return DropdownButtonFormField<String>(
                    value: selectedPref,
                    decoration: InputDecoration(
                      labelText: 'Pickup Preference',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.primary, width: 2),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Exact Address', child: Text('Prefer Exact Address')),
                      DropdownMenuItem(value: 'Approximate Area', child: Text('Prefer Approximate Area')),
                      DropdownMenuItem(value: 'Chat First', child: Text('Prefer to Chat First')),
                      DropdownMenuItem(value: 'Decide Later', child: Text('Decide Later')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setModalState(() => selectedPref = val);
                      }
                    },
                  );
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: messageCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Message to Owner',
                  hintText: 'Introduce yourself and explain your need…',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primary, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    
                    // Firestore Borrow request entry
                    final doc = FirebaseFirestore.instance.collection('bookings').doc();
                    await doc.set({
                      'bookingId': doc.id,
                      'equipmentId': item.equipmentId,
                      'equipmentName': item.equipmentName,
                      'imageUrl': item.imageUrls.isNotEmpty ? item.imageUrls.first : '',
                      'ownerId': item.ownerId,
                      'ownerName': item.ownerName,
                      'userId': widget.userId,
                      'userName': widget.userName,
                      'startDate': Timestamp.fromDate(_selectedStartDay ?? DateTime.now()),
                      'endDate': Timestamp.fromDate(_selectedEndDay ?? _selectedStartDay ?? DateTime.now()),
                      'status': 'pending',
                      'pickupPreference': selectedPref,
                      'borrowMessage': messageCtrl.text.trim(),
                      'createdAt': FieldValue.serverTimestamp(),
                      'shareOption': '',
                      'landmark': '',
                      'pickupTime': '',
                      'specialInstructions': '',
                      'contactInfo': '',
                      'readyToReturn': false,
                      'returned': false,
                    });

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              const Icon(Icons.check_circle, color: Colors.white),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Borrow request sent to ${item.ownerName}!',
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                          backgroundColor: AppColors.primary,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          duration: const Duration(seconds: 3),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  icon: const Icon(Icons.send_rounded),
                  label: const Text(
                    'Send Request',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // OWNER VIEW DASHBOARD IMPLEMENTATIONS (PART 3)
  // ──────────────────────────────────────────────────────────────────────────

  Widget _buildOwnerView(
      MarketplaceEquipmentModel item, String title, String category, String description) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: const Text('Manage Listing', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
        actions: [
          IconButton(
            icon: const Icon(Icons.visibility_outlined, color: Colors.black87),
            tooltip: 'Preview as Borrower',
            onPressed: () => _handlePreviewListing(item),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert_rounded, color: Colors.black87),
            tooltip: 'Menu',
            onPressed: () => _showOwnerMenuBottomSheet(item),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        children: [
          // Owner badge & Status Banner
          _buildOwnerHeaderBanner(item),
          const SizedBox(height: 20),

          // Requests summary
          _buildBookingSummaryCards(item),
          const SizedBox(height: 20),

          // Quick actions grid
          _buildOwnerQuickActions(item),
          const SizedBox(height: 20),

          // Details overview
          if (item.productId.isNotEmpty) ...[
            BorrowProductIdCard(productId: item.productId),
            const SizedBox(height: 20),
          ],
          _buildDetailsCard(item, description),
          const SizedBox(height: 12),
          _buildAskAiButton(item),
          const SizedBox(height: 20),

          // Specifications
          _buildSpecifications(item),
          const SizedBox(height: 20),

          // Listing general info
          _buildListingInfoPanel(item),
        ],
      ),
      bottomNavigationBar: Container(
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
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _handleEditListing,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary, width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  minimumSize: const Size(0, 52),
                ),
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Edit Details', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _handleViewRequests,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  minimumSize: const Size(0, 52),
                ),
                icon: const Icon(Icons.notifications_active_outlined, size: 18),
                label: const Text('Manage Requests', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOwnerHeaderBanner(MarketplaceEquipmentModel item) {
    String status = 'Available';
    Color chipColor = AppColors.primaryContainer;
    Color textColor = AppColors.primary;

    if (!item.availability) {
      status = 'Unavailable';
      chipColor = Colors.grey.shade200;
      textColor = Colors.grey.shade700;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE0E0E0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: AppColors.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('✓ Your Listing', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary)),
                  const SizedBox(height: 2),
                  Text(item.equipmentName, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                ],
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: chipColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              status,
              style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingSummaryCards(MarketplaceEquipmentModel item) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .where('equipmentId', isEqualTo: item.equipmentId)
          .snapshots(),
      builder: (context, snapshot) {
        int pending = 0;
        int active = 0;
        int completed = 0;
        String currentBorrower = 'None';

        if (snapshot.hasData) {
          final docs = snapshot.data!.docs;
          for (var doc in docs) {
            final data = doc.data();
            final stat = (data['status'] ?? '').toString().toLowerCase();
            if (stat == 'pending') {
              pending++;
            } else if (stat == 'approved' || stat == 'confirmed') {
              active++;
              currentBorrower = (data['userName'] ?? 'User').toString();
            } else if (stat == 'completed') {
              completed++;
            }
          }
        }

        return GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.6,
          children: [
            _buildStatSummaryCard('Pending Requests', '$pending', Icons.hourglass_empty_rounded, Colors.orange),
            _buildStatSummaryCard('Current Borrower', currentBorrower, Icons.person_outline_rounded, AppColors.primary),
            _buildStatSummaryCard('Active Loans', '$active', Icons.loop_rounded, Colors.blue),
            _buildStatSummaryCard('Completed Borrows', '$completed', Icons.done_all_rounded, Colors.grey.shade700),
          ],
        );
      },
    );
  }

  Widget _buildStatSummaryCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEBEFF0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: TextStyle(color: Colors.grey.shade600, fontSize: 11, fontWeight: FontWeight.bold)),
              Icon(icon, color: color, size: 18),
            ],
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildOwnerQuickActions(MarketplaceEquipmentModel item) {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Color(0xFFEBEFF0))),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Quick Actions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildActionButton('Edit Listing', Icons.edit_outlined, _handleEditListing),
                _buildActionButton('Borrow Requests', Icons.inbox_outlined, _handleViewRequests),
                _buildActionButton('Preview Listing', Icons.visibility_outlined, () => _handlePreviewListing(item)),
                _buildActionButton('Edit Availability', Icons.calendar_month_outlined, () => _showEditAvailabilitySheet(item)),
                _buildActionButton('Manage Images', Icons.image_outlined, () => _showManageImagesSheet(item)),
                _buildActionButton('Delete Listing', Icons.delete_outline_rounded, () => _handleDeleteListing(item), isDestructive: true),
              ],
            ),
            const Divider(height: 24, color: Color(0xFFEBEFF0)),
            SwitchListTile.adaptive(
              value: item.availability,
              activeColor: AppColors.primary,
              title: const Text('Available to Borrow', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: Text(
                item.availability ? 'Visible to borrowers in marketplace search and feeds' : 'Hidden from marketplace exploration feeds',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
              onChanged: (val) async {
                await _service.updateEquipment(equipmentId: item.equipmentId, updates: {'availability': val});
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Listing is now ${val ? "Available" : "Unavailable"}')),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, VoidCallback onTap, {bool isDestructive = false}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 104,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          border: Border.all(color: isDestructive ? Colors.red.shade100 : const Color(0xFFEBEFF0)),
          borderRadius: BorderRadius.circular(12),
          color: isDestructive ? Colors.red.withValues(alpha: 0.03) : Colors.transparent,
        ),
        child: Column(
          children: [
            Icon(icon, color: isDestructive ? Colors.red : AppColors.primary, size: 20),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isDestructive ? Colors.red : Colors.black87),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListingInfoPanel(MarketplaceEquipmentModel item) {
    final dateFormat = DateFormat.yMMMd();
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Color(0xFFEBEFF0))),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Listing Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary)),
            const SizedBox(height: 12),
            _buildInfoRow('Category', item.category),
            _buildInfoRow('Location', item.location),
            _buildInfoRow('Condition', item.condition),
            _buildInfoRow('Created Date', dateFormat.format(item.createdAt)),
            _buildInfoRow('Views Count', '${item.views}'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w500)),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  void _handlePreviewListing(MarketplaceEquipmentModel item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EquipmentDetailsPage(
          equipment: item,
          userId: widget.userId,
          userName: widget.userName,
          userEmail: widget.userEmail,
          userPhone: widget.userPhone,
          isPreviewMode: true,
        ),
      ),
    );
  }

  Future<void> _handleDeleteListing(MarketplaceEquipmentModel item) async {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Delete this listing?', style: TextStyle(fontWeight: FontWeight.bold)),
          content: const Text('This action cannot be undone. All associated requests and logs will be permanently deleted.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel', style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx); // pop dialog
                
                // Show loader
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                );

                try {
                  await _service.deleteEquipment(item.equipmentId);
                  if (mounted) {
                    Navigator.pop(context); // pop loader
                    Navigator.pop(context); // pop details page back to parent
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Listing deleted successfully.')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    Navigator.pop(context); // pop loader
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error deleting listing: $e')),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _showEditAvailabilitySheet(MarketplaceEquipmentModel item) {
    DateTime? fromDate = item.availabilityFrom ?? DateTime.now();
    DateTime? toDate = item.availabilityTo ?? DateTime.now().add(const Duration(days: 30));
    final durationCtrl = TextEditingController(text: '${item.minRentalDuration.toInt()}');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            Future<void> _pickDate(bool isFrom) async {
              final picked = await showDatePicker(
                context: context,
                initialDate: isFrom ? fromDate! : toDate!,
                firstDate: DateTime.now().subtract(const Duration(days: 365)),
                lastDate: DateTime.now().add(const Duration(days: 1000)),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: const ColorScheme.light(
                        primary: AppColors.primary,
                        onPrimary: Colors.white,
                        onSurface: Colors.black,
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (picked != null) {
                setModalState(() {
                  if (isFrom) {
                    fromDate = picked;
                    if (toDate!.isBefore(fromDate!)) {
                      toDate = fromDate!.add(const Duration(days: 1));
                    }
                  } else {
                    toDate = picked;
                  }
                });
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 32,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Edit Availability Calendar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.textPrimary)),
                  const SizedBox(height: 20),

                  // Dates pickers
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => _pickDate(true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade400),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Available From', style: TextStyle(color: Colors.grey, fontSize: 11)),
                                const SizedBox(height: 4),
                                Text(DateFormat.yMMMd().format(fromDate!), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: InkWell(
                          onTap: () => _pickDate(false),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade400),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Available Until', style: TextStyle(color: Colors.grey, fontSize: 11)),
                                const SizedBox(height: 4),
                                Text(DateFormat.yMMMd().format(toDate!), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Rental duration field
                  TextField(
                    controller: durationCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Minimum Borrow Duration (days)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(ctx); // pop sheet
                        
                        // Update database
                        final minDuration = double.tryParse(durationCtrl.text.trim()) ?? 1.0;
                        await _service.updateEquipment(
                          equipmentId: item.equipmentId,
                          updates: {
                            'availabilityFrom': Timestamp.fromDate(fromDate!),
                            'availabilityTo': Timestamp.fromDate(toDate!),
                            'minRentalDuration': minDuration,
                          },
                        );

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Availability details updated successfully.')),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('Save Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showManageImagesSheet(MarketplaceEquipmentModel item) {
    List<BorrowImageItem> currentImages = item.imageUrls.map((url) => BorrowImageItem(remoteUrl: url)).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.8,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Manage Photos', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.textPrimary)),
                  const SizedBox(height: 4),
                  Text('The first image is the cover photo. Reorder or delete images below.', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                  const SizedBox(height: 16),

                  // Image picker container
                  Expanded(
                    child: BorrowImagePicker(
                      initialImages: currentImages,
                      onImagesChanged: (updated) {
                        currentImages = updated;
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(ctx); // pop sheet
                        
                        // Show loading popup
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (context) => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                        );

                        try {
                          final List<String> finalUrls = [];
                          final CloudinaryService cloudinary = CloudinaryService();

                          for (var img in currentImages) {
                            if (img.isLocal) {
                              final secureUrl = await cloudinary.uploadImage(img.localFile!);
                              finalUrls.add(secureUrl);
                            } else {
                              finalUrls.add(img.remoteUrl!);
                            }
                          }

                          await _service.updateEquipment(
                            equipmentId: item.equipmentId,
                            updates: {
                              'imageUrls': finalUrls,
                            },
                          );

                          if (context.mounted) {
                            Navigator.pop(context); // pop loader
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Listing photos updated successfully.')),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            Navigator.pop(context); // pop loader
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error updating photos: $e')),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('Save Images', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showOwnerMenuBottomSheet(MarketplaceEquipmentModel item) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Listing Options', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.edit_outlined, color: AppColors.primary),
                title: const Text('Edit Listing details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                onTap: () {
                  Navigator.pop(ctx);
                  _handleEditListing();
                },
              ),
              ListTile(
                leading: const Icon(Icons.image_outlined, color: AppColors.primary),
                title: const Text('Manage listing photos', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                onTap: () {
                  Navigator.pop(ctx);
                  _showManageImagesSheet(item);
                },
              ),
              ListTile(
                leading: const Icon(Icons.notifications_active_outlined, color: AppColors.primary),
                title: const Text('Manage Borrow requests', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                onTap: () {
                  Navigator.pop(ctx);
                  _handleViewRequests();
                },
              ),
              ListTile(
                leading: const Icon(Icons.calendar_month_outlined, color: AppColors.primary),
                title: const Text('Change calendar availability', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                onTap: () {
                  Navigator.pop(ctx);
                  _showEditAvailabilitySheet(item);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                title: const Text('Delete Listing permanently', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.red)),
                onTap: () {
                  Navigator.pop(ctx);
                  _handleDeleteListing(item);
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }
}
