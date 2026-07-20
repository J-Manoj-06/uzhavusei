import 'package:flutter/foundation.dart';

class ContextValidator {
  ContextValidator._();
  static final ContextValidator instance = ContextValidator._();

  // Keys that will be automatically stripped from context maps for security and privacy
  static const List<String> _sensitiveKeys = [
    'uid',
    'firebaseuid',
    'userid',
    'email',
    'password',
    'token',
    'authtoken',
    'auth_token',
    'apikey',
    'api_key',
    'documentid',
    'docid',
    'phonenumber',
    'phone',
    'pwd',
    'secret',
    'sessionid',
  ];

  /// Sanitizes, optimizes and validates the input context map.
  /// Gracefully removes sensitive keys, empty/null values, and trims long properties.
  Map<String, dynamic> validateAndOptimize(Map<String, dynamic> rawContext) {
    final Map<String, dynamic> clean = {};

    rawContext.forEach((key, value) {
      final normalizedKey = key.toLowerCase().replaceAll('_', '').replaceAll('-', '');

      // 1. Skip sensitive keys
      if (_sensitiveKeys.contains(normalizedKey)) {
        return;
      }

      // 2. Skip null or empty values
      if (value == null) {
        return;
      }

      if (value is String) {
        final trimmed = value.trim();
        if (trimmed.isEmpty) return;

        // Skip image URLs/media storage links as per spec (only send metadata, no image URLs)
        if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
          if (trimmed.contains('firebasestorage') || trimmed.contains('cloudinary') || trimmed.contains('unsplash')) {
            return;
          }
        }

        // Limit maximum string lengths to optimize token usage
        if (trimmed.length > 500) {
          clean[key] = '${trimmed.substring(0, 500)}... [truncated for token optimization]';
        } else {
          clean[key] = trimmed;
        }
      } else if (value is Map<String, dynamic>) {
        final nestedClean = validateAndOptimize(value);
        if (nestedClean.isNotEmpty) {
          clean[key] = nestedClean;
        }
      } else if (value is List) {
        final cleanedList = [];
        for (final item in value) {
          if (item == null) continue;
          if (item is String) {
            final trimmed = item.trim();
            if (trimmed.isNotEmpty) cleanedList.add(trimmed);
          } else if (item is Map<String, dynamic>) {
            final cleanedMap = validateAndOptimize(item);
            if (cleanedMap.isNotEmpty) cleanedList.add(cleanedMap);
          } else {
            cleanedList.add(item);
          }
        }
        if (cleanedList.isNotEmpty) {
          clean[key] = cleanedList;
        }
      } else {
        clean[key] = value;
      }
    });

    return clean;
  }
}
