// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:latlong2/latlong.dart';

class Location {
  final String city;
  final String country;
  final String timeZoneString;
  final LatLng position;

  const Location({
    required this.city,
    required this.country,
    required this.timeZoneString,
    required this.position,
  });

  @override
  bool operator ==(covariant Location other) {
    if (identical(this, other)) return true;

    return other.city == city && other.country == country && other.timeZoneString == timeZoneString && other.position == position;
  }

  @override
  int get hashCode {
    return city.hashCode ^ country.hashCode ^ timeZoneString.hashCode ^ position.hashCode;
  }
}
