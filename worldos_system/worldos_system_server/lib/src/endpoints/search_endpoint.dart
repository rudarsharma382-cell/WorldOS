import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:serverpod/serverpod.dart';

class SearchEndpoint extends Endpoint {
  /// Worldwide Universal Geocoding Search via Photon (OSM)
  Future<List<Map<String, dynamic>>> searchLocation(
    Session session,
    String query,
  ) async {
    if (query.trim().isEmpty) return [];

    try {
      final url = Uri.parse(
        'https://photon.komoot.io/api/?q=${Uri.encodeComponent(query.trim())}&limit=5',
      );

      final response = await http.get(url).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final features = data['features'] as List? ?? [];

        final List<Map<String, dynamic>> results = [];
        for (final item in features) {
          final props = item['properties'] ?? {};
          final geom = item['geometry'] ?? {};
          final coords = geom['coordinates'] as List? ?? [0.0, 0.0];

          final name = props['name']?.toString() ?? props['city']?.toString() ?? props['country']?.toString() ?? 'Location';
          final country = props['country']?.toString() ?? '';
          final city = props['city']?.toString() ?? props['state']?.toString() ?? '';

          results.add({
            'name': name,
            'city': city,
            'country': country,
            'latitude': (coords[1] as num).toDouble(),
            'longitude': (coords[0] as num).toDouble(),
            'displayName': '$name${city.isNotEmpty ? ", $city" : ""}${country.isNotEmpty ? ", $country" : ""}',
          });
        }
        return results;
      }
    } catch (e) {
      session.log('Photon geocoding error: $e');
    }

    return [];
  }
}
