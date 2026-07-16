import 'package:flutter_test/flutter_test.dart';
import 'package:UzhavuSei/services/distance_service.dart';

void main() {
  group('DistanceService - Haversine Distance Calculation', () {
    final service = DistanceService.instance;

    test('Same location returns 0 meters', () {
      const lat = 13.08268;
      const lng = 80.270718;
      
      final meters = service.calculateDistance(
        startLatitude: lat,
        startLongitude: lng,
        endLatitude: lat,
        endLongitude: lng,
      );
      
      expect(meters, closeTo(0.0, 0.001));
    });

    test('Very short distance (<100m) calculation', () {
      // Chennai Central station platform walk coordinates (approx 50m)
      const lat1 = 13.082680;
      const lng1 = 80.270718;
      const lat2 = 13.082350;
      const lng2 = 80.270500;

      final meters = service.calculateDistance(
        startLatitude: lat1,
        startLongitude: lng1,
        endLatitude: lat2,
        endLongitude: lng2,
      );

      // Verify it is a short distance (should be around 43.6 meters)
      expect(meters, greaterThan(30.0));
      expect(meters, lessThan(60.0));
    });

    test('500 meters distance calculation', () {
      const lat1 = 13.082680;
      const lng1 = 80.270718;
      // Approx 500m away in Chennai
      const lat2 = 13.078430;
      const lng2 = 80.269380;

      final meters = service.calculateDistance(
        startLatitude: lat1,
        startLongitude: lng1,
        endLatitude: lat2,
        endLongitude: lng2,
      );

      expect(meters, closeTo(500.0, 50.0));
    });

    test('1 kilometer distance calculation', () {
      const lat1 = 13.082680;
      const lng1 = 80.270718;
      // Approx 1km away in Chennai
      const lat2 = 13.073900;
      const lng2 = 80.270000;

      final meters = service.calculateDistance(
        startLatitude: lat1,
        startLongitude: lng1,
        endLatitude: lat2,
        endLongitude: lng2,
      );

      expect(meters, closeTo(1000.0, 100.0));
    });

    test('10 kilometers distance calculation', () {
      const lat1 = 13.082680;
      const lng1 = 80.270718;
      // Approx 10km away in Chennai (e.g. to Guindy area)
      const lat2 = 13.007600;
      const lng2 = 80.220600;

      final meters = service.calculateDistance(
        startLatitude: lat1,
        startLongitude: lng1,
        endLatitude: lat2,
        endLongitude: lng2,
      );

      expect(meters, closeTo(10000.0, 1500.0));
    });

    test('100 kilometers distance calculation', () {
      const lat1 = 13.082680;
      const lng1 = 80.270718;
      // Approx 100km away (e.g. to Vellore / Ranipet area)
      const lat2 = 12.923400;
      const lng2 = 79.351200;

      final meters = service.calculateDistance(
        startLatitude: lat1,
        startLongitude: lng1,
        endLatitude: lat2,
        endLongitude: lng2,
      );

      expect(meters, closeTo(100000.0, 15000.0));
    });

    test('Invalid coordinates throw ArgumentError', () {
      expect(
        () => service.calculateDistance(
          startLatitude: 95.0,
          startLongitude: 80.0,
          endLatitude: 13.0,
          endLongitude: 80.0,
        ),
        throwsArgumentError,
      );
      
      expect(
        () => service.calculateDistance(
          startLatitude: 13.0,
          startLongitude: 80.0,
          endLatitude: 13.0,
          endLongitude: 185.0,
        ),
        throwsArgumentError,
      );
    });

    test('Null coordinates handled gracefully and return null', () {
      expect(service.distanceInMeters(null, 80.0, 13.0, 80.0), isNull);
      expect(service.distanceInMeters(13.0, null, 13.0, 80.0), isNull);
      expect(service.distanceInMeters(13.0, 80.0, null, 80.0), isNull);
      expect(service.distanceInMeters(13.0, 80.0, 13.0, null), isNull);
    });
  });

  group('DistanceService - Formatting', () {
    final service = DistanceService.instance;

    test('Meters formatting (< 1000m)', () {
      expect(service.formattedDistance(0), equals('0 m away'));
      expect(service.formattedDistance(35.2), equals('35 m away'));
      expect(service.formattedDistance(450.9), equals('451 m away'));
      expect(service.formattedDistance(999), equals('999 m away'));
    });

    test('Kilometers formatting (>= 1000m)', () {
      expect(service.formattedDistance(1000), equals('1 km away'));
      expect(service.formattedDistance(1250), equals('1.3 km away'));
      expect(service.formattedDistance(5100), equals('5.1 km away'));
      expect(service.formattedDistance(25000), equals('25 km away'));
      expect(service.formattedDistance(25200), equals('25.2 km away'));
    });
  });

  group('DistanceService - Sorting', () {
    final service = DistanceService.instance;

    test('Sorting by distance Nearest First and Farthest First', () {
      final userLat = 13.082680;
      final userLng = 80.270718;

      final items = [
        _MockListing(name: 'Far', lat: 12.9234, lng: 79.3512), // ~100km
        _MockListing(name: 'Medium', lat: 13.0784, lng: 80.2693), // ~500m
        _MockListing(name: 'Close', lat: 13.0823, lng: 80.2705), // ~50m
        _MockListing(name: 'Invalid', lat: null, lng: null), // Invalid
      ];

      // Test Nearest First
      final sortedNearest = service.sortByDistance<_MockListing>(
        listings: items,
        userLat: userLat,
        userLng: userLng,
        getLat: (item) => item.lat,
        getLng: (item) => item.lng,
        nearestFirst: true,
      );

      expect(sortedNearest[0].name, equals('Close'));
      expect(sortedNearest[1].name, equals('Medium'));
      expect(sortedNearest[2].name, equals('Far'));
      expect(sortedNearest[3].name, equals('Invalid')); // Invalid appended at end

      // Test Farthest First
      final sortedFarthest = service.sortByDistance<_MockListing>(
        listings: items,
        userLat: userLat,
        userLng: userLng,
        getLat: (item) => item.lat,
        getLng: (item) => item.lng,
        nearestFirst: false,
      );

      expect(sortedFarthest[0].name, equals('Far'));
      expect(sortedFarthest[1].name, equals('Medium'));
      expect(sortedFarthest[2].name, equals('Close'));
      expect(sortedFarthest[3].name, equals('Invalid')); // Invalid appended at end
    });
  });
}

class _MockListing {
  _MockListing({required this.name, this.lat, this.lng});
  final String name;
  final double? lat;
  final double? lng;
}
