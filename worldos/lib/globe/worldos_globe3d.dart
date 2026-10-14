import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// Web specific JS Interop
import 'dart:ui_web' as ui_web;
import 'package:web/web.dart' as web;
import 'dart:js_interop';

import '../config/env_config.dart';
import '../models/watch_zone.dart';
import '../models/world_event.dart';
import 'globe_models.dart';

@JS('mountMapboxGlobe')
external void _jsMountMapboxGlobe(web.HTMLDivElement element, JSString token);

@JS('updateMapboxMarkers')
external void _jsUpdateMapboxMarkers(JSString markersJson);

@JS('flyToMapbox')
external void _jsFlyToMapbox(JSNumber lat, JSNumber lon, JSNumber? zoom, JSNumber? pitch, JSNumber? bearing);

@JS('zoomInMapbox')
external void _jsZoomInMapbox();

@JS('zoomOutMapbox')
external void _jsZoomOutMapbox();

@JS('resetViewMapbox')
external void _jsResetViewMapbox();

@JS('setMapboxLayerVisibility')
external void _jsSetMapboxLayerVisibility(JSString layerId, JSBoolean isVisible);

@JS('setAutoRotateMapbox')
external void _jsSetAutoRotateMapbox(JSBoolean enabled);

bool _viewFactoryRegistered = false;

void _registerMapboxViewFactory() {
  if (_viewFactoryRegistered) return;
  _viewFactoryRegistered = true;

  ui_web.platformViewRegistry.registerViewFactory('mapbox-3d-globe-view', (int viewId) {
    final element = web.document.createElement('div') as web.HTMLDivElement;
    element.id = 'mapbox-3d-globe';
    element.style.width = '100vw';
    element.style.height = '100vh';
    element.style.position = 'absolute';
    element.style.top = '0px';
    element.style.left = '0px';
    element.style.right = '0px';
    element.style.bottom = '0px';
    element.style.backgroundColor = '#02040A';
    element.style.border = 'none';
    element.style.margin = '0px';
    element.style.padding = '0px';
    element.style.overflow = 'hidden';
    final token = EnvConfig.mapboxToken;
    _jsMountMapboxGlobe(element, token.toJS);

    return element;
  });
}

/// 3D Mapbox GL JS Satellite Earth Globe Engine with 3D DEM Terrain & Atmosphere
class WorldOSGlobe3D extends StatefulWidget {
  final List<GlobeMarker> markers;
  final GlobeConfig config;
  final Function(GlobeMarker)? onMarkerClick;
  final Function(GlobeMarker?)? onMarkerHover;
  final Function(double lat, double lon)? onLocationSelected;
  final List<WatchZone> watchZones;
  final double centerLat;
  final double centerLon;
  final double zoom;
  final Function(double lat, double lon, double zoom)? onCameraChanged;
  final VoidCallback? onFlightComplete;
  final VoidCallback? onUserPanStarted;

  const WorldOSGlobe3D({
    super.key,
    required this.markers,
    this.config = const GlobeConfig(),
    this.onMarkerClick,
    this.onMarkerHover,
    this.onLocationSelected,
    this.watchZones = const [],
    this.centerLat = 20.5937,
    this.centerLon = 78.9629,
    this.zoom = 1.8,
    this.onCameraChanged,
    this.onFlightComplete,
    this.onUserPanStarted,
  });

  @override
  State<WorldOSGlobe3D> createState() => WorldOSGlobe3DState();
}

class WorldOSGlobe3DState extends State<WorldOSGlobe3D> {
  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      _registerMapboxViewFactory();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _updateMarkersOnMapbox();
      });
    }
  }

  @override
  void didUpdateWidget(covariant WorldOSGlobe3D oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (kIsWeb) {
      _updateMarkersOnMapbox();
    }
  }

  void _updateMarkersOnMapbox() {
    if (!kIsWeb) return;
    try {
      final markersList = widget.markers.map((m) => {
        'id': m.label,
        'label': m.label,
        'type': m.type,
        'severity': m.severity >= 4.5 ? 'CRITICAL' : (m.severity >= 3.5 ? 'HIGH' : 'MEDIUM'),
        'lat': m.lat,
        'lng': m.lng,
        'heading': (m.data is WorldEvent) ? ((m.data as WorldEvent).severity * 40) % 360 : 0,
      }).toList();

      _jsUpdateMapboxMarkers(jsonEncode(markersList).toJS);
    } catch (_) {}
  }

  /// Triggers map resize on canvas
  void resize() {}

  /// Triggers smooth zoom in
  void zoomIn() {
    if (kIsWeb) {
      try { _jsZoomInMapbox(); } catch (_) {}
    }
  }

  /// Triggers smooth zoom out
  void zoomOut() {
    if (kIsWeb) {
      try { _jsZoomOutMapbox(); } catch (_) {}
    }
  }

  /// Toggles visibility of a specific telemetry data layer
  void setLayerVisibility(String layerKey, bool isVisible) {
    if (kIsWeb) {
      try { _jsSetMapboxLayerVisibility(layerKey.toJS, isVisible.toJS); } catch (_) {}
    }
  }

  /// Sets auto-rotation state
  void setAutoRotate(bool enabled) {
    if (kIsWeb) {
      try { _jsSetAutoRotateMapbox(enabled.toJS); } catch (_) {}
    }
  }

  /// Pauses auto-rotation on user interaction
  void freezeAutoRotation() {
    setAutoRotate(false);
  }

  /// Resumes auto-rotation after user is idle
  void scheduleUnfreezeAutoRotation() {
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        setAutoRotate(true);
      }
    });
  }

  /// Resets the 3D globe camera view to centered front-facing perspective
  void resetView() {
    if (kIsWeb) {
      try { _jsResetViewMapbox(); } catch (_) {}
    }
  }

  /// Executes cinematic 3D approach directly to geographic coordinates
  void flyToCoordinates(double lon, double lat, [double targetZoom = 11.5, double targetPitch = 60.0]) {
    flyTo(lat, lon, targetZoom, targetPitch);
  }

  /// Executes cinematic camera fly-to physics interpolation
  void flyTo(double targetLat, double targetLon, [double? targetZoom, double? pitch, double? bearing, double? speed, double? curve]) {
    if (kIsWeb) {
      try {
        _jsFlyToMapbox(
          targetLat.toJS,
          targetLon.toJS,
          (targetZoom ?? 4.8).toJS,
          (pitch ?? 50.0).toJS,
          (bearing ?? 0.0).toJS,
        );
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    return const HtmlElementView(
      viewType: 'mapbox-3d-globe-view',
    );
  }
}
