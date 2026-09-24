import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart';
import '../endpoints/event_endpoint.dart';

import '../adapters/nasa_firms_adapter.dart';

class IngestionService {
  /// Run full ingestion pipeline for USGS, Space/ISS, Wildfire/EONET, NASA FIRMS
  static Future<void> runIngestionPipeline(Session session) async {
    await fetchUSGSEarthquakes(session);
    await fetchISSPosition(session);
    await fetchEONETDisasters(session);

    final mapKey = session.serverpod.getPassword('nasaFirmsMapKey') ?? '476b6940af0159509d7f03cccf050723';
    final firmsEvents = await NasaFirmsAdapter.fetchThermalAnomalies(session, mapKey: mapKey);
    for (final event in firmsEvents) {
      await EventEndpoint().saveAndBroadcastEvent(session, event);
    }
  }

  /// Ingest USGS Earthquakes
  static Future<void> fetchUSGSEarthquakes(Session session) async {
    try {
      final url = Uri.parse('https://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/all_hour.geojson');
      final res = await http.get(url).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final features = data['features'] as List? ?? [];

        for (final item in features) {
          final props = item['properties'] ?? {};
          final geom = item['geometry'] ?? {};
          final coords = geom['coordinates'] as List? ?? [0.0, 0.0, 0.0];

          final mag = (props['mag'] as num?)?.toDouble() ?? 1.0;
          final title = props['title']?.toString() ?? 'Earthquake';
          final extId = item['id']?.toString() ?? 'usgs_${DateTime.now().millisecondsSinceEpoch}';
          final timeMs = (props['time'] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch;
          final place = props['place']?.toString() ?? 'Unknown Location';

          final event = WorldEvent(
            externalId: extId,
            type: 'EARTHQUAKE',
            title: title,
            description: 'Seismic activity of M${mag.toStringAsFixed(1)} detected at depth ${coords.length > 2 ? coords[2] : 0}km. Location: $place.',
            longitude: (coords[0] as num).toDouble(),
            latitude: (coords[1] as num).toDouble(),
            altitude: coords.length > 2 ? (coords[2] as num).toDouble() : 0.0,
            timestamp: DateTime.fromMillisecondsSinceEpoch(timeMs),
            updatedAt: DateTime.now(),
            source: 'USGS',
            sourceUrl: props['url']?.toString() ?? 'https://earthquake.usgs.gov',
            severity: mag,
            confidence: 0.98,
            region: place,
            rawMetadata: jsonEncode(props),
          );

          await EventEndpoint().saveAndBroadcastEvent(session, event);
        }
      }
    } catch (e) {
      session.log('USGS Ingestion error: $e', level: LogLevel.warning);
    }
  }

  /// Ingest ISS Live Position
  static Future<void> fetchISSPosition(Session session) async {
    try {
      final url = Uri.parse('http://api.open-notify.org/iss-now.json');
      final res = await http.get(url).timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final pos = data['iss_position'] ?? {};
        final lat = double.tryParse(pos['latitude']?.toString() ?? '') ?? 0.0;
        final lon = double.tryParse(pos['longitude']?.toString() ?? '') ?? 0.0;
        final timeMs = ((data['timestamp'] as num?)?.toInt() ?? (DateTime.now().millisecondsSinceEpoch ~/ 1000)) * 1000;

        final event = WorldEvent(
          externalId: 'iss_live_station',
          type: 'SATELLITE',
          title: 'ISS — International Space Station',
          description: 'Orbital velocity ~27,600 km/h at altitude ~420 km. Live telemetry overhead.',
          latitude: lat,
          longitude: lon,
          altitude: 420.0,
          timestamp: DateTime.fromMillisecondsSinceEpoch(timeMs),
          updatedAt: DateTime.now(),
          source: 'Open-Notify / NASA',
          sourceUrl: 'http://open-notify.org',
          severity: 5.0,
          confidence: 1.0,
          region: 'Orbital Pass',
          rawMetadata: jsonEncode(data),
        );

        await EventEndpoint().saveAndBroadcastEvent(session, event);
      }
    } catch (e) {
      session.log('ISS Ingestion error: $e', level: LogLevel.warning);
    }
  }

  /// Ingest NASA EONET Disasters (Wildfires, Storms, Volcanoes)
  static Future<void> fetchEONETDisasters(Session session) async {
    try {
      final url = Uri.parse('https://eonet.gsfc.nasa.gov/api/v3/events?limit=20');
      final res = await http.get(url).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final events = data['events'] as List? ?? [];

        for (final item in events) {
          final categories = item['categories'] as List? ?? [];
          final catTitle = categories.isNotEmpty ? categories[0]['title']?.toString().toUpperCase() : 'OTHER';
          final title = item['title']?.toString() ?? 'Natural Disaster';
          final extId = item['id']?.toString() ?? 'eonet_${DateTime.now().millisecondsSinceEpoch}';

          String type = 'OTHER';
          if (catTitle != null) {
            if (catTitle.contains('FIRE') || catTitle.contains('WILDFIRE')) type = 'WILDFIRE';
            else if (catTitle.contains('STORM') || catTitle.contains('SEVERE')) type = 'STORM';
            else if (catTitle.contains('VOLCANO')) type = 'VOLCANO';
            else if (catTitle.contains('FLOOD')) type = 'FLOOD';
          }

          final geometry = item['geometry'] as List? ?? [];
          if (geometry.isNotEmpty) {
            final firstGeom = geometry[0];
            final coords = firstGeom['coordinates'] as List? ?? [0.0, 0.0];
            final dateStr = firstGeom['date']?.toString();
            final timestamp = dateStr != null ? DateTime.tryParse(dateStr) ?? DateTime.now() : DateTime.now();

            final lon = (coords[0] as num).toDouble();
            final lat = (coords[1] as num).toDouble();

            final event = WorldEvent(
              externalId: extId,
              type: type,
              title: title,
              description: 'NASA Earth Observatory (EONET) natural event alert: $catTitle.',
              longitude: lon,
              latitude: lat,
              timestamp: timestamp,
              updatedAt: DateTime.now(),
              source: 'NASA EONET',
              sourceUrl: item['link']?.toString() ?? 'https://eonet.gsfc.nasa.gov',
              severity: 6.5,
              confidence: 0.95,
              region: 'Global Emergency',
              rawMetadata: jsonEncode(item),
            );

            await EventEndpoint().saveAndBroadcastEvent(session, event);
          }
        }
      }
    } catch (e) {
      session.log('EONET Ingestion error: $e', level: LogLevel.warning);
    }
  }
}
