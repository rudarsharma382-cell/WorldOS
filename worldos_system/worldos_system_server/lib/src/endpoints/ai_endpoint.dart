import 'dart:math';
import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart';
import '../services/hf_ai_service.dart';

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
    final telemetry = nearby.map((e) => '- ${e.title} (Severity: ${e.severity}, Source: ${e.source})').join('\n');

    return await HfAiService.generateBriefing(
      session: session,
      userPrompt: 'Generate intelligence briefing for $region',
      liveTelemetryContext: telemetry.isNotEmpty ? telemetry : 'Region status nominal.',
    );
  }

  Future<String> askWorldOS(Session session, String query, [String? telemetryContext]) async {
    return await HfAiService.generateBriefing(
      session: session,
      userPrompt: query,
      liveTelemetryContext: telemetryContext,
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
