import 'dart:math';

class ProjectedPoint {
  final double screenX;
  final double screenY;
  final double z; // Transformed Z depth (> 0 means facing viewer)
  final bool isVisible;

  ProjectedPoint({
    required this.screenX,
    required this.screenY,
    required this.z,
    required this.isVisible,
  });
}

class OrthographicProjection {
  /// Converts lat, lon (in degrees) to 2D screen coordinates given center (cx, cy), radius, azimuth, elevation.
  static ProjectedPoint project({
    required double latDeg,
    required double lonDeg,
    required double cx,
    required double cy,
    required double radius,
    required double centerLatDeg,
    required double centerLonDeg,
  }) {
    final lat = latDeg * (pi / 180.0);
    final lon = lonDeg * (pi / 180.0);
    final cLat = centerLatDeg * (pi / 180.0);
    final cLon = centerLonDeg * (pi / 180.0);

    final dLon = lon - cLon;

    final xRot = cos(lat) * sin(dLon);
    final yRot = sin(lat) * cos(cLat) - cos(lat) * sin(cLat) * cos(dLon);
    final zRot = sin(lat) * sin(cLat) + cos(lat) * cos(cLat) * cos(dLon);

    final screenX = cx + xRot * radius;
    final screenY = cy - yRot * radius;

    return ProjectedPoint(
      screenX: screenX,
      screenY: screenY,
      z: zRot,
      isVisible: zRot > 0.0,
    );
  }

  /// Convert screen click (tapX, tapY) back to lat, lon on the globe surface if inside radius
  static Point<double>? unproject({
    required double tapX,
    required double tapY,
    required double cx,
    required double cy,
    required double radius,
    required double centerLatDeg,
    required double centerLonDeg,
  }) {
    final dx = (tapX - cx) / radius;
    final dy = (cy - tapY) / radius;

    final rho = sqrt(dx * dx + dy * dy);
    if (rho > 1.0) return null; // Outside globe sphere

    final c = asin(rho);
    final cLat = centerLatDeg * (pi / 180.0);
    final cLon = centerLonDeg * (pi / 180.0);

    final latRad = asin(cos(c) * sin(cLat) + (dy * sin(c) * cos(cLat) / rho));
    final lonRad = cLon + atan2(dx * sin(c), (rho * cos(cLat) * cos(c) - dy * sin(cLat) * sin(c)));

    return Point(
      latRad * (180.0 / pi),
      lonRad * (180.0 / pi),
    );
  }
}
