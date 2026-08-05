import 'package:flutter/material.dart';
import 'all_books_page.dart';

class BooksMarketplacePage extends StatelessWidget {
  final double userLatitude;
  final double userLongitude;

  const BooksMarketplacePage({
    super.key,
    required this.userLatitude,
    required this.userLongitude,
  });

  @override
  Widget build(BuildContext context) {
    return const AllBooksPage();
  }
}
