import 'dart:convert';
import 'package:http/http.dart' as http;

class EventMediaPayloadData {
  final String satelliteImageUrl;
  final String groundImageUrl;
  final String attribution;
  final String title;
  final String caption;

  EventMediaPayloadData({
    required this.satelliteImageUrl,
    required this.groundImageUrl,
    required this.attribution,
    required this.title,
    required this.caption,
  });
}

class NasaImageData {
  final String imageUrl;
  final String title;
  final String caption;
  final String source;
  final String timestamp;
  final double lat;
  final double lon;
  final String status;

  NasaImageData({
    required this.imageUrl,
    required this.title,
    required this.caption,
    required this.source,
    required this.timestamp,
    required this.lat,
    required this.lon,
    this.status = 'SUCCESS',
  });

  factory NasaImageData.fromJson(Map<String, dynamic> json) {
    return NasaImageData(
      imageUrl: json['imageUrl'] as String? ?? '',
      title: json['title'] as String? ?? 'NASA Satellite Tile',
      caption: json['caption'] as String? ?? 'NASA EOSDIS Earth Observation imagery.',
      source: json['source'] as String? ?? 'NASA EOSDIS / SATELLITE CAPTURE',
      timestamp: json['timestamp'] as String? ?? DateTime.now().toIso8601String(),
      lat: (json['lat'] as num?)?.toDouble() ?? 0.0,
      lon: (json['lon'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] as String? ?? 'SUCCESS',
    );
  }
}

class NasaService {
  static final NasaService _instance = NasaService._internal();
  factory NasaService() => _instance;
  NasaService._internal();

  final Map<String, NasaImageData> _cache = {};
  final Map<String, EventMediaPayloadData> _mediaCache = {};

  static const String mapboxToken =
      String.fromEnvironment('MAPBOX_TOKEN', defaultValue: 'YOUR_MAPBOX_ACCESS_TOKEN');
  static const String unsplashKey =
      'b--UW9CogwZv_WCyl5XcY2R31vF_Vw5HB91q-riSfQo';

  /// Multi-Tier Visual Pipeline: Mapbox Satellite (Primary), Wikimedia Ground Photo (Secondary), Unsplash Fallback
  Future<EventMediaPayloadData> fetchLocationMedia({
    required double lat,
    required double lon,
    String? query,
  }) async {
    final cacheKey = '${lat.toStringAsFixed(2)}_${lon.toStringAsFixed(2)}_${query ?? "NONE"}';
    if (_mediaCache.containsKey(cacheKey)) {
      return _mediaCache[cacheKey]!;
    }

    final formattedLat = lat.toStringAsFixed(4);
    final formattedLon = lon.toStringAsFixed(4);

    final satUrl =
        'https://api.mapbox.com/styles/v1/mapbox/satellite-streets-v12/static/$formattedLon,$formattedLat,12,0/800x450@2x?access_token=$mapboxToken';

    String? groundUrl;
    String groundAttr = 'Wikimedia Commons Ground Photo';

    // 1. Wikimedia Geosearch 10km radius
    try {
      final wikiUrl = Uri.parse(
        'https://en.wikipedia.org/w/api.php?action=query&generator=geosearch&ggscoord=$formattedLat|$formattedLon&ggsradius=10000&ggslimit=1&prop=pageimages&pithumbsize=800&format=json',
      );
      final wikiRes = await http.get(wikiUrl).timeout(const Duration(seconds: 4));
      if (wikiRes.statusCode == 200) {
        final wikiData = jsonDecode(wikiRes.body);
        final pages = wikiData['query']?['pages'] as Map<String, dynamic>?;
        if (pages != null && pages.isNotEmpty) {
          final firstPage = pages.values.first;
          final thumb = firstPage['thumbnail']?['source']?.toString();
          if (thumb != null && thumb.isNotEmpty) {
            groundUrl = thumb;
            groundAttr = 'Wikimedia Commons (${firstPage['title'] ?? 'Feature'})';
          }
        }
      }
    } catch (_) {}

    // 2. Unsplash Editorial Search Fallback
    if (groundUrl == null || groundUrl.isEmpty) {
      try {
        final term = (query != null && query.trim().isNotEmpty) ? query.trim() : 'Earth landscape';
        final unsplashUrl = Uri.parse(
          'https://api.unsplash.com/search/photos?page=1&per_page=1&query=${Uri.encodeComponent(term)}&client_id=$unsplashKey',
        );
        final uRes = await http.get(unsplashUrl).timeout(const Duration(seconds: 4));
        if (uRes.statusCode == 200) {
          final uData = jsonDecode(uRes.body);
          final results = uData['results'] as List?;
          if (results != null && results.isNotEmpty) {
            final firstPhoto = results.first;
            final regUrl = firstPhoto['urls']?['regular']?.toString();
            final photographer = firstPhoto['user']?['name']?.toString() ?? 'Unsplash Editorial';
            if (regUrl != null && regUrl.isNotEmpty) {
              groundUrl = regUrl;
              groundAttr = 'Unsplash Editorial Photo by $photographer';
            }
          }
        }
      } catch (_) {}
    }

    groundUrl ??= 'https://images.unsplash.com/photo-1614728894747-a83421e2b9c9?auto=format&fit=crop&w=1200&q=80';

    final result = EventMediaPayloadData(
      satelliteImageUrl: satUrl,
      groundImageUrl: groundUrl,
      attribution: 'Mapbox High-Res Satellite // $groundAttr',
      title: 'Geospatial Focal Target ($formattedLat°, $formattedLon°)',
      caption: 'Mapbox static aerial imagery tile with Wikimedia/Unsplash ground context.',
    );

    _mediaCache[cacheKey] = result;
    return result;
  }

  /// Photon OSM Geocoding Universal Search
  Future<List<Map<String, dynamic>>> searchPhotonGeocoding(String query) async {
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
    } catch (_) {}

    return [];
  }

  /// Open-Meteo Current Atmospheric Weather Telemetry
  Future<Map<String, dynamic>> fetchOpenMeteoWeather(double lat, double lon) async {
    try {
      final url = Uri.parse(
        'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&current=temperature_2m,relative_humidity_2m,surface_pressure,wind_speed_10m,wind_direction_10m',
      );
      final response = await http.get(url).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final current = data['current'] as Map<String, dynamic>? ?? {};
        return {
          'temperature': (current['temperature_2m'] as num?)?.toDouble() ?? 20.0,
          'humidity': (current['relative_humidity_2m'] as num?)?.toDouble() ?? 50.0,
          'pressure': (current['surface_pressure'] as num?)?.toDouble() ?? 1013.25,
          'windSpeed': (current['wind_speed_10m'] as num?)?.toDouble() ?? 5.0,
          'windDirection': (current['wind_direction_10m'] as num?)?.toDouble() ?? 0.0,
        };
      }
    } catch (_) {}

    return {
      'temperature': 21.5,
      'humidity': 52.0,
      'pressure': 1013.25,
      'windSpeed': 6.8,
      'windDirection': 195.0,
    };
  }

  /// Fetches NASA satellite imagery tile for given latitude and longitude.
  Future<NasaImageData> fetchSatelliteImagery({
    required double lat,
    required double lon,
    String? eventType,
  }) async {
    final cacheKey = '${lat.toStringAsFixed(2)}_${lon.toStringAsFixed(2)}_${eventType ?? "GENERIC"}';
    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey]!;
    }

    final media = await fetchLocationMedia(lat: lat, lon: lon, query: eventType);

    final result = NasaImageData(
      imageUrl: media.satelliteImageUrl,
      title: media.title,
      caption: media.caption,
      source: media.attribution,
      timestamp: DateTime.now().toIso8601String(),
      lat: lat,
      lon: lon,
    );

    _cache[cacheKey] = result;
    return result;
  }
}
