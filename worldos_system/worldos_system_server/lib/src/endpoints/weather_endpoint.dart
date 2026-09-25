import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:serverpod/serverpod.dart';

class WeatherEndpoint extends Endpoint {
  /// Fetches real-time atmospheric telemetry from Open-Meteo API
  Future<Map<String, dynamic>> getWeatherForecast(
    Session session,
    double lat,
    double lon,
  ) async {
    try {
      final url = Uri.parse(
        'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&current=temperature_2m,relative_humidity_2m,surface_pressure,wind_speed_10m,wind_direction_10m',
      );

      final response = await http.get(url).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final current = data['current'] as Map<String, dynamic>? ?? {};

        return {
          'temperature': (current['temperature_2m'] as num?)?.toDouble() ?? 20.0,
          'humidity': (current['relative_humidity_2m'] as num?)?.toDouble() ?? 50.0,
          'pressure': (current['surface_pressure'] as num?)?.toDouble() ?? 1013.25,
          'windSpeed': (current['wind_speed_10m'] as num?)?.toDouble() ?? 5.0,
          'windDirection': (current['wind_direction_10m'] as num?)?.toDouble() ?? 0.0,
          'status': 'SUCCESS',
        };
      }
    } catch (e) {
      session.log('Open-Meteo API fetch error: $e');
    }

    return {
      'temperature': 22.0,
      'humidity': 55.0,
      'pressure': 1013.25,
      'windSpeed': 8.5,
      'windDirection': 180.0,
      'status': 'FALLBACK',
    };
  }
}
