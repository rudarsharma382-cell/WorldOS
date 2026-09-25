import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart';

class MediaEndpoint extends Endpoint {
  static const String defaultMapboxToken =
      'YOUR_MAPBOX_ACCESS_TOKEN';
  static const String defaultUnsplashKey =
      'b--UW9CogwZv_WCyl5XcY2R31vF_Vw5HB91q-riSfQo';

  /// Multi-Tier Visual Pipeline for (lat, lon) coordinates
  Future<EventMediaPayload> getLocationMedia(
    Session session,
    double lat,
    double lon,
    String? query,
  ) async {
    final mapboxToken = session.serverpod.getPassword('mapboxToken') ?? defaultMapboxToken;
    final unsplashKey = session.serverpod.getPassword('unsplashAccessKey') ?? defaultUnsplashKey;

    final formattedLat = lat.toStringAsFixed(4);
    final formattedLon = lon.toStringAsFixed(4);

    // 1. Primary: Mapbox High-Resolution Satellite Static Imagery Tile
    final satelliteImageUrl =
        'https://api.mapbox.com/styles/v1/mapbox/satellite-streets-v12/static/$formattedLon,$formattedLat,12,0/800x450@2x?access_token=$mapboxToken';

    String? groundImageUrl;
    String groundSource = 'Wikimedia Commons / GeoPhoto';

    // 2. Secondary: Wikimedia Commons Ground Photo (GeoSearch 10km radius)
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
            groundImageUrl = thumb;
            groundSource = 'Wikimedia Commons Ground Photo (${firstPage['title'] ?? 'Local Feature'})';
          }
        }
      }
    } catch (e) {
      session.log('Wikimedia Geosearch failed: $e');
    }

    // 3. Fallback: Unsplash Editorial Search API
    if (groundImageUrl == null || groundImageUrl.isEmpty) {
      try {
        final searchTerm = (query != null && query.trim().isNotEmpty)
            ? query.trim()
            : 'Earth satellite landmark';

        final unsplashUrl = Uri.parse(
          'https://api.unsplash.com/search/photos?page=1&per_page=1&query=${Uri.encodeComponent(searchTerm)}&client_id=$unsplashKey',
        );
        final unsplashRes = await http.get(unsplashUrl).timeout(const Duration(seconds: 4));
        if (unsplashRes.statusCode == 200) {
          final uData = jsonDecode(unsplashRes.body);
          final results = uData['results'] as List?;
          if (results != null && results.isNotEmpty) {
            final firstPhoto = results.first;
            final regularUrl = firstPhoto['urls']?['regular']?.toString();
            final photographer = firstPhoto['user']?['name']?.toString() ?? 'Unsplash Editorial';

            if (regularUrl != null && regularUrl.isNotEmpty) {
              groundImageUrl = regularUrl;
              groundSource = 'Unsplash Editorial Photo by $photographer';
            }
          }
        }
      } catch (e) {
        session.log('Unsplash Search API failed: $e');
      }
    }

    // Ultimate fallback ground photo if APIs fail
    groundImageUrl ??=
        'https://images.unsplash.com/photo-1614728894747-a83421e2b9c9?auto=format&fit=crop&w=1200&q=80';

    return EventMediaPayload(
      satelliteImageUrl: satelliteImageUrl,
      groundImageUrl: groundImageUrl,
      attribution: 'Mapbox Satellite // $groundSource',
      title: 'Orbital & Surface Telemetry ($formattedLat°, $formattedLon°)',
      caption: 'Mapbox high-res satellite imagery and ground context photo.',
    );
  }
}
