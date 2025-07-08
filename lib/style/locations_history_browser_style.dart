// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';

class LocationsHistoryBrowserStyle {
  final Color? selectedLocationBackgroundColor;
  final Color? selectedLocationTextColor;
  final Border? selectedLocationBorder;

  final Color? markerColor;
  final Color? selectedMarkerColor;

  final Color? locationVisitBackgroundColor;
  final Color? locationVisitTextColor;
  final Border? locationVisitBorder;

  const LocationsHistoryBrowserStyle({
    this.selectedLocationBackgroundColor,
    this.selectedLocationTextColor,
    this.selectedLocationBorder,
    this.locationVisitBackgroundColor,
    this.locationVisitTextColor,
    this.locationVisitBorder,
    this.markerColor,
    this.selectedMarkerColor,
  });

  LocationsHistoryBrowserStyle copyWith({
    Color? selectedLocationBackgroundColor,
    Color? selectedLocationTextColor,
    Border? selectedLocationBorder,
    Color? locationVisitBackgroundColor,
    Color? locationVisitTextColor,
    Border? locationVisitBorder,
    Color? markerColor,
    Color? selectedMarkerColor,
  }) {
    return LocationsHistoryBrowserStyle(
      selectedLocationBackgroundColor: selectedLocationBackgroundColor ?? this.selectedLocationBackgroundColor,
      selectedLocationTextColor: selectedLocationTextColor ?? this.selectedLocationTextColor,
      selectedLocationBorder: selectedLocationBorder ?? this.selectedLocationBorder,
      locationVisitBackgroundColor: locationVisitBackgroundColor ?? this.locationVisitBackgroundColor,
      locationVisitTextColor: locationVisitTextColor ?? this.locationVisitTextColor,
      locationVisitBorder: locationVisitBorder ?? this.locationVisitBorder,
      markerColor: markerColor ?? this.markerColor,
      selectedMarkerColor: selectedMarkerColor ?? this.selectedMarkerColor,
    );
  }
}
