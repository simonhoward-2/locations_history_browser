import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';

import '../constants/simons_visits.dart';
import '../models/location_visit.dart';
import '../state/current_selected_location.dart';
import '../style/locations_history_browser_style.dart';

class LocationsHistoryBrowser extends ConsumerStatefulWidget {
  final LocationsHistoryBrowserStyle? style;

  const LocationsHistoryBrowser({
    super.key,
    this.style,
  });

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _LocationsHistoryBrowserState();
}

class _LocationsHistoryBrowserState extends ConsumerState<LocationsHistoryBrowser> {
  final Completer<GoogleMapController> _controller = Completer<GoogleMapController>();
  late FutureProvider<String?> darkMapStyle;
  final carouselController = CarouselController();

  final tileOffest = 200.0;
  final carouselWidth = 600.0;

  @override
  void initState() {
    // Load the dark map style
    darkMapStyle = FutureProvider((ref) async {
      return await DefaultAssetBundle.of(context).loadString('assets/maps_dark_theme.json');
    });

    //carouselController.jumpTo(simonsVisits.length - 1);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      carouselController.animateTo(carouselController.position.maxScrollExtent, duration: Durations.long1, curve: Curves.easeInOut);
    });

    super.initState();
  }

  void animateCarouselTo(LocationVisit visit) {
    var index = simonsVisits.indexOf(visit);
    var desiredOffset = index * tileOffest - (carouselWidth - tileOffest) / 2;
    var offset = desiredOffset.clamp(0, carouselController.position.maxScrollExtent) as double;
    carouselController.animateTo(offset, duration: Durations.long1, curve: Curves.easeInOut);
  }

  @override
  Widget build(BuildContext context) {
    final locationsVisitBackgroundColor = widget.style?.locationVisitBackgroundColor ?? Colors.teal;
    final selectedLocationBackgroundColor = widget.style?.selectedLocationBackgroundColor ?? Colors.blue;

    // Load the json text of the dark map style
    var darkMapStyleLoaded = ref.watch(darkMapStyle);

    // Get the theme mode for the map styling
    // var themeMode = ref.watch(settingsProvider).themeMode;
    // if (themeMode == ThemeMode.system) {
    //   themeMode = MediaQuery.of(context).platformBrightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light;
    // }

    // watch for changes in the current location
    ref.listen(currentSelectedLocationProvider, (previous, next) {
      // Position has changed
      _controller.future.then((controller) {
        controller.animateCamera(CameraUpdate.newLatLng(next.location.position));
        controller.showMarkerInfoWindow(MarkerId(next.location.city));
      });
      animateCarouselTo(next);
    });

    final currentLocation = simonsVisits.last.location;
    var selectedLocation = ref.watch(currentSelectedLocationProvider);

    final dateFormat = DateFormat('MMM y');

    return Column(
      children: [
        // Map
        Align(
          alignment: Alignment.center,
          child: SizedBox(
            height: 400,
            width: 600,
            child: darkMapStyleLoaded.when(
              data: (data) => GoogleMap(
                mapType: MapType.normal,
                initialCameraPosition: CameraPosition(target: selectedLocation.location.position, zoom: 3),
                style: "[]", //themeMode == ThemeMode.dark ? data : "[]",
                markers: simonsVisits.map((visit) {
                  var location = visit.location;
                  return Marker(
                    markerId: MarkerId(location.city),
                    position: location.position,
                    onTap: () {
                      ref.read(currentSelectedLocationProvider.notifier).selectLocation(visit);
                    },
                    infoWindow: InfoWindow(
                      title: location.city,
                      snippet: '${dateFormat.format(visit.start)} - ${visit.end != null ? dateFormat.format(visit.end!) : "Present"}',
                    ),
                  );
                }).toSet(),
                onMapCreated: (GoogleMapController controller) {
                  _controller.complete(controller);
                },
              ),
              loading: () => Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => Center(child: Text("Error loading map style")),
            ),
          ),
        ),
        SizedBox(height: 20),
        Text('Current location: ${currentLocation.city}, ${currentLocation.country}'),
        Text('Timezone: ${currentLocation.timeZoneString}'),
        SizedBox(height: 20),
        Text('Timeline'),
        SizedBox(height: 20),
        SizedBox(
          width: carouselWidth,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: 100),
            child: CarouselView(
              itemExtent: tileOffest,
              controller: carouselController,
              onTap: (value) {
                ref.read(currentSelectedLocationProvider.notifier).selectLocation(simonsVisits[value]);
              },
              children: simonsVisits.map((visit) {
                return ColoredBox(
                  color: visit == selectedLocation ? selectedLocationBackgroundColor : locationsVisitBackgroundColor,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              '${visit.location.city}, ${visit.location.country}',
                              maxLines: 1,
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.fade,
                            ),
                          ),
                          Flexible(
                            child: Text(
                              '${dateFormat.format(visit.start)} - ${visit.end != null ? dateFormat.format(visit.end!) : "Present"}',
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.fade,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}
