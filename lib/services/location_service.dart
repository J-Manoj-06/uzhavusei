import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geocoding/geocoding.dart';

// ─────────────────────────────────────────────────────────────
//  Value objects
// ─────────────────────────────────────────────────────────────

/// Represents a successfully cached device location.
class VerifiedLocation {
  const VerifiedLocation({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    this.area,
    this.city,
    this.state,
    this.country,
    this.accuracy,
  });

  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final String? area;
  final String? city;
  final String? state;
  final String? country;
  final double? accuracy;

  /// Returns true if the cached location is older than 24 hours.
  bool get isStale =>
      DateTime.now().difference(timestamp).inHours >= 24;

  @override
  String toString() =>
      'VerifiedLocation(lat: $latitude, lng: $longitude, area: $area, city: $city, state: $state, country: $country, accuracy: $accuracy, at: $timestamp)';
}

// ─────────────────────────────────────────────────────────────
//  Result types  (sealed-class pattern via inheritance)
// ─────────────────────────────────────────────────────────────

/// Base class for the result of a location operation.
abstract class LocationResult {}

/// Successful GPS acquisition.
class LocationSuccess extends LocationResult {
  LocationSuccess(this.location);
  final VerifiedLocation location;
}

/// Failed GPS acquisition with a human-readable reason.
class LocationFailure extends LocationResult {
  LocationFailure(this.reason, {this.isPermanent = false});
  /// Human-readable description of what went wrong.
  final String reason;
  /// True when the permission is permanently denied and must be fixed in settings.
  final bool isPermanent;
}

// ─────────────────────────────────────────────────────────────
//  Permission status enum
// ─────────────────────────────────────────────────────────────

enum LocationPermissionStatus {
  granted,
  denied,
  permanentlyDenied,
  serviceDisabled,
  unknown,
}

// ─────────────────────────────────────────────────────────────
//  SharedPreferences key constants
// ─────────────────────────────────────────────────────────────

class _LvlKeys {
  static const String latitude  = 'lvl_latitude';
  static const String longitude = 'lvl_longitude';
  static const String timestamp = 'lvl_timestamp_ms';
}

// ─────────────────────────────────────────────────────────────
//  LocationService
// ─────────────────────────────────────────────────────────────

/// Singleton service responsible for:
/// - Checking and requesting location permissions
/// - Retrieving the device's current GPS position
/// - Reading and writing the Last Verified Location (LVL) cache
/// - Enforcing a 24-hour cache refresh policy
///
/// This service does NOT perform continuous location tracking.
/// It is designed for battery efficiency and production use.
class LocationService {
  LocationService._();
  static final LocationService instance = LocationService._();

  /// Cache refresh threshold.
  static const Duration _refreshThreshold = Duration(hours: 24);

  /// GPS acquisition timeout.
  static const Duration _gpsTimeout = Duration(seconds: 20);

  // ── Permission ─────────────────────────────────────────────

  /// Returns the current permission status without requesting it.
  Future<LocationPermissionStatus> checkPermissionStatus() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return LocationPermissionStatus.serviceDisabled;

      final permission = await Geolocator.checkPermission();
      return _mapPermission(permission);
    } catch (e) {
      debugPrint('[LocationService] checkPermissionStatus error: $e');
      return LocationPermissionStatus.unknown;
    }
  }

  /// Requests permission if not already granted.
  /// Returns the resolved [LocationPermissionStatus].
  Future<LocationPermissionStatus> requestPermission() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return LocationPermissionStatus.serviceDisabled;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      return _mapPermission(permission);
    } catch (e) {
      debugPrint('[LocationService] requestPermission error: $e');
      return LocationPermissionStatus.unknown;
    }
  }

  /// Returns true if GPS / location services are enabled at OS level.
  Future<bool> isLocationServiceEnabled() =>
      Geolocator.isLocationServiceEnabled();

  // ── Current location ──────────────────────────────────────

  /// Obtains a **fresh** GPS fix, saves it to the LVL cache,
  /// and returns a [LocationResult].
  ///
  /// Use this when:
  ///  - No cache exists
  ///  - The cache is stale (> 24 h)
  ///  - The user explicitly refreshes
  ///  - The user taps Publish in Create Listing
  Future<LocationResult> getCurrentLocation() async {
    try {
      // 1. Check services
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return LocationFailure(
          'Location services are disabled. Please enable GPS in your device settings.',
        );
      }

      // 2. Resolve permissions
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        return LocationFailure(
          'Location permission was denied. Borrow needs location to show nearby listings.',
        );
      }
      if (permission == LocationPermission.deniedForever) {
        return LocationFailure(
          'Location permission is permanently denied. Please enable it in app settings.',
          isPermanent: true,
        );
      }

      // 3. Acquire GPS position with retry logic (3 attempts)
      Position? position;
      String? errorMsg;
      for (int i = 0; i < 3; i++) {
        try {
          position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.medium,
            timeLimit: _gpsTimeout,
          );
          // Check quality: reject extremely poor accuracy (>100 meters)
          if (position.accuracy <= 100) {
            break;
          } else {
            errorMsg = 'Unable to determine an accurate location. Please move to an open area and try again.';
          }
        } catch (e) {
          if (e.toString().toLowerCase().contains('timeout') ||
              e.toString().toLowerCase().contains('timedout')) {
            errorMsg = 'GPS timed out. Please try again in an open area.';
          } else {
            errorMsg = 'Unable to determine your location. Please enable GPS or move to an open area.';
          }
        }
      }

      if (position == null) {
        return LocationFailure(errorMsg ?? 'Unable to determine location.');
      }
      if (position.accuracy > 100) {
        return LocationFailure('Unable to determine an accurate location. Please move to an open area and try again.');
      }

      // 4. Reverse Geocode to get address details
      String area = '';
      String city = '';
      String state = '';
      String country = '';
      try {
        final placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          area = place.subLocality ?? place.name ?? '';
          city = place.locality ?? '';
          state = place.administrativeArea ?? '';
          country = place.country ?? '';
        }
      } catch (e) {
        debugPrint('[LocationService] Reverse geocoding failed: $e');
        area = 'Unknown Area';
        city = 'Unknown City';
        state = 'Unknown State';
        country = 'Unknown Country';
      }

      // 5. Build and cache the verified location
      final location = VerifiedLocation(
        latitude: position.latitude,
        longitude: position.longitude,
        timestamp: DateTime.now(),
        area: area,
        city: city,
        state: state,
        country: country,
        accuracy: position.accuracy,
      );
      await _writeCache(location);

      debugPrint('[LocationService] Fresh location acquired: $location');
      return LocationSuccess(location);
    } catch (e) {
      debugPrint('[LocationService] getCurrentLocation error: $e');
      return LocationFailure('Unable to determine location. Please try again.');
    }
  }

  /// Returns the cached LVL without triggering GPS.
  /// Returns null if no cache exists.
  Future<VerifiedLocation?> getLastVerifiedLocation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lat   = prefs.getDouble(_LvlKeys.latitude);
      final lng   = prefs.getDouble(_LvlKeys.longitude);
      final tsMs  = prefs.getInt(_LvlKeys.timestamp);

      if (lat == null || lng == null || tsMs == null) return null;

      final area = prefs.getString('lvl_area');
      final city = prefs.getString('lvl_city');
      final state = prefs.getString('lvl_state');
      final country = prefs.getString('lvl_country');
      final accuracy = prefs.getDouble('lvl_accuracy');

      return VerifiedLocation(
        latitude: lat,
        longitude: lng,
        timestamp: DateTime.fromMillisecondsSinceEpoch(tsMs),
        area: area,
        city: city,
        state: state,
        country: country,
        accuracy: accuracy,
      );
    } catch (e) {
      debugPrint('[LocationService] getLastVerifiedLocation error: $e');
      return null;
    }
  }

  /// Smart location getter:
  /// - Returns cached LVL if fresh (< 24 h).
  /// - Requests a new GPS fix if stale or missing.
  Future<LocationResult> getLocationWithCachePolicy() async {
    final cached = await getLastVerifiedLocation();
    if (cached != null && !cached.isStale) {
      debugPrint('[LocationService] Returning cached LVL (fresh).');
      return LocationSuccess(cached);
    }
    debugPrint('[LocationService] Cache missing or stale – requesting fresh GPS.');
    return getCurrentLocation();
  }

  /// Force a fresh GPS fix regardless of cache age.
  Future<LocationResult> refreshLocation() => getCurrentLocation();

  /// Returns true if a fresh GPS fix should be requested.
  Future<bool> shouldRefresh() async {
    final cached = await getLastVerifiedLocation();
    if (cached == null) return true;
    return cached.isStale;
  }

  /// Caches a fresh GPS position.
  Future<VerifiedLocation> cachePosition(Position position) async {
    final location = VerifiedLocation(
      latitude: position.latitude,
      longitude: position.longitude,
      timestamp: DateTime.now(),
      accuracy: position.accuracy,
    );
    await _writeCache(location);
    return location;
  }

  // ── Cache helpers ─────────────────────────────────────────

  /// Persists a [VerifiedLocation] to SharedPreferences.
  Future<void> _writeCache(VerifiedLocation location) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_LvlKeys.latitude, location.latitude);
      await prefs.setDouble(_LvlKeys.longitude, location.longitude);
      await prefs.setInt(
          _LvlKeys.timestamp, location.timestamp.millisecondsSinceEpoch);
      if (location.area != null) await prefs.setString('lvl_area', location.area!);
      if (location.city != null) await prefs.setString('lvl_city', location.city!);
      if (location.state != null) await prefs.setString('lvl_state', location.state!);
      if (location.country != null) await prefs.setString('lvl_country', location.country!);
      if (location.accuracy != null) await prefs.setDouble('lvl_accuracy', location.accuracy!);
      debugPrint('[LocationService] LVL cache written: $location');
    } catch (e) {
      debugPrint('[LocationService] _writeCache error: $e');
    }
  }

  /// Clears the LVL cache (e.g. on sign-out).
  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_LvlKeys.latitude);
      await prefs.remove(_LvlKeys.longitude);
      await prefs.remove(_LvlKeys.timestamp);
      debugPrint('[LocationService] LVL cache cleared.');
    } catch (e) {
      debugPrint('[LocationService] clearCache error: $e');
    }
  }

  // ── Settings helpers ──────────────────────────────────────

  /// Opens the OS location settings page so the user can enable GPS.
  Future<void> openLocationSettings() => Geolocator.openLocationSettings();

  /// Opens the app-specific permission settings page.
  Future<void> openAppPermissionSettings() => Geolocator.openAppSettings();

  /// Returns a human-readable string describing when the LVL was last updated.
  Future<String> lastUpdatedDescription() async {
    final cached = await getLastVerifiedLocation();
    if (cached == null) return 'Never';
    final diff = DateTime.now().difference(cached.timestamp);
    if (diff.inMinutes < 1)  return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} minutes ago';
    if (diff.inHours < 24)   return '${diff.inHours} hours ago';
    return '${diff.inDays} days ago';
  }

  // ── Private helpers ────────────────────────────────────────

  LocationPermissionStatus _mapPermission(LocationPermission p) {
    switch (p) {
      case LocationPermission.always:
      case LocationPermission.whileInUse:
        return LocationPermissionStatus.granted;
      case LocationPermission.deniedForever:
        return LocationPermissionStatus.permanentlyDenied;
      case LocationPermission.denied:
        return LocationPermissionStatus.denied;
      default:
        return LocationPermissionStatus.unknown;
    }
  }

  // Expose threshold for tests / settings display
  Duration get refreshThreshold => _refreshThreshold;
}
