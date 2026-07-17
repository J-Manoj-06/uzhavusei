import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../HomePage.dart';
import '../../localization/app_localizations.dart';
import '../../models/app_user_model.dart';
import '../../providers/locale_provider.dart';
import '../../services/auth_service.dart';
import '../explore/presentation/chatbot_page.dart';
import '../explore/presentation/explore_page.dart';
import '../profile/presentation/marketplace_profile_page.dart';
import '../profile/presentation/my_listings_page.dart';
import '../equipment/presentation/create_listing_flow.dart';
import '../../services/deep_link_handler.dart';
import 'package:UzhavuSei/theme/app_theme.dart';

class MarketplaceShell extends StatefulWidget {
  const MarketplaceShell({
    super.key,
    required this.authService,
    required this.currentUser,
  });

  final AuthService authService;
  final AppUserModel currentUser;

  @override
  State<MarketplaceShell> createState() => _MarketplaceShellState();
}

class _MarketplaceShellState extends State<MarketplaceShell>
    with SingleTickerProviderStateMixin {
  // Index mapping: 0=Home, 1=Help, 2=Rent(center/action), 3=MyListings, 4=Profile
  // Pages list: index 2 is a placeholder (Rent opens a sheet, not a page)
  int _selectedIndex = 0;

  late final List<Widget> _pages = [
    const HomePage(),
    const ChatbotPage(),
    const ExplorePage(), // placeholder for index 2 (Rent)
    MyListingsPage(currentUser: widget.currentUser),
    MarketplaceProfilePage(
      currentUser: widget.currentUser,
      authService: widget.authService,
    ),
  ];

  static const Color _green = AppColors.primary;
  static const Color _darkGreen = AppColors.primary;
  static const Color _lightGreen = AppColors.primaryContainer;
  static const Color _grey = Color(0xFF9E9E9E);
  static const Color _lightGrey = Color(0xFFF5F5F5);

  late final AnimationController _floatController;
  late final Animation<double> _floatAnimation;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _floatAnimation = Tween<double>(begin: 0.0, end: -6.0).animate(
      CurvedAnimation(
        parent: _floatController,
        curve: Curves.easeInOut,
      ),
    );
    // Initialize Deep Link Handler
    WidgetsBinding.instance.addPostFrameCallback((_) {
      DeepLinkHandler.instance.init(context, widget.currentUser);
    });
  }

  @override
  void dispose() {
    _floatController.dispose();
    DeepLinkHandler.instance.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    context.read<LocaleProvider>().setLanguageCode(widget.currentUser.language);
  }

  @override
  void didUpdateWidget(covariant MarketplaceShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentUser.language != widget.currentUser.language) {
      context.read<LocaleProvider>().setLanguageCode(widget.currentUser.language);
    }
  }

  void _onTabTapped(int index) {
    if (index == 2) {
      // Center Rent button — open action sheet
      HapticFeedback.mediumImpact();
      _openAddOptions();
      return;
    }
    HapticFeedback.selectionClick();
    setState(() => _selectedIndex = index);
  }

  void _openAddOptions() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CategorySelectionPage(
          currentUser: widget.currentUser,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return SafeArea(
      child: Container(
        height: 76,
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: ClipRect(
          clipBehavior: Clip.none,
          child: Row(
            children: [
              _buildNavItem(icon: Icons.home_rounded, label: 'Home', index: 0),
              _buildNavItem(icon: Icons.auto_awesome, label: 'AI', index: 1),
              _buildCenterRentButton(),
              _buildNavItem(icon: Icons.inventory_2_rounded, label: 'My Listings', index: 3),
              _buildNavItem(icon: Icons.person_rounded, label: 'Profile', index: 4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final isSelected = _selectedIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => _onTabTapped(index),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected ? _lightGreen : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  size: 22,
                  color: isSelected ? _green : _grey,
                ),
              ),
              const SizedBox(height: 4),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? _green : _grey,
                  letterSpacing: 0.1,
                ),
                child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCenterRentButton() {
    return Expanded(
      child: GestureDetector(
        onTap: () => _onTabTapped(2),
        behavior: HitTestBehavior.opaque,
        child: OverflowBox(
          maxHeight: 100,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 0),
              AnimatedBuilder(
                animation: _floatAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, -10 + _floatAnimation.value),
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.secondary, _darkGreen],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: _green.withValues(alpha: 0.45),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.add, color: Colors.white, size: 30),
                    ),
                  );
                },
              ),
              Transform.translate(
                offset: const Offset(0, -6),
                child: const Text(
                  'Rent/Sell',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: _darkGreen,
                    letterSpacing: 0.1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Premium Action Sheet
// ─────────────────────────────────────────────────────────────
class _ActionSheet extends StatefulWidget {
  const _ActionSheet({
    required this.onRentEquipment,
    required this.onFarmExchange,
  });

  final VoidCallback onRentEquipment;
  final VoidCallback onFarmExchange;

  @override
  State<_ActionSheet> createState() => _ActionSheetState();
}

class _ActionSheetState extends State<_ActionSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideUp;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeIn,
      child: SlideTransition(
        position: _slideUp,
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                const SizedBox(height: 12),
                // Handle bar
                Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0E0E0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),

                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      // Icon row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _headerEmoji('🌾'),
                          const SizedBox(width: 8),
                          _headerEmoji('🚜'),
                          const SizedBox(width: 8),
                          _headerEmoji('🌽'),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'What would you like to do today?',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Earn more from your farm by renting equipment\nor selling agricultural products.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Option cards
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      _OptionCard(
                        emoji: '🌱',
                        tag: '♻️ Zero Waste',
                        tagColor: const Color(0xFF8BC34A),
                        title: 'Sell Surplus',
                        description:
                            'Share or exchange unused seeds, fertilizers, and pesticides with nearby farmers.',
                        features: const ['Reduce Waste', 'Community Giveaway', 'Exchanges'],
                        gradient: const LinearGradient(
                          colors: [Color(0xFFF1F8E9), AppColors.primaryContainer],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        iconBgGradient: const LinearGradient(
                          colors: [Color(0xFF8BC34A), Color(0xFF7CB342)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderColor: const Color(0xFFAED581),
                        titleColor: const Color(0xFF558B2F),
                        onTap: widget.onFarmExchange,
                      ),
                      const SizedBox(height: 12),
                      _OptionCard(
                        emoji: '🚜',
                        tag: '🚜  Equipment Rental',
                        tagColor: AppColors.primary,
                        title: 'Rent Out Equipment',
                        description:
                            'Generate income by renting out your idle farming machinery to nearby farmers.',
                        features: const ['Extra Income', 'Nearby Farmers', 'Flexible Pricing'],
                        gradient: const LinearGradient(
                          colors: [AppColors.primaryContainer, Color(0xFFF1F8E9)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        iconBgGradient: const LinearGradient(
                          colors: [AppColors.secondary, AppColors.primary],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderColor: AppColors.primaryContainer,
                        titleColor: AppColors.primary,
                        onTap: widget.onRentEquipment,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _headerEmoji(String emoji) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Center(
        child: Text(emoji, style: const TextStyle(fontSize: 24)),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Single Option Card
// ─────────────────────────────────────────────────────────────
class _OptionCard extends StatefulWidget {
  const _OptionCard({
    required this.emoji,
    required this.tag,
    required this.tagColor,
    required this.title,
    required this.description,
    required this.features,
    required this.gradient,
    required this.iconBgGradient,
    required this.borderColor,
    required this.titleColor,
    required this.onTap,
  });

  final String emoji;
  final String tag;
  final Color tagColor;
  final String title;
  final String description;
  final List<String> features;
  final LinearGradient gradient;
  final LinearGradient iconBgGradient;
  final Color borderColor;
  final Color titleColor;
  final VoidCallback onTap;

  @override
  State<_OptionCard> createState() => _OptionCardState();
}

class _OptionCardState extends State<_OptionCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleCtrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _scaleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.97,
      upperBound: 1.0,
      value: 1.0,
    );
    _scale = _scaleCtrl;
  }

  @override
  void dispose() {
    _scaleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _scaleCtrl.reverse(),
      onTapUp: (_) {
        _scaleCtrl.forward();
        widget.onTap();
      },
      onTapCancel: () => _scaleCtrl.forward(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) =>
            Transform.scale(scale: _scale.value, child: child),
        child: Container(
          decoration: BoxDecoration(
            gradient: widget.gradient,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: widget.borderColor, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: widget.borderColor.withValues(alpha: 0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: widget.iconBgGradient,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Center(
                    child: Text(
                      widget.emoji,
                      style: const TextStyle(fontSize: 30),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tag chip
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: widget.tagColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          widget.tag,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: widget.tagColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.title,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: widget.titleColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.description,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Feature chips
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: widget.features
                            .map((f) => Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.white
                                        .withValues(alpha: 0.8),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                        color: widget.borderColor,
                                        width: 1),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.check_circle_rounded,
                                          size: 11,
                                          color: widget.titleColor),
                                      const SizedBox(width: 4),
                                      Text(
                                        f,
                                        style: TextStyle(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w600,
                                          color: widget.titleColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ))
                            .toList(),
                      ),
                    ],
                  ),
                ),
                // Arrow
                Padding(
                  padding: const EdgeInsets.only(top: 18),
                  child: Icon(Icons.arrow_forward_ios_rounded,
                      size: 14, color: widget.titleColor),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
