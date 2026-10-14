class Investigation {
  final String id;
  final String title;
  final String? notes;
  final List<String> eventIds;
  final double? latitude;
  final double? longitude;
  final DateTime createdAt;

  Investigation({
    required this.id,
    required this.title,
    this.notes,
    required this.eventIds,
    this.latitude,
    this.longitude,
    required this.createdAt,
  });

  factory Investigation.fromJson(Map<String, dynamic> json) {
    return Investigation(
      id: json['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: json['title']?.toString() ?? 'Saved Investigation',
      notes: json['notes']?.toString(),
      eventIds: (json['eventIds'] as List?)?.map((e) => e.toString()).toList() ?? [],
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'notes': notes,
        'eventIds': eventIds,
        'latitude': latitude,
        'longitude': longitude,
        'createdAt': createdAt.toIso8601String(),
      };
}

