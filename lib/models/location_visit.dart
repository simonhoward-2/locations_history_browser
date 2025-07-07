// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'location.dart';

class LocationVisit {
  final Location location;
  final DateTime start;
  final DateTime? end;

  const LocationVisit({required this.location, required this.start, this.end});
}
