import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Web specific Wasm & JS Interop imports
import 'dart:ui_web' as ui_web;
import 'package:web/web.dart' as web;
import 'dart:js_interop';

import '../models/watch_zone.dart';
import '../models/world_event.dart';
import 'globe_models.dart';

@JS('WorldOSMapboxEngine.init')
external void _mapboxInit(
  JSString containerId,
  JSString accessToken,
  JSFunction? onMarkerClickCb,
  JSFunction? onCameraChangedCb,
  JSFunction? onLocationSelectedCb,
);

@JS('WorldOSMapboxEngine.updateMarkers')
external void _mapboxUpdateMarkers(JSString markersJsonString);

@JS('WorldOSMapboxEngine.flyTo')
external void _mapboxFlyTo(
  JSNumber lat,
  JSNumber lon,
  JSNumber? zoom,
  JSNumber? pitch,
  JSNumber? bearing,
  JSNumber? speed,
  JSNumber? curve,
);

@JS('WorldOSMapboxEngine.flyToCoordinates')
external void _mapboxFlyToCoordinates(
  JSNumber lon,
  JSNumber lat,
  JSNumber? targetZoom,
  JSNumber? targetPitch,
);

@JS('WorldOSMapboxEngine.resetView')
external void _mapboxResetView();

@JS('WorldOSMapboxEngine.setLayerVisibility')
external void _mapboxSetLayerVisibility(JSString layerKey, JSBoolean isVisible);

@JS('WorldOSMapboxEngine.zoomIn')
external void _mapboxZoomIn();

@JS('WorldOSMapboxEngine.zoomOut')
external void _mapboxZoomOut();

@JS('WorldOSMapboxEngine.setAutoRotate')
external void _mapboxSetAutoRotate(JSBoolean enabled);

@JS('WorldOSMapboxEngine.resize')
external void _mapboxResize();

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
    return element;
  });
}


/// High-Performance GPU-Accelerated 3D WebGL Globe Engine powered by Mapbox GL JS with 3D Terrain DEM
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
    this.centerLat = 5.0,
    this.centerLon = 78.9629,
    this.zoom = 2.2,
    this.onCameraChanged,
    this.onFlightComplete,
    this.onUserPanStarted,
  });

  @override
  State<WorldOSGlobe3D> createState() => WorldOSGlobe3DState();
}

class WorldOSGlobe3DState extends State<WorldOSGlobe3D> with TickerProviderStateMixin {
  // Canvas fallback animation controllers
  AnimationController? _tickerController;
  AnimationController? _flightController;
  AnimationController? _reticlePulseController;
  ui.Image? _earthImage;

  // Canvas Orbit Camera Angles
  double _pitch = 0.35;
  double _yaw = 0.0;
  double _zoom = 1.0;

  double _startPitch = 0.35;
  double _startYaw = 0.0;
  double _startZoom = 1.0;
  double _targetPitch = 0.35;
  double _targetYaw = 0.0;
  double _targetZoom = 1.0;

  double? _targetReticleLat;
  double? _targetReticleLon;
  bool _autoRotate = true;
  Timer? _unfreezeTimer;

  bool _isUserDragging = false;
  Offset _lastPanPos = Offset.zero;
  double _velocityYaw = 0.0;
  double _velocityPitch = 0.0;
  GlobeMarker? _hoveredMarker;

  @override
  void initState() {
    super.initState();
    _zoom = widget.zoom;
    _pitch = (widget.centerLat * pi / 180.0).clamp(-1.2, 1.2);
    _yaw = -widget.centerLon * pi / 180.0;
    _autoRotate = widget.config.autoRotate;

    if (kIsWeb) {
      _registerMapboxViewFactory();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _initMapboxEngine();
      });
    } else {
      _tickerController = AnimationController(
        vsync: this,
        duration: const Duration(seconds: 60),
      )..repeat();
      _tickerController!.addListener(_onTick);

      _flightController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1000),
      );
      _flightController!.addListener(_onFlightTick);
      _flightController!.addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _reticlePulseController?.forward(from: 0.0);
          widget.onFlightComplete?.call();
        }
      });

      _reticlePulseController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600),
      );
      _reticlePulseController!.addListener(() {
        if (mounted) setState(() {});
      });

      _loadEarthTexture();
    }
  }

  void _initMapboxEngine() {
    if (!kIsWeb) return;

    const mapboxToken = String.fromEnvironment('MAPBOX_TOKEN', defaultValue: 'YOUR_MAPBOX_ACCESS_TOKEN');

    final onMarkerClickJs = ((JSString propsJson) {
      final jsonStr = propsJson.toDart;
      try {
        final map = jsonDecode(jsonStr) as Map<String, dynamic>;
        final lat = (map['lat'] as num?)?.toDouble() ?? 0.0;
        final lng = (map['lng'] as num?)?.toDouble() ?? 0.0;
        final label = map['title']?.toString() ?? 'TARGET TELEMETRY';
        final type = map['type']?.toString() ?? 'GENERAL';
        final severityStr = map['severity']?.toString() ?? 'LOW';
        final severity = severityStr == 'CRITICAL' ? 5.0 : (severityStr == 'HIGH' ? 4.0 : 3.0);

        GlobeMarker? hitMarker;
        for (final m in widget.markers) {
          if ((m.lat - lat).abs() < 0.001 && (m.lng - lng).abs() < 0.001) {
            hitMarker = m;
            break;
          }
        }
        hitMarker ??= GlobeMarker(
          lat: lat,
          lng: lng,
          label: label,
          severity: severity,
          type: type,
        );

        // High-Altitude Regional Fly-To target marker
        flyTo(lat, lng, 4.8, 50.0, 0.0, 1.0, 1.2);

        widget.onMarkerClick?.call(hitMarker);
      } catch (e) {
        debugPrint('Error parsing JS marker click: $e');
      }
    }).toJS;

    final onCameraChangedJs = ((JSNumber lat, JSNumber lon, JSNumber zoom) {
      widget.onCameraChanged?.call(lat.toDartDouble, lon.toDartDouble, zoom.toDartDouble);
    }).toJS;

    final onLocationSelectedJs = ((JSNumber lat, JSNumber lon) {
      final dLat = lat.toDartDouble;
      final dLon = lon.toDartDouble;

      // High-Altitude Regional Fly-To location tap
      flyTo(dLat, dLon, 4.8, 50.0, 0.0, 1.0, 1.2);

      widget.onLocationSelected?.call(dLat, dLon);
    }).toJS;

    _mapboxInit(
      'mapbox-3d-globe'.toJS,
      mapboxToken.toJS,
      onMarkerClickJs,
      onCameraChangedJs,
      onLocationSelectedJs,
    );

    _updateMapboxMarkers();
  }

  void _updateMapboxMarkers() {
    if (!kIsWeb) return;
    final markersList = widget.markers.map((m) => {
      'id': m.label,
      'label': m.label,
      'type': m.type,
      'severity': m.severity >= 4.5 ? 'CRITICAL' : (m.severity >= 3.5 ? 'HIGH' : 'MEDIUM'),
      'lat': m.lat,
      'lng': m.lng,
      'heading': (m.data is WorldEvent) ? ((m.data as WorldEvent).severity * 40) % 360 : 0,
    }).toList();

    _mapboxUpdateMarkers(jsonEncode(markersList).toJS);
  }

  @override
  void didUpdateWidget(covariant WorldOSGlobe3D oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (kIsWeb) {
      _updateMapboxMarkers();
    }
  }

  @override
  void dispose() {
    _unfreezeTimer?.cancel();
    if (!kIsWeb) {
      _tickerController?.removeListener(_onTick);
      _tickerController?.dispose();
      _flightController?.removeListener(_onFlightTick);
      _flightController?.dispose();
      _reticlePulseController?.dispose();
    }
    super.dispose();
  }

  /// Triggers map resize on WebGL canvas
  void resize() {
    if (kIsWeb) {
      _mapboxResize();
    }
  }

  /// Triggers smooth zoom in on active Mapbox GL map
  void zoomIn() {
    if (kIsWeb) {
      _mapboxZoomIn();
    }
  }

  /// Triggers smooth zoom out on active Mapbox GL map
  void zoomOut() {
    if (kIsWeb) {
      _mapboxZoomOut();
    }
  }

  /// Toggles visibility of a specific telemetry data layer in Mapbox GL engine
  void setLayerVisibility(String layerKey, bool isVisible) {
    if (kIsWeb) {
      _mapboxSetLayerVisibility(layerKey.toJS, isVisible.toJS);
    }
  }

  /// Resets the 3D globe camera view to centered front-facing perspective (pitch: 0, zoom: 1.8)
  void resetView() {
    if (kIsWeb) {
      _mapboxResetView();
    } else {
      flyTo(20.5937, 78.9629, 1.8, 0.0);
    }
  }

  /// Executes cinematic 3D approach directly to geographic coordinates
  void flyToCoordinates(double lon, double lat, [double targetZoom = 11.5, double targetPitch = 60.0]) {
    if (kIsWeb) {
      _mapboxFlyToCoordinates(lon.toJS, lat.toJS, targetZoom.toJS, targetPitch.toJS);
    } else {
      flyTo(lat, lon, targetZoom, targetPitch);
    }
  }

  /// Executes cinematic camera fly-to physics interpolation with 3D terrain elevation perspective
  void flyTo(double targetLat, double targetLon, [double? targetZoom, double? pitch, double? bearing, double? speed, double? curve]) {
    if (kIsWeb) {
      final finalZoom = (targetZoom ?? 11.5).clamp(1.2, 16.0);
      final finalPitch = (pitch ?? 60.0).clamp(0.0, 75.0);
      final finalBearing = bearing ?? -15.0;
      final finalSpeed = speed ?? 1.1;
      final finalCurve = curve ?? 1.3;

      _mapboxFlyTo(
        targetLat.toJS,
        targetLon.toJS,
        finalZoom.toJS,
        finalPitch.toJS,
        finalBearing.toJS,
        finalSpeed.toJS,
        finalCurve.toJS,
      );
    } else {
      freezeAutoRotation();
      _startPitch = _pitch;
      _startYaw = _yaw;
      _startZoom = _zoom;

      _targetPitch = (targetLat * pi / 180.0).clamp(-1.2, 1.2);

      final rawTargetYaw = -targetLon * pi / 180.0;
      double diffYaw = (rawTargetYaw - _startYaw) % (2 * pi);
      if (diffYaw > pi) diffYaw -= 2 * pi;
      if (diffYaw < -pi) diffYaw += 2 * pi;
      _targetYaw = _startYaw + diffYaw;

      _targetZoom = targetZoom ?? 2.2;
      _targetReticleLat = targetLat;
      _targetReticleLon = targetLon;

      _flightController?.stop();
      _reticlePulseController?.reset();
      _flightController?.forward(from: 0.0);
    }
  }

  void freezeAutoRotation() {
    if (kIsWeb) {
      _mapboxSetAutoRotate(false.toJS);
    } else {
      _unfreezeTimer?.cancel();
      setState(() {
        _autoRotate = false;
        _velocityYaw = 0.0;
        _velocityPitch = 0.0;
      });
    }
  }

  void scheduleUnfreezeAutoRotation() {
    if (kIsWeb) {
      _mapboxSetAutoRotate(true.toJS);
    } else {
      _unfreezeTimer?.cancel();
      _unfreezeTimer = Timer(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _autoRotate = true;
          });
        }
      });
    }
  }

  void setAutoRotate(bool enabled) {
    if (kIsWeb) {
      _mapboxSetAutoRotate(enabled.toJS);
    } else {
      setState(() {
        _autoRotate = enabled;
      });
    }
  }

  Future<void> _loadEarthTexture() async {
    try {
      final data = await rootBundle.load('assets/earth_map.png');
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      final frame = await codec.getNextFrame();
      if (mounted) {
        setState(() {
          _earthImage = frame.image;
        });
      }
    } catch (_) {}
  }

  void _onFlightTick() {
    if (!mounted || _flightController == null) return;

    final t = _flightController!.value;
    final curvedT = Curves.easeOutCubic.transform(t);

    _pitch = _startPitch + (_targetPitch - _startPitch) * curvedT;
    _yaw = _startYaw + (_targetYaw - _startYaw) * curvedT;
    _zoom = (_startZoom + (_targetZoom - _startZoom) * curvedT).clamp(0.5, 4.5);

    setState(() {});

    if (widget.onCameraChanged != null) {
      final currentLat = (_pitch * 180.0 / pi).clamp(-85.0, 85.0);
      double currentLon = (-_yaw * 180.0 / pi) % 360.0;
      if (currentLon > 180.0) currentLon -= 360.0;
      if (currentLon < -180.0) currentLon += 360.0;
      widget.onCameraChanged!(currentLat, currentLon, _zoom);
    }
  }

  void _onTick() {
    if (!mounted || _flightController == null) return;

    if (_flightController!.isAnimating) return;

    setState(() {
      if (_autoRotate && !_isUserDragging) {
        _yaw += (widget.config.autoRotateSpeed * 0.008);
      }

      if (!_isUserDragging) {
        if (_velocityYaw.abs() > 0.0001 || _velocityPitch.abs() > 0.0001) {
          _yaw += _velocityYaw;
          _pitch = (_pitch + _velocityPitch).clamp(-1.3, 1.3);
          _velocityYaw *= 0.92;
          _velocityPitch *= 0.92;
        }
      }
    });

    if (widget.onCameraChanged != null) {
      final currentLat = (_pitch * 180.0 / pi).clamp(-85.0, 85.0);
      double currentLon = (-_yaw * 180.0 / pi) % 360.0;
      if (currentLon > 180.0) currentLon -= 360.0;
      if (currentLon < -180.0) currentLon += 360.0;
      widget.onCameraChanged!(currentLat, currentLon, _zoom);
    }
  }

  void _handlePanStart(DragStartDetails details) {
    if (_flightController?.isAnimating ?? false) _flightController!.stop();
    freezeAutoRotation();
    _isUserDragging = true;
    _lastPanPos = details.localPosition;
    _velocityYaw = 0.0;
    _velocityPitch = 0.0;
    widget.onUserPanStarted?.call();
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    final delta = details.localPosition - _lastPanPos;
    _lastPanPos = details.localPosition;

    final sensitivity = 0.005 / _zoom;
    final dyaw = delta.dx * sensitivity;
    final dpitch = -delta.dy * sensitivity;

    setState(() {
      _yaw += dyaw;
      _pitch = (_pitch + dpitch).clamp(-1.3, 1.3);
      _velocityYaw = dyaw;
      _velocityPitch = dpitch;
    });
  }

  void _handlePanEnd(DragEndDetails details) {
    _isUserDragging = false;
    scheduleUnfreezeAutoRotation();
  }

  void _handlePointerSignal(PointerSignalEvent event) {
    if (event is PointerScrollEvent) {
      final zoomDelta = event.scrollDelta.dy > 0 ? -0.12 : 0.12;
      setState(() {
        _zoom = (_zoom + zoomDelta).clamp(0.6, 4.5);
      });
    }
  }

  void _handleHover(PointerHoverEvent event, Size size) {
    final hitMarker = _findMarkerAtScreenPos(event.localPosition, size);
    if (hitMarker != _hoveredMarker) {
      setState(() {
        _hoveredMarker = hitMarker;
      });
      widget.onMarkerHover?.call(hitMarker);
    }
  }

  void _handleTapUp(TapUpDetails details, Size size) {
    freezeAutoRotation();
    final hitMarker = _findMarkerAtScreenPos(details.localPosition, size);
    if (hitMarker != null) {
      flyTo(hitMarker.lat, hitMarker.lng, 2.2);
      widget.onMarkerClick?.call(hitMarker);
    } else if (widget.onLocationSelected != null) {
      final unproj = _unprojectScreenToLatLng(details.localPosition, size);
      if (unproj != null) {
        flyTo(unproj.x, unproj.y, 2.2);
        widget.onLocationSelected!(unproj.x, unproj.y);
      }
    }
  }

  GlobeMarker? _findMarkerAtScreenPos(Offset screenPos, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final radius = min(size.width, size.height) * 0.40 * _zoom;

    GlobeMarker? closestMarker;
    double minDistance = 18.0;

    for (final marker in widget.markers) {
      final phi = marker.lat * pi / 180.0;
      final lam = marker.lng * pi / 180.0;

      final x0 = cos(phi) * sin(lam);
      final y0 = sin(phi);
      final z0 = cos(phi) * cos(lam);

      final x1 = x0 * cos(_yaw) + z0 * sin(_yaw);
      final y1 = y0;
      final z1 = -x0 * sin(_yaw) + z0 * cos(_yaw);

      final x2 = x1;
      final y2 = y1 * cos(_pitch) - z1 * sin(_pitch);
      final z2 = y1 * sin(_pitch) + z1 * cos(_pitch);

      if (z2 > -0.05) {
        final px = cx + x2 * radius;
        final py = cy - y2 * radius;
        final dist = sqrt(pow(screenPos.dx - px, 2) + pow(screenPos.dy - py, 2));

        if (dist < minDistance) {
          minDistance = dist;
          closestMarker = marker;
        }
      }
    }

    return closestMarker;
  }

  Point<double>? _unprojectScreenToLatLng(Offset screenPos, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final radius = min(size.width, size.height) * 0.40 * _zoom;

    final dx = (screenPos.dx - cx) / radius;
    final dy = -(screenPos.dy - cy) / radius;

    final r2 = dx * dx + dy * dy;
    if (r2 > 1.0) return null;

    final dz = sqrt(1.0 - r2);

    final x1 = dx;
    final y1 = dy * cos(-_pitch) - dz * sin(-_pitch);
    final z1 = dy * sin(-_pitch) + dz * cos(-_pitch);

    final x0 = x1 * cos(-_yaw) + z1 * sin(-_yaw);
    final y0 = y1;
    final z0 = -x1 * sin(-_yaw) + z1 * cos(-_yaw);

    final lat = asin(y0.clamp(-1.0, 1.0)) * 180.0 / pi;
    final lng = atan2(x0, z0) * 180.0 / pi;

    return Point(lat, lng);
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return const HtmlElementView(
        viewType: 'mapbox-3d-globe-view',
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);

        return MouseRegion(
          onHover: (event) => _handleHover(event, size),
          cursor: _hoveredMarker != null ? SystemMouseCursors.click : SystemMouseCursors.grab,
          child: Listener(
            onPointerSignal: _handlePointerSignal,
            child: GestureDetector(
              onPanStart: _handlePanStart,
              onPanUpdate: _handlePanUpdate,
              onPanEnd: _handlePanEnd,
              onTapUp: (details) => _handleTapUp(details, size),
              child: AnimatedBuilder(
                animation: Listenable.merge([
                  if (_tickerController != null) _tickerController!,
                  if (_flightController != null) _flightController!,
                  if (_reticlePulseController != null) _reticlePulseController!,
                ]),
                builder: (context, child) {
                  return RepaintBoundary(
                    child: CustomPaint(
                      size: size,
                      painter: _TexturedGlobe3DPainter(
                        earthImage: _earthImage,
                        markers: widget.markers,
                        config: widget.config,
                        pitch: _pitch,
                        yaw: _yaw,
                        zoom: _zoom,
                        animValue: _tickerController?.value ?? 0.0,
                        hoveredMarker: _hoveredMarker,
                        watchZones: widget.watchZones,
                        targetReticleLat: _targetReticleLat,
                        targetReticleLon: _targetReticleLon,
                        flightProgress: _flightController?.value ?? 1.0,
                        reticlePulseProgress: _reticlePulseController?.value ?? 0.0,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TexturedGlobe3DPainter extends CustomPainter {
  final ui.Image? earthImage;
  final List<GlobeMarker> markers;
  final GlobeConfig config;
  final double pitch;
  final double yaw;
  final double zoom;
  final double animValue;
  final GlobeMarker? hoveredMarker;
  final List<WatchZone> watchZones;
  final double? targetReticleLat;
  final double? targetReticleLon;
  final double flightProgress;
  final double reticlePulseProgress;

  _TexturedGlobe3DPainter({
    required this.earthImage,
    required this.markers,
    required this.config,
    required this.pitch,
    required this.yaw,
    required this.zoom,
    required this.animValue,
    this.hoveredMarker,
    required this.watchZones,
    this.targetReticleLat,
    this.targetReticleLon,
    this.flightProgress = 1.0,
    this.reticlePulseProgress = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final radius = min(size.width, size.height) * 0.40 * zoom;
    final centerOffset = Offset(cx, cy);

    final atmospherePaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF38BDF8).withValues(alpha: 0.0),
          const Color(0xFF38BDF8).withValues(alpha: 0.25),
          const Color(0xFF0369A1).withValues(alpha: 0.10),
          Colors.transparent,
        ],
        stops: const [0.94, 0.98, 1.02, 1.06],
      ).createShader(Rect.fromCircle(center: centerOffset, radius: radius * 1.06));

    canvas.drawCircle(centerOffset, radius * 1.06, atmospherePaint);

    final baseShader = RadialGradient(
      center: const Alignment(-0.35, -0.35),
      colors: const [
        Color(0xFF0D1B2A),
        Color(0xFF050C16),
        Color(0xFF020408),
      ],
      stops: const [0.0, 0.7, 1.0],
    ).createShader(Rect.fromCircle(center: centerOffset, radius: radius));

    final basePaint = Paint()..shader = baseShader;
    canvas.drawCircle(centerOffset, radius, basePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
