import 'package:flutter/material.dart';
import '../services/network_status_service.dart';

class OfflineSearchProvider extends ChangeNotifier {
  late final NetworkStatusService _networkService;
  bool _isDisposed = false;

  OfflineSearchProvider({NetworkStatusService? networkService}) {
    _networkService = networkService ?? NetworkStatusService.instance;
    _networkService.addListener(_onNetworkChanged);
  }

  bool get isOffline => !_networkService.isOnline;
  NetworkState get networkState => _networkService.state;

  void _onNetworkChanged() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  Future<void> checkConnectionNow() async {
    await _networkService.checkConnection();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _networkService.removeListener(_onNetworkChanged);
    super.dispose();
  }
}
