import 'package:flutter/material.dart';

class ListingAnalyticsSheet extends StatelessWidget {
  const ListingAnalyticsSheet({
    super.key,
    required this.title,
    required this.category,
    required this.views,
    required this.favoritesCount,
    required this.bookingsCount,
    required this.price,
  });

  final String title;
  final String category;
  final int views;
  final int favoritesCount;
  final int bookingsCount;
  final double price;

  @override
  Widget build(BuildContext context) {
    // Generate derived analytics
    final clicks = (views * 0.25).round(); // 25% CTR mock
    final interestedUsers = favoritesCount + (bookingsCount * 1.5).round();
    final revenue = bookingsCount * price;
    final rentalDays = bookingsCount * 3; // Mock average 3 days per booking
    const responseRate = '98%';

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Pull handle
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
            // Header
            Row(
              children: [
                const Icon(Icons.bar_chart_rounded, color: Color(0xFF2E7D32), size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      Text(
                        'Analytics for category: $category',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 32),
            // Stats Grid
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.8,
              children: [
                _buildMetricCard('Number of Views', '$views', Icons.visibility_outlined, Colors.blue),
                _buildMetricCard('Number of Clicks', '$clicks', Icons.touch_app_outlined, Colors.teal),
                _buildMetricCard('Interested Users', '$interestedUsers', Icons.people_outline, Colors.orange),
                _buildMetricCard('Bookings', '$bookingsCount', Icons.calendar_month_outlined, Colors.purple),
                _buildMetricCard('Revenue Generated', '₹${revenue.toStringAsFixed(0)}', Icons.monetization_on_outlined, Colors.green),
                _buildMetricCard('Rental Days', '$rentalDays days', Icons.schedule_outlined, Colors.indigo),
              ],
            ),
            const SizedBox(height: 16),
            // Bottom stats row
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAF8),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFEBEFF0)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.flash_on, color: Color(0xFF2E7D32), size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Avg. Host Response Rate',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey.shade800),
                      ),
                    ],
                  ),
                  const Text(
                    responseRate,
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF2E7D32)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEBEFF0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.01),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 20),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade500),
              ),
            ],
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1A1A1A),
            ),
          ),
        ],
      ),
    );
  }
}
