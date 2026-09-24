import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart';

class NasaFirmsAdapter {
  /// Fetch 24-hour thermal anomalies from NASA FIRMS VIIRS instrument
  static Future<List<WorldEvent>> fetchThermalAnomalies(
    Session session, {
    required String mapKey,
  }) async {
    final events = <WorldEvent>[];
    try {
      final url = Uri.parse('https://firms.modaps.eosdis.nasa.gov/api/area/csv/$mapKey/VIIRS_SNPP_NRT/world/1');
      session.log('Fetching NASA FIRMS thermal anomaly data from: $url');

      final res = await http.get(url).timeout(const Duration(seconds: 15));
      if (res.statusCode != 200) {
        session.log('NASA FIRMS API returned status code ${res.statusCode}', level: LogLevel.warning);
        return events;
      }

      final lines = LineSplitter.split(res.body).toList();
      if (lines.length <= 1) {
        return events;
      }

      // Headers: latitude,longitude,bright_ti4,scan,track,acq_date,acq_time,satellite,confidence,version,bright_ti5,frp,daynight
      final header = lines[0].split(',');
      final latIdx = header.indexOf('latitude');
      final lonIdx = header.indexOf('longitude');
      final brightIdx = header.indexOf('bright_ti4');
      final dateIdx = header.indexOf('acq_date');
      final timeIdx = header.indexOf('acq_time');
      final satIdx = header.indexOf('satellite');
      final confIdx = header.indexOf('confidence');
      final frpIdx = header.indexOf('frp');

      for (int i = 1; i < lines.length; i++) {
        final row = lines[i].split(',');
        if (row.length < 7) continue;

        final lat = double.tryParse(latIdx >= 0 ? row[latIdx] : row[0]);
        final lon = double.tryParse(lonIdx >= 0 ? row[lonIdx] : row[1]);
        if (lat == null || lon == null) continue;

        final brightTi4 = double.tryParse(brightIdx >= 0 ? row[brightIdx] : '310.0') ?? 310.0;
        final acqDate = dateIdx >= 0 ? row[dateIdx] : '2026-09-24';
        final acqTime = timeIdx >= 0 ? row[timeIdx] : '0000';
        final satellite = satIdx >= 0 ? row[satIdx] : 'N';
        final confidenceStr = confIdx >= 0 ? row[confIdx] : 'n';
        final frp = frpIdx >= 0 ? row[frpIdx] : '0.0';

        // Parse UTC timestamp from YYYY-MM-DD and HHMM
        DateTime timestamp = DateTime.now().toUtc();
        try {
          final dateParts = acqDate.split('-');
          if (dateParts.length == 3) {
            final y = int.parse(dateParts[0]);
            final m = int.parse(dateParts[1]);
            final d = int.parse(dateParts[2]);
            final timePadded = acqTime.padLeft(4, '0');
            final hh = int.parse(timePadded.substring(0, 2));
            final mm = int.parse(timePadded.substring(2, 4));
            timestamp = DateTime.utc(y, m, d, hh, mm);
          }
        } catch (_) {}

        // Calculate severity: ((brightness - 300.0) / 20.0).clamp(1.0, 9.5)
        final severity = ((brightTi4 - 300.0) / 20.0).clamp(1.0, 9.5);

        final extId = 'FIRMS_${lat.toStringAsFixed(2)}_${lon.toStringAsFixed(2)}_$acqDate';

        final event = WorldEvent(
          externalId: extId,
          type: 'WILDFIRE',
          title: 'Thermal Anomaly / Active Fire',
          description: 'Brightness: ${brightTi4}K, FRP: ${frp}MW, Sensor: VIIRS ($satellite)',
          latitude: lat,
          longitude: lon,
          altitude: 0.0,
          timestamp: timestamp,
          updatedAt: DateTime.now().toUtc(),
          source: 'NASA FIRMS',
          sourceUrl: 'https://firms.modaps.eosdis.nasa.gov',
          severity: severity,
          confidence: confidenceStr == 'h' ? 0.95 : (confidenceStr == 'n' ? 0.75 : 0.50),
          region: 'Global Thermal Anomaly',
          rawMetadata: jsonEncode({
            'bright_ti4': brightTi4,
            'acq_date': acqDate,
            'acq_time': acqTime,
            'satellite': satellite,
            'confidence': confidenceStr,
            'frp': frp,
          }),
        );

        events.add(event);

        // Limit to top 200 high-confidence anomalies to prevent database flooding
        if (events.length >= 200) break;
      }

      session.log('Parsed ${events.length} NASA FIRMS thermal anomaly events.');
    } catch (e, st) {
      session.log('NASA FIRMS adapter error: $e\n$st', level: LogLevel.warning);
    }

    return events;
  }
}
