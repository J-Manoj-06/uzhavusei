import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../Calender.dart';
import '../../HomePage.dart';
import '../../TransactionsPage.dart';
import '../../localization/app_localizations.dart';
import '../../models/app_user_model.dart';
import '../../providers/locale_provider.dart';
import '../../services/auth_service.dart';
import '../explore/presentation/chatbot_page.dart';
import '../explore/presentation/explore_page.dart';
import '../profile/presentation/marketplace_profile_page.dart';

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

class _MarketplaceShellState extends State<MarketplaceShell> {
  int _selectedIndex = 0;

  late final List<Widget> _pages = [
    const HomePage(),
    const ExplorePage(),
    const TransactionsPage(),
    MarketplaceProfilePage(
      currentUser: widget.currentUser,
      authService: widget.authService,
    ),
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    context.read<LocaleProvider>().setLanguageCode(widget.currentUser.language);
  }

  @override
  void didUpdateWidget(covariant MarketplaceShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentUser.language != widget.currentUser.language) {
      context
          .read<LocaleProvider>()
          .setLanguageCode(widget.currentUser.language);
    }
  }

  void _openChatbot() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ChatbotPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: _pages[_selectedIndex],
      floatingActionButton: FloatingActionButton(
        onPressed: _openChatbot,
        backgroundColor: const Color(0xFF4CAF50),
        foregroundColor: Colors.white,
        elevation: 4,
        shape: const CircleBorder(),
        child: const Icon(Icons.smart_toy, size: 28), // Robot icon
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        color: Colors.white,
        elevation: 8,
        height: 70, // Explicit height to prevent flex overflow
        padding: EdgeInsets.zero, // Remove M3 default internal padding
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Left side
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildNavItem(icon: Icons.home, label: l10n.tr('home'), index: 0),
                  const SizedBox(width: 8),
                  _buildNavItem(icon: Icons.explore_rounded, label: l10n.tr('explore'), index: 1),
                ],
              ),
              // Right side
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildNavItem(icon: Icons.currency_rupee, label: l10n.tr('transactions'), index: 2),
                  const SizedBox(width: 8),
                  _buildNavItem(icon: Icons.person, label: l10n.tr('profile'), index: 3),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({required IconData icon, required String label, required int index}) {
    final isSelected = _selectedIndex == index;
    return InkWell(
      onTap: () => setState(() => _selectedIndex = index),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: isSelected
            ? BoxDecoration(
                color: const Color(0xFFE8F5E9), // Light green capsule shape
                borderRadius: BorderRadius.circular(24),
              )
            : const BoxDecoration(color: Colors.transparent),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFF4CAF50) : Colors.grey,
            ),
            if (isSelected) ...[
              const SizedBox(height: 2),
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF4CAF50),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
