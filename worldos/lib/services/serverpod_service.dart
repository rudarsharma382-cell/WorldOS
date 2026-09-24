import 'dart:async';
import 'dart:math';
import '../models/watch_zone.dart';
import '../models/investigation.dart';
import 'ingestion_service.dart';

class ServerpodService {
  static final ServerpodService _instance = ServerpodService._internal();
  factory ServerpodService() => _instance;
  ServerpodService._internal();

  final IngestionService ingestionService = IngestionService();
  final bool _isConnected = true;
  bool get isConnected => _isConnected;

  final List<WatchZone> _watchZones = [];
  List<WatchZone> get watchZones => List.unmodifiable(_watchZones);

  final List<Investigation> _investigations = [];
  List<Investigation> get investigations => List.unmodifiable(_investigations);

  void initialize() {
    ingestionService.initialize();
    
    // Seed default Watch Zones
    _watchZones.add(WatchZone(
      id: 'wz_japan',
      name: 'Japan Seismic Watch Zone',
      latitude: 36.2048,
      longitude: 138.2529,
      radiusKm: 1000.0,
      trackedTypes: ['EARTHQUAKE', 'WEATHER', 'STORM'],
      createdAt: DateTime.now(),
    ));

    _watchZones.add(WatchZone(
      id: 'wz_india',
      name: 'India Space & Weather Zone',
      latitude: 28.6139,
      longitude: 77.2090,
      radiusKm: 1500.0,
      trackedTypes: ['SATELLITE', 'WEATHER', 'STORM'],
      createdAt: DateTime.now(),
    ));
  }

  void dispose() {
    ingestionService.dispose();
  }

  /// Create a new watch zone
  void addWatchZone(WatchZone zone) {
    _watchZones.insert(0, zone);
  }

  /// Save an investigation session
  void saveInvestigation(Investigation inv) {
    _investigations.insert(0, inv);
  }

  /// Grounded AI briefing generator for specified lat, lon, radius
  Future<String> fetchAiBriefing({
    required double latitude,
    required double longitude,
    required double radiusKm,
    String? regionName,
  }) async {
    final allEvents = ingestionService.events;
    
    // Filter events inside spatial radius
    final nearby = allEvents.where((e) {
      final d = _haversineDistance(latitude, longitude, e.latitude, e.longitude);
      return d <= radiusKm;
    }).toList();

    final region = regionName ?? _determineRegionName(latitude, longitude);

    if (nearby.isEmpty) {
      return '''
WORLDOS INTELLIGENCE BRIEFING — ${region.toUpperCase()}
────────────────────────────────────────
Status: NOMINAL (Zero high-risk anomalies detected within ${radiusKm.toInt()} km).
Telemetry Feeds: USGS Earthquakes, NASA EONET Disasters, ISS Orbital Tracking, OpenWeather Radar.
Recommendation: Active watch zones monitoring real-time telemetry.
''';
    }

    final earthquakes = nearby.where((e) => e.type == 'EARTHQUAKE').toList();
    final weather = nearby.where((e) => e.type == 'WEATHER' || e.type == 'STORM').toList();
    final fires = nearby.where((e) => e.type == 'WILDFIRE').toList();
    final satellites = nearby.where((e) => e.type == 'SATELLITE').toList();

    final sb = StringBuffer();
    sb.writeln('WORLDOS INTELLIGENCE BRIEFING — ${region.toUpperCase()}');
    sb.writeln('────────────────────────────────────────');
    sb.writeln('Total Active Events: ${nearby.length} detected within ${radiusKm.toInt()} km radius.');
    sb.writeln();

    if (earthquakes.isNotEmpty) {
      final maxEq = earthquakes.reduce((a, b) => a.severity > b.severity ? a : b);
      sb.writeln('🌋 Seismic Activity (${earthquakes.length} events):');
      sb.writeln('  • Peak Intensity: M${maxEq.severity.toStringAsFixed(1)} — ${maxEq.title}');
      sb.writeln('  • Source: ${maxEq.source} (${maxEq.timeAgo})');
      sb.writeln();
    }

    if (weather.isNotEmpty) {
      sb.writeln('🌩 Meteorological Alert (${weather.length} systems):');
      sb.writeln('  • System: ${weather.first.title}');
      sb.writeln('  • Severity Rating: ${weather.first.severity.toStringAsFixed(1)}/10');
      sb.writeln();
    }

    if (fires.isNotEmpty) {
      sb.writeln('🔥 Thermal Anomalies (${fires.length} active zones):');
      sb.writeln('  • Primary Hotspot: ${fires.first.title}');
      sb.writeln();
    }

    if (satellites.isNotEmpty) {
      sb.writeln('🛰 Space Objects (${satellites.length} overhead):');
      sb.writeln('  • Satellite: ${satellites.first.title} (${satellites.first.latitude.toStringAsFixed(2)}°, ${satellites.first.longitude.toStringAsFixed(2)}°)');
      sb.writeln();
    }

    sb.writeln('SYSTEM INTEGRITY & TRANSPARENCY:');
    sb.writeln('• Verified multi-source ingestion. Telemetry strictly grounded in live database state.');

    return sb.toString();
  }

  /// Process natural language exploration query
  Future<String> askWorldOS(String query) async {
    final q = query.toLowerCase();
    double lat = 0.0;
    double lon = 0.0;
    String region = 'Global';

    if (q.contains('japan') || q.contains('tokyo')) {
      lat = 36.2048; lon = 138.2529; region = 'Japan';
    } else if (q.contains('india') || q.contains('delhi')) {
      lat = 28.6139; lon = 77.2090; region = 'India';
    } else if (q.contains('europe') || q.contains('london') || q.contains('paris')) {
      lat = 48.8566; lon = 2.3522; region = 'Europe';
    } else if (q.contains('california') || q.contains('usa') || q.contains('america')) {
      lat = 37.7749; lon = -122.4194; region = 'North America';
    }

    return fetchAiBriefing(latitude: lat, longitude: lon, radiusKm: 3000.0, regionName: region);
  }

  String _determineRegionName(double lat, double lon) {
    if (lat > 20 && lat < 50 && lon > 120 && lon < 150) return 'Japan / East Asia';
    if (lat > 5 && lat < 35 && lon > 65 && lon < 95) return 'India / South Asia';
    if (lat > 35 && lat < 70 && lon > -15 && lon < 40) return 'Europe';
    if (lat > 20 && lat < 60 && lon > -130 && lon < -60) return 'North America';
    if (lat < 10 && lat > -60 && lon > -90 && lon < -30) return 'South America';
    if (lat < -10 && lon > 110 && lon < 160) return 'Australia';
    return 'Coordinates (${lat.toStringAsFixed(1)}°, ${lon.toStringAsFixed(1)}°)';
  }

  double _haversineDistance(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371.0;
    final dLat2 = (lat2 - lat1) * (pi / 180.0);
    final dLon2 = (lon2 - lon1) * (pi / 180.0);
    final a = (sin(dLat2 / 2) * sin(dLat2 / 2)) +
        cos(lat1 * (pi / 180.0)) * cos(lat2 * (pi / 180.0)) * (sin(dLon2 / 2) * sin(dLon2 / 2));
    return r * 2 * atan2(sqrt(a), sqrt(1 - a));
  }
}
