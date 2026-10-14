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

import 'package:serverpod/serverpod.dart' as _i1;

abstract class CameraFeedPayload
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  CameraFeedPayload._({
    required this.id,
    required this.title,
    required this.latitude,
    required this.longitude,
    required this.previewImageUrl,
    required this.fullImageUrl,
    required this.updatedAt,
  });

  factory CameraFeedPayload({
    required String id,
    required String title,
    required double latitude,
    required double longitude,
    required String previewImageUrl,
    required String fullImageUrl,
    required String updatedAt,
  }) = _CameraFeedPayloadImpl;

  factory CameraFeedPayload.fromJson(Map<String, dynamic> jsonSerialization) {
    return CameraFeedPayload(
      id: jsonSerialization['id'] as String,
      title: jsonSerialization['title'] as String,
      latitude: (jsonSerialization['latitude'] as num).toDouble(),
      longitude: (jsonSerialization['longitude'] as num).toDouble(),
      previewImageUrl: jsonSerialization['previewImageUrl'] as String,
      fullImageUrl: jsonSerialization['fullImageUrl'] as String,
      updatedAt: jsonSerialization['updatedAt'] as String,
    );
  }

  String id;

  String title;

  double latitude;

  double longitude;

  String previewImageUrl;

  String fullImageUrl;

  String updatedAt;

  /// Returns a shallow copy of this [CameraFeedPayload]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  CameraFeedPayload copyWith({
    String? id,
    String? title,
    double? latitude,
    double? longitude,
    String? previewImageUrl,
    String? fullImageUrl,
    String? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'CameraFeedPayload',
      'id': id,
      'title': title,
      'latitude': latitude,
      'longitude': longitude,
      'previewImageUrl': previewImageUrl,
      'fullImageUrl': fullImageUrl,
      'updatedAt': updatedAt,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'CameraFeedPayload',
      'id': id,
      'title': title,
      'latitude': latitude,
      'longitude': longitude,
      'previewImageUrl': previewImageUrl,
      'fullImageUrl': fullImageUrl,
      'updatedAt': updatedAt,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _CameraFeedPayloadImpl extends CameraFeedPayload {
  _CameraFeedPayloadImpl({
    required String id,
    required String title,
    required double latitude,
    required double longitude,
    required String previewImageUrl,
    required String fullImageUrl,
    required String updatedAt,
  }) : super._(
         id: id,
         title: title,
         latitude: latitude,
         longitude: longitude,
         previewImageUrl: previewImageUrl,
         fullImageUrl: fullImageUrl,
         updatedAt: updatedAt,
       );

  /// Returns a shallow copy of this [CameraFeedPayload]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  CameraFeedPayload copyWith({
    String? id,
    String? title,
    double? latitude,
    double? longitude,
    String? previewImageUrl,
    String? fullImageUrl,
    String? updatedAt,
  }) {
    return CameraFeedPayload(
      id: id ?? this.id,
      title: title ?? this.title,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      previewImageUrl: previewImageUrl ?? this.previewImageUrl,
      fullImageUrl: fullImageUrl ?? this.fullImageUrl,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
