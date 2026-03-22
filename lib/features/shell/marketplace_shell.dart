import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../Calender.dart';
import '../../HomePage.dart';
import '../../TransactionsPage.dart';
import '../../localization/app_localizations.dart';
import '../../models/app_user_model.dart';
import '../../providers/locale_provider.dart';
import '../../services/auth_service.dart';
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
    const Calendar(),
    const TransactionsPage(),
    const ExplorePage(),
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFF4CAF50),
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home),
            label: l10n.tr('home'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.calendar_today),
            label: l10n.tr('calendar'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.currency_rupee),
            label: l10n.tr('transactions'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.explore_rounded),
            label: l10n.tr('explore'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person),
            label: l10n.tr('profile'),
          ),
        ],
        selectedLabelStyle: const TextStyle(fontSize: 12),
      ),
    );
  }
}
