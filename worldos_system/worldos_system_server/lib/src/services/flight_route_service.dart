import 'dart:convert';
import 'package:http/http.dart' as http;

class FlightRouteService {
  static final Map<String, Map<String, String>> _cache = {};

  static Future<Map<String, String>> resolveRoute({
    required String rawCallsign,
    required String fallbackCountry,
  }) async {
    final cleanCallsign = rawCallsign.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toUpperCase();
    if (cleanCallsign.isEmpty) {
      return {
        'origin': 'Origin Airspace ($fallbackCountry)',
        'destination': 'In-Flight En Route',
      };
    }

    if (_cache.containsKey(cleanCallsign)) {
      return _cache[cleanCallsign]!;
    }

    try {
      final url = Uri.parse('https://api.adsbdb.com/v0/callsign/$cleanCallsign');
      final response = await http.get(url).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final flightroute = data['response']?['flightroute'];

        if (flightroute != null && flightroute is Map) {
          final origin = flightroute['origin'];
          final destination = flightroute['destination'];

          String originStr = 'Origin Airspace ($fallbackCountry)';
          if (origin != null && origin is Map) {
            final name = origin['name']?.toString().trim() ?? '';
            final iata = origin['iata_code']?.toString().trim() ?? '';
            if (name.isNotEmpty) {
              originStr = iata.isNotEmpty ? '$name [$iata]' : name;
            }
          }

          String destStr = 'In-Flight En Route';
          if (destination != null && destination is Map) {
            final name = destination['name']?.toString().trim() ?? '';
            final iata = destination['iata_code']?.toString().trim() ?? '';
            if (name.isNotEmpty) {
              destStr = iata.isNotEmpty ? '$name [$iata]' : name;
            }
          }

          final route = {
            'origin': originStr,
            'destination': destStr,
          };
          _cache[cleanCallsign] = route;
          return route;
        }
      }
    } catch (_) {}

    final fallback = {
      'origin': 'Origin Airspace ($fallbackCountry)',
      'destination': 'In-Flight En Route',
    };
    _cache[cleanCallsign] = fallback;
    return fallback;
  }
}
