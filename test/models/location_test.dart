import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:locations_history_browser/models/location.dart';
import 'package:locations_history_browser/models/location_visit.dart';

void main() {
  group('Location Model Tests', () {
    test('should create Location instance with all properties', () {
      final location = Location(
        city: 'London',
        country: 'UK',
        timeZoneString: 'Europe/London',
        position: LatLng(51.5074, -0.1278),
      );

      expect(location.city, equals('London'));
      expect(location.country, equals('UK'));
      expect(location.timeZoneString, equals('Europe/London'));
      expect(location.position.latitude, equals(51.5074));
      expect(location.position.longitude, equals(-0.1278));
    });

    test('should compare Location instances correctly', () {
      final location1 = Location(
        city: 'London',
        country: 'UK',
        timeZoneString: 'Europe/London',
        position: LatLng(51.5074, -0.1278),
      );

      final location2 = Location(
        city: 'London',
        country: 'UK',
        timeZoneString: 'Europe/London',
        position: LatLng(51.5074, -0.1278),
      );

      final location3 = Location(
        city: 'Paris',
        country: 'France',
        timeZoneString: 'Europe/Paris',
        position: LatLng(48.8566, 2.3522),
      );

      expect(location1, equals(location2));
      expect(location1, isNot(equals(location3)));
      expect(location1.hashCode, equals(location2.hashCode));
      expect(location1.hashCode, isNot(equals(location3.hashCode)));
    });
  });

  group('LocationVisit Model Tests', () {
    late Location testLocation;

    setUp(() {
      testLocation = Location(
        city: 'Tokyo',
        country: 'Japan',
        timeZoneString: 'Asia/Tokyo',
        position: LatLng(35.6762, 139.6503),
      );
    });

    test('should create LocationVisit with start and end dates', () {
      final startDate = DateTime(2023, 1, 1);
      final endDate = DateTime(2023, 12, 31);

      final visit = LocationVisit(
        location: testLocation,
        start: startDate,
        end: endDate,
      );

      expect(visit.location, equals(testLocation));
      expect(visit.start, equals(startDate));
      expect(visit.end, equals(endDate));
    });

    test('should create LocationVisit with null end date (current location)', () {
      final startDate = DateTime(2024, 1, 1);

      final visit = LocationVisit(
        location: testLocation,
        start: startDate,
        end: null,
      );

      expect(visit.location, equals(testLocation));
      expect(visit.start, equals(startDate));
      expect(visit.end, isNull);
    });

    test('should compare LocationVisit instances correctly', () {
      final startDate = DateTime(2023, 1, 1);
      final endDate = DateTime(2023, 12, 31);

      final visit1 = LocationVisit(
        location: testLocation,
        start: startDate,
        end: endDate,
      );

      final visit2 = LocationVisit(
        location: testLocation,
        start: startDate,
        end: endDate,
      );

      final visit3 = LocationVisit(
        location: testLocation,
        start: DateTime(2024, 1, 1),
        end: null,
      );

      expect(visit1, equals(visit2));
      expect(visit1, isNot(equals(visit3)));
      expect(visit1.hashCode, equals(visit2.hashCode));
      expect(visit1.hashCode, isNot(equals(visit3.hashCode)));
    });

    test('should handle visits with same location but different dates', () {
      final visit1 = LocationVisit(
        location: testLocation,
        start: DateTime(2023, 1, 1),
        end: DateTime(2023, 6, 30),
      );

      final visit2 = LocationVisit(
        location: testLocation,
        start: DateTime(2023, 7, 1),
        end: DateTime(2023, 12, 31),
      );

      expect(visit1.location, equals(visit2.location));
      expect(visit1, isNot(equals(visit2)));
    });
  });

  group('Model Integration Tests', () {
    test('should create complex location visit history', () {
      final locations = [
        Location(
          city: 'London',
          country: 'UK',
          timeZoneString: 'Europe/London',
          position: LatLng(51.5074, -0.1278),
        ),
        Location(
          city: 'New York',
          country: 'USA',
          timeZoneString: 'America/New_York',
          position: LatLng(40.7128, -74.0060),
        ),
      ];

      final visits = [
        LocationVisit(
          location: locations[0],
          start: DateTime(2022, 1, 1),
          end: DateTime(2022, 12, 31),
        ),
        LocationVisit(
          location: locations[1],
          start: DateTime(2023, 1, 1),
          end: null,
        ),
      ];

      expect(visits.length, equals(2));
      expect(visits[0].location.city, equals('London'));
      expect(visits[1].location.city, equals('New York'));
      expect(visits[1].end, isNull); // Current location
    });

    test('should sort location visits by start date', () {
      final london = Location(
        city: 'London',
        country: 'UK',
        timeZoneString: 'Europe/London',
        position: LatLng(51.5074, -0.1278),
      );

      final paris = Location(
        city: 'Paris',
        country: 'France',
        timeZoneString: 'Europe/Paris',
        position: LatLng(48.8566, 2.3522),
      );

      final tokyo = Location(
        city: 'Tokyo',
        country: 'Japan',
        timeZoneString: 'Asia/Tokyo',
        position: LatLng(35.6762, 139.6503),
      );

      // Create visits in non-chronological order
      final visits = [
        LocationVisit(
          location: tokyo,
          start: DateTime(2023, 6, 1),
          end: DateTime(2023, 8, 31),
        ),
        LocationVisit(
          location: london,
          start: DateTime(2022, 1, 1),
          end: DateTime(2022, 12, 31),
        ),
        LocationVisit(
          location: paris,
          start: DateTime(2023, 1, 1),
          end: DateTime(2023, 5, 31),
        ),
      ];

      // Sort by start date
      visits.sort((a, b) => a.start.compareTo(b.start));

      expect(visits[0].location.city, equals('London')); // 2022
      expect(visits[1].location.city, equals('Paris')); // 2023 Jan
      expect(visits[2].location.city, equals('Tokyo')); // 2023 Jun
    });
  });
}
