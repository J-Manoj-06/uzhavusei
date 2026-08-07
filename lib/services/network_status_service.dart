import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

enum NetworkState { online, offline, reconnecting }

class NetworkStatusService extends ChangeNotifier {
  NetworkStatusService._() {
    _initMonitoring();
  }
  static final NetworkStatusService instance = NetworkStatusService._();

  NetworkState _state = NetworkState.online;
  Timer? _checkTimer;

  NetworkState get state => _state;
  bool get isOnline => _state == NetworkState.online;

  void _initMonitoring() {
    checkConnection();
    _checkTimer = Timer.periodic(const Duration(seconds: 10), (_) => checkConnection());
  }

  Future<void> checkConnection() async {
    try {
      final response = await http
          .get(Uri.parse('https://www.google.com/generate_204'))
          .timeout(const Duration(seconds: 3));

      if (response.statusCode == 204 || response.statusCode == 200) {
        if (_state != NetworkState.online) {
          _state = NetworkState.online;
          notifyListeners();
        }
      } else {
        _setOffline();
      }
    } catch (_) {
      _setOffline();
    }
  }

  void _setOffline() {
    if (_state != NetworkState.offline) {
      _state = NetworkState.offline;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _checkTimer?.cancel();
    super.dispose();
  }
}
