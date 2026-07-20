import 'package:flutter/material.dart';

class DetailsTheme {
  // Color Palette
  static const Color primary = Color(0xFF2563EB);
  static const Color primaryContainer = Color(0xFFDBEAFE);
  static const Color secondary = Color(0xFF06B6D4);
  static const Color success = Color(0xFF22C55E);
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color text = Color(0xFF0F172A);
  static const Color secondaryText = Color(0xFF64748B);
  static const Color border = Color(0xFFE2E8F0);

  // Typography
  static const TextStyle titleStyle = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: text,
    height: 1.2,
  );

  static const TextStyle sectionHeadingStyle = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: text,
    height: 1.3,
  );

  static const TextStyle cardHeadingStyle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: text,
    height: 1.3,
  );

  static const TextStyle bodyStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: text,
    height: 1.5,
  );

  static const TextStyle secondaryBodyStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: secondaryText,
    height: 1.5,
  );

  static const TextStyle captionStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: secondaryText,
    height: 1.4,
  );

  // Spacing & Radius Constants
  static const double outerPadding = 20.0;
  static const double cardRadius = 20.0;
  static const double sectionSpacing = 24.0;
  static const double cardSpacing = 16.0;
  static const double chipSpacing = 8.0;

  // Box Shadow
  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: const Color(0xFF0F172A).withValues(alpha: 0.04),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];
}
