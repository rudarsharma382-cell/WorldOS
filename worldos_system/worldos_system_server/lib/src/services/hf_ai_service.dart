import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:serverpod/serverpod.dart';

class HfAiService {
  static const String _model = 'Qwen/Qwen2.5-72B-Instruct';

  // Primary router endpoint and legacy fallback endpoint
  static const List<String> _endpoints = [
    'https://router.huggingface.co/hf-inference/v1/chat/completions',
    'https://api-inference.huggingface.co/models/Qwen/Qwen2.5-72B-Instruct/v1/chat/completions',
  ];

  static Future<String> generateBriefing({
    required Session session,
    required String userPrompt,
    int? activeFlightCount,
    String? liveTelemetryContext,
  }) async {
    final token = session.serverpod.getPassword('hfApiToken') ??
        Platform.environment['HF_TOKEN'] ??
        const String.fromEnvironment('HF_TOKEN', defaultValue: '');

    if (token.isEmpty) {
      session.log('HF API Token is not configured in passwords.yaml or HF_TOKEN env.');
      return 'WorldOS AI Service: Hugging Face API token is not configured on the server. Please define hfApiToken in config/passwords.yaml or set HF_TOKEN environment variable.';
    }

    final systemPrompt = '''
You are WorldOS Tactical AI, a command-grade geospatial and strategic intelligence assistant.
Provide clear, structured, and factual answers to the operator's prompt.
If asked about a location, nation, or city, provide its coordinates, terrain, administrative capital, and strategic context.
Never hallucinate. Keep your tone crisp and analytical.
${liveTelemetryContext != null ? 'Active System Telemetry:\n$liveTelemetryContext' : ''}
''';

    for (final endpoint in _endpoints) {
      try {
        session.log('Attempting HF inference via: $endpoint');

        final response = await http.post(
          Uri.parse(endpoint),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'model': _model,
            'messages': [
              {'role': 'system', 'content': systemPrompt},
              {'role': 'user', 'content': userPrompt},
            ],
            'max_tokens': 1024,
            'temperature': 0.4,
          }),
        ).timeout(const Duration(seconds: 25));

        session.log('HF Response Code: ${response.statusCode}');

        if (response.statusCode == 200) {
          final decoded = jsonDecode(utf8.decode(response.bodyBytes));
          if (decoded['choices'] != null && (decoded['choices'] as List).isNotEmpty) {
            return decoded['choices'][0]['message']['content'] as String;
          }
        } else if (response.statusCode == 503) {
          // Model loading / cold start
          session.log('HF 503: Model is warming up on cluster. Trying fallback...');
          continue;
        } else {
          session.log(
            'HF HTTP Error ${response.statusCode}:${response.body}',
            level: LogLevel.error,
          );
        }
      } catch (e, st) {
        session.log('HF connection failed on $endpoint:$e', level: LogLevel.error, stackTrace: st);
      }
    }

    // Secondary fallback: Fast backup model if 72B is temporarily queued on free tier
    try {
      session.log('Attempting secondary fallback model (Qwen/Qwen2.5-7B-Instruct)...');
      final fallbackResp = await http.post(
        Uri.parse('https://router.huggingface.co/hf-inference/v1/chat/completions'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': 'Qwen/Qwen2.5-7B-Instruct',
          'messages': [
            {'role': 'system', 'content': systemPrompt},
            {'role': 'user', 'content': userPrompt},
          ],
          'max_tokens': 800,
        }),
      ).timeout(const Duration(seconds: 15));

      if (fallbackResp.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(fallbackResp.bodyBytes));
        if (decoded['choices'] != null && (decoded['choices'] as List).isNotEmpty) {
          return decoded['choices'][0]['message']['content'] as String;
        }
      }
    } catch (e) {
      session.log('Secondary fallback failed: $e', level: LogLevel.error);
    }

    return 'Operational notice: Hugging Face inference gateway timed out or rejected authorization. Verify token permissions at huggingface.co/settings/tokens.';
  }
}
