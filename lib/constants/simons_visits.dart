import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/location_visit.dart';

import '../models/location.dart';

final homeLocation = Location(city: 'Sydney', country: 'Australia', timeZoneString: 'AEST +10', position: LatLng(-33.8626157, 151.1949714));

final simonsVisits = [
  // Sydney Oct 2023 - Feb 2024
  LocationVisit(location: homeLocation, start: DateTime(2023, 10), end: DateTime(2024, 2)),
  // Fukuyama, Japan
  LocationVisit(
    location: Location(city: 'Fukuyama', country: 'Japan', timeZoneString: 'JST +9', position: LatLng(34.4854, 133.3619)),
    start: DateTime(2024, 3),
    end: DateTime(2024, 3),
  ),
  // Hiroshima, Japan
  LocationVisit(
    location: Location(city: 'Hiroshima', country: 'Japan', timeZoneString: 'JST +9', position: LatLng(34.3853, 132.4553)),
    start: DateTime(2024, 4),
    end: DateTime(2024, 4),
  ),
  // Beppu, Japan
  LocationVisit(
    location: Location(city: 'Beppu', country: 'Japan', timeZoneString: 'JST +9', position: LatLng(33.2741, 131.5053)),
    start: DateTime(2024, 4),
    end: DateTime(2024, 4),
  ),
  // Kathmandu, Nepal
  LocationVisit(
    location: Location(city: 'Kathmandu', country: 'Nepal', timeZoneString: 'NPT +5:45', position: LatLng(27.7172, 85.3240)),
    start: DateTime(2024, 5),
    end: DateTime(2024, 5),
  ),
  // Istanbul, Turkey
  LocationVisit(
    location: Location(city: 'Istanbul', country: 'Turkey', timeZoneString: 'TRT +3', position: LatLng(41.0082, 28.9784)),
    start: DateTime(2024, 6),
    end: DateTime(2024, 6),
  ),
  // Peschichi, Italy
  LocationVisit(
    location: Location(city: 'Peschici', country: 'Italy', timeZoneString: 'CEST +2', position: LatLng(41.9583, 16.0076)),
    start: DateTime(2024, 7),
    end: DateTime(2024, 7),
  ),
  // Berlin, Germany
  LocationVisit(
    location: Location(city: 'Berlin', country: 'Germany', timeZoneString: 'CEST +2', position: LatLng(52.5200, 13.4050)),
    start: DateTime(2024, 7),
    end: DateTime(2024, 7),
  ),
  // Shkoder, Albania
  LocationVisit(
    location: Location(city: 'Shkoder', country: 'Albania', timeZoneString: 'CEST +2', position: LatLng(42.0685, 19.5188)),
    start: DateTime(2024, 8),
    end: DateTime(2024, 8),
  ),
  // Split, Croatia
  LocationVisit(
    location: Location(city: 'Split', country: 'Croatia', timeZoneString: 'CEST +2', position: LatLng(43.5081, 16.4402)),
    start: DateTime(2024, 8),
    end: DateTime(2024, 8),
  ),
  // Asturias, Spain
  LocationVisit(
    location: Location(city: 'Asturias', country: 'Spain', timeZoneString: 'CEST +2', position: LatLng(43.3614, -5.8593)),
    start: DateTime(2024, 9),
    end: DateTime(2024, 9),
  ),
  // Milan, Italy
  LocationVisit(
    location: Location(city: 'Milan', country: 'Italy', timeZoneString: 'CEST +2', position: LatLng(45.4642, 9.1900)),
    start: DateTime(2024, 9),
    end: DateTime(2024, 9),
  ),
  // Spello, Italy
  LocationVisit(
    location: Location(city: 'Spello', country: 'Italy', timeZoneString: 'CEST +2', position: LatLng(42.9911, 12.6719)),
    start: DateTime(2024, 10),
    end: DateTime(2024, 10),
  ),
  // Sydney Oct 2024 - Feb 2025
  LocationVisit(location: homeLocation, start: DateTime(2024, 10), end: DateTime(2025, 2)),
  // India
  LocationVisit(
    location: Location(city: 'Rhishikesh', country: 'India', timeZoneString: 'IST +5:30', position: LatLng(30.1033, 78.2948)),
    start: DateTime(2025, 2),
    end: DateTime(2025, 3),
  ),
  // Sydney Mar 2025 - present
  LocationVisit(location: homeLocation, start: DateTime(2025, 3)),
];
