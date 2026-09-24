import 'package:flutter/material.dart';

/// Data marker schema for 3D geospatial telemetry point on WorldOSGlobe3D
class GlobeMarker {
  final double lat;
  final double lng;
  final String label;
  final double severity;
  final String type;
  final dynamic data;

  const GlobeMarker({
    required this.lat,
    required this.lng,
    required this.label,
    this.severity = 1.0,
    required this.type,
    this.data,
  });

  Color get accentColor {
    switch (type.toUpperCase()) {
      case 'EARTHQUAKE':
        return const Color(0xFFEF4444);
      case 'WILDFIRE':
      case 'THERMAL':
        return const Color(0xFFF59E0B);
      case 'SATELLITE':
      case 'SPACE':
        return const Color(0xFFA855F7);
      case 'STORM':
      case 'WEATHER':
        return const Color(0xFF38BDF8);
      default:
        return const Color(0xFF10B981);
    }
  }
}

/// Configuration schema for Aceternity UI 3D Globe rendering engine
class GlobeConfig {
  final Color atmosphereColor;
  final double atmosphereIntensity;
  final bool autoRotate;
  final double autoRotateSpeed;
  final Color baseColor;
  final Color landDotColor;
  final Color oceanDotColor;
  final int dotCount;

  const GlobeConfig({
    this.atmosphereColor = const Color(0xFF4DA6FF),
    this.atmosphereIntensity = 0.8,
    this.autoRotate = true,
    this.autoRotateSpeed = 0.3,
    this.baseColor = const Color(0xFF040711),
    this.landDotColor = const Color(0xFF38BDF8),
    this.oceanDotColor = const Color(0xFF1E2D4A),
    this.dotCount = 1800,
  });
}
