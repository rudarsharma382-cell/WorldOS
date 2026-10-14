import 'package:serverpod/serverpod.dart';
import '../services/hf_ai_service.dart';

class IntelligenceEndpoint extends Endpoint {
  Future<String> askWorldOS(
    Session session,
    String query, [
    String? telemetryContext,
  ]) async {
    return await HfAiService.generateBriefing(
      session: session,
      userPrompt: query,
      liveTelemetryContext: telemetryContext,
    );
  }
}
