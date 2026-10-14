import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/watch_zone.dart';
import '../models/world_event.dart';
import 'globe_models.dart';
import 'globe_painter.dart';
import 'orthographic_projection.dart';

/// High-Performance GPU-Accelerated 3D Geospatial Intelligence Globe Engine
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

class WorldOSGlobe3DState extends State<WorldOSGlobe3D> with TickerProviderStateMixin {
  // Animation controllers
  AnimationController? _tickerController;
  AnimationController? _flightController;
  AnimationController? _reticlePulseController;
  ui.Image? _earthImage;

  // Active layers filter
  final Set<String> _activeLayers = {
    'ALL',
    'EARTHQUAKE',
    'WEATHER',
    'WILDFIRE',
    'SATELLITE',
    'STORM',
    'AIRCRAFT',
    'SHIP',
    'CAMERA',
    'TARGET'
  };

  // Orbit Camera Angles
  double _pitch = 0.35;
  double _yaw = 0.0;
  double _zoom = 1.8;

  double _startPitch = 0.35;
  double _startYaw = 0.0;
  double _startZoom = 1.8;
  double _targetPitch = 0.35;
  double _targetYaw = 0.0;
  double _targetZoom = 1.8;

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

  Future<void> _loadEarthTexture() async {
    try {
      final byteData = await rootBundle.load('assets/earth_map.png');
      final codec = await ui.instantiateImageCodec(byteData.buffer.asUint8List());
      final frame = await codec.getNextFrame();
      if (mounted) {
        setState(() {
          _earthImage = frame.image;
        });
      }
    } catch (e) {
      debugPrint('[WorldOSGlobe3D] Procedural vector mode active: $e');
    }
  }

  @override
  void didUpdateWidget(covariant WorldOSGlobe3D oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _unfreezeTimer?.cancel();
    _tickerController?.removeListener(_onTick);
    _tickerController?.dispose();
    _flightController?.removeListener(_onFlightTick);
    _flightController?.dispose();
    _reticlePulseController?.dispose();
    super.dispose();
  }

  /// Triggers map resize on canvas
  void resize() {
    if (mounted) setState(() {});
  }

  /// Triggers smooth zoom in
  void zoomIn() {
    setState(() {
      _zoom = (_zoom + 0.35).clamp(0.6, 4.5);
    });
    _notifyCameraChanged();
  }

  /// Triggers smooth zoom out
  void zoomOut() {
    setState(() {
      _zoom = (_zoom - 0.35).clamp(0.6, 4.5);
    });
    _notifyCameraChanged();
  }

  /// Toggles visibility of a specific telemetry data layer
  void setLayerVisibility(String layerKey, bool isVisible) {
    setState(() {
      if (isVisible) {
        _activeLayers.add(layerKey);
        if (layerKey == 'ALL') {
          _activeLayers.addAll(['EARTHQUAKE', 'WEATHER', 'WILDFIRE', 'SATELLITE', 'STORM', 'AIRCRAFT', 'SHIP', 'CAMERA', 'TARGET']);
        }
      } else {
        _activeLayers.remove(layerKey);
        _activeLayers.remove('ALL');
      }
    });
  }

  /// Sets auto-rotation state
  void setAutoRotate(bool enabled) {
    setState(() {
      _autoRotate = enabled;
    });
  }

  /// Resets the 3D globe camera view to centered front-facing perspective
  void resetView() {
    flyTo(20.5937, 78.9629, 1.8, 0.0);
  }

  /// Executes cinematic 3D approach directly to geographic coordinates
  void flyToCoordinates(double lon, double lat, [double targetZoom = 2.8, double targetPitch = 0.0]) {
    flyTo(lat, lon, targetZoom, targetPitch);
  }

  /// Executes cinematic camera fly-to physics interpolation
  void flyTo(double targetLat, double targetLon, [double? targetZoom, double? pitch, double? bearing, double? speed, double? curve]) {
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

    _targetZoom = (targetZoom ?? 2.2).clamp(0.6, 4.5);

    _flightController?.stop();
    _reticlePulseController?.reset();
    _flightController?.forward(from: 0.0);
  }

  void freezeAutoRotation() {
    _unfreezeTimer?.cancel();
    setState(() {
      _autoRotate = false;
      _velocityYaw = 0.0;
      _velocityPitch = 0.0;
    });
  }

  void scheduleUnfreezeAutoRotation() {
    _unfreezeTimer?.cancel();
    _unfreezeTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() {
          _autoRotate = true;
        });
      }
    });
  }

  void _onFlightTick() {
    if (!mounted || _flightController == null) return;

    final t = _flightController!.value;
    final curvedT = Curves.easeOutCubic.transform(t);

    _pitch = _startPitch + (_targetPitch - _startPitch) * curvedT;
    _yaw = _startYaw + (_targetYaw - _startYaw) * curvedT;
    _zoom = (_startZoom + (_targetZoom - _startZoom) * curvedT).clamp(0.5, 4.5);

    setState(() {});
    _notifyCameraChanged();
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

    _notifyCameraChanged();
  }

  void _notifyCameraChanged() {
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
      final zoomDelta = event.scrollDelta.dy > 0 ? -0.15 : 0.15;
      setState(() {
        _zoom = (_zoom + zoomDelta).clamp(0.6, 4.5);
      });
      _notifyCameraChanged();
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
      flyTo(hitMarker.lat, hitMarker.lng, 2.8);
      widget.onMarkerClick?.call(hitMarker);
    } else if (widget.onLocationSelected != null) {
      final unproj = _unprojectScreenToLatLng(details.localPosition, size);
      if (unproj != null) {
        flyTo(unproj.x, unproj.y, 2.5);
        widget.onLocationSelected!(unproj.x, unproj.y);
      }
    }
  }

  GlobeMarker? _findMarkerAtScreenPos(Offset screenPos, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final radius = min(size.width, size.height) * 0.42 * _zoom;

    final currentLat = (_pitch * 180.0 / pi).clamp(-85.0, 85.0);
    double currentLon = (-_yaw * 180.0 / pi) % 360.0;
    if (currentLon > 180.0) currentLon -= 360.0;
    if (currentLon < -180.0) currentLon += 360.0;

    GlobeMarker? closestMarker;
    double minDistance = 22.0;

    for (final marker in widget.markers) {
      final proj = OrthographicProjection.project(
        latDeg: marker.lat,
        lonDeg: marker.lng,
        cx: cx,
        cy: cy,
        radius: radius,
        centerLatDeg: currentLat,
        centerLonDeg: currentLon,
      );

      if (proj.isVisible) {
        final dist = sqrt(pow(screenPos.dx - proj.screenX, 2) + pow(screenPos.dy - proj.screenY, 2));
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
    final radius = min(size.width, size.height) * 0.42 * _zoom;

    final currentLat = (_pitch * 180.0 / pi).clamp(-85.0, 85.0);
    double currentLon = (-_yaw * 180.0 / pi) % 360.0;
    if (currentLon > 180.0) currentLon -= 360.0;
    if (currentLon < -180.0) currentLon += 360.0;

    return OrthographicProjection.unproject(
      tapX: screenPos.dx,
      tapY: screenPos.dy,
      cx: cx,
      cy: cy,
      radius: radius,
      centerLatDeg: currentLat,
      centerLonDeg: currentLon,
    );
  }

  @override
  Widget build(BuildContext context) {
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
                  final currentLat = (_pitch * 180.0 / pi).clamp(-85.0, 85.0);
                  double currentLon = (-_yaw * 180.0 / pi) % 360.0;
                  if (currentLon > 180.0) currentLon -= 360.0;
                  if (currentLon < -180.0) currentLon += 360.0;

                  final rawEvents = widget.markers.map((m) {
                    if (m.data is WorldEvent) return m.data as WorldEvent;
                    return WorldEvent(
                      id: m.label,
                      externalId: m.label,
                      title: m.label,
                      type: m.type,
                      severity: m.severity,
                      latitude: m.lat,
                      longitude: m.lng,
                      timestamp: DateTime.now(),
                      updatedAt: DateTime.now(),
                      source: 'LIVE TELEMETRY',
                      description: m.label,
                      city: m.label,
                    );
                  }).toList();

                  return RepaintBoundary(
                    child: CustomPaint(
                      size: size,
                      painter: GlobePainter(
                        centerLat: currentLat,
                        centerLon: currentLon,
                        zoom: _zoom,
                        events: rawEvents,
                        activeLayers: _activeLayers,
                        selectedEvent: _hoveredMarker?.data is WorldEvent ? (_hoveredMarker!.data as WorldEvent) : null,
                        watchZones: widget.watchZones,
                        animationValue: _tickerController?.value ?? 0.0,
                        earthImage: _earthImage,
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
