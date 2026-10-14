import 'dart:convert';
import 'package:http/http.dart' as http;

class TacticalNavigationService {
  // Cleans phrases like "fly me to...", "go to...", "where is...", "take me to..."
  static String extractTargetLocation(String input) {
    String clean = input.trim();
    final prefixes = [
      RegExp(r'^(?:fly\s+(?:me\s+)?to\s+)', caseSensitive: false),
      RegExp(r'^(?:take\s+(?:me\s+)?to\s+)', caseSensitive: false),
      RegExp(r'^(?:navigate\s+to\s+)', caseSensitive: false),
      RegExp(r'^(?:go\s+to\s+)', caseSensitive: false),
      RegExp(r'^(?:locate\s+)', caseSensitive: false),
      RegExp(r'^(?:where\s+is\s+)', caseSensitive: false),
    ];

    for (final pattern in prefixes) {
      if (pattern.hasMatch(clean)) {
        clean = clean.replaceFirst(pattern, '').trim();
        break;
      }
    }
    // Remove trailing question marks or punctuation
    return clean.replaceAll(RegExp(r'[?!.]+$'), '').trim();
  }

  // Resolves target via Photon / OpenStreetMap API (Instant, No API Key Required)
  static Future<Map<String, dynamic>?> resolveCoordinates(String query) async {
    final target = extractTargetLocation(query);
    if (target.isEmpty) return null;

    try {
      final url = Uri.parse('https://photon.komoot.io/api/?q=${Uri.encodeComponent(target)}&limit=1');
      final res = await http.get(url).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final data = jsonDecode(utf8.decode(res.bodyBytes));
        final features = data['features'] as List?;
        if (features != null && features.isNotEmpty) {
          final first = features[0];
          final geometry = first['geometry'];
          final props = first['properties'];

          final double lon = (geometry['coordinates'][0] as num).toDouble();
          final double lat = (geometry['coordinates'][1] as num).toDouble();

          final String name = props['name'] ?? target;
          final String country = props['country'] ?? '';
          final String displayName = country.isNotEmpty ? '$name, $country' : name;

          // Determine optimal camera altitude based on feature type
          double zoomLevel = 6.0;
          final osmKey = props['osm_key'];
          final osmValue = props['osm_value'];
          if (osmValue == 'country') {
            zoomLevel = 4.0;
          } else if (osmValue == 'city') {
            zoomLevel = 10.5;
          } else if (osmValue == 'building' || osmKey == 'amenity') {
            zoomLevel = 15.0;
          }

          return {
            'displayName': displayName,
            'lat': lat,
            'lon': lon,
            'zoom': zoomLevel,
          };
        }
      }
    } catch (_) {}
    return null;
  }
}
