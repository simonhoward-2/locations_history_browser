import 'package:collection/collection.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_animations/flutter_map_animations.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:flutter_map_marker_popup/flutter_map_marker_popup.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:locations_history_browser/models/location.dart';

import '../models/location_visit.dart';
import '../state/current_selected_location.dart';
import '../style/locations_history_browser_style.dart';

class LocationsHistoryBrowser extends ConsumerStatefulWidget {
  final LocationsHistoryBrowserStyle? style;
  final String mapsUrlTemplate;
  final List<LocationVisit> locationVisits;

  const LocationsHistoryBrowser({super.key, this.style, required this.mapsUrlTemplate, required this.locationVisits});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _LocationsHistoryBrowserState();
}

class _LocationsHistoryBrowserState extends ConsumerState<LocationsHistoryBrowser> with TickerProviderStateMixin {
  final carouselController = CarouselController();
  late final _controller = AnimatedMapController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
    curve: Curves.easeInOut,
    cancelPreviousAnimations: true, // Default to false
  );
  final PopupController _popupController = PopupController();

  final tileOffest = 200.0;
  final locationVisitFocusMargin = 50;
  final carouselWidth = 600.0;

  late final Map<Location, List<LocationVisit>> _locationsMap = {};

  late final currentSelectedLocationProvider = StateNotifierProvider<CurrentSelectedLocationNotifier, LocationVisit>((ref) {
    return CurrentSelectedLocationNotifier(widget.locationVisits.last);
  });

  @override
  void initState() {
    // Create a map of locations to visits for quick access
    for (var visit in widget.locationVisits) {
      if (_locationsMap.containsKey(visit.location)) {
        _locationsMap[visit.location]!.add(visit);
      } else {
        _locationsMap[visit.location] = [visit];
      }
    }

    // Animate to strarting position
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
    final selectedItemIndex = widget.locationVisits.indexOf(ref.read(currentSelectedLocationProvider));
    final selectedItemStart = selectedItemIndex * tileOffest;
    final selectedItemEnd = selectedItemStart + tileOffest;
    final isSelectedItemVisible =
        (selectedItemStart >= scrollOffset + locationVisitFocusMargin && selectedItemStart < scrollOffset + viewport - locationVisitFocusMargin) ||
        (selectedItemEnd > scrollOffset + locationVisitFocusMargin && selectedItemEnd <= scrollOffset + viewport - locationVisitFocusMargin);

    if (!isSelectedItemVisible) {
      // Calculate which item is currently centered in the viewport
      final offset = carouselController.offset;
      final focusedOffset = offset + (carouselWidth - tileOffest);
      final itemIndex = (focusedOffset / tileOffest).round().clamp(0, widget.locationVisits.length - 1);

      // Update the selected location if it's different from the current one
      final currentSelectedLocation = ref.read(currentSelectedLocationProvider);
      if (itemIndex < widget.locationVisits.length && widget.locationVisits[itemIndex] != currentSelectedLocation) {
        ref.read(currentSelectedLocationProvider.notifier).selectLocationVisit(widget.locationVisits[itemIndex]);
      }
    }
  }

  void animateCarouselTo(LocationVisit visit) {
    // Remove the listener to prevent triggering during animation
    carouselController.removeListener(_onCarouselScroll);

    // Calculate the desired offset to center the visit in the carousel
    var index = widget.locationVisits.indexOf(visit);
    var desiredOffset = index * tileOffest - (carouselWidth - tileOffest) / 2;
    var offset = desiredOffset.clamp(0, carouselController.position.maxScrollExtent) as double;

    // Animate to the calculated offset
    carouselController.animateTo(offset, duration: Durations.long1, curve: Curves.easeInOut).then((_) {
      // Re-add the listener after the animation completes
      carouselController.addListener(_onCarouselScroll);
    });
  }

  Widget _buildPopupContent(Location location) {
    final dateFormat = DateFormat('MMM y');
    final visits = _locationsMap[location] ?? [];
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.0),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4.0, offset: Offset(0, 2))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${location.city}, ${location.country}',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
          ),
          SizedBox(height: 4),
          for (final visit in visits)
            Text(
              '${dateFormat.format(visit.start)} - ${visit.end != null ? dateFormat.format(visit.end!) : "Present"}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get the theme mode for the map styling
    // var themeMode = ref.watch(settingsProvider).themeMode;
    // if (themeMode == ThemeMode.system) {
    //   themeMode = MediaQuery.of(context).platformBrightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light;
    // }

    final markers = _locationsMap.entries
        .map(
          (e) => Marker(
            key: ValueKey(e.key),
            point: e.key.position,
            child: GestureDetector(
              onTap: () {
                // Update selected location to last visit for this location
                final lastVisit = e.value.last;
                ref.read(currentSelectedLocationProvider.notifier).selectLocationVisit(lastVisit);
                // Animate carousel to show the selected location
                animateCarouselTo(lastVisit);
              },
              child: Icon(
                Icons.location_on,
                color: e.key == ref.watch(currentSelectedLocationProvider).location
                    ? widget.style?.selectedMarkerColor ?? Colors.red
                    : widget.style?.markerColor ?? Colors.black,
                size: 30,
              ),
            ),
          ),
        )
        .toList();

    // watch for changes in the current location
    ref.listen(currentSelectedLocationProvider, (previous, next) {
      // Position has changed
      _controller.animateTo(dest: next.location.position);

      final index = _locationsMap.keys.toList().indexOf(next.location);
      final marker = markers[index];

      _popupController.showPopupsOnlyFor([marker]);
    });

    final currentLocation = widget.locationVisits.last.location;
    var selectedLocation = ref.watch(currentSelectedLocationProvider);

    final dateFormat = DateFormat('MMM y');

    return Column(
      children: [
        // Map
        Align(
          alignment: Alignment.center,
          child: Container(
            height: 400,
            width: 600,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28.0),
            ),
            child: FlutterMap(
              options: MapOptions(initialCenter: currentLocation.position, initialZoom: 5.0, onTap: (_, __) => _popupController.hideAllPopups()),
              mapController: _controller.mapController,
              children: [
                TileLayer(tileProvider: CancellableNetworkTileProvider(), urlTemplate: widget.mapsUrlTemplate, subdomains: const ['a', 'b', 'c']),
                PopupMarkerLayer(
                  options: PopupMarkerLayerOptions(
                    popupController: _popupController,
                    markers: markers,
                    popupDisplayOptions: PopupDisplayOptions(
                      builder: (_, Marker marker) {
                        final location = _locationsMap.keys.firstWhere((v) => ValueKey(v) == marker.key);
                        return _buildPopupContent(location);
                      },
                    ),
                  ),
                ),
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
            constraints: BoxConstraints(maxHeight: 150),
            child: Listener(
              onPointerSignal: (pointerSignal) {
                if (pointerSignal is PointerScrollEvent) {
                  // Get the current scroll position
                  final currentOffset = carouselController.offset;
                  
                  // Calculate scroll delta (adjust sensitivity as needed)
                  final scrollDelta = pointerSignal.scrollDelta.dy * 2; // Multiply by 2 for better sensitivity
                  
                  // Calculate new offset
                  final newOffset = (currentOffset + scrollDelta).clamp(
                    0.0, 
                    carouselController.position.maxScrollExtent,
                  );
                  
                  // Animate to new position
                  carouselController.animateTo(
                    newOffset,
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                  );
                }
              },
              child: CarouselView(
                itemExtent: tileOffest,
                controller: carouselController,
                onTap: null,
                enableSplash: false,
                
                shape: Border(),
                children: widget.locationVisits.mapIndexed((index, visit) {
                  String? yearHeader;
                  if (index == 0 || (visit.end != null && visit.end!.year > widget.locationVisits[index - 1].end!.year)) {
                    yearHeader = visit.end!.year.toString();
                  }
                  return carouselBox(visit, visit == selectedLocation, yearHeader, dateFormat);
                }).toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget carouselBox(
    LocationVisit visit,
    bool selected,
    String? yearHeader,
    DateFormat dateFormat,
  ) {
    final locationsVisitBackgroundColor = widget.style?.locationVisitBackgroundColor ?? Colors.teal;
    final selectedLocationBackgroundColor = widget.style?.selectedLocationBackgroundColor ?? Colors.blue;

    final WidgetStateProperty<Color?> effectiveOverlayColor = WidgetStateProperty.resolveWith((Set<WidgetState> states) {
      if (states.contains(WidgetState.pressed)) {
        return Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1);
      }
      if (states.contains(WidgetState.hovered)) {
        return Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08);
      }
      if (states.contains(WidgetState.focused)) {
        return Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1);
      }
      return null;
    });

    return Column(
      children: [
        SizedBox(
          height: 50,
          child: yearHeader == null
              ? const SizedBox.shrink()
              : Center(
                  child: Flexible(
                    child: Text(
                      yearHeader,
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.fade,
                      maxLines: 1,
                    ),
                  ),
                ),
        ),
        Expanded(
          child: Material(
            clipBehavior: Clip.antiAlias,
            color: selected ? selectedLocationBackgroundColor : locationsVisitBackgroundColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28.0),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Padding(
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
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      ref.read(currentSelectedLocationProvider.notifier).selectLocationVisit(visit);
                    },
                    overlayColor: effectiveOverlayColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
