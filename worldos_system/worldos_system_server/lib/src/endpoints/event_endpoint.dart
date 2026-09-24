import 'dart:math';
import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart';

class EventEndpoint extends Endpoint {
  static const String liveEventChannel = 'worldos_live_events';

  Future<List<WorldEvent>> getActiveEvents(
    Session session,
    String? typeFilter,
    String? searchQuery,
    int limit,
  ) async {
    List<WorldEvent> events = await WorldEvent.db.find(
      session,
      limit: limit > 0 ? limit : 200,
      orderBy: (t) => t.timestamp,
      orderDescending: true,
    );

    if (typeFilter != null && typeFilter.isNotEmpty && typeFilter.toUpperCase() != 'ALL') {
      final tf = typeFilter.toUpperCase();
      events = events.where((e) => e.type.toUpperCase() == tf).toList();
    }

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final q = searchQuery.toLowerCase().trim();
      events = events.where((e) {
        final title = e.title.toLowerCase();
        final desc = (e.description ?? '').toLowerCase();
        final country = (e.country ?? '').toLowerCase();
        final type = e.type.toLowerCase();
        return title.contains(q) || desc.contains(q) || country.contains(q) || type.contains(q);
      }).toList();
    }

    return events;
  }

  Future<List<WorldEvent>> getEventsNearLocation(
    Session session,
    double lat,
    double lon,
    double radiusKm,
  ) async {
    final allEvents = await WorldEvent.db.find(
      session,
      limit: 500,
      orderBy: (t) => t.timestamp,
      orderDescending: true,
    );

    return allEvents.where((e) {
      final d = _haversineDistance(lat, lon, e.latitude, e.longitude);
      return d <= radiusKm;
    }).toList();
  }

  Future<WorldEvent> saveAndBroadcastEvent(Session session, WorldEvent event) async {
    final existing = await WorldEvent.db.findFirstRow(
      session,
      where: (t) => t.externalId.equals(event.externalId),
    );

    WorldEvent saved;
    if (existing != null) {
      event.id = existing.id;
      saved = await WorldEvent.db.updateRow(session, event);
    } else {
      saved = await WorldEvent.db.insertRow(session, event);
    }

    await session.messages.postMessage(liveEventChannel, saved);
    return saved;
  }

  @override
  Future<void> streamOpened(StreamingSession session) async {
    session.messages.addListener(liveEventChannel, (message) {
      if (message is WorldEvent) {
        sendStreamMessage(session, message);
      }
    });
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
