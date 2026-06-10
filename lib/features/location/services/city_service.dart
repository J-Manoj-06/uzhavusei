import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/foundation.dart';

class CityService {
  static List<String>? _cachedCities;

  static Future<List<String>> getCities() async {
    if (_cachedCities != null) return _cachedCities!;

    try {
      // Load the large JSON file from assets as bytes
      final byteData = await rootBundle.load('assets/a-detailed-version.json');
      final bytes = byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes);
      final jsonString = utf8.decode(bytes, allowMalformed: true);
      
      // Parse JSON in a background isolate to prevent UI freezing
      _cachedCities = await compute(_parseCities, jsonString);
      return _cachedCities!;
    } catch (e) {
      debugPrint('Error loading cities: $e');
      return [];
    }
  }

  static List<String> _parseCities(String jsonString) {
    final Map<String, dynamic> jsonMap = jsonDecode(jsonString);
    final Set<String> cityNames = {};
    for (var value in jsonMap.values) {
      if (value['accentcity'] != null) {
        cityNames.add(value['accentcity'].toString());
      }
    }
    final list = cityNames.toList();
    list.sort(); // Sort alphabetically for better dropdown UX
    return list;
  }
}
