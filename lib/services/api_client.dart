import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';

class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    final base = Config.apiBaseUrl;
    final sanitized = base.replaceAll(RegExp(r'/+$'), '');
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$sanitized$normalizedPath')
        .replace(queryParameters: query);
  }

  Future<List<Map<String, dynamic>>> fetchFeaturedEquipment() async {
    final url = _uri('/api/equipment/featured');
    final response = await http.get(url, headers: _defaultHeaders());
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    }
    throw Exception(
        'Failed to load featured equipment: ${response.statusCode}');
  }

  Future<List<Map<String, dynamic>>> fetchNearbyItems() async {
    final url = _uri('/api/items/nearby');
    final response = await http.get(url, headers: _defaultHeaders());
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    }
    throw Exception('Failed to load nearby items: ${response.statusCode}');
  }

  Future<List<Map<String, dynamic>>> fetchTransactions() async {
    final url = _uri('/api/transactions');
    final response = await http.get(url, headers: _defaultHeaders());
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    }
    throw Exception('Failed to load transactions: ${response.statusCode}');
  }

  Future<void> createMaintenanceSchedule(Map<String, dynamic> payload) async {
    final url = _uri('/api/maintenance/schedule');
    final response = await http.post(
      url,
      headers: _jsonHeaders(),
      body: jsonEncode(payload),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
          'Failed to create maintenance schedule: ${response.statusCode}');
    }
  }

  Map<String, String> _defaultHeaders() {
    return {
      'Accept': 'application/json',
    };
  }

  Map<String, String> _jsonHeaders() {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }
}
