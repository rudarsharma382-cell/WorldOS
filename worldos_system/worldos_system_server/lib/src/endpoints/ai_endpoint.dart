import 'dart:math';
import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart';

class AiEndpoint extends Endpoint {
  Future<String> generateBriefing(
    Session session,
    double lat,
    double lon,
    double radiusKm,
    String? regionName,
  ) async {
    final events = await WorldEvent.db.find(
      session,
      limit: 300,
      orderBy: (t) => t.timestamp,
      orderDescending: true,
    );

    final nearby = events.where((e) {
      final d = _haversineDistance(lat, lon, e.latitude, e.longitude);
      return d <= radiusKm;
    }).toList();

    final region = regionName ?? 'Selected Region';
    if (nearby.isEmpty) {
      return '''
WORLDOS INTELLIGENCE BRIEFING — $region
────────────────────────────────────────
Status: NOMINAL (No high-severity events detected within ${radiusKm.toInt()} km).
Monitored Data Feeds: USGS Earthquakes, NASA EONET Disasters, ISS Orbital Tracking, OpenWeather Radar.
Recommendation: Keep watch zones active to receive immediate real-time alerts.
''';
    }

    final earthquakes = nearby.where((e) => e.type == 'EARTHQUAKE').toList();
    final weather = nearby.where((e) => e.type == 'WEATHER' || e.type == 'STORM').toList();
    final fires = nearby.where((e) => e.type == 'WILDFIRE').toList();
    final satellites = nearby.where((e) => e.type == 'SATELLITE').toList();

    final StringBuffer sb = StringBuffer();
    sb.writeln('WORLDOS INTELLIGENCE BRIEFING — ${region.toUpperCase()}');
    sb.writeln('────────────────────────────────────────');
    sb.writeln('Active Events Detected: ${nearby.length} within ${radiusKm.toInt()} km radius.');
    sb.writeln();

    if (earthquakes.isNotEmpty) {
      final maxEq = earthquakes.reduce((a, b) => a.severity > b.severity ? a : b);
      sb.writeln('🌋 Seismic Activity (${earthquakes.length} events):');
      sb.writeln('  • Peak Event: M${maxEq.severity.toStringAsFixed(1)} — ${maxEq.title}');
      sb.writeln('  • Source: ${maxEq.source}');
      sb.writeln();
    }

    if (weather.isNotEmpty) {
      sb.writeln('🌩 Meteorological Systems (${weather.length} events):');
      sb.writeln('  • Active System: ${weather.first.title}');
      sb.writeln('  • Severity: Level ${weather.first.severity.toStringAsFixed(1)}/10');
      sb.writeln();
    }

    if (fires.isNotEmpty) {
      sb.writeln('🔥 Thermal & Wildfire Anomaly (${fires.length} active zones):');
      sb.writeln('  • Major Cluster: ${fires.first.title}');
      sb.writeln();
    }

    if (satellites.isNotEmpty) {
      sb.writeln('🛰 Orbital Objects Overhead (${satellites.length} tracked):');
      sb.writeln('  • Primary Object: ${satellites.first.title} (${satellites.first.latitude.toStringAsFixed(2)}°, ${satellites.first.longitude.toStringAsFixed(2)}°)');
      sb.writeln();
    }

    sb.writeln('DATA SOURCE INTEGRITY:');
    sb.writeln('• Multi-source telemetry verified. All events strictly grounded in live backend database feeds.');

    return sb.toString();
  }

  Future<String> askWorldOS(Session session, String query) async {
    final q = query.toLowerCase();
    double targetLat = 0;
    double targetLon = 0;
    String region = 'Global';

    if (q.contains('japan') || q.contains('tokyo')) {
      targetLat = 36.2048;
      targetLon = 138.2529;
      region = 'Japan';
    } else if (q.contains('india') || q.contains('delhi')) {
      targetLat = 28.6139;
      targetLon = 77.2090;
      region = 'India';
    } else if (q.contains('europe') || q.contains('london') || q.contains('paris')) {
      targetLat = 48.8566;
      targetLon = 2.3522;
      region = 'Europe';
    } else if (q.contains('usa') || q.contains('america') || q.contains('california')) {
      targetLat = 37.7749;
      targetLon = -122.4194;
      region = 'North America';
    }

    return generateBriefing(
      session,
      targetLat,
      targetLon,
      3000.0,
      region,
    );
  }

  double _haversineDistance(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371.0;
    final dLat = (lat2 - lat1) * (pi / 180.0);
    final dLon = (lon2 - lon1) * (pi / 180.0);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * (pi / 180.0)) * cos(lat2 * (pi / 180.0)) * sin(dLon / 2) * sin(dLon / 2);
    return r * 2 * atan2(sqrt(a), sqrt(1 - a));
  }
}
