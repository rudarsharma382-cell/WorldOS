import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart';
import '../endpoints/event_endpoint.dart';

class FlightIngestionJob extends FutureCall {
  static const String jobName = 'FlightIngestionJob';

  @override
  Future<void> invoke(Session session, SerializableModel? object) async {
    session.log('Executing FlightIngestionJob for OpenSky Live Flights...');

    try {
      final url = Uri.parse('https://opensky-network.org/api/states/all');
      final res = await http.get(url).timeout(const Duration(seconds: 12));

      int insertedCount = 0;

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final states = data['states'] as List? ?? [];

        // Ingest up to 1,200 active airborne flights for God's Eye tactical density
        final processStates = states.take(1200).toList();

        for (final item in processStates) {
          if (item is! List || item.length < 11) continue;

          final icao24 = item[0]?.toString() ?? '';
          final rawCallsign = item[1]?.toString() ?? '';
          final callsign = rawCallsign.trim();
          final originCountry = item[2]?.toString() ?? 'International';
          final lon = (item[5] as num?)?.toDouble();
          final lat = (item[6] as num?)?.toDouble();
          final baroAltitude = (item[7] as num?)?.toDouble();
          final onGround = item[8] == true;
          final velocity = (item[9] as num?)?.toDouble();
          final trueTrack = (item[10] as num?)?.toDouble() ?? 0.0;

          if (lat == null || lon == null || onGround) continue;

          final flightTitle = callsign.isNotEmpty ? 'Flight $callsign ($originCountry)' : 'Aircraft $icao24 ($originCountry)';
          final extId = 'flight_${icao24}_${callsign.isNotEmpty ? callsign : "unnamed"}';

          final event = WorldEvent(
            externalId: extId,
            type: 'AIRCRAFT',
            title: flightTitle,
            description: 'Live commercial aircraft telemetry. Callsign: ${callsign.isNotEmpty ? callsign : icao24}, Airspeed: ${velocity != null ? velocity.toStringAsFixed(0) : "N/A"} m/s, Altitude: ${baroAltitude != null ? baroAltitude.toStringAsFixed(0) : "N/A"} m, Heading: ${trueTrack.toStringAsFixed(0)}°.',
            latitude: lat,
            longitude: lon,
            altitude: baroAltitude != null ? baroAltitude / 1000.0 : 10.0,
            timestamp: DateTime.now(),
            updatedAt: DateTime.now(),
            source: 'OpenSky Network',
            sourceUrl: 'https://opensky-network.org',
            severity: velocity != null ? (velocity / 40.0).clamp(1.0, 9.9) : 4.0,
            confidence: 0.99,
            region: originCountry,
            rawMetadata: jsonEncode({
              'callsign': callsign,
              'icao24': icao24,
              'origin_country': originCountry,
              'velocity': velocity,
              'heading': trueTrack,
              'altitude': baroAltitude,
            }),
          );

          await EventEndpoint().saveAndBroadcastEvent(session, event);
          insertedCount++;
        }
      }

      session.log('FlightIngestionJob completed successfully. Broadcasted $insertedCount commercial flights.');
    } catch (e, st) {
      session.log('FlightIngestionJob error: $e\n$st', level: LogLevel.warning);
    } finally {
      // Self-schedule job every 60 seconds
      session.serverpod.futureCallWithDelay(
        jobName,
        null,
        const Duration(seconds: 60),
      );
    }
  }
}
