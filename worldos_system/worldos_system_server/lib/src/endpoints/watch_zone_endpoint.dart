import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart';

class WatchZoneEndpoint extends Endpoint {
  Future<WatchZone> createWatchZone(Session session, WatchZone watchZone) async {
    return await WatchZone.db.insertRow(session, watchZone);
  }

  Future<List<WatchZone>> getWatchZones(Session session) async {
    return await WatchZone.db.find(session, orderBy: (t) => t.createdAt, orderDescending: true);
  }
}
