/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member

// ignore_for_file: no_leading_underscores_for_library_prefixes

import 'package:serverpod_client/serverpod_client.dart' as _i1;

abstract class WorldEvent implements _i1.SerializableModel {
  WorldEvent._({
    this.id,
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

  factory WorldEvent({
    int? id,
    required String externalId,
    required String type,
    required String title,
    String? description,
    required double latitude,
    required double longitude,
    double? altitude,
    required DateTime timestamp,
    required DateTime updatedAt,
    required String source,
    String? sourceUrl,
    required double severity,
    double? confidence,
    String? country,
    String? region,
    String? city,
    String? rawMetadata,
  }) = _WorldEventImpl;

  factory WorldEvent.fromJson(Map<String, dynamic> jsonSerialization) {
    return WorldEvent(
      id: jsonSerialization['id'] as int?,
      externalId: jsonSerialization['externalId'] as String,
      type: jsonSerialization['type'] as String,
      title: jsonSerialization['title'] as String,
      description: jsonSerialization['description'] as String?,
      latitude: (jsonSerialization['latitude'] as num).toDouble(),
      longitude: (jsonSerialization['longitude'] as num).toDouble(),
      altitude: (jsonSerialization['altitude'] as num?)?.toDouble(),
      timestamp: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['timestamp'],
      ),
      updatedAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['updatedAt'],
      ),
      source: jsonSerialization['source'] as String,
      sourceUrl: jsonSerialization['sourceUrl'] as String?,
      severity: (jsonSerialization['severity'] as num).toDouble(),
      confidence: (jsonSerialization['confidence'] as num?)?.toDouble(),
      country: jsonSerialization['country'] as String?,
      region: jsonSerialization['region'] as String?,
      city: jsonSerialization['city'] as String?,
      rawMetadata: jsonSerialization['rawMetadata'] as String?,
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  String externalId;

  String type;

  String title;

  String? description;

  double latitude;

  double longitude;

  double? altitude;

  DateTime timestamp;

  DateTime updatedAt;

  String source;

  String? sourceUrl;

  double severity;

  double? confidence;

  String? country;

  String? region;

  String? city;

  String? rawMetadata;

  /// Returns a shallow copy of this [WorldEvent]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  WorldEvent copyWith({
    int? id,
    String? externalId,
    String? type,
    String? title,
    String? description,
    double? latitude,
    double? longitude,
    double? altitude,
    DateTime? timestamp,
    DateTime? updatedAt,
    String? source,
    String? sourceUrl,
    double? severity,
    double? confidence,
    String? country,
    String? region,
    String? city,
    String? rawMetadata,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'WorldEvent',
      if (id != null) 'id': id,
      'externalId': externalId,
      'type': type,
      'title': title,
      if (description != null) 'description': description,
      'latitude': latitude,
      'longitude': longitude,
      if (altitude != null) 'altitude': altitude,
      'timestamp': timestamp.toJson(),
      'updatedAt': updatedAt.toJson(),
      'source': source,
      if (sourceUrl != null) 'sourceUrl': sourceUrl,
      'severity': severity,
      if (confidence != null) 'confidence': confidence,
      if (country != null) 'country': country,
      if (region != null) 'region': region,
      if (city != null) 'city': city,
      if (rawMetadata != null) 'rawMetadata': rawMetadata,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _WorldEventImpl extends WorldEvent {
  _WorldEventImpl({
    int? id,
    required String externalId,
    required String type,
    required String title,
    String? description,
    required double latitude,
    required double longitude,
    double? altitude,
    required DateTime timestamp,
    required DateTime updatedAt,
    required String source,
    String? sourceUrl,
    required double severity,
    double? confidence,
    String? country,
    String? region,
    String? city,
    String? rawMetadata,
  }) : super._(
         id: id,
         externalId: externalId,
         type: type,
         title: title,
         description: description,
         latitude: latitude,
         longitude: longitude,
         altitude: altitude,
         timestamp: timestamp,
         updatedAt: updatedAt,
         source: source,
         sourceUrl: sourceUrl,
         severity: severity,
         confidence: confidence,
         country: country,
         region: region,
         city: city,
         rawMetadata: rawMetadata,
       );

  /// Returns a shallow copy of this [WorldEvent]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  WorldEvent copyWith({
    Object? id = _Undefined,
    String? externalId,
    String? type,
    String? title,
    Object? description = _Undefined,
    double? latitude,
    double? longitude,
    Object? altitude = _Undefined,
    DateTime? timestamp,
    DateTime? updatedAt,
    String? source,
    Object? sourceUrl = _Undefined,
    double? severity,
    Object? confidence = _Undefined,
    Object? country = _Undefined,
    Object? region = _Undefined,
    Object? city = _Undefined,
    Object? rawMetadata = _Undefined,
  }) {
    return WorldEvent(
      id: id is int? ? id : this.id,
      externalId: externalId ?? this.externalId,
      type: type ?? this.type,
      title: title ?? this.title,
      description: description is String? ? description : this.description,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      altitude: altitude is double? ? altitude : this.altitude,
      timestamp: timestamp ?? this.timestamp,
      updatedAt: updatedAt ?? this.updatedAt,
      source: source ?? this.source,
      sourceUrl: sourceUrl is String? ? sourceUrl : this.sourceUrl,
      severity: severity ?? this.severity,
      confidence: confidence is double? ? confidence : this.confidence,
      country: country is String? ? country : this.country,
      region: region is String? ? region : this.region,
      city: city is String? ? city : this.city,
      rawMetadata: rawMetadata is String? ? rawMetadata : this.rawMetadata,
    );
  }
}
