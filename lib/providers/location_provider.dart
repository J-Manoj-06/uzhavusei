import 'package:flutter/foundation.dart';
import '../services/location_service.dart';

/// Reactive wrapper around [LocationService].
///
/// Exposes:
/// - [lastVerifiedLocation] – the last successfully cached location.
/// - [permissionStatus]     – current OS permission state.
/// - [isLoading]            – true while a GPS operation is in progress.
/// - [errorMessage]         – human-readable error from the last failed attempt.
///
/// Call [initialize()] once at app startup (from main.dart).
/// Call [refresh()] when the user manually requests a location update.
class LocationProvider extends ChangeNotifier {
  final LocationService _service = LocationService.instance;

  VerifiedLocation? _lastVerifiedLocation;
  LocationPermissionStatus _permissionStatus = LocationPermissionStatus.unknown;
  bool _isLoading = false;
  String? _errorMessage;

  /// Creates the provider and automatically begins location initialisation.
  LocationProvider() {
    initialize();
  }

  // ── Getters ───────────────────────────────────────────────

  VerifiedLocation? get lastVerifiedLocation => _lastVerifiedLocation;
  LocationPermissionStatus get permissionStatus => _permissionStatus;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// True when a valid, non-stale location is available.
  bool get hasValidLocation =>
      _lastVerifiedLocation != null && !_lastVerifiedLocation!.isStale;

  // ── Initialisation ────────────────────────────────────────

  /// Should be called once when the app starts (after Firebase is ready).
  ///
  /// Strategy:
  /// 1. Load the cached LVL from disk (instant, no GPS).
  /// 2. Request permission if not yet determined.
  /// 3. If the cache is missing or stale, fetch a fresh GPS fix.
  Future<void> initialize() async {
    _setLoading(true);

    // Step 1: Load whatever is already cached
    _lastVerifiedLocation = await _service.getLastVerifiedLocation();
    notifyListeners();

    // Step 2: Check / request permission
    _permissionStatus = await _service.requestPermission();
    notifyListeners();

    // Step 3: Refresh if needed
    if (_permissionStatus == LocationPermissionStatus.granted) {
      final needsRefresh = await _service.shouldRefresh();
      if (needsRefresh) {
        await _fetchFreshLocation();
      }
    } else {
      _errorMessage = _describePermissionStatus(_permissionStatus);
    }

    _setLoading(false);
  }

  // ── Public actions ────────────────────────────────────────

  /// Forces a fresh GPS fix regardless of cache age.
  /// Suitable for: pull-to-refresh, Settings "Refresh Location" button.
  Future<void> refresh() async {
    _setLoading(true);
    _errorMessage = null;
    notifyListeners();

    _permissionStatus = await _service.requestPermission();
    if (_permissionStatus == LocationPermissionStatus.granted) {
      await _fetchFreshLocation();
    } else {
      _errorMessage = _describePermissionStatus(_permissionStatus);
    }

    _setLoading(false);
  }

  /// Opens the OS location settings screen.
  Future<void> openLocationSettings() => _service.openLocationSettings();

  /// Opens the app permission settings screen.
  Future<void> openAppPermissionSettings() =>
      _service.openAppPermissionSettings();

  /// Re-checks permission status (e.g. after returning from settings).
  Future<void> recheckPermission() async {
    _permissionStatus = await _service.checkPermissionStatus();
    _errorMessage = _permissionStatus == LocationPermissionStatus.granted
        ? null
        : _describePermissionStatus(_permissionStatus);
    notifyListeners();
  }

  /// Returns a human-readable description of when the LVL was last updated.
  Future<String> lastUpdatedDescription() =>
      _service.lastUpdatedDescription();

  // ── Internal helpers ──────────────────────────────────────

  Future<void> _fetchFreshLocation() async {
    final result = await _service.getCurrentLocation();
    if (result is LocationSuccess) {
      _lastVerifiedLocation = result.location;
      _errorMessage = null;
      debugPrint('[LocationProvider] Location updated: ${result.location}');
    } else if (result is LocationFailure) {
      _errorMessage = result.reason;
      debugPrint('[LocationProvider] Location error: ${result.reason}');
    }
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  String _describePermissionStatus(LocationPermissionStatus status) {
    switch (status) {
      case LocationPermissionStatus.denied:
        return 'Location permission denied. Tap to enable.';
      case LocationPermissionStatus.permanentlyDenied:
        return 'Location permanently denied. Open settings to enable.';
      case LocationPermissionStatus.serviceDisabled:
        return 'GPS is turned off. Please enable location services.';
      default:
        return 'Location unavailable.';
    }
  }
}
