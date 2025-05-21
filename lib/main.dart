import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'HomePage.dart';
import 'ProfilePage.dart';
import 'TransactionsPage.dart';
import 'Calender.dart';
import 'Maintenance.dart';
import 'splash_screen.dart';
import 'providers/user_profile_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProfileProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'FarmConnect',
        theme: ThemeData(
          primaryColor: const Color(0xFF4CAF50),
          fontFamily: 'Roboto',
        ),
        home: const SplashScreen(),
      ),
    );
  }
}

class UzhavuSei extends StatefulWidget {
  const UzhavuSei({super.key});

  @override
  _FarmConnectAppState createState() => _FarmConnectAppState();
}

class _FarmConnectAppState extends State<UzhavuSei> {
  int _selectedIndex = 0;
  final List<Widget> _pages = [
    const HomePage(),
    const Calendar(),
    const TransactionsPage(),
    const MaintenancePage(),
    const ProfilePage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Calendar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.currency_rupee),
            label: 'Transactions',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.app_settings_alt_rounded),
            label: 'Maintenance',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle),
            label: 'Profile',
          ),
        ],
        selectedItemColor: const Color(0xFF4CAF50),
        unselectedItemColor: Colors.grey,
        selectedLabelStyle: const TextStyle(color: Color(0xFF4CAF50)),
        unselectedLabelStyle: const TextStyle(color: Colors.grey),
      ),
    );
  }
}
