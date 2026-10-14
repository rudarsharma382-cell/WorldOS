import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../config/env_config.dart';

class RegionalDossier {
  final double latitude;
  final double longitude;
  final String cityName;
  final String districtOrState;
  final String countryAndCode;
  final String localityType;
  final String wikiExtract;
  final String wikiDescription;
  final String imageUrl;
  final String imageBadgeLabel;
  
  // Weather / Atmospheric data
  final double? temperature;
  final int? humidity;
  final double? windSpeed;
  final double? windDirection;
  final double? pressure;
  final String localSolarTime;
  final String daylightStatus;
  
  // Infrastructure & Threat Matrix
  final String nearestAirportInfo;
  final String nearestHighwayInfo;
  final String nearestFaultLineInfo;
  final String threatLevel;

  RegionalDossier({
    required this.latitude,
    required this.longitude,
    required this.cityName,
    required this.districtOrState,
    required this.countryAndCode,
    required this.localityType,
    required this.wikiExtract,
    required this.wikiDescription,
    required this.imageUrl,
    required this.imageBadgeLabel,
    this.temperature,
    this.humidity,
    this.windSpeed,
    this.windDirection,
    this.pressure,
    required this.localSolarTime,
    required this.daylightStatus,
    required this.nearestAirportInfo,
    required this.nearestHighwayInfo,
    required this.nearestFaultLineInfo,
    required this.threatLevel,
  });

  String get formattedLocationHeader {
    List<String> parts = [];
    if (cityName.isNotEmpty && !cityName.startsWith('Sector')) parts.add(cityName.toUpperCase());
    if (districtOrState.isNotEmpty && districtOrState != 'Open Terrain / Offshore') parts.add(districtOrState.toUpperCase());
    if (countryAndCode.isNotEmpty) parts.add(countryAndCode.split('/')[0].trim().toUpperCase());
    
    if (parts.isEmpty) return 'SECTOR [ ${latitude.toStringAsFixed(2)}°, ${longitude.toStringAsFixed(2)}° ]';
    return parts.join(', ');
  }
}

class RegionalBriefingService {
  /// Fetch complete Regional Intelligence Dossier for given coordinates
  static Future<RegionalDossier> fetchDossier({
    required double lat,
    required double lon,
    Map<String, dynamic>? weatherData,
    double? eventSeverity,
    String? eventType,
  }) async {
    // 1. Reverse Geocoding via Photon OSM with fallback to Nominatim
    Map<String, String> geoInfo = await _reverseGeocode(lat, lon);
    
    String cityName = geoInfo['city'] ?? 'Sector';
    String districtOrState = geoInfo['districtOrState'] ?? 'Regional Sector';
    String countryAndCode = geoInfo['country'] ?? 'International Territory';
    String osmValue = geoInfo['osmValue'] ?? '';
    
    // Determine Locality Type Badge
    String localityType = _determineLocalityType(lat, lon, cityName, districtOrState, countryAndCode, osmValue);

    // 2. Wikipedia Summary Retrieval
    Map<String, String> wikiInfo = await _fetchWikiSummary(cityName, districtOrState, countryAndCode);
    String wikiExtract = wikiInfo['extract'] ?? '';
    String wikiDescription = wikiInfo['description'] ?? 'REGIONAL CLASSIFICATION & GEOPOLITICAL SECTOR';

    if (wikiExtract.isEmpty) {
      wikiExtract = _buildFallbackExtract(cityName, districtOrState, countryAndCode, localityType, lat, lon);
    }

    // 2b. Hierarchical Regional Image Pipeline (3 Tiers)
    final imgInfo = await _fetchHierarchicalImage(
      cityName: cityName,
      districtOrState: districtOrState,
      country: countryAndCode,
    );

    // 3. Solar & Lighting State
    final solarData = _calculateSolarState(lat, lon);

    // 4. Infrastructure & Threat Scans
    final airportInfo = _scanNearestAirport(lat, lon);
    final highwayInfo = _scanNearestHighway(lat, lon, districtOrState);
    final faultLineInfo = _scanNearestFaultLine(lat, lon);

    // Threat Level Evaluation
    double temp = (weatherData?['temperature_2m'] as num?)?.toDouble() ?? 25.0;
    double severity = eventSeverity ?? 1.0;
    String type = (eventType ?? '').toUpperCase();

    String threatLevel = 'NORMAL // SECURE';
    if (severity >= 6.0 || type.contains('QUAKE') || type.contains('SEISMIC')) {
      threatLevel = 'ELEVATED SEISMIC HAZARD';
    } else if (type.contains('FIRE') || temp > 40.0) {
      threatLevel = 'ELEVATED THERMAL ANOMALY';
    } else if (type.contains('STORM') || type.contains('TYPHOON') || type.contains('WEATHER')) {
      threatLevel = 'ATMOSPHERIC DISTURBANCE';
    } else if (type.contains('MILITARY') || type.contains('CONFLICT')) {
      threatLevel = 'TACTICAL DEFENSE ALERT';
    }

    return RegionalDossier(
      latitude: lat,
      longitude: lon,
      cityName: cityName,
      districtOrState: districtOrState,
      countryAndCode: countryAndCode,
      localityType: localityType,
      wikiExtract: wikiExtract,
      wikiDescription: wikiDescription,
      imageUrl: imgInfo['url']!,
      imageBadgeLabel: imgInfo['label']!,
      temperature: (weatherData?['temperature_2m'] as num?)?.toDouble(),
      humidity: (weatherData?['relative_humidity_2m'] as num?)?.toInt(),
      windSpeed: (weatherData?['wind_speed_10m'] as num?)?.toDouble(),
      windDirection: (weatherData?['wind_direction_10m'] as num?)?.toDouble(),
      pressure: (weatherData?['surface_pressure'] as num?)?.toDouble(),
      localSolarTime: solarData['time']!,
      daylightStatus: solarData['status']!,
      nearestAirportInfo: airportInfo,
      nearestHighwayInfo: highwayInfo,
      nearestFaultLineInfo: faultLineInfo,
      threatLevel: threatLevel,
    );
  }

  static String _cleanPlaceName(String raw) {
    if (raw.trim().isEmpty) return '';
    List<String> parts = raw.split(',');
    String mainPart = parts.isNotEmpty ? parts[0].trim() : raw.trim();

    // Strip POI facility prefixes if present (e.g. Government Dispensary, Hospital, etc.)
    mainPart = mainPart.replaceAll(RegExp(r'^(?:Government|Govt|Laboratory|Dispensary|Hospital|School|College|Station|Airport|Park|Hotel|Resort)\s+.*?\s+(?=Tahsil|Tehsil|District|City|Town|Village|[A-Z])', caseSensitive: false), '');
    
    // Clean trailing "Tahsil", "Tehsil", "District"
    mainPart = mainPart.replaceAll(RegExp(r'\s+(?:Tahsil|Tehsil|District|Subdistrict)\b', caseSensitive: false), '');
    
    return mainPart.trim();
  }

  static Future<Map<String, String>> _reverseGeocode(double lat, double lon) async {
    try {
      final photonUrl = Uri.parse('https://photon.komoot.io/reverse?lat=$lat&lon=$lon');
      final res = await http.get(photonUrl).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['features'] != null && (data['features'] as List).isNotEmpty) {
          final props = data['features'][0]['properties'] as Map<String, dynamic>;
          
          // Prioritize actual settlement keys over POI facility names
          String name = (props['city'] ?? props['town'] ?? props['village'] ?? props['municipality'] ?? props['locality'] ?? props['suburb'] ?? props['county'] ?? props['district'] ?? '').toString();
          
          if (name.isEmpty) {
            name = (props['name'] ?? '').toString();
          }

          name = _cleanPlaceName(name);

          String district = _cleanPlaceName((props['district'] ?? props['county'] ?? '').toString());
          String state = _cleanPlaceName((props['state'] ?? '').toString());
          String country = (props['country'] ?? '').toString();
          String countryCode = (props['countrycode'] ?? '').toString().toUpperCase();
          String osmVal = (props['osm_value'] ?? props['type'] ?? '').toString();

          if (district.isNotEmpty && name.toLowerCase() == district.toLowerCase()) {
            district = '';
          }

          String districtOrState = district.isNotEmpty && state.isNotEmpty
              ? '$district / $state'
              : (state.isNotEmpty ? state : (district.isNotEmpty ? district : 'Regional Sector'));

          String countryStr = countryCode.isNotEmpty ? '$country / $countryCode' : country;

          if (name.isNotEmpty) {
            return {
              'city': name,
              'districtOrState': districtOrState,
              'country': countryStr,
              'osmValue': osmVal,
            };
          }
        }
      }
    } catch (_) {}

    // Fallback: Nominatim reverse lookup
    try {
      final nomUrl = Uri.parse('https://nominatim.openstreetmap.org/reverse?lat=$lat&lon=$lon&format=jsonv2');
      final res = await http.get(nomUrl, headers: {'User-Agent': 'WorldOS-Tactical/1.0'}).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final addr = data['address'] as Map<String, dynamic>?;
        if (addr != null) {
          String name = (addr['city'] ?? addr['town'] ?? addr['village'] ?? addr['municipality'] ?? addr['suburb'] ?? addr['county'] ?? addr['district'] ?? '').toString();
          name = _cleanPlaceName(name);

          String state = _cleanPlaceName((addr['state'] ?? addr['region'] ?? '').toString());
          String country = (addr['country'] ?? '').toString();
          String countryCode = (addr['country_code'] ?? '').toString().toUpperCase();

          String countryStr = countryCode.isNotEmpty ? '$country / $countryCode' : country;

          return {
            'city': name.isNotEmpty ? name : 'Sector',
            'districtOrState': state.isNotEmpty ? state : 'Regional Zone',
            'country': countryStr.isNotEmpty ? countryStr : 'Global Sector',
            'osmValue': '',
          };
        }
      }
    } catch (_) {}

    return {
      'city': 'Sector [ ${lat.toStringAsFixed(2)}°, ${lon.toStringAsFixed(2)}° ]',
      'districtOrState': 'Open Terrain / Offshore',
      'country': 'International Territory',
      'osmValue': '',
    };
  }

  static String _determineLocalityType(double lat, double lon, String city, String state, String country, String osmValue) {
    final lowerState = state.toLowerCase();
    final lowerCity = city.toLowerCase();
    final lowerCountry = country.toLowerCase();

    if (lowerState.contains('rajasthan') || lowerCity.contains('didwana') || lowerCity.contains('nagaur') || lowerCity.contains('jodhpur') || lowerCity.contains('bikaner')) {
      return 'ARID SEMI-DESERT // RAJASTHAN PLAINS';
    }
    if (lowerCountry.contains('saudi') || lowerCountry.contains('emirates') || lowerCountry.contains('egypt') || lowerCountry.contains('algeria') || lowerCountry.contains('libya')) {
      return 'DESERT BASIN // ARID SECTOR';
    }
    if (lowerState.contains('california') || lowerState.contains('tokyo') || lowerCity.contains('london') || lowerCity.contains('new york') || osmValue == 'city' || osmValue == 'town') {
      return 'METROPOLITAN CORRIDOR';
    }
    if (lat > 60.0 || lat < -60.0) {
      return 'POLAR / SUB-ARCTIC MARGIN';
    }
    if (lowerState.contains('alps') || lowerState.contains('himalaya') || lowerState.contains('colorado') || lowerState.contains('nepal') || lowerState.contains('chile')) {
      return 'MOUNTAIN RANGE // TACTICAL HIGHLANDS';
    }
    if (lowerState.contains('island') || lowerState.contains('coast') || lowerCountry.contains('japan') || lowerCountry.contains('philippines') || lowerCountry.contains('indonesia')) {
      return 'COASTAL BASIN // MARITIME SECTOR';
    }

    return 'REGIONAL BASIN // TERRESTRIAL SECTOR';
  }

  static Future<Map<String, String>> _fetchWikiSummary(String city, String districtOrState, String country) async {
    List<String> candidates = [
      city,
      districtOrState.split('/')[0].trim(),
      if (districtOrState.contains('/')) districtOrState.split('/')[1].trim(),
      country.split('/')[0].trim(),
    ].where((c) => c.isNotEmpty && !c.startsWith('Sector')).toList();

    for (String cand in candidates) {
      try {
        final uri = Uri.parse('https://en.wikipedia.org/api/rest_v1/page/summary/${Uri.encodeComponent(cand)}');
        final res = await http.get(uri).timeout(const Duration(seconds: 3));
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          String extract = (data['extract'] ?? '').toString();
          String description = (data['description'] ?? '').toString();
          if (extract.isNotEmpty) {
            return {
              'extract': extract,
              'description': description.toUpperCase(),
            };
          }
        }
      } catch (_) {}
    }

    // Try Wikipedia Search API if summary endpoint 404s
    if (candidates.isNotEmpty) {
      try {
        final searchUri = Uri.parse(
          'https://en.wikipedia.org/w/api.php?action=query&list=search&srsearch=${Uri.encodeComponent(candidates.first)}&utf8=&format=json',
        );
        final res = await http.get(searchUri).timeout(const Duration(seconds: 3));
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          final searchList = data['query']?['search'] as List?;
          if (searchList != null && searchList.isNotEmpty) {
            String pageTitle = searchList[0]['title'].toString();
            final summaryUri = Uri.parse('https://en.wikipedia.org/api/rest_v1/page/summary/${Uri.encodeComponent(pageTitle)}');
            final summaryRes = await http.get(summaryUri).timeout(const Duration(seconds: 3));
            if (summaryRes.statusCode == 200) {
              final sumData = jsonDecode(summaryRes.body);
              String extract = (sumData['extract'] ?? '').toString();
              String description = (sumData['description'] ?? '').toString();
              if (extract.isNotEmpty) {
                return {
                  'extract': extract,
                  'description': description.toUpperCase(),
                };
              }
            }
          }
        }
      } catch (_) {}
    }

    return {'extract': '', 'description': ''};
  }

  static Future<Map<String, String>> _fetchHierarchicalImage({
    required String cityName,
    required String districtOrState,
    required String country,
  }) async {
    String stateName = districtOrState.contains('/')
        ? districtOrState.split('/')[1].trim()
        : districtOrState.trim();
    if (stateName.isEmpty || stateName == 'Regional Sector') {
      stateName = districtOrState.split('/')[0].trim();
    }
    String countryName = country.split('/')[0].trim();

    // Tier 1: Local Settlement / Landmark Query
    if (cityName.isNotEmpty && !cityName.startsWith('Sector')) {
      try {
        final uri = Uri.parse('https://en.wikipedia.org/api/rest_v1/page/summary/${Uri.encodeComponent(cityName)}');
        final res = await http.get(uri).timeout(const Duration(seconds: 3));
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          String? src = data['originalimage']?['source'] ?? data['thumbnail']?['source'];
          if (src != null && src.isNotEmpty) {
            return {
              'url': src,
              'label': '[ LOCAL OPTICAL INTERCEPT: ${cityName.toUpperCase()} ]',
            };
          }
        }
      } catch (_) {}
    }

    // Tier 2: State / Provincial Landmark Fallback (The Fix for small villages like Dabkehri)
    List<String> stateQueries = [
      if (stateName.isNotEmpty && stateName != 'Regional Sector') stateName,
      if (stateName.isNotEmpty && stateName != 'Regional Sector') '$stateName tourism',
      if (districtOrState.contains('/')) districtOrState.split('/')[0].trim(),
    ];

    for (String sq in stateQueries) {
      if (sq.isEmpty) continue;
      try {
        final uri = Uri.parse('https://en.wikipedia.org/api/rest_v1/page/summary/${Uri.encodeComponent(sq)}');
        final res = await http.get(uri).timeout(const Duration(seconds: 3));
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          String? src = data['originalimage']?['source'] ?? data['thumbnail']?['source'];
          if (src != null && src.isNotEmpty) {
            String badgeState = stateName.isNotEmpty ? stateName : sq;
            return {
              'url': src,
              'label': '[ PROVINCIAL ARCHIVE: ${badgeState.toUpperCase()} // SECTOR BRIEFING ]',
            };
          }
        }
      } catch (_) {}
    }

    // Tier 3: High-Res Editorial Fallback (Unsplash / Curated Geocache)
    try {
      final unsplashKey = EnvConfig.unsplashKey;
      if (unsplashKey.isNotEmpty) {
        String query = stateName.isNotEmpty ? '$stateName landscape $countryName' : '$countryName landscape';
        final unsplashUrl = Uri.parse(
          'https://api.unsplash.com/search/photos?query=${Uri.encodeComponent(query)}&orientation=landscape&per_page=1&client_id=$unsplashKey',
        );
        final res = await http.get(unsplashUrl).timeout(const Duration(seconds: 3));
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          final results = data['results'] as List?;
          if (results != null && results.isNotEmpty) {
            String? url = results[0]['urls']?['regular'] ?? results[0]['urls']?['full'];
            if (url != null && url.isNotEmpty) {
              return {
                'url': url,
                'label': '[ PROVINCIAL ARCHIVE: ${stateName.toUpperCase()} // SECTOR BRIEFING ]',
              };
            }
          }
        }
      }
    } catch (_) {}

    String fallbackUrl = getCuratedRegionalImage(countryName, stateName);
    String labelState = stateName.isNotEmpty && stateName != 'Regional Sector' ? stateName.toUpperCase() : countryName.toUpperCase();

    return {
      'url': fallbackUrl,
      'label': '[ PROVINCIAL ARCHIVE: $labelState // SECTOR BRIEFING ]',
    };
  }

  static String getCuratedRegionalImage(String country, String state) {
    final c = country.toLowerCase();
    final s = state.toLowerCase();

    if (c.contains('india') || s.contains('haryana') || s.contains('punjab') || s.contains('rajasthan')) {
      return 'https://images.unsplash.com/photo-1524492412937-b28074a5d7da?auto=format&fit=crop&w=1200&q=80';
    }
    if (c.contains('japan') || s.contains('tokyo')) {
      return 'https://images.unsplash.com/photo-1493976040374-85c8e12f0c0e?auto=format&fit=crop&w=1200&q=80';
    }
    if (c.contains('united states') || c.contains('usa') || s.contains('california') || s.contains('york')) {
      return 'https://images.unsplash.com/photo-1506744038136-46273834b3fb?auto=format&fit=crop&w=1200&q=80';
    }
    if (c.contains('france') || c.contains('uk') || c.contains('germany') || c.contains('europe')) {
      return 'https://images.unsplash.com/photo-1499856871958-5b9627545d1a?auto=format&fit=crop&w=1200&q=80';
    }
    if (c.contains('saudi') || c.contains('emirates') || c.contains('egypt')) {
      return 'https://images.unsplash.com/photo-1509316975850-ff9c5deb0cd9?auto=format&fit=crop&w=1200&q=80';
    }

    return 'https://images.unsplash.com/photo-1451187580459-43490279c0fa?auto=format&fit=crop&w=1200&q=80';
  }

  /// Ground Optical Recon Intercept for Monuments, Landmarks, or CCTV fallback
  static Future<Map<String, String>> fetchGroundOpticalImage({
    required String targetTitle,
    required String locationName,
    required String countryName,
  }) async {
    List<String> queries = [
      targetTitle,
      locationName,
      '$locationName monument',
      '$countryName landmark',
    ].where((q) => q.trim().isNotEmpty && !q.startsWith('Sector')).toList();

    for (String q in queries) {
      try {
        final uri = Uri.parse('https://en.wikipedia.org/api/rest_v1/page/summary/${Uri.encodeComponent(q)}');
        final res = await http.get(uri).timeout(const Duration(seconds: 3));
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          String? src = data['originalimage']?['source'] ?? data['thumbnail']?['source'];
          if (src != null && src.isNotEmpty) {
            return {
              'url': src,
              'title': data['title']?.toString().toUpperCase() ?? q.toUpperCase(),
            };
          }
        }
      } catch (_) {}
    }

    return {
      'url': getCuratedRegionalImage(countryName, locationName),
      'title': targetTitle.toUpperCase(),
    };
  }

  static String _buildFallbackExtract(String city, String state, String country, String localityType, double lat, double lon) {
    return '$city is a strategic regional municipality situated in $state, $country (Coordinates: ${lat.toStringAsFixed(2)}° N, ${lon.toStringAsFixed(2)}° E). Classified under the $localityType ecosystem, this sector anchors vital agricultural, economic, and logistical transit networks within the region.';
  }

  static Map<String, String> _calculateSolarState(double lat, double lon) {
    final utcNow = DateTime.now().toUtc();
    double solarOffsetHours = lon / 15.0;
    double utcDecimalHours = utcNow.hour + (utcNow.minute / 60.0) + (utcNow.second / 3600.0);
    double localSolarHour = (utcDecimalHours + solarOffsetHours) % 24.0;
    if (localSolarHour < 0) localSolarHour += 24.0;

    int lstHour = localSolarHour.floor();
    int lstMin = ((localSolarHour - lstHour) * 60).floor();
    String timeStr = '${lstHour.toString().padLeft(2, '0')}:${lstMin.toString().padLeft(2, '0')} LST';

    String status = 'NIGHTFALL // LOW LIGHT REGIME';
    if (localSolarHour >= 6.5 && localSolarHour <= 17.5) {
      status = 'DAYLIGHT // HIGH SOLAR FLUX';
    } else if (localSolarHour >= 5.5 && localSolarHour < 6.5) {
      status = 'GOLDEN HOUR // DAWN TRANSITION';
    } else if (localSolarHour > 17.5 && localSolarHour <= 18.5) {
      status = 'GOLDEN HOUR // DUSK TRANSITION';
    }

    return {'time': timeStr, 'status': status};
  }

  static String _scanNearestAirport(double lat, double lon) {
    final airports = [
      {'name': 'Jodhpur Airport (JDH)', 'lat': 26.2514, 'lon': 73.0489},
      {'name': 'Jaipur International (JAI)', 'lat': 26.8242, 'lon': 75.8122},
      {'name': 'Indira Gandhi Intl (DEL)', 'lat': 28.5562, 'lon': 77.1000},
      {'name': 'Chhatrapati Shivaji Intl (BOM)', 'lat': 19.0896, 'lon': 72.8656},
      {'name': 'Dubai International (DXB)', 'lat': 25.2532, 'lon': 55.3657},
      {'name': 'Tokyo Haneda Intl (HND)', 'lat': 35.5494, 'lon': 139.7798},
      {'name': 'London Heathrow (LHR)', 'lat': 51.4700, 'lon': -0.4543},
      {'name': 'John F. Kennedy Intl (JFK)', 'lat': 40.6413, 'lon': -73.7781},
      {'name': 'Singapore Changi (SIN)', 'lat': 1.3644, 'lon': 103.9915},
    ];

    double minDistance = double.infinity;
    Map<String, dynamic> closest = airports.first;

    for (var ap in airports) {
      double d = _haversineDistance(lat, lon, ap['lat'] as double, ap['lon'] as double);
      if (d < minDistance) {
        minDistance = d;
        closest = ap;
      }
    }

    String dir = _getCardinalDirection(lat, lon, closest['lat'] as double, closest['lon'] as double);
    return '${closest['name']} — ${minDistance.toStringAsFixed(1)} km [ $dir ]';
  }

  static String _scanNearestHighway(double lat, double lon, String state) {
    final highways = [
      {'name': 'NH-58 / State Highway 21 Axis', 'lat': 27.0500, 'lon': 74.5000},
      {'name': 'NH-48 Delhi-Mumbai Express Corridor', 'lat': 26.9000, 'lon': 75.8000},
      {'name': 'Interstate 95 Atlantic Transit Axis', 'lat': 39.0000, 'lon': -76.8000},
      {'name': 'Interstate 10 Pacific Corridor', 'lat': 33.5000, 'lon': -112.0000},
      {'name': 'Autobahn A1 Arterial Highway', 'lat': 51.2000, 'lon': 7.2000},
      {'name': 'Trans-Asian Highway AH1 Route', 'lat': 35.7000, 'lon': 139.7000},
    ];

    double minDistance = double.infinity;
    Map<String, dynamic> closest = highways.first;

    for (var hw in highways) {
      double d = _haversineDistance(lat, lon, hw['lat'] as double, hw['lon'] as double);
      if (d < minDistance) {
        minDistance = d;
        closest = hw;
      }
    }

    return '${closest['name']} — ${minDistance.toStringAsFixed(1)} km';
  }

  static String _scanNearestFaultLine(double lat, double lon) {
    final faultLines = [
      {'name': 'Great Boundary Fault System', 'lat': 25.2000, 'lon': 74.8000},
      {'name': 'Main Himalayan Thrust (MHT Zone)', 'lat': 28.0000, 'lon': 84.0000},
      {'name': 'San Andreas Fault System', 'lat': 35.7000, 'lon': -120.3000},
      {'name': 'North Anatolian Fault Zone', 'lat': 40.7000, 'lon': 31.0000},
      {'name': 'Japan Trench Subduction Margin', 'lat': 38.0000, 'lon': 143.0000},
      {'name': 'Alpine Fault Zone (NZ)', 'lat': -43.5000, 'lon': 170.5000},
    ];

    double minDistance = double.infinity;
    Map<String, dynamic> closest = faultLines.first;

    for (var fl in faultLines) {
      double d = _haversineDistance(lat, lon, fl['lat'] as double, fl['lon'] as double);
      if (d < minDistance) {
        minDistance = d;
        closest = fl;
      }
    }

    return '${closest['name']} — ${minDistance.toStringAsFixed(1)} km';
  }

  static double _haversineDistance(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371.0;
    final dLat = (lat2 - lat1) * pi / 180.0;
    final dLon = (lon2 - lon1) * pi / 180.0;
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180.0) * cos(lat2 * pi / 180.0) * sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  static String _getCardinalDirection(double lat1, double lon1, double lat2, double lon2) {
    final dLon = (lon2 - lon1) * pi / 180.0;
    final y = sin(dLon) * cos(lat2 * pi / 180.0);
    final x = cos(lat1 * pi / 180.0) * sin(lat2 * pi / 180.0) -
        sin(lat1 * pi / 180.0) * cos(lat2 * pi / 180.0) * cos(dLon);
    final bearing = (atan2(y, x) * 180.0 / pi + 360) % 360;
    const directions = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
    int index = (((bearing + 22.5) % 360) / 45).floor();
    return directions[index.clamp(0, 7)];
  }
}
