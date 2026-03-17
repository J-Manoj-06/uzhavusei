import 'package:flutter/material.dart';

import '../../Calender.dart';
import '../../HomePage.dart';
import '../../Maintenance.dart';
import '../../ProfilePage.dart';
import '../../TransactionsPage.dart';
import '../../models/app_user_model.dart';
import '../../services/auth_service.dart';

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
    const MaintenancePage(),
    const ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
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
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today), label: 'Calendar'),
          BottomNavigationBarItem(
              icon: Icon(Icons.currency_rupee), label: 'Transactions'),
          BottomNavigationBarItem(
              icon: Icon(Icons.app_settings_alt_rounded), label: 'Maintenance'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
