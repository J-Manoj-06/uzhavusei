import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:UzhavuSei/models/marketplace_equipment_model.dart';
import 'package:UzhavuSei/widgets/image_loader.dart';
import 'details_theme.dart';

class HeroSection extends StatefulWidget {
  const HeroSection({
    super.key,
    required this.equipment,
    required this.isSaved,
    required this.isOwner,
    required this.onBack,
    required this.onShare,
    required this.onToggleSave,
    required this.onOpenFullscreen,
  });

  final MarketplaceEquipmentModel equipment;
  final bool isSaved;
  final bool isOwner;
  final VoidCallback onBack;
  final VoidCallback onShare;
  final VoidCallback onToggleSave;
  final ValueChanged<String> onOpenFullscreen;

  @override
  State<HeroSection> createState() => _HeroSectionState();
}

class _HeroSectionState extends State<HeroSection> {
  int _currentImageIndex = 0;

  @override
  Widget build(BuildContext context) {
    final images = widget.equipment.imageUrls.isEmpty
        ? ['assets/logo.jpg']
        : widget.equipment.imageUrls;
    final isAvailable = widget.equipment.availability;

    return Stack(
      children: [
        // Hero Image Carousel Container
        ClipRRect(
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(28),
          ),
          child: AspectRatio(
            aspectRatio: 16 / 11,
            child: PageView.builder(
              itemCount: images.length,
              onPageChanged: (index) {
                setState(() => _currentImageIndex = index);
              },
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () => widget.onOpenFullscreen(images[index]),
                  child: Hero(
                    tag: 'equipment_image_${widget.equipment.equipmentId}_$index',
                    child: buildSmartImage(images[index], fit: BoxFit.cover),
                  ),
                );
              },
            ),
          ),
        ),

        // Back button - Top Left
        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          left: 16,
          child: _buildGlassButton(
            icon: Icons.arrow_back_rounded,
            onTap: widget.onBack,
          ),
        ),

        // Share & Favorite - Top Right
        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          right: 16,
          child: Row(
            children: [
              _buildGlassButton(
                icon: Icons.share_rounded,
                onTap: widget.onShare,
              ),
              if (!widget.isOwner) ...[
                const SizedBox(width: 8),
                _buildGlassButton(
                  icon: widget.isSaved
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  color: widget.isSaved ? Colors.red : DetailsTheme.text,
                  onTap: widget.onToggleSave,
                ),
              ],
            ],
          ),
        ),

        // Modern Status Badge Card - Bottom Left overlay
        Positioned(
          bottom: 16,
          left: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isAvailable
                  ? DetailsTheme.success
                  : const Color(0xFFEF4444),
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  isAvailable ? 'Available Now' : 'Currently On Loan',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Pill Page Indicators - Bottom Right overlay
        if (images.length > 1)
          Positioned(
            bottom: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(
                  images.length,
                  (index) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2.5),
                    width: _currentImageIndex == index ? 16 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: _currentImageIndex == index
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildGlassButton({
    required IconData icon,
    required VoidCallback onTap,
    Color color = DetailsTheme.text,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.88),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
        ),
      ),
    );
  }
}
