import 'dart:convert';

class WorldEvent {
  final String id;
  final String externalId;
  final String type; // EARTHQUAKE, WEATHER, WILDFIRE, STORM, SATELLITE, AIRCRAFT, VOLCANO, FLOOD, OTHER
  final String title;
  final String? description;
  final double latitude;
  final double longitude;
  final double? altitude;
  final DateTime timestamp;
  final DateTime updatedAt;
  final String source;
  final String? sourceUrl;
  final double severity; // 0.0 to 10.0 or magnitude
  final double? confidence;
  final String? country;
  final String? region;
  final String? city;
  final Map<String, dynamic>? rawMetadata;

  WorldEvent({
    required this.id,
    required this.externalId,
    required this.type,
    required this.title,
    this.description,
    required this.latitude,
    required this.longitude,
    this.altitude,
    required this.timestamp,
    required this.updatedAt,
    required this.source,
    this.sourceUrl,
    required this.severity,
    this.confidence,
    this.country,
    this.region,
    this.city,
    this.rawMetadata,
  });

  factory WorldEvent.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic>? meta;
    if (json['rawMetadata'] != null) {
      if (json['rawMetadata'] is String) {
        try {
          meta = jsonDecode(json['rawMetadata']);
        } catch (_) {}
      } else if (json['rawMetadata'] is Map) {
        meta = Map<String, dynamic>.from(json['rawMetadata']);
      }
    }

    return WorldEvent(
      id: json['id']?.toString() ?? json['externalId']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      externalId: json['externalId']?.toString() ?? 'ext_${DateTime.now().millisecondsSinceEpoch}',
      type: (json['type']?.toString() ?? 'OTHER').toUpperCase(),
      title: json['title']?.toString() ?? 'Unknown Event',
      description: json['description']?.toString(),
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      altitude: (json['altitude'] as num?)?.toDouble(),
      timestamp: json['timestamp'] != null
          ? (json['timestamp'] is int
              ? DateTime.fromMillisecondsSinceEpoch(json['timestamp'])
              : DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now())
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? (json['updatedAt'] is int
              ? DateTime.fromMillisecondsSinceEpoch(json['updatedAt'])
              : DateTime.tryParse(json['updatedAt'].toString()) ?? DateTime.now())
          : DateTime.now(),
      source: json['source']?.toString() ?? 'Public Feed',
      sourceUrl: json['sourceUrl']?.toString(),
      severity: (json['severity'] as num?)?.toDouble() ?? 1.0,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.9,
      country: json['country']?.toString(),
      region: json['region']?.toString(),
      city: json['city']?.toString(),
      rawMetadata: meta,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'externalId': externalId,
      'type': type,
      'title': title,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'altitude': altitude,
      'timestamp': timestamp.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'source': source,
      'sourceUrl': sourceUrl,
      'severity': severity,
      'confidence': confidence,
      'country': country,
      'region': region,
      'city': city,
      'rawMetadata': rawMetadata != null ? jsonEncode(rawMetadata) : null,
    };
  }

  String get timeAgo {
    final diff = DateTime.now().difference(updatedAt);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  String get freshnessStatus {
    final diff = DateTime.now().difference(updatedAt);
    if (diff.inMinutes < 15) return 'LIVE';
    if (diff.inHours < 2) return 'NEAR REAL-TIME';
    if (diff.inHours < 24) return 'PERIODIC';
    return 'HISTORICAL';
  }
}
