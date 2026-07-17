import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../../models/marketplace_equipment_model.dart';
import '../../../../../models/farm_surplus_exchange_model.dart';
import '../../../../../services/marketplace_service.dart';
import 'package:UzhavuSei/theme/app_theme.dart';

class ListingsAnalyticsSection extends StatefulWidget {
  const ListingsAnalyticsSection({super.key, required this.userId});
  final String userId;

  @override
  State<ListingsAnalyticsSection> createState() => _ListingsAnalyticsSectionState();
}

class _ListingsAnalyticsSectionState extends State<ListingsAnalyticsSection> {
  final MarketplaceService _service = MarketplaceService();
  
  StreamSubscription? _equipmentSub;
  StreamSubscription? _surplusSub;
  StreamSubscription? _bookingsSub;

  int _totalEquipments = 0;
  int _activeRentals = 0;
  int _surplusCount = 0;
  double _potentialEarnings = 0;

  @override
  void initState() {
    super.initState();
    _initStreams();
  }

  void _initStreams() {
    _equipmentSub = _service.watchEquipmentsByOwner(widget.userId).listen((equipments) {
      if (!mounted) return;
      setState(() {
        _totalEquipments = equipments.length;
        // Count anything 'published' or not expired as active? Let's just use total for now or 'published'
        _activeRentals = equipments.where((e) => e.status == 'published').length;
      });
    });

    _surplusSub = _service.watchExchangesByOwner(widget.userId).listen((surplus) {
      if (!mounted) return;
      setState(() {
        _surplusCount = surplus.length;
      });
    });

    _bookingsSub = _service.watchOwnerBookings(widget.userId).listen((bookings) {
      if (!mounted) return;
      double earnings = 0;
      for (var b in bookings) {
        if (b.status == 'confirmed' || b.status == 'completed' || b.status == 'pending') {
          earnings += b.totalPrice;
        }
      }
      setState(() {
        _potentialEarnings = earnings;
      });
    });
  }

  @override
  void dispose() {
    _equipmentSub?.cancel();
    _surplusSub?.cancel();
    _bookingsSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final totalListings = _totalEquipments + _surplusCount;

    return Container(
      height: 130,
      color: Colors.white,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          _buildAnalyticsCard(
            title: 'Total Listings',
            value: '$totalListings',
            subtitle: 'Listings',
            icon: Icons.inventory_2,
            gradient: const LinearGradient(colors: [AppColors.primaryContainer, AppColors.primaryContainer]),
            iconColor: AppColors.primary,
          ),
          const SizedBox(width: 12),
          _buildAnalyticsCard(
            title: 'Active Rentals',
            value: '$_activeRentals',
            subtitle: 'Active',
            icon: Icons.agriculture,
            gradient: const LinearGradient(colors: [Color(0xFFFFF3E0), Color(0xFFFFE0B2)]),
            iconColor: const Color(0xFFE65100),
          ),
          const SizedBox(width: 12),
          _buildAnalyticsCard(
            title: 'Surplus Listings',
            value: '$_surplusCount',
            subtitle: 'Active',
            icon: Icons.eco,
            gradient: const LinearGradient(colors: [Color(0xFFE0F7FA), Color(0xFFB2EBF2)]),
            iconColor: const Color(0xFF006064),
          ),
          const SizedBox(width: 12),
          _buildAnalyticsCard(
            title: 'Potential Earnings',
            value: '₹${_potentialEarnings.toStringAsFixed(0)}',
            subtitle: 'Estimated',
            icon: Icons.account_balance_wallet,
            gradient: const LinearGradient(colors: [Color(0xFFF3E5F5), Color(0xFFE1BEE7)]),
            iconColor: const Color(0xFF4A148C),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required LinearGradient gradient,
    required Color iconColor,
  }) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: iconColor.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: iconColor, size: 24),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: iconColor.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: iconColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: iconColor.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}
