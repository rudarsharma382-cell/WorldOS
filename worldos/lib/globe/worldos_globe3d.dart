import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/watch_zone.dart';
import '../services/geo_data.dart';
import 'globe_models.dart';

/// High-Performance Textured 3D Earth Globe Engine for WorldOS
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

  const WorldOSGlobe3D({
    super.key,
    required this.markers,
    this.config = const GlobeConfig(),
    this.onMarkerClick,
    this.onMarkerHover,
    this.onLocationSelected,
    this.watchZones = const [],
    this.centerLat = 20.0,
    this.centerLon = 0.0,
    this.zoom = 1.0,
    this.onCameraChanged,
  });

  @override
  State<WorldOSGlobe3D> createState() => _WorldOSGlobe3DState();
}

class _WorldOSGlobe3DState extends State<WorldOSGlobe3D> with SingleTickerProviderStateMixin {
  late AnimationController _tickerController;
  ui.Image? _earthImage;

  // 3D Orbit Camera Angles (in radians)
  double _pitch = 0.35; // Lat tilt (~20 deg)
  double _yaw = 0.0; // Lon rotation
  double _zoom = 1.0;

  // User Drag State & Inertia Velocity
  bool _isUserDragging = false;
  Offset _lastPanPos = Offset.zero;
  double _velocityYaw = 0.0;
  double _velocityPitch = 0.0;

  // Hovered Marker
  GlobeMarker? _hoveredMarker;

  @override
  void initState() {
    super.initState();
    _zoom = widget.zoom;
    _pitch = (widget.centerLat * pi / 180.0).clamp(-1.2, 1.2);
    _yaw = -widget.centerLon * pi / 180.0;

    _tickerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60),
    )..repeat();

    _tickerController.addListener(_onTick);

    _loadEarthTexture();
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

  @override
  void didUpdateWidget(covariant WorldOSGlobe3D oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.zoom != widget.zoom) {
      _zoom = widget.zoom;
    }
    if (oldWidget.centerLat != widget.centerLat || oldWidget.centerLon != widget.centerLon) {
      final targetPitch = (widget.centerLat * pi / 180.0).clamp(-1.2, 1.2);
      final targetYaw = -widget.centerLon * pi / 180.0;
      _pitch = _pitch + (targetPitch - _pitch) * 0.3;
      _yaw = _yaw + (targetYaw - _yaw) * 0.3;
    }
  }

  @override
  void dispose() {
    _tickerController.removeListener(_onTick);
    _tickerController.dispose();
    super.dispose();
  }

  void _onTick() {
    if (!mounted) return;

    setState(() {
      // Auto-rotation if enabled and user not actively dragging
      if (widget.config.autoRotate && !_isUserDragging) {
        _yaw += (widget.config.autoRotateSpeed * 0.008);
      }

      // Inertia decay
      if (!_isUserDragging) {
        if (_velocityYaw.abs() > 0.0001 || _velocityPitch.abs() > 0.0001) {
          _yaw += _velocityYaw;
          _pitch = (_pitch + _velocityPitch).clamp(-1.3, 1.3);
          _velocityYaw *= 0.92;
          _velocityPitch *= 0.92;
        }
      }
    });

    // Notify camera updates if listener provided
    if (widget.onCameraChanged != null) {
      final currentLat = (_pitch * 180.0 / pi).clamp(-85.0, 85.0);
      double currentLon = (-_yaw * 180.0 / pi) % 360.0;
      if (currentLon > 180.0) currentLon -= 360.0;
      if (currentLon < -180.0) currentLon += 360.0;
      widget.onCameraChanged!(currentLat, currentLon, _zoom);
    }
  }

  void _handlePanStart(DragStartDetails details) {
    _isUserDragging = true;
    _lastPanPos = details.localPosition;
    _velocityYaw = 0.0;
    _velocityPitch = 0.0;
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
      if (widget.onMarkerHover != null) {
        widget.onMarkerHover!(hitMarker);
      }
    }
  }

  void _handleTapUp(TapUpDetails details, Size size) {
    final hitMarker = _findMarkerAtScreenPos(details.localPosition, size);
    if (hitMarker != null) {
      if (widget.onMarkerClick != null) {
        widget.onMarkerClick!(hitMarker);
      }
    } else if (widget.onLocationSelected != null) {
      final unproj = _unprojectScreenToLatLng(details.localPosition, size);
      if (unproj != null) {
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

      // Rotate yaw
      final x1 = x0 * cos(_yaw) + z0 * sin(_yaw);
      final y1 = y0;
      final z1 = -x0 * sin(_yaw) + z0 * cos(_yaw);

      // Rotate pitch
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
    if (r2 > 1.0) return null; // Outside globe sphere boundary

    final dz = sqrt(1.0 - r2);

    // Un-rotate pitch
    final x1 = dx;
    final y1 = dy * cos(-_pitch) - dz * sin(-_pitch);
    final z1 = dy * sin(-_pitch) + dz * cos(-_pitch);

    // Un-rotate yaw
    final x0 = x1 * cos(-_yaw) + z1 * sin(-_yaw);
    final y0 = y1;
    final z0 = -x1 * sin(-_yaw) + z1 * cos(-_yaw);

    final lat = asin(y0.clamp(-1.0, 1.0)) * 180.0 / pi;
    final lng = atan2(x0, z0) * 180.0 / pi;

    return Point(lat, lng);
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
                animation: _tickerController,
                builder: (context, child) {
                  return CustomPaint(
                    size: size,
                    painter: _TexturedGlobe3DPainter(
                      earthImage: _earthImage,
                      markers: widget.markers,
                      config: widget.config,
                      pitch: _pitch,
                      yaw: _yaw,
                      zoom: _zoom,
                      animValue: _tickerController.value,
                      hoveredMarker: _hoveredMarker,
                      watchZones: widget.watchZones,
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
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final radius = min(size.width, size.height) * 0.40 * zoom;
    final centerOffset = Offset(cx, cy);

    // 1. Smooth Outer Atmosphere Rim Glow (Drawn OUTSIDE globe clip path)
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

    // 2. Base Dark Oceanic Sphere Body
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

    // Clip internal 3D rendering strictly inside sphere disk
    canvas.save();
    canvas.clipPath(Path()..addOval(Rect.fromCircle(center: centerOffset, radius: radius)));

    // 3. Render High-Res Textured 3D Sphere (or Vector Contours fallback)
    if (earthImage != null) {
      _drawSmoothTexturedSphere(canvas, cx, cy, radius);
    } else {
      _drawVectorLandmasses(canvas, cx, cy, radius);
    }

    // 4. Tactical Grid Lines (Parallels & Meridians)
    _drawTacticalGridLines(canvas, cx, cy, radius);

    // 5. Spherical Directional Lighting & Inner Limb Shadow (3D Horizon Darkening)
    _drawSphericalLighting(canvas, centerOffset, radius);

    // 6. Watch Zones Coverage (True Spherical Projected Boundary & Tactical Radar Sweep)
    _drawWatchZones(canvas, cx, cy, radius);

    // 7. Tactical Reticles & Sector Vector Markers
    _drawTacticalMarkers(canvas, cx, cy, radius);

    canvas.restore();

    // 8. C4ISR Corner Reticles & Perimeter Overlays
    _drawCornerReticles(canvas, size);
  }

  void _drawSmoothTexturedSphere(Canvas canvas, double cx, double cy, double radius) {
    if (earthImage == null) return;

    // 1. Polar Cap Glacial Base Fill Pass (Underneath texture to prevent black void)
    _drawPolarCapFallbackFills(canvas, cx, cy, radius);

    final imgW = earthImage!.width.toDouble();
    final imgH = earthImage!.height.toDouble();

    const latStep = 4;
    const lonStep = 4;

    final List<Offset> positions = [];
    final List<Offset> texCoords = [];

    final cosYaw = cos(yaw);
    final sinYaw = sin(yaw);
    final cosPitch = cos(pitch);
    final sinPitch = sin(pitch);

    Offset? projectVertex(double latDeg, double lonDeg) {
      final clampedLat = latDeg.clamp(-89.999, 89.999);
      final phi = clampedLat * pi / 180.0;
      final lam = lonDeg * pi / 180.0;

      final clampedY = sin(phi).clamp(-1.0, 1.0);
      final x0 = cos(phi) * sin(lam);
      final y0 = clampedY;
      final z0 = cos(phi) * cos(lam);

      final x1 = x0 * cosYaw + z0 * sinYaw;
      final y1 = y0;
      final z1 = -x0 * sinYaw + z0 * cosYaw;

      final x2 = x1;
      final y2 = y1 * cosPitch - z1 * sinPitch;
      final z2 = y1 * sinPitch + z1 * cosPitch;

      if (z2 <= -0.05) return null; // Backface culled

      final px = cx + x2 * radius;
      final py = cy - y2 * radius;
      return Offset(px, py);
    }

    // Full [-90, 90] Latitude Mesh Loop
    for (int lat = -90; lat < 90; lat += latStep) {
      for (int lon = -180; lon < 180; lon += lonStep) {
        final p00 = projectVertex(lat.toDouble(), lon.toDouble());
        final p10 = projectVertex(lat.toDouble(), (lon + lonStep).toDouble());
        final p11 = projectVertex((lat + latStep).toDouble(), (lon + lonStep).toDouble());
        final p01 = projectVertex((lat + latStep).toDouble(), lon.toDouble());

        if (p00 != null && p10 != null && p11 != null && p01 != null) {
          final u0 = (((lon + 180) / 360.0).clamp(0.0, 1.0)) * imgW;
          final u1 = ((((lon + lonStep) + 180) / 360.0).clamp(0.0, 1.0)) * imgW;

          // V-coordinate singularity clamping [0.001, 0.999]
          final v0 = (((90 - (lat + latStep)) / 180.0).clamp(0.001, 0.999)) * imgH;
          final v1 = (((90 - lat) / 180.0).clamp(0.001, 0.999)) * imgH;

          final t00 = Offset(u0, v1);
          final t10 = Offset(u1, v1);
          final t11 = Offset(u1, v0);
          final t01 = Offset(u0, v0);

          positions.addAll([p00, p10, p11]);
          texCoords.addAll([t00, t10, t11]);

          positions.addAll([p00, p11, p01]);
          texCoords.addAll([t00, t11, t01]);
        }
      }
    }

    if (positions.isNotEmpty) {
      final vertices = ui.Vertices(
        ui.VertexMode.triangles,
        positions,
        textureCoordinates: texCoords,
      );

      final matrix = Matrix4.identity().storage;
      final imageShader = ui.ImageShader(
        earthImage!,
        ui.TileMode.clamp,
        ui.TileMode.clamp,
        Float64List.fromList(matrix),
      );

      final paint = Paint()
        ..shader = imageShader
        ..filterQuality = FilterQuality.high
        ..isAntiAlias = true;

      canvas.drawVertices(vertices, BlendMode.src, paint);
    }
  }

  /// Polar Cap Fallback Fill (Ice/Ocean Tints for North and South Poles)
  void _drawPolarCapFallbackFills(Canvas canvas, double cx, double cy, double radius) {
    // Arctic North Cap (Glacial Ice Tint Color(0xFFD6E8FA))
    _drawPolarCapDisk(canvas, cx, cy, radius, minLat: 70.0, maxLat: 90.0, color: const Color(0xFFD6E8FA));
    // Antarctic South Cap (Glacial Ice Tint Color(0xFFEAF4FC))
    _drawPolarCapDisk(canvas, cx, cy, radius, minLat: -90.0, maxLat: -70.0, color: const Color(0xFFEAF4FC));
  }

  void _drawPolarCapDisk(Canvas canvas, double cx, double cy, double radius, {required double minLat, required double maxLat, required Color color}) {
    final cosYaw = cos(yaw);
    final sinYaw = sin(yaw);
    final cosPitch = cos(pitch);
    final sinPitch = sin(pitch);

    final path = Path();
    bool started = false;

    for (int lon = -180; lon <= 180; lon += 10) {
      final phi = (minLat < 0 ? minLat : minLat) * pi / 180.0;
      final lam = lon * pi / 180.0;

      final x0 = cos(phi) * sin(lam);
      final y0 = sin(phi);
      final z0 = cos(phi) * cos(lam);

      final x1 = x0 * cosYaw + z0 * sinYaw;
      final y1 = y0;
      final z1 = -x0 * sinYaw + z0 * cosYaw;

      final x2 = x1;
      final y2 = y1 * cosPitch - z1 * sinPitch;
      final z2 = y1 * sinPitch + z1 * cosPitch;

      if (z2 > -0.05) {
        final px = cx + x2 * radius;
        final py = cy - y2 * radius;
        if (!started) {
          path.moveTo(px, py);
          started = true;
        } else {
          path.lineTo(px, py);
        }
      }
    }

    if (started) {
      path.close();
      canvas.drawPath(path, Paint()..color = color.withValues(alpha: 0.90)..style = PaintingStyle.fill);
    }
  }

  void _drawVectorLandmasses(Canvas canvas, double cx, double cy, double radius) {
    final landFillPaint = Paint()
      ..color = const Color(0xFF152D24).withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;

    final landStrokePaint = Paint()
      ..color = const Color(0xFF10B981).withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final cosYaw = cos(yaw);
    final sinYaw = sin(yaw);
    final cosPitch = cos(pitch);
    final sinPitch = sin(pitch);

    for (final continent in GeoData.continents) {
      final path = Path();
      bool started = false;

      for (final pt in continent) {
        final phi = pt.x * pi / 180.0;
        final lam = pt.y * pi / 180.0;

        final x0 = cos(phi) * sin(lam);
        final y0 = sin(phi);
        final z0 = cos(phi) * cos(lam);

        final x1 = x0 * cosYaw + z0 * sinYaw;
        final y1 = y0;
        final z1 = -x0 * sinYaw + z0 * cosYaw;

        final x2 = x1;
        final y2 = y1 * cosPitch - z1 * sinPitch;
        final z2 = y1 * sinPitch + z1 * cosPitch;

        if (z2 > -0.05) {
          final px = cx + x2 * radius;
          final py = cy - y2 * radius;
          if (!started) {
            path.moveTo(px, py);
            started = true;
          } else {
            path.lineTo(px, py);
          }
        } else {
          started = false;
        }
      }

      if (started) {
        canvas.drawPath(path, landFillPaint);
        canvas.drawPath(path, landStrokePaint);
      }
    }
  }

  void _drawSphericalLighting(Canvas canvas, Offset center, double radius) {
    // 3D Solar Light & Inner Limb Shadow (Planetary Edge Terminator Shadow)
    final shadowPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.35, -0.35),
        colors: [
          Colors.white.withValues(alpha: 0.15),
          Colors.transparent,
          const Color(0xFF02040A).withValues(alpha: 0.40),
          const Color(0xFF010205).withValues(alpha: 0.75), // Inner limb edge darkening curve
        ],
        stops: const [0.0, 0.60, 0.88, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, shadowPaint);
  }

  void _drawTacticalGridLines(Canvas canvas, double cx, double cy, double radius) {
    final gridPaint = Paint()
      ..color = const Color(0xFF38BDF8).withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6;

    final cosYaw = cos(yaw);
    final sinYaw = sin(yaw);
    final cosPitch = cos(pitch);
    final sinPitch = sin(pitch);

    for (int lat = -60; lat <= 60; lat += 30) {
      final path = Path();
      bool started = false;
      final phi = lat * pi / 180.0;

      for (int lng = -180; lng <= 180; lng += 6) {
        final lam = lng * pi / 180.0;
        final x0 = cos(phi) * sin(lam);
        final y0 = sin(phi);
        final z0 = cos(phi) * cos(lam);

        final x1 = x0 * cosYaw + z0 * sinYaw;
        final y1 = y0;
        final z1 = -x0 * sinYaw + z0 * cosYaw;

        final x2 = x1;
        final y2 = y1 * cosPitch - z1 * sinPitch;
        final z2 = y1 * sinPitch + z1 * cosPitch;

        if (z2 > -0.05) {
          final px = cx + x2 * radius;
          final py = cy - y2 * radius;

          if (!started) {
            path.moveTo(px, py);
            started = true;
          } else {
            path.lineTo(px, py);
          }
        } else {
          started = false;
        }
      }
      canvas.drawPath(path, gridPaint);
    }
  }

  void _drawWatchZones(Canvas canvas, double cx, double cy, double radius) {
    final cosYaw = cos(yaw);
    final sinYaw = sin(yaw);
    final cosPitch = cos(pitch);
    final sinPitch = sin(pitch);

    const double earthRadiusKm = 6371.0;

    for (final zone in watchZones) {
      final phi1 = zone.latitude * pi / 180.0;
      final lam1 = zone.longitude * pi / 180.0;
      final delta = zone.radiusKm / earthRadiusKm;

      final List<Offset> polyPoints = [];

      // 1. Calculate 36 spherical trigonometry points along the circumference
      for (int i = 0; i <= 36; i++) {
        final theta = (i * 10) * pi / 180.0;
        final phi2 = asin((sin(phi1) * cos(delta) + cos(phi1) * sin(delta) * cos(theta)).clamp(-1.0, 1.0));
        final dLam = atan2(sin(theta) * sin(delta) * cos(phi1), cos(delta) - sin(phi1) * sin(phi2));
        final lam2 = lam1 + dLam;

        final x0 = cos(phi2) * sin(lam2);
        final y0 = sin(phi2);
        final z0 = cos(phi2) * cos(lam2);

        final x1 = x0 * cosYaw + z0 * sinYaw;
        final y1 = y0;
        final z1 = -x0 * sinYaw + z0 * cosYaw;

        final x2 = x1;
        final y2 = y1 * cosPitch - z1 * sinPitch;
        final z2 = y1 * sinPitch + z1 * cosPitch;

        if (z2 > -0.05) {
          final px = cx + x2 * radius;
          final py = cy - y2 * radius;
          polyPoints.add(Offset(px, py));
        }
      }

      // 2. Render Spherical Projected Polygon (Subtle Amber Fill & Stippled Perimeter)
      if (polyPoints.length >= 3) {
        final zonePath = Path()..moveTo(polyPoints[0].dx, polyPoints[0].dy);
        for (int i = 1; i < polyPoints.length; i++) {
          zonePath.lineTo(polyPoints[i].dx, polyPoints[i].dy);
        }
        zonePath.close();

        final fillPaint = Paint()
          ..color = const Color(0xFFF59E0B).withValues(alpha: 0.06)
          ..style = PaintingStyle.fill;
        canvas.drawPath(zonePath, fillPaint);

        // Subtle 0.8px stippled hairline perimeter (dashed segments)
        final strokePaint = Paint()
          ..color = const Color(0xFFF59E0B).withValues(alpha: 0.35)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8
          ..isAntiAlias = true;

        for (int i = 0; i < polyPoints.length - 1; i += 2) {
          canvas.drawLine(polyPoints[i], polyPoints[i + 1], strokePaint);
        }
      }

      // 3. Projected Center Crosshair (+) & Pinned Monospace Label
      final cx0 = cos(phi1) * sin(lam1);
      final cy0 = sin(phi1);
      final cz0 = cos(phi1) * cos(lam1);

      final cx1 = cx0 * cosYaw + cz0 * sinYaw;
      final cy1 = cy0;
      final cz1 = -cx0 * sinYaw + cz0 * cosYaw;

      final cx2 = cx1;
      final cy2 = cy1 * cosPitch - cz1 * sinPitch;
      final cz2 = cy1 * sinPitch + cz1 * cosPitch;

      if (cz2 > -0.05) {
        final cPx = cx + cx2 * radius;
        final cPy = cy - cy2 * radius;
        final centerPos = Offset(cPx, cPy);

        final crosshairPaint = Paint()
          ..color = const Color(0xFFF59E0B).withValues(alpha: 0.8)
          ..strokeWidth = 0.8
          ..isAntiAlias = true;

        canvas.drawLine(Offset(centerPos.dx - 4, centerPos.dy), Offset(centerPos.dx + 4, centerPos.dy), crosshairPaint);
        canvas.drawLine(Offset(centerPos.dx, centerPos.dy - 4), Offset(centerPos.dx, centerPos.dy + 4), crosshairPaint);

        // Monospace Tag Pinned 8px Beneath Center: `WATCH_ZONE // 1000KM`
        final zoneLabel = zone.name.isNotEmpty ? zone.name.toUpperCase() : 'WATCH_ZONE';
        final textSpan = TextSpan(
          text: '$zoneLabel // ${zone.radiusKm.toInt()}KM',
          style: GoogleFonts.jetBrainsMono(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.90),
            fontSize: 8.0,
            fontWeight: FontWeight.w600,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        );
        final textPainter = TextPainter(text: textSpan, textDirection: TextDirection.ltr)..layout();
        final textOffset = Offset(centerPos.dx - textPainter.width / 2, centerPos.dy + 6.0);

        final bgRect = RRect.fromRectAndRadius(
          Rect.fromLTWH(textOffset.dx - 3, textOffset.dy - 1, textPainter.width + 6, textPainter.height + 2),
          const Radius.circular(2),
        );
        canvas.drawRRect(bgRect, Paint()..color = const Color(0xFF0C1017).withValues(alpha: 0.85));
        canvas.drawRRect(
          bgRect,
          Paint()
            ..color = const Color(0xFFF59E0B).withValues(alpha: 0.4)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.5
            ..isAntiAlias = true,
        );

        textPainter.paint(canvas, textOffset);
      }
    }
  }

  void _drawTacticalMarkers(Canvas canvas, double cx, double cy, double radius) {
    final cosYaw = cos(yaw);
    final sinYaw = sin(yaw);
    final cosPitch = cos(pitch);
    final sinPitch = sin(pitch);

    for (final marker in markers) {
      final phi = marker.lat * pi / 180.0;
      final lam = marker.lng * pi / 180.0;

      final x0 = cos(phi) * sin(lam);
      final y0 = sin(phi);
      final z0 = cos(phi) * cos(lam);

      final x1 = x0 * cosYaw + z0 * sinYaw;
      final y1 = y0;
      final z1 = -x0 * sinYaw + z0 * cosYaw;

      final x2 = x1;
      final y2 = y1 * cosPitch - z1 * sinPitch;
      final z2 = y1 * sinPitch + z1 * cosPitch;

      // Strict Backface Culling
      if (z2 <= -0.05) continue;

      final px = cx + x2 * radius;
      final py = cy - y2 * radius;
      final pos = Offset(px, py);

      final isHovered = hoveredMarker?.label == marker.label;
      final type = marker.type.toUpperCase();

      if (type == 'EARTHQUAKE' || type == 'SEISMIC') {
        _drawSeismicReticle(canvas, pos, marker, isHovered);
      } else if (type == 'STORM' || type == 'WEATHER' || type == 'CYCLONE') {
        _drawCycloneGlyph(canvas, pos, marker, isHovered);
      } else if (type == 'SATELLITE' || type == 'ORBITAL') {
        _drawSatelliteGlyph(canvas, pos, marker, isHovered);
      } else if (type == 'WILDFIRE' || type == 'THERMAL') {
        _drawHexagonGlyph(canvas, pos, marker, isHovered);
      } else {
        _drawDefaultTacticalReticle(canvas, pos, marker, isHovered);
      }
    }
  }

  /// 1. Earthquake / Seismic: 4-Corner Reticle Brackets [ ] + Seismic Peak + Floating M6.4 Micro-Pill
  void _drawSeismicReticle(Canvas canvas, Offset pos, GlobeMarker marker, bool isHovered) {
    final color = const Color(0xFFEF4444); // Crimson
    final b = isHovered ? 8.0 : 6.0; // 16x16 or 12x12px box
    final arm = 3.5;

    final strokePaint = Paint()
      ..color = isHovered ? Colors.white : color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..isAntiAlias = true;

    // 4 Corner Brackets [ ]
    // Top-Left
    canvas.drawLine(Offset(pos.dx - b, pos.dy - b + arm), Offset(pos.dx - b, pos.dy - b), strokePaint);
    canvas.drawLine(Offset(pos.dx - b, pos.dy - b), Offset(pos.dx - b + arm, pos.dy - b), strokePaint);

    // Top-Right
    canvas.drawLine(Offset(pos.dx + b - arm, pos.dy - b), Offset(pos.dx + b, pos.dy - b), strokePaint);
    canvas.drawLine(Offset(pos.dx + b, pos.dy - b), Offset(pos.dx + b, pos.dy - b + arm), strokePaint);

    // Bottom-Left
    canvas.drawLine(Offset(pos.dx - b, pos.dy + b - arm), Offset(pos.dx - b, pos.dy + b), strokePaint);
    canvas.drawLine(Offset(pos.dx - b, pos.dy + b), Offset(pos.dx - b + arm, pos.dy + b), strokePaint);

    // Bottom-Right
    canvas.drawLine(Offset(pos.dx + b - arm, pos.dy + b), Offset(pos.dx + b, pos.dy + b), strokePaint);
    canvas.drawLine(Offset(pos.dx + b, pos.dy + b), Offset(pos.dx + b, pos.dy + b - arm), strokePaint);

    // Fine horizontal seismic line with pulse peak in middle
    final seismicPath = Path()
      ..moveTo(pos.dx - b + 1.5, pos.dy)
      ..lineTo(pos.dx - 2.0, pos.dy)
      ..lineTo(pos.dx - 1.0, pos.dy - 3.5)
      ..lineTo(pos.dx + 1.0, pos.dy + 3.0)
      ..lineTo(pos.dx + 2.0, pos.dy)
      ..lineTo(pos.dx + b - 1.5, pos.dy);

    final linePaint = Paint()
      ..color = color.withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..isAntiAlias = true;
    canvas.drawPath(seismicPath, linePaint);

    // Micro-Pill Floating Strictly 8px Above Reticle: `M6.4`
    final magText = 'M${marker.severity.toStringAsFixed(1)}';
    final textSpan = TextSpan(
      text: magText,
      style: GoogleFonts.jetBrainsMono(
        color: Colors.white,
        fontSize: 8.5,
        fontWeight: FontWeight.w700,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
    final textPainter = TextPainter(text: textSpan, textDirection: TextDirection.ltr)..layout();

    final pillWidth = textPainter.width + 8.0;
    final pillHeight = textPainter.height + 3.0;
    final pillOffset = Offset(pos.dx - pillWidth / 2, pos.dy - b - 8.0 - pillHeight);

    final pillBg = Paint()
      ..color = const Color(0xFF0C1017).withValues(alpha: 0.90)
      ..style = PaintingStyle.fill;
    final pillBorder = Paint()
      ..color = isHovered ? Colors.white : color
      ..style = PaintingStyle.stroke
      ..strokeWidth = isHovered ? 1.0 : 0.6
      ..isAntiAlias = true;

    final pillRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(pillOffset.dx, pillOffset.dy, pillWidth, pillHeight),
      const Radius.circular(3),
    );
    canvas.drawRRect(pillRect, pillBg);
    canvas.drawRRect(pillRect, pillBorder);

    textPainter.paint(canvas, Offset(pillOffset.dx + 4.0, pillOffset.dy + 1.5));
  }

  /// 2. Severe Weather / Storms: Rotating Dual-Arc Cyclone Glyph + 45 deg Hairline Leader Line + Datum Badge
  void _drawCycloneGlyph(Canvas canvas, Offset pos, GlobeMarker marker, bool isHovered) {
    final color = const Color(0xFF38BDF8); // Sky Blue
    final r = isHovered ? 7.0 : 5.0;
    final angle = animValue * 2 * pi;

    final arcPaint = Paint()
      ..color = isHovered ? Colors.white : color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..isAntiAlias = true;

    // Outer Arc 1
    canvas.drawArc(
      Rect.fromCircle(center: pos, radius: r),
      angle,
      2.09, // ~120 degrees
      false,
      arcPaint,
    );

    // Inner Arc 2 (Opposite)
    canvas.drawArc(
      Rect.fromCircle(center: pos, radius: r * 0.65),
      angle + pi,
      2.09,
      false,
      arcPaint,
    );

    // Center eye dot
    canvas.drawCircle(pos, 1.2, Paint()..color = color..style = PaintingStyle.fill);

    // 45 Degree Hairline Leader Line (Length 14px)
    final leaderStart = Offset(pos.dx + r * 0.707, pos.dy - r * 0.707);
    final leaderEnd = Offset(leaderStart.dx + 10.0, leaderStart.dy - 10.0);

    final leaderPaint = Paint()
      ..color = color.withValues(alpha: isHovered ? 0.9 : 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..isAntiAlias = true;
    canvas.drawLine(leaderStart, leaderEnd, leaderPaint);
    canvas.drawLine(leaderEnd, Offset(leaderEnd.dx + 6.0, leaderEnd.dy), leaderPaint);

    // Datum Badge: `CYCLONE DUJUAN // 980 hPa`
    final badgeTitle = marker.label.isNotEmpty ? marker.label.toUpperCase() : 'CYCLONE';
    final badgeText = '$badgeTitle // 980 hPa';

    final textSpan = TextSpan(
      text: badgeText,
      style: GoogleFonts.jetBrainsMono(
        color: Colors.white.withValues(alpha: 0.90),
        fontSize: 8.5,
        fontWeight: FontWeight.w600,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
    final textPainter = TextPainter(text: textSpan, textDirection: TextDirection.ltr)..layout();

    final badgeOffset = Offset(leaderEnd.dx + 8.0, leaderEnd.dy - textPainter.height / 2);
    final badgeRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(badgeOffset.dx - 3, badgeOffset.dy - 2, textPainter.width + 6, textPainter.height + 4),
      const Radius.circular(2),
    );

    canvas.drawRRect(badgeRect, Paint()..color = const Color(0xFF0C1017).withValues(alpha: 0.85));
    canvas.drawRRect(
      badgeRect,
      Paint()
        ..color = color.withValues(alpha: isHovered ? 0.9 : 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = isHovered ? 1.0 : 0.5
        ..isAntiAlias = true,
    );

    textPainter.paint(canvas, badgeOffset);
  }

  /// 3. Satellites / Orbital Pass: Angled Tactical Diamond Glyph ◇ + Dotted Motion Vector
  void _drawSatelliteGlyph(Canvas canvas, Offset pos, GlobeMarker marker, bool isHovered) {
    final color = const Color(0xFFA855F7); // Purple
    final d = isHovered ? 7.0 : 5.0;

    final diamondPath = Path()
      ..moveTo(pos.dx, pos.dy - d)
      ..lineTo(pos.dx + d, pos.dy)
      ..lineTo(pos.dx, pos.dy + d)
      ..lineTo(pos.dx - d, pos.dy)
      ..close();

    final diamondPaint = Paint()
      ..color = isHovered ? Colors.white : color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..isAntiAlias = true;
    canvas.drawPath(diamondPath, diamondPaint);
    canvas.drawCircle(pos, 1.2, Paint()..color = color..style = PaintingStyle.fill);

    // 12px Dotted Trailing Motion Vector (Orbital heading trail)
    final dotPaint = Paint()..color = color.withValues(alpha: 0.6)..style = PaintingStyle.fill;
    for (int i = 1; i <= 3; i++) {
      final trailOffset = Offset(pos.dx - (i * 4.0), pos.dy + (i * 3.0));
      canvas.drawCircle(trailOffset, 0.9, dotPaint);
    }

    if (isHovered || marker.severity >= 5.0) {
      final textSpan = TextSpan(
        text: 'SAT-ORBIT // ${marker.lat.toStringAsFixed(1)}°',
        style: GoogleFonts.jetBrainsMono(
          color: Colors.white,
          fontSize: 8.5,
          fontWeight: FontWeight.w600,
        ),
      );
      final textPainter = TextPainter(text: textSpan, textDirection: TextDirection.ltr)..layout();
      textPainter.paint(canvas, Offset(pos.dx + d + 4, pos.dy - 5));
    }
  }

  /// 4. Wildfire / Thermal Anomaly: Fine Geometric Hexagon ⬡ + Animated Inner Pulse
  void _drawHexagonGlyph(Canvas canvas, Offset pos, GlobeMarker marker, bool isHovered) {
    final color = const Color(0xFFF59E0B); // Amber
    final r = isHovered ? 7.5 : 5.5;

    Path buildHex(double radius) {
      final path = Path();
      for (int i = 0; i < 6; i++) {
        final a = (i * 60) * pi / 180.0;
        final x = pos.dx + radius * cos(a);
        final y = pos.dy + radius * sin(a);
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      path.close();
      return path;
    }

    final hexPaint = Paint()
      ..color = isHovered ? Colors.white : color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..isAntiAlias = true;
    canvas.drawPath(buildHex(r), hexPaint);

    // Inner animated pulse hexagon
    final pulseScale = 0.3 + 0.45 * (sin(animValue * 2 * pi).abs());
    final innerPaint = Paint()
      ..color = color.withValues(alpha: 0.7)
      ..style = PaintingStyle.fill;
    canvas.drawPath(buildHex(r * pulseScale), innerPaint);

    if (isHovered) {
      final textSpan = TextSpan(
        text: 'THERMAL // ${marker.severity.toStringAsFixed(1)}k',
        style: GoogleFonts.jetBrainsMono(
          color: Colors.white,
          fontSize: 8.5,
          fontWeight: FontWeight.w600,
        ),
      );
      final textPainter = TextPainter(text: textSpan, textDirection: TextDirection.ltr)..layout();
      textPainter.paint(canvas, Offset(pos.dx + r + 4, pos.dy - 5));
    }
  }

  /// Default Tactical Reticle & Datum Tag
  void _drawDefaultTacticalReticle(Canvas canvas, Offset pos, GlobeMarker marker, bool isHovered) {
    final color = marker.accentColor;
    final r = isHovered ? 5.5 : 3.5;

    final tickPaint = Paint()
      ..color = isHovered ? Colors.white : color
      ..strokeWidth = 1.0
      ..isAntiAlias = true;

    canvas.drawCircle(pos, r, Paint()..color = color.withValues(alpha: 0.25)..style = PaintingStyle.fill);
    canvas.drawCircle(pos, r, Paint()..color = isHovered ? Colors.white : color..style = PaintingStyle.stroke..strokeWidth = 1.0..isAntiAlias = true);

    canvas.drawLine(Offset(pos.dx - r - 3, pos.dy), Offset(pos.dx - r + 1, pos.dy), tickPaint);
    canvas.drawLine(Offset(pos.dx + r - 1, pos.dy), Offset(pos.dx + r + 3, pos.dy), tickPaint);
    canvas.drawLine(Offset(pos.dx, pos.dy - r - 3), Offset(pos.dx, pos.dy - r + 1), tickPaint);
    canvas.drawLine(Offset(pos.dx, pos.dy + r - 1), Offset(pos.dx, pos.dy + r + 3), tickPaint);
  }

  void _drawCornerReticles(Canvas canvas, Size size) {
    final reticlePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.18)
      ..strokeWidth = 0.8;

    const pad = 16.0;
    const len = 10.0;

    // Top-Left
    canvas.drawLine(const Offset(pad - len, pad), const Offset(pad + len, pad), reticlePaint);
    canvas.drawLine(const Offset(pad, pad - len), const Offset(pad, pad + len), reticlePaint);

    // Top-Right
    canvas.drawLine(Offset(size.width - pad - len, pad), Offset(size.width - pad + len, pad), reticlePaint);
    canvas.drawLine(Offset(size.width - pad, pad - len), Offset(size.width - pad, pad + len), reticlePaint);

    // Bottom-Left
    canvas.drawLine(Offset(pad - len, size.height - pad), Offset(pad + len, size.height - pad), reticlePaint);
    canvas.drawLine(Offset(pad, size.height - pad - len), Offset(pad, size.height - pad + len), reticlePaint);

    // Bottom-Right
    canvas.drawLine(Offset(size.width - pad - len, size.height - pad), Offset(size.width - pad + len, size.height - pad), reticlePaint);
    canvas.drawLine(Offset(size.width - pad, size.height - pad - len), Offset(size.width - pad, size.height - pad + len), reticlePaint);
  }

  @override
  bool shouldRepaint(covariant _TexturedGlobe3DPainter oldDelegate) {
    return oldDelegate.pitch != pitch ||
        oldDelegate.yaw != yaw ||
        oldDelegate.zoom != zoom ||
        oldDelegate.animValue != animValue ||
        oldDelegate.markers != markers ||
        oldDelegate.hoveredMarker != hoveredMarker ||
        oldDelegate.watchZones != watchZones ||
        oldDelegate.earthImage != earthImage;
  }
}
