import 'package:flutter/material.dart';
import '../../../models/app_user_model.dart';
import '../../equipment/presentation/equipment_form_page.dart';
import '../../surplus/presentation/farm_exchange_form_page.dart';
import 'widgets/listings_analytics_section.dart';
import 'widgets/equipment_tab_view.dart';
import 'widgets/surplus_tab_view.dart';

class MyListingsPage extends StatefulWidget {
  const MyListingsPage({
    super.key,
    required this.currentUser,
  });

  final AppUserModel currentUser;

  @override
  State<MyListingsPage> createState() => _MyListingsPageState();
}

class _MyListingsPageState extends State<MyListingsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _openCreateListingSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.only(bottom: 24),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0E0E0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Create Listing',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 24),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text('🚜', style: TextStyle(fontSize: 24)),
                ),
                title: const Text('List Equipment for Rent', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Rent out your idle machinery.'),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EquipmentFormPage(
                        ownerId: widget.currentUser.userId,
                        ownerName: widget.currentUser.name,
                      ),
                    ),
                  );
                },
              ),
              const Divider(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F8E9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text('🌱', style: TextStyle(fontSize: 24)),
                ),
                title: const Text('Farm Surplus Exchange', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Sell or exchange extra seeds, fertilizers, etc.'),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FarmExchangeFormPage(
                        ownerId: widget.currentUser.userId,
                        ownerName: widget.currentUser.name,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '📋 My Listings',
              style: TextStyle(
                color: Color(0xFF1A1A1A),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Manage your rentals and surplus.',
              style: TextStyle(
                color: Color(0xFF6F7A6B),
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Color(0xFF3F4A3C)),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.tune, color: Color(0xFF3F4A3C)),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Top Analytics Section
          ListingsAnalyticsSection(userId: widget.currentUser.userId),
          
          // Segmented Control
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              indicatorColor: const Color(0xFF006E1C),
              indicatorWeight: 3,
              labelColor: const Color(0xFF006E1C),
              unselectedLabelColor: const Color(0xFF6F7A6B),
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              tabs: const [
                Tab(text: '🚜 Equipment'),
                Tab(text: '🌱 Surplus'),
              ],
            ),
          ),
          
          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                EquipmentTabView(currentUser: widget.currentUser),
                SurplusTabView(currentUser: widget.currentUser),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
