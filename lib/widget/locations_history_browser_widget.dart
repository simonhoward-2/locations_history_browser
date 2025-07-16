import 'package:collection/collection.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_animations/flutter_map_animations.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:flutter_map_marker_popup/flutter_map_marker_popup.dart';
import 'package:intl/intl.dart';
import 'package:locations_history_browser/models/location.dart';

import '../models/location_visit.dart';
import '../style/locations_history_browser_style.dart';

class LocationsHistoryBrowser extends StatefulWidget {
  final LocationsHistoryBrowserStyle? style;
  final String? mapsUrlTemplate;
  final List<LocationVisit> locationVisits;

  LocationsHistoryBrowser({
    super.key,
    this.style,
    this.mapsUrlTemplate,
    required this.locationVisits,
  }) : assert(locationVisits.where((visit) => visit.end == null).length <= 1, 'Only one location visit can be ongoing (end == null)');

  @override
  State<StatefulWidget> createState() => _LocationsHistoryBrowserState();
}

class _LocationsHistoryBrowserState extends State<LocationsHistoryBrowser> with TickerProviderStateMixin {
  final carouselController = CarouselController();
  late final _controller = AnimatedMapController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
    curve: Curves.easeInOut,
    cancelPreviousAnimations: true, // Default to false
  );
  final PopupController _popupController = PopupController();

  static const tileOffest = 200.0;
  static const locationVisitFocusMargin = 100;
  static const yearHeaderHeight = 50.0;

  late final Map<Location, List<LocationVisit>> _locationsMap = {};

  var markers = <Marker>[];

  late final List<LocationVisit> sortedVisits = widget.locationVisits.sortedBy((visit) => visit.start).toList();

  // state object
  late LocationVisit? currentSelectedLocationVisit = sortedVisits.isNotEmpty ? sortedVisits.last : null;

  int activeAnimations = 0; // Keep track of active animations, so we can avoid re-adding listeners during animations

  @override
  void initState() {
    // Create a map of locations to visits for quick access
    for (var visit in sortedVisits) {
      if (_locationsMap.containsKey(visit.location)) {
        _locationsMap[visit.location]!.add(visit);
      } else {
        _locationsMap[visit.location] = [visit];
      }
    }

    // Animate to strarting position
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (sortedVisits.isNotEmpty && carouselController.hasClients) {
        carouselController.animateTo(carouselController.position.maxScrollExtent, duration: Durations.long1, curve: Curves.easeInOut).then((_) {
          // Add scroll listener for detecting scroll changes
          carouselController.addListener(_onCarouselScroll);
        });
      }
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
    if (!carouselController.hasClients || sortedVisits.isEmpty || currentSelectedLocationVisit == null) return;

    // Determine if the selected item is currently visible in the viewport
    final viewport = carouselController.position.viewportDimension;
    final scrollOffset = carouselController.offset;
    final selectedItemIndex = sortedVisits.indexOf(currentSelectedLocationVisit!);
    final selectedItemStart = selectedItemIndex * tileOffest;
    final selectedItemEnd = selectedItemStart + tileOffest;
    final isSelectedItemVisible =
        (selectedItemStart >= scrollOffset + locationVisitFocusMargin && selectedItemStart < scrollOffset + viewport - locationVisitFocusMargin) ||
        (selectedItemEnd > scrollOffset + locationVisitFocusMargin && selectedItemEnd <= scrollOffset + viewport - locationVisitFocusMargin);

    if (!isSelectedItemVisible) {
      // Calculate which item is currently centered in the viewport
      final offset = carouselController.offset;
      final carouselWidth = carouselController.position.viewportDimension;
      final focusedOffset = offset + (carouselWidth - tileOffest);
      final itemIndex = (focusedOffset / tileOffest).round().clamp(0, sortedVisits.length - 1);

      // Update the selected location if it's different from the current one
      if (itemIndex < sortedVisits.length && sortedVisits[itemIndex] != currentSelectedLocationVisit) {
        updateLocation(sortedVisits[itemIndex]);
      }
    }
  }

  void updateLocation(LocationVisit visit) {
    setState(() {
      currentSelectedLocationVisit = visit;

      _controller.animateTo(dest: visit.location.position);

      final index = _locationsMap.keys.toList().indexOf(visit.location);
      final marker = markers[index];

      _popupController.showPopupsOnlyFor([marker]);
    });
  }

  void locationVisitClicked(LocationVisit visit) {
    // Update the selected location to the clicked visit
    updateLocation(visit);
    // Animate carousel to show the selected location
    animateCarouselTo(visit);
  }

  void animateCarouselTo(LocationVisit visit) {
    if (sortedVisits.isEmpty || !carouselController.hasClients) return;

    // Remove the listener to prevent triggering during animation
    carouselController.removeListener(_onCarouselScroll);
    activeAnimations++;

    // Calculate the desired offset to center the visit in the carousel
    var index = sortedVisits.indexOf(visit);
    final carouselWidth = carouselController.position.viewportDimension;
    var desiredOffset = index * tileOffest - (carouselWidth - tileOffest) / 2;
    var offset = desiredOffset.clamp(0.0, carouselController.position.maxScrollExtent);

    // Animate to the calculated offset
    carouselController.animateTo(offset, duration: Durations.long1, curve: Curves.easeInOut).then((_) {
      activeAnimations--;
      if (activeAnimations <= 0) {
        activeAnimations = 0; // Reset active animations count in case
        // Re-add the listener after all animations completes
        carouselController.addListener(_onCarouselScroll);
      }
    });
  }

  void navigateCarouselLeft() {
    if (sortedVisits.isEmpty || !carouselController.hasClients) return;

    final currentIndex = sortedVisits.indexOf(currentSelectedLocationVisit!);
    if (currentIndex > 0) {
      final previousVisit = sortedVisits[currentIndex - 1];
      updateLocation(previousVisit);
      animateCarouselTo(previousVisit);
    }
  }

  void navigateCarouselRight() {
    if (sortedVisits.isEmpty || !carouselController.hasClients) return;

    final currentIndex = sortedVisits.indexOf(currentSelectedLocationVisit!);
    if (currentIndex < sortedVisits.length - 1) {
      final nextVisit = sortedVisits[currentIndex + 1];
      updateLocation(nextVisit);
      animateCarouselTo(nextVisit);
    }
  }

  bool _canNavigateLeft() {
    if (sortedVisits.isEmpty || currentSelectedLocationVisit == null) return false;
    final currentIndex = sortedVisits.indexOf(currentSelectedLocationVisit!);
    return currentIndex > 0;
  }

  bool _canNavigateRight() {
    if (sortedVisits.isEmpty || currentSelectedLocationVisit == null) return false;
    final currentIndex = sortedVisits.indexOf(currentSelectedLocationVisit!);
    return currentIndex < sortedVisits.length - 1;
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
            key: Key('popup_${location.city}_${location.country}'),
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
    if (sortedVisits.isEmpty) {
      // Handle empty state
      return const Center(
        child: Text('No location visits to display'),
      );
    }

    const currentLocationIcon = Icons.person;
    const normalLocationIcon = Icons.location_on;
    final currentLocation = sortedVisits.last.location;

    // Build markers
    markers.clear();
    for (final entry in _locationsMap.entries) {
      final marker = Marker(
        key: ValueKey(entry.key),
        point: entry.key.position,
        child: GestureDetector(
          onTap: () {
            // Update selected location to last visit for this location
            final lastVisit = entry.value.last;
            locationVisitClicked(lastVisit);

            // Show popup for this marker
            final currentMarker = markers.firstWhere((m) => m.key == ValueKey(entry.key));
            _popupController.showPopupsOnlyFor([currentMarker]);
          },
          child: Icon(
            entry.key == currentLocation ? currentLocationIcon : normalLocationIcon,
            color: entry.key == currentSelectedLocationVisit?.location
                ? widget.style?.selectedMarkerColor ?? Colors.red
                : widget.style?.markerColor ?? Colors.black,
            size: 30,
          ),
        ),
      );
      markers.add(marker);
    }

    final dateFormat = DateFormat('MMM y');

    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 400),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Current location
          Align(
            alignment: Alignment.center,
            child: InkWell(
              borderRadius: BorderRadius.circular(28.0),
              onTap: () {
                // Animate carousel to show the current location
                final currentVisit = sortedVisits.last;
                locationVisitClicked(currentVisit);
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(currentLocationIcon),
                  SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Current location: ${currentLocation.city}, ${currentLocation.country}'),
                      Text('Timezone: ${currentLocation.timeZoneString}'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16),
          // Map
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final availableWidth = constraints.maxWidth;
                final double mapWidth = availableWidth > 400 ? (availableWidth - 48 * 2).clamp(400, availableWidth) as double : 400.0; // Limit
                return Align(
                  alignment: Alignment.center,
                  child: Container(
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28.0),
                    ),
                    constraints: BoxConstraints.tightFor(width: mapWidth),
                    child: FlutterMap(
                      options: MapOptions(
                        initialCenter: currentLocation.position,
                        initialZoom: 5.0,
                        onTap: (_, __) => _popupController.hideAllPopups(),
                      ),
                      mapController: _controller.mapController,
                      children: [
                        if (widget.mapsUrlTemplate != null)
                          TileLayer(
                            tileProvider: CancellableNetworkTileProvider(),
                            urlTemplate: widget.mapsUrlTemplate,
                            subdomains: const ['a', 'b', 'c'],
                          ),
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
                );
              },
            ),
          ),
          SizedBox(height: 16),
          SizedBox(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: 150),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Left chevron button
                  Padding(
                    padding: const EdgeInsets.only(top: yearHeaderHeight),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        onPressed: _canNavigateLeft() ? navigateCarouselLeft : null,
                        icon: Icon(Icons.chevron_left),
                        iconSize: 32,
                        style: IconButton.styleFrom(
                          foregroundColor: _canNavigateLeft()
                              ? (widget.style?.markerColor ?? Colors.black)
                              : (widget.style?.markerColor ?? Colors.black).withValues(alpha: 0.3),
                        ),
                      ),
                    ),
                  ),
                  // Carousel
                  Expanded(
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
                        children: sortedVisits.mapIndexed((index, visit) {
                          String? yearHeader;
                          if (index == 0) {
                            yearHeader = visit.end?.year.toString() ?? visit.start.year.toString();
                          } else {
                            final previousYear = sortedVisits[index - 1].end?.year ?? sortedVisits[index - 1].start.year;
                            final currentYear = visit.end?.year ?? visit.start.year;
                            if (currentYear != previousYear) {
                              yearHeader = currentYear.toString();
                            }
                          }
                          return carouselBox(visit, visit == currentSelectedLocationVisit, yearHeader, dateFormat);
                        }).toList(),
                      ),
                    ),
                  ),
                  // Right chevron button
                  Padding(
                    padding: const EdgeInsets.only(top: yearHeaderHeight),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: IconButton(
                        onPressed: _canNavigateRight() ? navigateCarouselRight : null,
                        icon: Icon(Icons.chevron_right),
                        iconSize: 32,
                        style: IconButton.styleFrom(
                          foregroundColor: _canNavigateRight()
                              ? (widget.style?.markerColor ?? Colors.black)
                              : (widget.style?.markerColor ?? Colors.black).withValues(alpha: 0.3),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
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
    final locationsVisitTextColor = widget.style?.locationVisitTextColor ?? Colors.black;
    final selectedLocationTextColor = widget.style?.selectedLocationTextColor ?? Colors.white;
    final textColor = selected ? selectedLocationTextColor : locationsVisitTextColor;

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
          height: yearHeaderHeight,
          child: yearHeader == null
              ? const SizedBox.shrink()
              : Center(
                  child: Text(
                    yearHeader,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.fade,
                    maxLines: 1,
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
                            key: Key('carousel_${visit.location.city}_${visit.location.country}'),
                            style: TextStyle(
                              color: textColor,
                            ),
                            softWrap: false,
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.fade,
                          ),
                        ),
                        Flexible(
                          child: Text(
                            '${dateFormat.format(visit.start)} - ${visit.end != null ? dateFormat.format(visit.end!) : "Present"}',
                            style: TextStyle(
                              color: textColor,
                            ),
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.fade,
                            softWrap: false,
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
                      updateLocation(visit);
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
