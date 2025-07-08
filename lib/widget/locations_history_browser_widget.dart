import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

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
  late FutureProvider<String?> darkMapStyle;
  final carouselController = CarouselController();

  final tileOffest = 200.0;
  final locationVisitFocusMargin = 50;
  final carouselWidth = 600.0;

  @override
  void initState() {
    // Load the dark map style
    darkMapStyle = FutureProvider((ref) async {
      return await DefaultAssetBundle.of(context).loadString('assets/maps_dark_theme.json');
    });

    //carouselController.jumpTo(simonsVisits.length - 1);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      carouselController.animateTo(carouselController.position.maxScrollExtent, duration: Durations.long1, curve: Curves.easeInOut).then((_) {
        // Add scroll listener for detecting scroll changes
        carouselController.addListener(_onCarouselScroll);
      });
    });

    super.initState();
  }

  @override
  void dispose() {
    carouselController.removeListener(_onCarouselScroll);
    carouselController.dispose();
    super.dispose();
  }

  void _onCarouselScroll() {
    if (!carouselController.hasClients) return;

    // Determine if the selected item is currently visible in the viewport
    final viewport = carouselController.position.viewportDimension;
    final scrollOffset = carouselController.offset;
    final selectedItemIndex = simonsVisits.indexOf(ref.read(currentSelectedLocationProvider));
    final selectedItemStart = selectedItemIndex * tileOffest;
    final selectedItemEnd = selectedItemStart + tileOffest;
    final isSelectedItemVisible =
        (selectedItemStart >= scrollOffset + locationVisitFocusMargin && selectedItemStart < scrollOffset + viewport - locationVisitFocusMargin) ||
        (selectedItemEnd > scrollOffset + locationVisitFocusMargin && selectedItemEnd <= scrollOffset + viewport - locationVisitFocusMargin);

    if (!isSelectedItemVisible) {
      // Calculate which item is currently centered in the viewport
      final offset = carouselController.offset;
      final focusedOffset = offset + (carouselWidth - tileOffest);
      final itemIndex = (focusedOffset / tileOffest).round().clamp(0, simonsVisits.length - 1);

      // Update the selected location if it's different from the current one
      final currentSelectedLocation = ref.read(currentSelectedLocationProvider);
      if (itemIndex < simonsVisits.length && simonsVisits[itemIndex] != currentSelectedLocation) {
        ref.read(currentSelectedLocationProvider.notifier).selectLocation(simonsVisits[itemIndex]);
      }
    }
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

    // Get the theme mode for the map styling
    // var themeMode = ref.watch(settingsProvider).themeMode;
    // if (themeMode == ThemeMode.system) {
    //   themeMode = MediaQuery.of(context).platformBrightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light;
    // }

    // // watch for changes in the current location
    // ref.listen(currentSelectedLocationProvider, (previous, next) {
    //   // Position has changed
    //   _controller.future.then((controller) {
    //     controller.animateCamera(CameraUpdate.newLatLng(next.location.position));
    //     controller.showMarkerInfoWindow(MarkerId(next.location.city));
    //   });
    //   animateCarouselTo(next);
    // });

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
            child: FlutterMap(
              options: MapOptions(
                initialCenter: LatLng(currentLocation.position.latitude, currentLocation.position.longitude),
              ),
              children: [
                TileLayer(
                  tileProvider: CancellableNetworkTileProvider(),
                  urlTemplate:
                      'https://api.mapbox.com/styles/v1/coolmogo/cmcsmzesv003201rf1ddn5zco/tiles/256/{z}/{x}/{y}@2x?access_token=pk.eyJ1IjoiY29vbG1vZ28iLCJhIjoiY21jc2k1MW5hMTR4eDJtbXRrbnBmMDV6ZiJ9.tclAU2NfOf-8s0wetRfeRw',
                  subdomains: const ['a', 'b', 'c'],
                ),
                MarkerLayer(
                  markers: simonsVisits.map(
                    (e) {
                      return Marker(
                        point: LatLng(e.location.position.latitude, e.location.position.longitude),
                        child: Icon(
                          Icons.location_on,
                          color: e == selectedLocation ? widget.style?.selectedMarkerColor ?? Colors.red : widget.style?.markerColor ?? Colors.black,
                        ),
                      );
                    },
                  ).toList(),
                ),
                // SimpleAttributionWidget(
                //   source: Text(
                //     'OpenStreetMap contributors',
                //   ),
                //   onTap: () => launchUrl(Uri.parse('https://openstreetmap.org/copyright')), // (external)
                // ),
                // RichAttributionWidget(
                //   // Include a stylish prebuilt attribution widget that meets all requirments
                //   attributions: [
                //     TextSourceAttribution(
                //       'OpenStreetMap contributors',
                //       onTap: () => launchUrl(Uri.parse('https://openstreetmap.org/copyright')), // (external)
                //     ),
                //   ],
                // ),
              ],
            ),
          ),
        ),
        SizedBox(height: 20),
        Text('Current location: ${currentLocation.city}, ${currentLocation.country}'),
        Text('Timezone: ${currentLocation.timeZoneString}'),
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
