// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';

class LocationsHistoryBrowserStyle {
  final Color? selectedLocationBackgroundColor;
  final Color? selectedLocationTextColor;
  final Border? selectedLocationBorder;

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
  });

  LocationsHistoryBrowserStyle copyWith({
    Color? selectedLocationBackgroundColor,
    Color? selectedLocationTextColor,
    Border? selectedLocationBorder,
    Color? locationVisitBackgroundColor,
    Color? locationVisitTextColor,
    Border? locationVisitBorder,
  }) {
    return LocationsHistoryBrowserStyle(
      selectedLocationBackgroundColor: selectedLocationBackgroundColor ?? this.selectedLocationBackgroundColor,
      selectedLocationTextColor: selectedLocationTextColor ?? this.selectedLocationTextColor,
      selectedLocationBorder: selectedLocationBorder ?? this.selectedLocationBorder,
      locationVisitBackgroundColor: locationVisitBackgroundColor ?? this.locationVisitBackgroundColor,
      locationVisitTextColor: locationVisitTextColor ?? this.locationVisitTextColor,
      locationVisitBorder: locationVisitBorder ?? this.locationVisitBorder,
    );
  }
}
