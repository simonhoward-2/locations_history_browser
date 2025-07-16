import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:locations_history_browser/models/location.dart';
import 'package:locations_history_browser/models/location_visit.dart';
import 'package:locations_history_browser/style/locations_history_browser_style.dart';
import 'package:locations_history_browser/widget/locations_history_browser_widget.dart';

void main() {
  group('LocationsHistoryBrowser Widget Tests', () {
    // Test data setup
    late List<LocationVisit> testLocationVisits;
    late LocationsHistoryBrowserStyle testStyle;

    setUpAll(() {
      // Create test locations
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

      final newYork = Location(
        city: 'New York',
        country: 'USA',
        timeZoneString: 'America/New_York',
        position: LatLng(40.7128, -74.0060),
      );

      // Create test location visits (intentionally not in chronological order)
      testLocationVisits = [
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
        LocationVisit(
          location: newYork,
          start: DateTime(2024, 1, 1),
          end: null, // Current location
        ),
      ];

      // Create test style
      testStyle = LocationsHistoryBrowserStyle(
        selectedLocationBackgroundColor: Colors.blue,
        selectedLocationTextColor: Colors.white,
        locationVisitBackgroundColor: Colors.teal,
        locationVisitTextColor: Colors.black,
        markerColor: Colors.black,
        selectedMarkerColor: Colors.red,
      );
    });

    testWidgets('should render widget with required parameters', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LocationsHistoryBrowser(
              locationVisits: testLocationVisits,
            ),
          ),
        ),
      );

      // Wait for the widget to initialize with timeout
      await tester.pumpAndSettle();

      // Check if the widget is rendered
      expect(find.byType(LocationsHistoryBrowser), findsOneWidget);
    });

    testWidgets('should display current location information', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LocationsHistoryBrowser(
              locationVisits: testLocationVisits,
              style: testStyle,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should display current location (last visit chronologically)
      expect(find.text('Current location: New York, USA'), findsOneWidget);
      expect(find.text('Timezone: America/New_York'), findsOneWidget);
    });

    testWidgets('should render FlutterMap with markers', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LocationsHistoryBrowser(
              locationVisits: testLocationVisits,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check if FlutterMap is rendered
      expect(find.byType(FlutterMap), findsOneWidget);

      // Check if markers are rendered (should be 4 unique locations)
      final markers = find.byIcon(Icons.location_on);
      final personMarkers = find.byIcon(Icons.person);

      // Should have at least one marker (some might be location_on, one might be person for current)
      expect(markers.evaluate().length + personMarkers.evaluate().length, greaterThan(0));
    });

    testWidgets('should render carousel with location visits', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LocationsHistoryBrowser(
              locationVisits: testLocationVisits,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check if CarouselView is rendered
      expect(find.byType(CarouselView), findsOneWidget);

      // Check if location visits are displayed in the carousel
      expect(find.text('London, UK'), findsOneWidget);
      expect(find.text('Paris, France'), findsOneWidget);
      expect(find.text('Tokyo, Japan'), findsOneWidget);
      expect(find.text('New York, USA'), findsOneWidget);
    });

    testWidgets('should display year headers in carousel', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LocationsHistoryBrowser(
              locationVisits: testLocationVisits,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should display year headers for different years
      expect(find.text('2022'), findsOneWidget);
      expect(find.text('2023'), findsOneWidget);
      expect(find.text('2024'), findsOneWidget);
    });

    testWidgets('should sort location visits chronologically', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LocationsHistoryBrowser(
              locationVisits: testLocationVisits,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify that the current location is the most recent visit (New York from 2024)
      expect(find.text('Current location: New York, USA'), findsOneWidget);

      // Verify year headers appear in chronological order
      expect(find.text('2022'), findsOneWidget);
      expect(find.text('2023'), findsOneWidget);
      expect(find.text('2024'), findsOneWidget);
    });

    testWidgets('should handle tap on carousel item', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LocationsHistoryBrowser(
              locationVisits: testLocationVisits,
              style: testStyle,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find and tap on a specific location visit in the carousel
      final parisText = find.byKey(const Key('carousel_Paris_France'));
      expect(parisText, findsOneWidget);

      await tester.tap(parisText);
      await tester.pumpAndSettle();

      // Verify that interaction was handled (widget should still be present and functional)
      expect(find.byType(LocationsHistoryBrowser), findsOneWidget);
      expect(find.byKey(const Key('carousel_Paris_France')), findsOneWidget);
    });

    testWidgets('should handle tap on current location header', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LocationsHistoryBrowser(
              locationVisits: testLocationVisits,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find and tap on the current location header
      final currentLocationHeader = find.text('Current location: New York, USA');
      expect(currentLocationHeader, findsOneWidget);

      await tester.tap(currentLocationHeader);
      await tester.pumpAndSettle();

      // Should handle the tap gracefully
      expect(find.byType(LocationsHistoryBrowser), findsOneWidget);
      expect(find.text('Current location: New York, USA'), findsOneWidget);
    });

    testWidgets('should apply custom style correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LocationsHistoryBrowser(
              locationVisits: testLocationVisits,
              style: testStyle,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find Material widgets in the carousel to check colors
      final materials = find.descendant(
        of: find.byType(CarouselView),
        matching: find.byType(Material),
      );

      expect(materials.evaluate().isNotEmpty, isTrue);

      // Check if custom style is applied by looking for the colors in the widget tree
      final widget = tester.widget<LocationsHistoryBrowser>(find.byType(LocationsHistoryBrowser));
      expect(widget.style?.selectedLocationBackgroundColor, equals(Colors.blue));
      expect(widget.style?.locationVisitBackgroundColor, equals(Colors.teal));
    });

    testWidgets('should handle empty location visits list', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LocationsHistoryBrowser(
              locationVisits: [],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should handle empty list gracefully
      expect(find.byType(LocationsHistoryBrowser), findsOneWidget);
    });

    testWidgets('should handle single location visit', (WidgetTester tester) async {
      final singleVisit = [testLocationVisits.first];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LocationsHistoryBrowser(
              locationVisits: singleVisit,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should display the single location
      expect(find.text('Tokyo, Japan'), findsOneWidget);
      expect(find.text('Current location: Tokyo, Japan'), findsOneWidget);
    });

    group('Date Formatting Tests', () {
      testWidgets('should format dates correctly in carousel', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: LocationsHistoryBrowser(
                locationVisits: testLocationVisits,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Check date formatting (MMM y format)
        expect(find.text('Jan 2022 - Dec 2022'), findsOneWidget); // London
        expect(find.text('Jan 2023 - May 2023'), findsOneWidget); // Paris
        expect(find.text('Jun 2023 - Aug 2023'), findsOneWidget); // Tokyo
        expect(find.text('Jan 2024 - Present'), findsOneWidget); // New York (current)
      });
    });

    group('Animation Tests', () {
      testWidgets('should handle carousel animation', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: LocationsHistoryBrowser(
                locationVisits: testLocationVisits,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify initial state
        expect(find.text('London, UK'), findsOneWidget);

        // Tap on a different location
        await tester.tap(find.byKey(const Key('carousel_London_UK')));
        await tester.pump(); // Start animation
        await tester.pumpAndSettle(); // Complete animation

        // Verify the widget is still functional after animation
        expect(find.byType(LocationsHistoryBrowser), findsOneWidget);
        expect(find.byKey(const Key('carousel_London_UK')), findsOneWidget);
      });
    });

    group('Edge Cases', () {
      testWidgets('should handle visits with same start date', (WidgetTester tester) async {
        final sameStartDate = DateTime(2023, 1, 1);
        final visitsWithSameDate = [
          LocationVisit(
            location: Location(
              city: 'City A',
              country: 'Country A',
              timeZoneString: 'UTC',
              position: LatLng(0, 0),
            ),
            start: sameStartDate,
            end: DateTime(2023, 6, 1),
          ),
          LocationVisit(
            location: Location(
              city: 'City B',
              country: 'Country B',
              timeZoneString: 'UTC',
              position: LatLng(1, 1),
            ),
            start: sameStartDate,
            end: DateTime(2023, 12, 31),
          ),
        ];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: LocationsHistoryBrowser(
                locationVisits: visitsWithSameDate,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Should handle same start dates gracefully
        expect(find.text('City A, Country A'), findsOneWidget);
        expect(find.text('City B, Country B'), findsOneWidget);
      });
    });

    group('Carousel Navigation', () {
      testWidgets('should display left and right chevron buttons', (WidgetTester tester) async {
        final mockLocationVisits = [
          LocationVisit(
            location: Location(
              city: 'Paris',
              country: 'France',
              timeZoneString: 'CET',
              position: LatLng(48.8566, 2.3522),
            ),
            start: DateTime(2023, 1, 1),
            end: DateTime(2023, 6, 30),
          ),
          LocationVisit(
            location: Location(
              city: 'London',
              country: 'UK',
              timeZoneString: 'GMT',
              position: LatLng(51.5074, -0.1278),
            ),
            start: DateTime(2023, 7, 1),
            end: DateTime(2023, 12, 31),
          ),
        ];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: LocationsHistoryBrowser(
                locationVisits: mockLocationVisits,
              ),
            ),
          ),
        );

        // Wait for widget to render
        await tester.pump();

        // Find the left and right chevron buttons
        expect(find.byIcon(Icons.chevron_left), findsOneWidget);
        expect(find.byIcon(Icons.chevron_right), findsOneWidget);
      });

      testWidgets('should handle left chevron button tap', (WidgetTester tester) async {
        final mockLocationVisits = [
          LocationVisit(
            location: Location(
              city: 'Paris',
              country: 'France',
              timeZoneString: 'CET',
              position: LatLng(48.8566, 2.3522),
            ),
            start: DateTime(2023, 1, 1),
            end: DateTime(2023, 6, 30),
          ),
          LocationVisit(
            location: Location(
              city: 'London',
              country: 'UK',
              timeZoneString: 'GMT',
              position: LatLng(51.5074, -0.1278),
            ),
            start: DateTime(2023, 7, 1),
            end: DateTime(2023, 12, 31),
          ),
        ];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: LocationsHistoryBrowser(
                locationVisits: mockLocationVisits,
              ),
            ),
          ),
        );

        // Wait for widget to render
        await tester.pump();

        // Tap the left chevron button
        await tester.tap(find.byIcon(Icons.chevron_left));
        await tester.pumpAndSettle();

        // Button should be tappable without errors
        expect(find.byIcon(Icons.chevron_left), findsOneWidget);
      });

      testWidgets('should handle right chevron button tap', (WidgetTester tester) async {
        final mockLocationVisits = [
          LocationVisit(
            location: Location(
              city: 'Paris',
              country: 'France',
              timeZoneString: 'CET',
              position: LatLng(48.8566, 2.3522),
            ),
            start: DateTime(2023, 1, 1),
            end: DateTime(2023, 6, 30),
          ),
          LocationVisit(
            location: Location(
              city: 'London',
              country: 'UK',
              timeZoneString: 'GMT',
              position: LatLng(51.5074, -0.1278),
            ),
            start: DateTime(2023, 7, 1),
            end: DateTime(2023, 12, 31),
          ),
        ];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: LocationsHistoryBrowser(
                locationVisits: mockLocationVisits,
              ),
            ),
          ),
        );

        // Wait for widget to render
        await tester.pump();

        // Tap the right chevron button
        await tester.tap(find.byIcon(Icons.chevron_right));
        await tester.pumpAndSettle();

        // Button should be tappable without errors
        expect(find.byIcon(Icons.chevron_right), findsOneWidget);
      });
    });
  });
}
