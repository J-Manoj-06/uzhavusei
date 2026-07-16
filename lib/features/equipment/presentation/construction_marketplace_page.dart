import 'package:flutter/material.dart';
import 'category_marketplace_page.dart';

class ConstructionMarketplacePage extends StatelessWidget {
  final double userLatitude;
  final double userLongitude;

  const ConstructionMarketplacePage({
    super.key,
    required this.userLatitude,
    required this.userLongitude,
  });

  @override
  Widget build(BuildContext context) {
    return const CategoryMarketplacePage(category: 'Construction Equipment');
  }
}
