import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/simons_visits.dart';
import '../models/location_visit.dart';

final currentSelectedLocationProvider = StateNotifierProvider<CurrentSelectedLocationNotifier, LocationVisit>((ref) {
  return CurrentSelectedLocationNotifier();
});

class CurrentSelectedLocationNotifier extends StateNotifier<LocationVisit> {
  CurrentSelectedLocationNotifier() : super(simonsVisits.last);

  void selectLocation(LocationVisit locationVisit) {
    state = locationVisit;
  }
}
