import 'dart:convert';
import 'package:http/http.dart' as http;

class FlightRouteInfo {
  final String originTitle;
  final String destinationTitle;
  final String? airlineName;

  FlightRouteInfo({
    required this.originTitle,
    required this.destinationTitle,
    this.airlineName,
  });
}

class FlightRouteService {
  static final Map<String, FlightRouteInfo> _cache = {};

  /// Resolve origin and destination route for a given flight callsign
  static Future<FlightRouteInfo> resolveFlightRoute({
    required String rawCallsign,
    required String fallbackCountry,
  }) async {
    final cleanCallsign = rawCallsign.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toUpperCase();
    if (cleanCallsign.isEmpty) {
      return FlightRouteInfo(
        originTitle: 'Origin Airspace ($fallbackCountry)',
        destinationTitle: 'In-Flight En Route',
      );
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
          final airline = flightroute['airline'];

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

          String? airlineStr;
          if (airline != null && airline is Map) {
            airlineStr = airline['name']?.toString().trim();
          }

          final info = FlightRouteInfo(
            originTitle: originStr,
            destinationTitle: destStr,
            airlineName: airlineStr,
          );

          _cache[cleanCallsign] = info;
          return info;
        }
      }
    } catch (_) {
      // Gracefully fall back to regional airspace placeholder
    }

    final fallbackInfo = FlightRouteInfo(
      originTitle: 'Origin Airspace ($fallbackCountry)',
      destinationTitle: 'In-Flight En Route',
    );
    _cache[cleanCallsign] = fallbackInfo;
    return fallbackInfo;
  }
}
