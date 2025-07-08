import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/location_visit.dart';

class CurrentSelectedLocationNotifier extends StateNotifier<LocationVisit> {
  CurrentSelectedLocationNotifier(super.intialValue) : super();

  void selectLocationVisit(LocationVisit locationVisit) {
    state = locationVisit;
  }
}
