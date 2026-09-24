class WatchZone {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final double radiusKm;
  final List<String> trackedTypes;
  final DateTime createdAt;

  WatchZone({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.radiusKm,
    required this.trackedTypes,
    required this.createdAt,
  });

  factory WatchZone.fromJson(Map<String, dynamic> json) {
    return WatchZone(
      id: json['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: json['name']?.toString() ?? 'Watch Zone',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      radiusKm: (json['radiusKm'] as num?)?.toDouble() ?? 100.0,
      trackedTypes: (json['trackedTypes'] as List?)?.map((e) => e.toString()).toList() ?? ['EARTHQUAKE', 'WEATHER', 'WILDFIRE'],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'latitude': latitude,
        'longitude': longitude,
        'radiusKm': radiusKm,
        'trackedTypes': trackedTypes,
        'createdAt': createdAt.toIso8601String(),
      };
}
