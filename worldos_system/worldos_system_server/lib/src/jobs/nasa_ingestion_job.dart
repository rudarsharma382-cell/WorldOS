import 'package:serverpod/serverpod.dart';
import '../adapters/nasa_firms_adapter.dart';
import '../endpoints/event_endpoint.dart';

class NasaIngestionJob extends FutureCall {
  static const String jobName = 'NasaIngestionJob';

  @override
  Future<void> invoke(Session session, SerializableModel? object) async {
    session.log('Executing NasaIngestionJob for NASA FIRMS Thermal Anomalies...');

    try {
      final mapKey = session.serverpod.getPassword('nasaFirmsMapKey') ?? '476b6940af0159509d7f03cccf050723';
      final events = await NasaFirmsAdapter.fetchThermalAnomalies(session, mapKey: mapKey);

      int insertedCount = 0;
      for (final event in events) {
        await EventEndpoint().saveAndBroadcastEvent(session, event);
        insertedCount++;
      }

      session.log('NasaIngestionJob completed successfully. Ingested & broadcasted $insertedCount wildfire events.');
    } catch (e, st) {
      session.log('NasaIngestionJob error: $e\n$st', level: LogLevel.warning);
    } finally {
      // Self-schedule job to run automatically every 30 minutes
      session.serverpod.futureCallWithDelay(
        jobName,
        null,
        const Duration(minutes: 30),
      );
    }
  }
}
