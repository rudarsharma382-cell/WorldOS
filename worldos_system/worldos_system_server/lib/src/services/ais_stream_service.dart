import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart';
import '../endpoints/event_endpoint.dart';

class AisStreamService {
  static final AisStreamService _instance = AisStreamService._internal();
  factory AisStreamService() => _instance;
  AisStreamService._internal();

  WebSocket? _webSocket;
  bool _isConnecting = false;
  Timer? _reconnectTimer;

  static const String defaultAisKey = '608ae8357c3a3d148cd04b81633d14cc15fe7ab7';

  void initialize(Serverpod pod) {
    if (_webSocket != null || _isConnecting) return;
    _connect(pod);
  }

  Future<void> _connect(Serverpod pod) async {
    _isConnecting = true;
    try {
      final key = pod.getPassword('aisStreamKey') ?? defaultAisKey;
      _webSocket = await WebSocket.connect('wss://stream.aisstream.io/v0/stream')
          .timeout(const Duration(seconds: 10));

      _isConnecting = false;

      final subscribeMsg = jsonEncode({
        "APIKey": key,
        "BoundingBoxes": [
          [
            [-90.0, -180.0],
            [90.0, 180.0]
          ]
        ]
      });

      _webSocket!.add(subscribeMsg);

      _webSocket!.listen(
        (message) async {
          try {
            final data = jsonDecode(message.toString());
            final msgType = data['MessageType']?.toString();
            final meta = data['MetaData'] ?? {};
            final body = data['Message'] ?? {};

            final mmsi = meta['MMSI'] ?? body['PositionReport']?['UserID'] ?? 0;
            final shipName = meta['ShipName']?.toString().trim() ?? 'Vessel $mmsi';

            if (msgType == 'PositionReport' && body['PositionReport'] != null) {
              final pos = body['PositionReport'];
              final lat = (pos['Latitude'] as num?)?.toDouble();
              final lon = (pos['Longitude'] as num?)?.toDouble();
              final cog = (pos['Cog'] as num?)?.toDouble() ?? 0.0;
              final sog = (pos['Sog'] as num?)?.toDouble() ?? 0.0;

              if (lat != null && lon != null && lat != 0.0 && lon != 0.0) {
                final extId = 'ship_$mmsi';
                final event = WorldEvent(
                  externalId: extId,
                  type: 'SHIP',
                  title: 'Vessel $shipName (MMSI $mmsi)',
                  description: 'Live maritime AIS vessel telemetry. Course Over Ground: ${cog.toStringAsFixed(1)}°, Speed Over Ground: ${sog.toStringAsFixed(1)} knots.',
                  latitude: lat,
                  longitude: lon,
                  altitude: 0.0,
                  timestamp: DateTime.now(),
                  updatedAt: DateTime.now(),
                  source: 'AISStream Maritime',
                  sourceUrl: 'https://aisstream.io',
                  severity: (sog / 3.0).clamp(1.0, 9.0),
                  confidence: 1.0,
                  region: 'International Waters',
                  rawMetadata: jsonEncode({
                    'mmsi': mmsi,
                    'ship_name': shipName,
                    'cog': cog,
                    'sog': sog,
                  }),
                );

                // Broadcast live vessel event
                final session = await pod.createSession();
                try {
                  await EventEndpoint().saveAndBroadcastEvent(session, event);
                } finally {
                  await session.close();
                }
              }
            }
          } catch (_) {}
        },
        onError: (e) {
          _isConnecting = false;
          _scheduleReconnect(pod);
        },
        onDone: () {
          _isConnecting = false;
          _scheduleReconnect(pod);
        },
      );
    } catch (_) {
      _isConnecting = false;
      _scheduleReconnect(pod);
    }
  }

  void _scheduleReconnect(Serverpod pod) {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 30), () {
      _connect(pod);
    });
  }
}
