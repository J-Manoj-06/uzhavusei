import 'dart:math' as math;

/// Model containing distance computation info between the user and a listing.
class DistanceInfo {
  const DistanceInfo({
    required this.meters,
    required this.kilometers,
    required this.formattedString,
  });

  final double meters;
  final double kilometers;
  final String formattedString;

  @override
  String toString() =>
      'DistanceInfo(meters: $meters, km: $kilometers, formatted: $formattedString)';
}

/// Reusable Distance Engine for:
/// - Haversine distance calculations
/// - Null-safe unit conversions (meters/kilometers)
/// - Auto-formatting distance strings (m/km)
/// - Sorting support for list widgets
class DistanceService {
  DistanceService._();
  static final DistanceService instance = DistanceService._();

  /// Earth's radius in meters (accurate average radius = 6371008.8 meters).
  static const double _earthRadiusMeters = 6371008.8;

  /// Calculates distance in meters between two GPS coordinates using the Haversine formula.
  /// Throws [ArgumentError] if coordinates are invalid.
  double calculateDistance({
    required double startLatitude,
    required double startLongitude,
    required double endLatitude,
    required double endLongitude,
  }) {
    if (!_isValidCoordinate(startLatitude, startLongitude) ||
        !_isValidCoordinate(endLatitude, endLongitude)) {
      throw ArgumentError('Invalid latitude/longitude coordinates');
    }

    final dLat = _toRadians(endLatitude - startLatitude);
    final dLon = _toRadians(endLongitude - startLongitude);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(startLatitude)) *
            math.cos(_toRadians(endLatitude)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final c = 2 * math.asin(math.sqrt(a));
    return _earthRadiusMeters * c;
  }

  /// Helper to convert degrees to radians.
  double _toRadians(double degree) => degree * math.pi / 180.0;

  /// Validates coordinates: Latitude must be in [-90, 90] and Longitude in [-180, 180].
  bool _isValidCoordinate(double lat, double lon) {
    return lat >= -90.0 && lat <= 90.0 && lon >= -180.0 && lon <= 180.0;
  }

  /// Calculates and returns distance in meters. Returns null if inputs are null or invalid.
  double? distanceInMeters(double? lat1, double? lon1, double? lat2, double? lon2) {
    if (lat1 == null || lon1 == null || lat2 == null || lon2 == null) return null;
    try {
      return calculateDistance(
        startLatitude: lat1,
        startLongitude: lon1,
        endLatitude: lat2,
        endLongitude: lon2,
      );
    } catch (_) {
      return null;
    }
  }

  /// Calculates and returns distance in kilometers. Returns null if inputs are null or invalid.
  double? distanceInKilometers(double? lat1, double? lon1, double? lat2, double? lon2) {
    final meters = distanceInMeters(lat1, lon1, lat2, lon2);
    if (meters == null) return null;
    return meters / 1000.0;
  }

  /// Formats distance in meters into a user-friendly string.
  /// Examples:
  /// - 35 m -> "35 m away"
  /// - 450 m -> "450 m away"
  /// - 1250 m -> "1.3 km away"
  /// - 5100 m -> "5.1 km away"
  /// - 25000 m -> "25 km away"
  String formattedDistance(double meters) {
    if (meters < 0) return '0 m away';
    if (meters < 1000) {
      return '${meters.toStringAsFixed(0)} m away';
    } else {
      final km = meters / 1000.0;
      final formattedKm = km.toStringAsFixed(1);
      if (formattedKm.endsWith('.0')) {
        return '${km.toStringAsFixed(0)} km away';
      }
      return '$formattedKm km away';
    }
  }

  /// Returns [DistanceInfo] model for valid inputs, or null if invalid/null.
  DistanceInfo? getDistanceInfo(double? lat1, double? lon1, double? lat2, double? lon2) {
    final meters = distanceInMeters(lat1, lon1, lat2, lon2);
    if (meters == null) return null;
    return DistanceInfo(
      meters: meters,
      kilometers: meters / 1000.0,
      formattedString: formattedDistance(meters),
    );
  }

  /// In-memory sorting helper to sort listings by distance.
  /// Skips invalid listings or appends them at the end.
  List<T> sortByDistance<T>({
    required List<T> listings,
    required double userLat,
    required double userLng,
    required double? Function(T) getLat,
    required double? Function(T) getLng,
    bool nearestFirst = true,
  }) {
    final validListings = <_EnrichedItem<T>>[];
    final invalidListings = <T>[];

    for (final item in listings) {
      final lat = getLat(item);
      final lng = getLng(item);
      final dist = distanceInMeters(userLat, userLng, lat, lng);
      if (dist != null) {
        validListings.add(_EnrichedItem(item, dist));
      } else {
        invalidListings.add(item);
      }
    }

    validListings.sort((a, b) {
      return nearestFirst ? a.distance.compareTo(b.distance) : b.distance.compareTo(a.distance);
    });

    final sorted = validListings.map((e) => e.item).toList();
    sorted.addAll(invalidListings);
    return sorted;
  }
}

class _EnrichedItem<T> {
  const _EnrichedItem(this.item, this.distance);
  final T item;
  final double distance;
}
