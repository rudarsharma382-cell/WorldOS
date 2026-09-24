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
import 'package:worldos_system_client/src/protocol/protocol.dart' as _i2;

abstract class WatchZone implements _i1.SerializableModel {
  WatchZone._({
    this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.radiusKm,
    required this.trackedTypes,
    required this.createdAt,
  });

  factory WatchZone({
    int? id,
    required String name,
    required double latitude,
    required double longitude,
    required double radiusKm,
    required List<String> trackedTypes,
    required DateTime createdAt,
  }) = _WatchZoneImpl;

  factory WatchZone.fromJson(Map<String, dynamic> jsonSerialization) {
    return WatchZone(
      id: jsonSerialization['id'] as int?,
      name: jsonSerialization['name'] as String,
      latitude: (jsonSerialization['latitude'] as num).toDouble(),
      longitude: (jsonSerialization['longitude'] as num).toDouble(),
      radiusKm: (jsonSerialization['radiusKm'] as num).toDouble(),
      trackedTypes: _i2.Protocol().deserialize<List<String>>(
        jsonSerialization['trackedTypes'],
      ),
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  String name;

  double latitude;

  double longitude;

  double radiusKm;

  List<String> trackedTypes;

  DateTime createdAt;

  /// Returns a shallow copy of this [WatchZone]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  WatchZone copyWith({
    int? id,
    String? name,
    double? latitude,
    double? longitude,
    double? radiusKm,
    List<String>? trackedTypes,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'WatchZone',
      if (id != null) 'id': id,
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'radiusKm': radiusKm,
      'trackedTypes': trackedTypes.toJson(),
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _WatchZoneImpl extends WatchZone {
  _WatchZoneImpl({
    int? id,
    required String name,
    required double latitude,
    required double longitude,
    required double radiusKm,
    required List<String> trackedTypes,
    required DateTime createdAt,
  }) : super._(
         id: id,
         name: name,
         latitude: latitude,
         longitude: longitude,
         radiusKm: radiusKm,
         trackedTypes: trackedTypes,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [WatchZone]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  WatchZone copyWith({
    Object? id = _Undefined,
    String? name,
    double? latitude,
    double? longitude,
    double? radiusKm,
    List<String>? trackedTypes,
    DateTime? createdAt,
  }) {
    return WatchZone(
      id: id is int? ? id : this.id,
      name: name ?? this.name,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      radiusKm: radiusKm ?? this.radiusKm,
      trackedTypes: trackedTypes ?? this.trackedTypes.map((e0) => e0).toList(),
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
