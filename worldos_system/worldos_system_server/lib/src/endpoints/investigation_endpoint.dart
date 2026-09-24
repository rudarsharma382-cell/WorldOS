import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart';

class InvestigationEndpoint extends Endpoint {
  Future<Investigation> createInvestigation(Session session, Investigation investigation) async {
    return await Investigation.db.insertRow(session, investigation);
  }

  Future<List<Investigation>> getInvestigations(Session session) async {
    return await Investigation.db.find(session, orderBy: (t) => t.createdAt, orderDescending: true);
  }
}
