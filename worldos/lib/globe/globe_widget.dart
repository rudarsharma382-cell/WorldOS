import 'package:flutter/material.dart';
import '../models/world_event.dart';
import '../models/watch_zone.dart';
import 'globe_models.dart';
import 'worldos_globe3d.dart';

export 'globe_models.dart';
export 'worldos_globe3d.dart';

/// Legacy GlobeWidget adapter delegating to the high-performance WorldOSGlobe3D engine
class GlobeWidget extends StatelessWidget {
  final List<WorldEvent> events;
  final Set<String> activeLayers;
  final WorldEvent? selectedEvent;
  final List<WatchZone> watchZones;
  final Function(WorldEvent?) onEventSelected;
  final Function(double lat, double lon) onLocationSelected;
  final double centerLat;
  final double centerLon;
  final double zoom;
  final Function(double lat, double lon, double zoom) onCameraChanged;

  const GlobeWidget({
    super.key,
    required this.events,
    required this.activeLayers,
    this.selectedEvent,
    required this.watchZones,
    required this.onEventSelected,
    required this.onLocationSelected,
    required this.centerLat,
    required this.centerLon,
    required this.zoom,
    required this.onCameraChanged,
  });

  @override
  Widget build(BuildContext context) {
    final filteredEvents = events.where((e) {
      return activeLayers.contains(e.type) || activeLayers.contains('ALL');
    }).toList();

    return WorldOSGlobe3D(
      markers: filteredEvents.map((e) => GlobeMarker(
        lat: e.latitude,
        lng: e.longitude,
        label: e.title,
        severity: e.severity,
        type: e.type,
        data: e,
      )).toList(),
      config: const GlobeConfig(
        atmosphereColor: Color(0xFF4DA6FF),
        atmosphereIntensity: 0.8,
        autoRotate: true,
        autoRotateSpeed: 0.3,
      ),
      watchZones: watchZones,
      centerLat: centerLat,
      centerLon: centerLon,
      zoom: zoom,
      onCameraChanged: onCameraChanged,
      onMarkerClick: (marker) {
        if (marker.data is WorldEvent) {
          onEventSelected(marker.data as WorldEvent);
        }
      },
      onLocationSelected: onLocationSelected,
    );
  }
}
