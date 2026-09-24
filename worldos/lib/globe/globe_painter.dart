import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/world_event.dart';
import '../models/watch_zone.dart';
import '../services/geo_data.dart';
import 'orthographic_projection.dart';

class GlobePainter extends CustomPainter {
  final double centerLat;
  final double centerLon;
  final double zoom;
  final List<WorldEvent> events;
  final Set<String> activeLayers;
  final WorldEvent? selectedEvent;
  final List<WatchZone> watchZones;
  final double animationValue;
  final ui.Image? earthImage;

  GlobePainter({
    required this.centerLat,
    required this.centerLon,
    required this.zoom,
    required this.events,
    required this.activeLayers,
    this.selectedEvent,
    required this.watchZones,
    required this.animationValue,
    this.earthImage,
  });

  @override
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final radius = min(size.width, size.height) * 0.42 * zoom;
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

    // 2. Base Dark Shaded Sphere Body
    final oceanShader = RadialGradient(
      center: const Alignment(-0.3, -0.3),
      colors: const [
        Color(0xFF0D1B2A),
        Color(0xFF050C16),
        Color(0xFF020408),
      ],
      stops: const [0.0, 0.7, 1.0],
    ).createShader(Rect.fromCircle(center: centerOffset, radius: radius));

    final oceanPaint = Paint()
      ..shader = oceanShader
      ..style = PaintingStyle.fill;
    canvas.drawCircle(centerOffset, radius, oceanPaint);

    // Clip to globe sphere for internal 3D rendering
    canvas.save();
    final clipPath = Path()..addOval(Rect.fromCircle(center: centerOffset, radius: radius));
    canvas.clipPath(clipPath);

    // 3. Render Smooth GPU Mesh Vertices 3D Textured Globe
    if (earthImage != null) {
      _drawSmoothTexturedSphere(canvas, cx, cy, radius);
    } else {
      _drawVectorLandmasses(canvas, cx, cy, radius);
    }

    // 4. Draw Parallels & Meridians (Tactical Grid Lines)
    _drawGridLines(canvas, cx, cy, radius);

    // 5. 3D Spherical Directional Lighting & Inner Limb Shadow
    _drawSphericalLighting(canvas, centerOffset, radius);

    // 6. Draw Watch Zones
    _drawWatchZones(canvas, cx, cy, radius);

    // 7. Draw Aerospace Tactical Reticle Event Markers
    _drawEventMarkers(canvas, cx, cy, radius);

    canvas.restore();

    // 8. C4ISR Screen Perimeter Ticks & Corner Reticles
    _drawPerimeterOverlays(canvas, size);
  }

  void _drawSphericalLighting(Canvas canvas, Offset center, double radius) {
    final shadowPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.4, -0.4),
        colors: [
          Colors.white.withValues(alpha: 0.12),
          Colors.transparent,
          const Color(0xFF02040A).withValues(alpha: 0.40),
          const Color(0xFF010205).withValues(alpha: 0.75),
        ],
        stops: const [0.0, 0.60, 0.88, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, shadowPaint);
  }

  void _drawEventMarkers(Canvas canvas, double cx, double cy, double radius) {
    for (final event in events) {
      if (!activeLayers.contains(event.type) && !activeLayers.contains('ALL')) continue;

      final proj = OrthographicProjection.project(
        latDeg: event.latitude,
        lonDeg: event.longitude,
        cx: cx,
        cy: cy,
        radius: radius,
        centerLatDeg: centerLat,
        centerLonDeg: centerLon,
      );

      if (!proj.isVisible) continue;

      final pos = Offset(proj.screenX, proj.screenY);
      final isSelected = selectedEvent?.id == event.id;
      final type = event.type.toUpperCase();

      if (type == 'EARTHQUAKE' || type == 'SEISMIC') {
        _drawSeismicReticle(canvas, pos, event, isSelected);
      } else if (type == 'STORM' || type == 'WEATHER' || type == 'CYCLONE') {
        _drawCycloneGlyph(canvas, pos, event, isSelected);
      } else if (type == 'SATELLITE' || type == 'ORBITAL') {
        _drawSatelliteGlyph(canvas, pos, event, isSelected);
      } else if (type == 'WILDFIRE' || type == 'THERMAL') {
        _drawHexagonGlyph(canvas, pos, event, isSelected);
      } else {
        _drawDefaultTacticalReticle(canvas, pos, event, isSelected);
      }
    }
  }

  /// 1. Earthquake / Seismic: 4-Corner Reticle Brackets [ ] + Seismic Peak + Floating M6.4 Micro-Pill
  void _drawSeismicReticle(Canvas canvas, Offset pos, WorldEvent event, bool isSelected) {
    final color = const Color(0xFFEF4444);
    final b = isSelected ? 8.0 : 6.0;
    final arm = 3.5;

    final strokePaint = Paint()
      ..color = isSelected ? Colors.white : color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..isAntiAlias = true;

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

    final seismicPath = Path()
      ..moveTo(pos.dx - b + 1.5, pos.dy)
      ..lineTo(pos.dx - 2.0, pos.dy)
      ..lineTo(pos.dx - 1.0, pos.dy - 3.5)
      ..lineTo(pos.dx + 1.0, pos.dy + 3.0)
      ..lineTo(pos.dx + 2.0, pos.dy)
      ..lineTo(pos.dx + b - 1.5, pos.dy);

    canvas.drawPath(
      seismicPath,
      Paint()
        ..color = color.withValues(alpha: 0.9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0
        ..isAntiAlias = true,
    );

    final magText = 'M${event.severity.toStringAsFixed(1)}';
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

    final pillRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(pillOffset.dx, pillOffset.dy, pillWidth, pillHeight),
      const Radius.circular(3),
    );
    canvas.drawRRect(pillRect, Paint()..color = const Color(0xFF0C1017).withValues(alpha: 0.90));
    canvas.drawRRect(
      pillRect,
      Paint()
        ..color = isSelected ? Colors.white : color
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSelected ? 1.0 : 0.6
        ..isAntiAlias = true,
    );

    textPainter.paint(canvas, Offset(pillOffset.dx + 4.0, pillOffset.dy + 1.5));
  }

  /// 2. Severe Weather / Storms
  void _drawCycloneGlyph(Canvas canvas, Offset pos, WorldEvent event, bool isSelected) {
    final color = const Color(0xFF38BDF8);
    final r = isSelected ? 7.0 : 5.0;
    final angle = animationValue * 2 * pi;

    final arcPaint = Paint()
      ..color = isSelected ? Colors.white : color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..isAntiAlias = true;

    canvas.drawArc(Rect.fromCircle(center: pos, radius: r), angle, 2.09, false, arcPaint);
    canvas.drawArc(Rect.fromCircle(center: pos, radius: r * 0.65), angle + pi, 2.09, false, arcPaint);
    canvas.drawCircle(pos, 1.2, Paint()..color = color..style = PaintingStyle.fill);

    final leaderStart = Offset(pos.dx + r * 0.707, pos.dy - r * 0.707);
    final leaderEnd = Offset(leaderStart.dx + 10.0, leaderStart.dy - 10.0);

    final leaderPaint = Paint()
      ..color = color.withValues(alpha: isSelected ? 0.9 : 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..isAntiAlias = true;
    canvas.drawLine(leaderStart, leaderEnd, leaderPaint);
    canvas.drawLine(leaderEnd, Offset(leaderEnd.dx + 6.0, leaderEnd.dy), leaderPaint);

    final badgeTitle = event.title.isNotEmpty ? event.title.toUpperCase() : 'CYCLONE';
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
        ..color = color.withValues(alpha: isSelected ? 0.9 : 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSelected ? 1.0 : 0.5
        ..isAntiAlias = true,
    );

    textPainter.paint(canvas, badgeOffset);
  }

  /// 3. Satellites / Orbital Pass
  void _drawSatelliteGlyph(Canvas canvas, Offset pos, WorldEvent event, bool isSelected) {
    final color = const Color(0xFFA855F7);
    final d = isSelected ? 7.0 : 5.0;

    final diamondPath = Path()
      ..moveTo(pos.dx, pos.dy - d)
      ..lineTo(pos.dx + d, pos.dy)
      ..lineTo(pos.dx, pos.dy + d)
      ..lineTo(pos.dx - d, pos.dy)
      ..close();

    final diamondPaint = Paint()
      ..color = isSelected ? Colors.white : color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..isAntiAlias = true;
    canvas.drawPath(diamondPath, diamondPaint);
    canvas.drawCircle(pos, 1.2, Paint()..color = color..style = PaintingStyle.fill);

    final dotPaint = Paint()..color = color.withValues(alpha: 0.6)..style = PaintingStyle.fill;
    for (int i = 1; i <= 3; i++) {
      canvas.drawCircle(Offset(pos.dx - (i * 4.0), pos.dy + (i * 3.0)), 0.9, dotPaint);
    }

    if (isSelected || event.severity >= 5.0) {
      final textSpan = TextSpan(
        text: 'SAT-ORBIT // ${event.latitude.toStringAsFixed(1)}°',
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

  /// 4. Wildfire / Thermal Anomaly
  void _drawHexagonGlyph(Canvas canvas, Offset pos, WorldEvent event, bool isSelected) {
    final color = const Color(0xFFF59E0B);
    final r = isSelected ? 7.5 : 5.5;

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
      ..color = isSelected ? Colors.white : color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..isAntiAlias = true;
    canvas.drawPath(buildHex(r), hexPaint);

    final pulseScale = 0.3 + 0.45 * (sin(animationValue * 2 * pi).abs());
    canvas.drawPath(buildHex(r * pulseScale), Paint()..color = color.withValues(alpha: 0.7)..style = PaintingStyle.fill);

    if (isSelected) {
      final textSpan = TextSpan(
        text: 'THERMAL // ${event.severity.toStringAsFixed(1)}k',
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

  /// Default Tactical Reticle
  void _drawDefaultTacticalReticle(Canvas canvas, Offset pos, WorldEvent event, bool isSelected) {
    final color = const Color(0xFF10B981);
    final r = isSelected ? 5.5 : 3.5;

    final tickPaint = Paint()
      ..color = isSelected ? Colors.white : color
      ..strokeWidth = 1.0
      ..isAntiAlias = true;

    canvas.drawCircle(pos, r, Paint()..color = color.withValues(alpha: 0.25)..style = PaintingStyle.fill);
    canvas.drawCircle(pos, r, Paint()..color = isSelected ? Colors.white : color..style = PaintingStyle.stroke..strokeWidth = 1.0..isAntiAlias = true);

    canvas.drawLine(Offset(pos.dx - r - 3, pos.dy), Offset(pos.dx - r + 1, pos.dy), tickPaint);
    canvas.drawLine(Offset(pos.dx + r - 1, pos.dy), Offset(pos.dx + r + 3, pos.dy), tickPaint);
    canvas.drawLine(Offset(pos.dx, pos.dy - r - 3), Offset(pos.dx, pos.dy - r + 1), tickPaint);
    canvas.drawLine(Offset(pos.dx, pos.dy + r - 1), Offset(pos.dx, pos.dy + r + 3), tickPaint);
  }

  void _drawSmoothTexturedSphere(Canvas canvas, double cx, double cy, double radius) {
    if (earthImage == null) return;

    final imgW = earthImage!.width.toDouble();
    final imgH = earthImage!.height.toDouble();

    const latStep = 4;
    const lonStep = 4;

    final List<Offset> positions = [];
    final List<Offset> texCoords = [];

    for (int lat = -90; lat < 90; lat += latStep) {
      for (int lon = -180; lon < 180; lon += lonStep) {
        final p00 = OrthographicProjection.project(latDeg: lat.toDouble(), lonDeg: lon.toDouble(), cx: cx, cy: cy, radius: radius, centerLatDeg: centerLat, centerLonDeg: centerLon);
        final p10 = OrthographicProjection.project(latDeg: lat.toDouble(), lonDeg: (lon + lonStep).toDouble(), cx: cx, cy: cy, radius: radius, centerLatDeg: centerLat, centerLonDeg: centerLon);
        final p11 = OrthographicProjection.project(latDeg: (lat + latStep).toDouble(), lonDeg: (lon + lonStep).toDouble(), cx: cx, cy: cy, radius: radius, centerLatDeg: centerLat, centerLonDeg: centerLon);
        final p01 = OrthographicProjection.project(latDeg: (lat + latStep).toDouble(), lonDeg: lon.toDouble(), cx: cx, cy: cy, radius: radius, centerLatDeg: centerLat, centerLonDeg: centerLon);

        if (p00.isVisible && p10.isVisible && p11.isVisible && p01.isVisible) {
          final u0 = (((lon + 180) / 360.0).clamp(0.0, 1.0)) * imgW;
          final u1 = ((((lon + lonStep) + 180) / 360.0).clamp(0.0, 1.0)) * imgW;
          final v0 = (((90 - (lat + latStep)) / 180.0).clamp(0.001, 0.999)) * imgH;
          final v1 = (((90 - lat) / 180.0).clamp(0.001, 0.999)) * imgH;

          final pt00 = Offset(p00.screenX, p00.screenY);
          final pt10 = Offset(p10.screenX, p10.screenY);
          final pt11 = Offset(p11.screenX, p11.screenY);
          final pt01 = Offset(p01.screenX, p01.screenY);

          final t00 = Offset(u0, v1);
          final t10 = Offset(u1, v1);
          final t11 = Offset(u1, v0);
          final t01 = Offset(u0, v0);

          positions.addAll([pt00, pt10, pt11]);
          texCoords.addAll([t00, t10, t11]);

          positions.addAll([pt00, pt11, pt01]);
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

  void _drawVectorLandmasses(Canvas canvas, double cx, double cy, double radius) {
    final landFillPaint = Paint()
      ..color = const Color(0xFF152D24).withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;

    final landStrokePaint = Paint()
      ..color = const Color(0xFF10B981).withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (final continent in GeoData.continents) {
      final path = Path();
      bool started = false;

      for (final pt in continent) {
        final proj = OrthographicProjection.project(
          latDeg: pt.x,
          lonDeg: pt.y,
          cx: cx,
          cy: cy,
          radius: radius,
          centerLatDeg: centerLat,
          centerLonDeg: centerLon,
        );

        if (proj.isVisible) {
          if (!started) {
            path.moveTo(proj.screenX, proj.screenY);
            started = true;
          } else {
            path.lineTo(proj.screenX, proj.screenY);
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

  void _drawGridLines(Canvas canvas, double cx, double cy, double radius) {
    final gridPaint = Paint()
      ..color = const Color(0xFF38BDF8).withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6;

    for (int lat = -60; lat <= 60; lat += 30) {
      final path = Path();
      bool first = true;

      for (int lon = -180; lon <= 180; lon += 5) {
        final pt = OrthographicProjection.project(
          latDeg: lat.toDouble(),
          lonDeg: lon.toDouble(),
          cx: cx,
          cy: cy,
          radius: radius,
          centerLatDeg: centerLat,
          centerLonDeg: centerLon,
        );

        if (pt.isVisible) {
          if (first) {
            path.moveTo(pt.screenX, pt.screenY);
            first = false;
          } else {
            path.lineTo(pt.screenX, pt.screenY);
          }
        } else {
          first = true;
        }
      }
      canvas.drawPath(path, gridPaint);
    }

    for (int lon = -180; lon <= 180; lon += 30) {
      final path = Path();
      bool first = true;

      for (int lat = -90; lat <= 90; lat += 5) {
        final pt = OrthographicProjection.project(
          latDeg: lat.toDouble(),
          lonDeg: lon.toDouble(),
          cx: cx,
          cy: cy,
          radius: radius,
          centerLatDeg: centerLat,
          centerLonDeg: centerLon,
        );

        if (pt.isVisible) {
          if (first) {
            path.moveTo(pt.screenX, pt.screenY);
            first = false;
          } else {
            path.lineTo(pt.screenX, pt.screenY);
          }
        } else {
          first = true;
        }
      }
      canvas.drawPath(path, gridPaint);
    }
  }

  void _drawWatchZones(Canvas canvas, double cx, double cy, double radius) {
    const double earthRadiusKm = 6371.0;

    for (final zone in watchZones) {
      final phi1 = zone.latitude * pi / 180.0;
      final lam1 = zone.longitude * pi / 180.0;
      final delta = zone.radiusKm / earthRadiusKm;

      final List<Offset> polyPoints = [];

      for (int i = 0; i <= 36; i++) {
        final theta = (i * 10) * pi / 180.0;
        final phi2 = asin((sin(phi1) * cos(delta) + cos(phi1) * sin(delta) * cos(theta)).clamp(-1.0, 1.0));
        final dLam = atan2(sin(theta) * sin(delta) * cos(phi1), cos(delta) - sin(phi1) * sin(phi2));
        final lam2 = lam1 + dLam;

        final pt = OrthographicProjection.project(
          latDeg: phi2 * 180.0 / pi,
          lonDeg: lam2 * 180.0 / pi,
          cx: cx,
          cy: cy,
          radius: radius,
          centerLatDeg: centerLat,
          centerLonDeg: centerLon,
        );

        if (pt.isVisible) {
          polyPoints.add(Offset(pt.screenX, pt.screenY));
        }
      }

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

        final strokePaint = Paint()
          ..color = const Color(0xFFF59E0B).withValues(alpha: 0.35)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8
          ..isAntiAlias = true;

        for (int i = 0; i < polyPoints.length - 1; i += 2) {
          canvas.drawLine(polyPoints[i], polyPoints[i + 1], strokePaint);
        }
      }

      final centerPt = OrthographicProjection.project(
        latDeg: zone.latitude,
        lonDeg: zone.longitude,
        cx: cx,
        cy: cy,
        radius: radius,
        centerLatDeg: centerLat,
        centerLonDeg: centerLon,
      );

      if (centerPt.isVisible) {
        final centerPos = Offset(centerPt.screenX, centerPt.screenY);

        final crosshairPaint = Paint()
          ..color = const Color(0xFFF59E0B).withValues(alpha: 0.8)
          ..strokeWidth = 0.8
          ..isAntiAlias = true;

        canvas.drawLine(Offset(centerPos.dx - 4, centerPos.dy), Offset(centerPos.dx + 4, centerPos.dy), crosshairPaint);
        canvas.drawLine(Offset(centerPos.dx, centerPos.dy - 4), Offset(centerPos.dx, centerPos.dy + 4), crosshairPaint);

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

  /// Draw C4ISR Screen Perimeter Ticks & Corner Reticles
  void _drawPerimeterOverlays(Canvas canvas, Size size) {
    final reticlePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.2)
      ..strokeWidth = 0.8
      ..isAntiAlias = true;

    // Corner Crosshairs (+)
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
  bool shouldRepaint(covariant GlobePainter oldDelegate) {
    return oldDelegate.centerLat != centerLat ||
        oldDelegate.centerLon != centerLon ||
        oldDelegate.zoom != zoom ||
        oldDelegate.events != events ||
        oldDelegate.activeLayers != activeLayers ||
        oldDelegate.selectedEvent != selectedEvent ||
        oldDelegate.animationValue != animationValue ||
        oldDelegate.earthImage != earthImage;
  }
}
