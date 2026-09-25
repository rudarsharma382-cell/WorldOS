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

abstract class EventMediaPayload
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  EventMediaPayload._({
    this.satelliteImageUrl,
    this.groundImageUrl,
    this.attribution,
    this.title,
    this.caption,
  });

  factory EventMediaPayload({
    String? satelliteImageUrl,
    String? groundImageUrl,
    String? attribution,
    String? title,
    String? caption,
  }) = _EventMediaPayloadImpl;

  factory EventMediaPayload.fromJson(Map<String, dynamic> jsonSerialization) {
    return EventMediaPayload(
      satelliteImageUrl: jsonSerialization['satelliteImageUrl'] as String?,
      groundImageUrl: jsonSerialization['groundImageUrl'] as String?,
      attribution: jsonSerialization['attribution'] as String?,
      title: jsonSerialization['title'] as String?,
      caption: jsonSerialization['caption'] as String?,
    );
  }

  String? satelliteImageUrl;

  String? groundImageUrl;

  String? attribution;

  String? title;

  String? caption;

  /// Returns a shallow copy of this [EventMediaPayload]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  EventMediaPayload copyWith({
    String? satelliteImageUrl,
    String? groundImageUrl,
    String? attribution,
    String? title,
    String? caption,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'EventMediaPayload',
      if (satelliteImageUrl != null) 'satelliteImageUrl': satelliteImageUrl,
      if (groundImageUrl != null) 'groundImageUrl': groundImageUrl,
      if (attribution != null) 'attribution': attribution,
      if (title != null) 'title': title,
      if (caption != null) 'caption': caption,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'EventMediaPayload',
      if (satelliteImageUrl != null) 'satelliteImageUrl': satelliteImageUrl,
      if (groundImageUrl != null) 'groundImageUrl': groundImageUrl,
      if (attribution != null) 'attribution': attribution,
      if (title != null) 'title': title,
      if (caption != null) 'caption': caption,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _EventMediaPayloadImpl extends EventMediaPayload {
  _EventMediaPayloadImpl({
    String? satelliteImageUrl,
    String? groundImageUrl,
    String? attribution,
    String? title,
    String? caption,
  }) : super._(
         satelliteImageUrl: satelliteImageUrl,
         groundImageUrl: groundImageUrl,
         attribution: attribution,
         title: title,
         caption: caption,
       );

  /// Returns a shallow copy of this [EventMediaPayload]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  EventMediaPayload copyWith({
    Object? satelliteImageUrl = _Undefined,
    Object? groundImageUrl = _Undefined,
    Object? attribution = _Undefined,
    Object? title = _Undefined,
    Object? caption = _Undefined,
  }) {
    return EventMediaPayload(
      satelliteImageUrl: satelliteImageUrl is String?
          ? satelliteImageUrl
          : this.satelliteImageUrl,
      groundImageUrl: groundImageUrl is String?
          ? groundImageUrl
          : this.groundImageUrl,
      attribution: attribution is String? ? attribution : this.attribution,
      title: title is String? ? title : this.title,
      caption: caption is String? ? caption : this.caption,
    );
  }
}
