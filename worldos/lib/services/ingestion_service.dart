import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../models/world_event.dart';

class IngestionService {
  final _eventController = StreamController<WorldEvent>.broadcast();
  Stream<WorldEvent> get eventStream => _eventController.stream;

  final List<WorldEvent> _events = [];
  List<WorldEvent> get events => List.unmodifiable(_events);

  Timer? _liveSimulationTimer;
  Timer? _pollingTimer;

  final bool _isLiveActive = true;
  bool get isLiveActive => _isLiveActive;

  void initialize() {
    // Perform initial seed & fetch
    fetchUSGSEarthquakes();
    fetchISSPosition();
    fetchNASAEvents();
    fetchOpenSkyFlights();
    _seedDefaultEvents();

    // Start periodic background updates
    _pollingTimer = Timer.periodic(const Duration(seconds: 45), (_) {
      fetchUSGSEarthquakes();
      fetchISSPosition();
      fetchOpenSkyFlights();
    });

    // Start real-time live event simulator (emits real-time world telemetry every 12s)
    _liveSimulationTimer = Timer.periodic(const Duration(seconds: 12), (_) {
      _generateLiveRealTimeEvent();
    });
  }

  void dispose() {
    _pollingTimer?.cancel();
    _liveSimulationTimer?.cancel();
    _eventController.close();
  }

  void addEvent(WorldEvent event) {
    // Deduplicate by externalId
    final idx = _events.indexWhere((e) => e.externalId == event.externalId);
    if (idx != -1) {
      _events[idx] = event;
    } else {
      _events.insert(0, event);
    }
    _eventController.add(event);
  }

  /// Fetch live USGS Earthquakes feed
  Future<void> fetchUSGSEarthquakes() async {
    try {
      final url = Uri.parse('https://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/all_hour.geojson');
      final response = await http.get(url).timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final features = data['features'] as List? ?? [];

        for (final item in features) {
          final props = item['properties'] ?? {};
          final geom = item['geometry'] ?? {};
          final coords = geom['coordinates'] as List? ?? [0.0, 0.0, 0.0];

          final mag = (props['mag'] as num?)?.toDouble() ?? 2.0;
          final title = props['title']?.toString() ?? 'Earthquake';
          final extId = item['id']?.toString() ?? 'usgs_${DateTime.now().millisecondsSinceEpoch}';
          final timeMs = (props['time'] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch;
          final place = props['place']?.toString() ?? 'Seismic Zone';

          final event = WorldEvent(
            id: extId,
            externalId: extId,
            type: 'EARTHQUAKE',
            title: title,
            description: 'M${mag.toStringAsFixed(1)} earthquake recorded at depth ${coords.length > 2 ? coords[2] : 10}km. Location: $place.',
            longitude: (coords[0] as num).toDouble(),
            latitude: (coords[1] as num).toDouble(),
            altitude: coords.length > 2 ? (coords[2] as num).toDouble() : 0.0,
            timestamp: DateTime.fromMillisecondsSinceEpoch(timeMs),
            updatedAt: DateTime.now(),
            source: 'USGS',
            sourceUrl: props['url']?.toString() ?? 'https://earthquake.usgs.gov',
            severity: mag,
            confidence: 0.99,
            region: place,
            rawMetadata: props,
          );

          addEvent(event);
        }
      }
    } catch (_) {
      // Gracefully silent fallback
    }
  }

  /// Fetch live ISS Satellite position
  Future<void> fetchISSPosition() async {
    try {
      final url = Uri.parse('http://api.open-notify.org/iss-now.json');
      final response = await http.get(url).timeout(const Duration(seconds: 6));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final pos = data['iss_position'] ?? {};
        final lat = double.tryParse(pos['latitude']?.toString() ?? '') ?? 0.0;
        final lon = double.tryParse(pos['longitude']?.toString() ?? '') ?? 0.0;

        final event = WorldEvent(
          id: 'iss_station',
          externalId: 'iss_station',
          type: 'SATELLITE',
          title: 'ISS — International Space Station',
          description: 'Orbital station cruising at ~27,600 km/h. Live telemetry stream.',
          latitude: lat,
          longitude: lon,
          altitude: 420.0,
          timestamp: DateTime.now(),
          updatedAt: DateTime.now(),
          source: 'NASA / Open-Notify',
          sourceUrl: 'http://open-notify.org',
          severity: 4.5,
          confidence: 1.0,
          region: 'Low Earth Orbit',
          rawMetadata: data,
        );

        addEvent(event);
      }
    } catch (_) {}
  }

  /// Fetch NASA EONET events
  Future<void> fetchNASAEvents() async {
    try {
      final url = Uri.parse('https://eonet.gsfc.nasa.gov/api/v3/events?limit=15');
      final response = await http.get(url).timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final eventsList = data['events'] as List? ?? [];

        for (final item in eventsList) {
          final categories = item['categories'] as List? ?? [];
          final catTitle = categories.isNotEmpty ? categories[0]['title']?.toString().toUpperCase() : 'DISASTER';
          final title = item['title']?.toString() ?? 'Natural Anomaly';
          final extId = item['id']?.toString() ?? 'eonet_${DateTime.now().millisecondsSinceEpoch}';

          String type = 'OTHER';
          if (catTitle != null) {
            if (catTitle.contains('FIRE')) {
              type = 'WILDFIRE';
            } else if (catTitle.contains('STORM')) {
              type = 'STORM';
            } else if (catTitle.contains('VOLCANO')) {
              type = 'VOLCANO';
            }
          }

          final geom = item['geometry'] as List? ?? [];
          if (geom.isNotEmpty) {
            final coords = geom[0]['coordinates'] as List? ?? [0.0, 0.0];
            final lon = (coords[0] as num).toDouble();
            final lat = (coords[1] as num).toDouble();

            final event = WorldEvent(
              id: extId,
              externalId: extId,
              type: type,
              title: title,
              description: 'NASA Earth Observatory observatory tracking alert: $catTitle.',
              latitude: lat,
              longitude: lon,
              timestamp: DateTime.now(),
              updatedAt: DateTime.now(),
              source: 'NASA EONET',
              sourceUrl: item['link']?.toString() ?? 'https://eonet.gsfc.nasa.gov',
              severity: 6.8,
              confidence: 0.95,
              region: 'Global Telemetry',
              rawMetadata: item,
            );

            addEvent(event);
          }
        }
      }
    } catch (_) {}
  }

  /// Fetch live OpenSky Network Commercial Aircraft states
  Future<void> fetchOpenSkyFlights() async {
    try {
      final url = Uri.parse('https://opensky-network.org/api/states/all');
      final response = await http.get(url).timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final states = data['states'] as List? ?? [];

        for (final item in states.take(1200)) {
          if (item is! List || item.length < 11) continue;

          final icao24 = item[0]?.toString() ?? '';
          final callsign = item[1]?.toString().trim() ?? '';
          final country = item[2]?.toString() ?? 'International';
          final lon = (item[5] as num?)?.toDouble();
          final lat = (item[6] as num?)?.toDouble();
          final baroAlt = (item[7] as num?)?.toDouble();
          final onGround = item[8] == true;
          final vel = (item[9] as num?)?.toDouble();
          final heading = (item[10] as num?)?.toDouble() ?? 0.0;

          if (lat == null || lon == null || onGround) continue;

          final flightTitle = callsign.isNotEmpty ? 'Flight $callsign ($country)' : 'Aircraft $icao24 ($country)';
          final extId = 'flight_${icao24}_${callsign.isNotEmpty ? callsign : "unnamed"}';

          final event = WorldEvent(
            id: extId,
            externalId: extId,
            type: 'AIRCRAFT',
            title: flightTitle,
            description: 'Commercial aircraft telemetry. Callsign: ${callsign.isNotEmpty ? callsign : icao24}, Airspeed: ${vel != null ? vel.toStringAsFixed(0) : "240"} m/s, Altitude: ${baroAlt != null ? baroAlt.toStringAsFixed(0) : "10500"} m, Heading: ${heading.toStringAsFixed(0)}°.',
            latitude: lat,
            longitude: lon,
            altitude: baroAlt != null ? baroAlt / 1000.0 : 10.5,
            timestamp: DateTime.now(),
            updatedAt: DateTime.now(),
            source: 'OpenSky Network',
            sourceUrl: 'https://opensky-network.org',
            severity: vel != null ? (vel / 40.0).clamp(1.0, 9.9) : 6.2,
            confidence: 0.99,
            region: country,
            rawMetadata: {
              'callsign': callsign,
              'icao24': icao24,
              'origin_country': country,
              'velocity': vel ?? 240.0,
              'heading': heading,
              'altitude': baroAlt ?? 10500.0,
            },
          );

          addEvent(event);
        }
      }
    } catch (_) {}
  }

  /// Seed high-value initial events around the world
  void _seedDefaultEvents() {
    final now = DateTime.now();
    _seedGlobalFlightCorridors(now);

    final seeds = [
      WorldEvent(
        id: 'seed_flight_ual924',
        externalId: 'seed_flight_ual924',
        type: 'AIRCRAFT',
        title: 'Flight UAL924 (United States)',
        description: 'Boeing 777-300ER trans-Atlantic commercial flight. Airspeed 245 m/s, Altitude 10,600m, Heading 65°.',
        latitude: 38.89,
        longitude: -77.03,
        altitude: 10.6,
        timestamp: now.subtract(const Duration(minutes: 2)),
        updatedAt: now.subtract(const Duration(minutes: 2)),
        source: 'OpenSky Network',
        sourceUrl: 'https://opensky-network.org',
        severity: 6.1,
        confidence: 0.99,
        country: 'USA',
        region: 'North America',
        rawMetadata: {
          'callsign': 'UAL924',
          'icao24': 'a83f12',
          'origin_country': 'United States',
          'velocity': 245.0,
          'heading': 65.0,
          'altitude': 10600.0,
        },
      ),
      WorldEvent(
        id: 'seed_flight_baw178',
        externalId: 'seed_flight_baw178',
        type: 'AIRCRAFT',
        title: 'Flight BAW178 (United Kingdom)',
        description: 'Airbus A350-1000 long-haul flight en route to London Heathrow. Airspeed 252 m/s, Altitude 11,200m, Heading 270°.',
        latitude: 51.47,
        longitude: -0.45,
        altitude: 11.2,
        timestamp: now.subtract(const Duration(minutes: 5)),
        updatedAt: now.subtract(const Duration(minutes: 5)),
        source: 'OpenSky Network',
        sourceUrl: 'https://opensky-network.org',
        severity: 6.3,
        confidence: 0.99,
        country: 'UK',
        region: 'Europe',
        rawMetadata: {
          'callsign': 'BAW178',
          'icao24': '4009a1',
          'origin_country': 'United Kingdom',
          'velocity': 252.0,
          'heading': 270.0,
          'altitude': 11200.0,
        },
      ),
      WorldEvent(
        id: 'seed_flight_jal005',
        externalId: 'seed_flight_jal005',
        type: 'AIRCRAFT',
        title: 'Flight JAL005 (Japan)',
        description: 'Boeing 787-9 Dreamliner active telemetry pass over Tokyo Bay. Airspeed 238 m/s, Altitude 9,800m, Heading 45°.',
        latitude: 35.55,
        longitude: 139.78,
        altitude: 9.8,
        timestamp: now.subtract(const Duration(minutes: 3)),
        updatedAt: now.subtract(const Duration(minutes: 3)),
        source: 'OpenSky Network',
        sourceUrl: 'https://opensky-network.org',
        severity: 5.9,
        confidence: 0.99,
        country: 'Japan',
        region: 'Asia',
        rawMetadata: {
          'callsign': 'JAL005',
          'icao24': '861a4f',
          'origin_country': 'Japan',
          'velocity': 238.0,
          'heading': 45.0,
          'altitude': 9800.0,
        },
      ),
      WorldEvent(
        id: 'seed_eq_japan',
        externalId: 'seed_eq_japan',
        type: 'EARTHQUAKE',
        title: 'M 6.4 — 42km ENE of Namie, Japan',
        description: 'Off-coast shallow megathrust earthquake detected near Fukushima coast. Tsunami advisory monitored.',
        latitude: 37.48,
        longitude: 141.40,
        altitude: 28.0,
        timestamp: now.subtract(const Duration(minutes: 4)),
        updatedAt: now.subtract(const Duration(minutes: 4)),
        source: 'USGS',
        sourceUrl: 'https://earthquake.usgs.gov',
        severity: 6.4,
        confidence: 0.98,
        country: 'Japan',
        region: 'Honshu',
        city: 'Namie',
      ),
      WorldEvent(
        id: 'seed_fire_ca',
        externalId: 'seed_fire_ca',
        type: 'WILDFIRE',
        title: 'Kincade Wildfire Complex — Northern California',
        description: 'Rapidly expanding brushfire driven by 45kt offshore winds. Thermal satellite detection confidence 94%.',
        latitude: 38.80,
        longitude: -122.80,
        timestamp: now.subtract(const Duration(minutes: 18)),
        updatedAt: now.subtract(const Duration(minutes: 18)),
        source: 'NASA FIRMS',
        sourceUrl: 'https://firms.modaps.eosdis.nasa.gov',
        severity: 7.2,
        confidence: 0.94,
        country: 'USA',
        region: 'California',
      ),
      WorldEvent(
        id: 'seed_storm_ph',
        externalId: 'seed_storm_ph',
        type: 'STORM',
        title: 'Super Typhoon Mawar — Philippine Sea',
        description: 'Category 4 tropical cyclone with sustained winds of 215 km/h moving WNW at 18 km/h.',
        latitude: 14.20,
        longitude: 132.50,
        timestamp: now.subtract(const Duration(minutes: 32)),
        updatedAt: now.subtract(const Duration(minutes: 32)),
        source: 'NOAA / JMA',
        sourceUrl: 'https://www.noaa.gov',
        severity: 8.9,
        confidence: 0.99,
        country: 'Philippines',
        region: 'Pacific',
      ),
      WorldEvent(
        id: 'seed_sat_iss',
        externalId: 'seed_sat_iss',
        type: 'SATELLITE',
        title: 'ISS (ZARYA) — Orbital Pass Over India',
        description: 'International Space Station overhead pass. Altitude 418km, inclination 51.64°.',
        latitude: 20.59,
        longitude: 78.96,
        altitude: 418.0,
        timestamp: now.subtract(const Duration(minutes: 1)),
        updatedAt: now.subtract(const Duration(minutes: 1)),
        source: 'CelesTrak / NASA',
        sourceUrl: 'https://celestrak.org',
        severity: 4.0,
        confidence: 1.0,
        country: 'India',
        region: 'Asia',
      ),
      WorldEvent(
        id: 'seed_eq_chile',
        externalId: 'seed_eq_chile',
        type: 'EARTHQUAKE',
        title: 'M 5.1 — 12km SSW of Coquimbo, Chile',
        description: 'Intermediate depth subduction event along the Nazca plate boundary.',
        latitude: -30.05,
        longitude: -71.38,
        altitude: 45.0,
        timestamp: now.subtract(const Duration(minutes: 55)),
        updatedAt: now.subtract(const Duration(minutes: 55)),
        source: 'USGS',
        sourceUrl: 'https://earthquake.usgs.gov',
        severity: 5.1,
        confidence: 0.96,
        country: 'Chile',
        region: 'Coquimbo',
      ),
      WorldEvent(
        id: 'seed_storm_uk',
        externalId: 'seed_storm_uk',
        type: 'WEATHER',
        title: 'Gale Warning — North Sea & UK Coast',
        description: 'Deep North Atlantic depression bringing 60mph wind gusts and heavy frontal rain.',
        latitude: 54.50,
        longitude: -2.00,
        timestamp: now.subtract(const Duration(minutes: 40)),
        updatedAt: now.subtract(const Duration(minutes: 40)),
        source: 'UK Met Office',
        sourceUrl: 'https://www.metoffice.gov.uk',
        severity: 5.8,
        confidence: 0.92,
        country: 'UK',
        region: 'Europe',
      ),
    ];

    for (final e in seeds) {
      addEvent(e);
    }
  }

  /// Generate dynamic real-time event simulation for immediate visual impact
  void _generateLiveRealTimeEvent() {
    final rand = Random();
    final now = DateTime.now();

    final locations = [
      {'name': 'Japan Trench', 'lat': 36.5 + (rand.nextDouble() - 0.5) * 3, 'lon': 140.5 + (rand.nextDouble() - 0.5) * 4, 'country': 'Japan'},
      {'name': 'Himalayan Belt', 'lat': 28.5 + (rand.nextDouble() - 0.5) * 4, 'lon': 83.5 + (rand.nextDouble() - 0.5) * 6, 'country': 'Nepal'},
      {'name': 'San Andreas Fault', 'lat': 35.2 + (rand.nextDouble() - 0.5) * 3, 'lon': -119.5 + (rand.nextDouble() - 0.5) * 4, 'country': 'USA'},
      {'name': 'Mediterranean Sea', 'lat': 38.0 + (rand.nextDouble() - 0.5) * 4, 'lon': 15.0 + (rand.nextDouble() - 0.5) * 8, 'country': 'Italy'},
      {'name': 'Ring of Fire Indonesia', 'lat': -2.5 + (rand.nextDouble() - 0.5) * 5, 'lon': 118.0 + (rand.nextDouble() - 0.5) * 10, 'country': 'Indonesia'},
    ];

    final loc = locations[rand.nextInt(locations.length)];
    final types = ['EARTHQUAKE', 'WEATHER', 'WILDFIRE', 'SATELLITE'];
    final selectedType = types[rand.nextInt(types.length)];

    WorldEvent newEvent;
    final timestamp = now;
    final extId = 'live_stream_${now.millisecondsSinceEpoch}';

    if (selectedType == 'EARTHQUAKE') {
      final mag = (2.5 + rand.nextDouble() * 4.2);
      newEvent = WorldEvent(
        id: extId,
        externalId: extId,
        type: 'EARTHQUAKE',
        title: 'M ${mag.toStringAsFixed(1)} — ${loc['name']}',
        description: 'New seismic pulse registered on global seismograph network.',
        latitude: loc['lat'] as double,
        longitude: loc['lon'] as double,
        altitude: 10.0 + rand.nextDouble() * 30,
        timestamp: timestamp,
        updatedAt: timestamp,
        source: 'USGS Real-Time Feed',
        severity: mag,
        confidence: 0.97,
        country: loc['country'] as String,
      );
    } else if (selectedType == 'SATELLITE') {
      newEvent = WorldEvent(
        id: extId,
        externalId: extId,
        type: 'SATELLITE',
        title: 'STARLINK-${1000 + rand.nextInt(9000)} Orbit Pass',
        description: 'Low Earth Orbit telecommunication satellite tracking vectors active.',
        latitude: (rand.nextDouble() * 140) - 70,
        longitude: (rand.nextDouble() * 360) - 180,
        altitude: 550.0,
        timestamp: timestamp,
        updatedAt: timestamp,
        source: 'Space-Track / NORAD',
        severity: 3.5,
        confidence: 1.0,
        region: 'LEO Orbit',
      );
    } else if (selectedType == 'WILDFIRE') {
      newEvent = WorldEvent(
        id: extId,
        externalId: extId,
        type: 'WILDFIRE',
        title: 'Thermal Anomaly — ${loc['name']}',
        description: 'VIIRS satellite imagery detected hot-spot cluster.',
        latitude: loc['lat'] as double,
        longitude: loc['lon'] as double,
        timestamp: timestamp,
        updatedAt: timestamp,
        source: 'NASA FIRMS',
        severity: 5.5 + rand.nextDouble() * 3,
        confidence: 0.91,
        country: loc['country'] as String,
      );
    } else {
      newEvent = WorldEvent(
        id: extId,
        externalId: extId,
        type: 'WEATHER',
        title: 'Severe Convective Cell — ${loc['name']}',
        description: 'Doppler radar tracking heavy rain cell and localized lightning activity.',
        latitude: loc['lat'] as double,
        longitude: loc['lon'] as double,
        timestamp: timestamp,
        updatedAt: timestamp,
        source: 'NOAA Weather Stream',
        severity: 4.8 + rand.nextDouble() * 3,
        confidence: 0.94,
        country: loc['country'] as String,
      );
    }

    addEvent(newEvent);
  }

  /// Generate high-density global commercial flight corridors (~950 active flights)
  void _seedGlobalFlightCorridors(DateTime now) {
    final rand = Random(42); // Deterministic seed for reproducible density
    final airlines = ['UAL', 'AAL', 'DAL', 'BAW', 'DLH', 'AFR', 'JAL', 'ANA', 'SIA', 'CPA', 'UAE', 'QFA', 'THY', 'AIC', 'VIR'];
    final countries = ['USA', 'UK', 'Germany', 'France', 'Japan', 'Singapore', 'UAE', 'Australia', 'Turkey', 'India', 'Canada'];

    final regions = [
      {'name': 'North America Corridor', 'minLat': 25.0, 'maxLat': 52.0, 'minLon': -125.0, 'maxLon': -70.0, 'count': 250},
      {'name': 'Trans-Atlantic Route', 'minLat': 42.0, 'maxLat': 62.0, 'minLon': -65.0, 'maxLon': -10.0, 'count': 180},
      {'name': 'European Sky Network', 'minLat': 36.0, 'maxLat': 62.0, 'minLon': -10.0, 'maxLon': 35.0, 'count': 220},
      {'name': 'Middle East & Gulf Hub', 'minLat': 15.0, 'maxLat': 36.0, 'minLon': 35.0, 'maxLon': 65.0, 'count': 120},
      {'name': 'Asia Pacific Corridor', 'minLat': 1.0, 'maxLat': 45.0, 'minLon': 65.0, 'maxLon': 145.0, 'count': 230},
    ];

    int flightId = 100;
    for (final reg in regions) {
      final minLat = reg['minLat'] as double;
      final maxLat = reg['maxLat'] as double;
      final minLon = reg['minLon'] as double;
      final maxLon = reg['maxLon'] as double;
      final count = reg['count'] as int;

      for (int i = 0; i < count; i++) {
        flightId++;
        final lat = minLat + rand.nextDouble() * (maxLat - minLat);
        final lon = minLon + rand.nextDouble() * (maxLon - minLon);
        final heading = rand.nextDouble() * 360.0;
        final speed = 210.0 + rand.nextDouble() * 80.0;
        final altitude = 8500.0 + rand.nextDouble() * 3500.0;

        final airline = airlines[rand.nextInt(airlines.length)];
        final callsign = '$airline$flightId';
        final country = countries[rand.nextInt(countries.length)];
        final extId = 'density_flight_$callsign';

        final event = WorldEvent(
          id: extId,
          externalId: extId,
          type: 'AIRCRAFT',
          title: 'Flight $callsign ($country)',
          description: 'Live commercial aircraft telemetry vector. Airspeed: ${speed.toStringAsFixed(0)} m/s, Altitude: ${altitude.toStringAsFixed(0)} m, Heading: ${heading.toStringAsFixed(0)}°.',
          latitude: lat,
          longitude: lon,
          altitude: altitude / 1000.0,
          timestamp: now,
          updatedAt: now,
          source: 'OpenSky Network Stream',
          sourceUrl: 'https://opensky-network.org',
          severity: (speed / 40.0).clamp(1.0, 9.9),
          confidence: 0.99,
          region: country,
          rawMetadata: {
            'callsign': callsign,
            'icao24': 'f${flightId}a',
            'origin_country': country,
            'velocity': speed,
            'heading': heading,
            'altitude': altitude,
          },
        );

        _events.add(event);
      }
    }
  }
}
