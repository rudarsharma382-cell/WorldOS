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

abstract class Investigation implements _i1.SerializableModel {
  Investigation._({
    this.id,
    required this.title,
    this.notes,
    required this.eventIds,
    required this.createdAt,
  });

  factory Investigation({
    int? id,
    required String title,
    String? notes,
    required List<String> eventIds,
    required DateTime createdAt,
  }) = _InvestigationImpl;

  factory Investigation.fromJson(Map<String, dynamic> jsonSerialization) {
    return Investigation(
      id: jsonSerialization['id'] as int?,
      title: jsonSerialization['title'] as String,
      notes: jsonSerialization['notes'] as String?,
      eventIds: _i2.Protocol().deserialize<List<String>>(
        jsonSerialization['eventIds'],
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

  String title;

  String? notes;

  List<String> eventIds;

  DateTime createdAt;

  /// Returns a shallow copy of this [Investigation]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  Investigation copyWith({
    int? id,
    String? title,
    String? notes,
    List<String>? eventIds,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'Investigation',
      if (id != null) 'id': id,
      'title': title,
      if (notes != null) 'notes': notes,
      'eventIds': eventIds.toJson(),
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _InvestigationImpl extends Investigation {
  _InvestigationImpl({
    int? id,
    required String title,
    String? notes,
    required List<String> eventIds,
    required DateTime createdAt,
  }) : super._(
         id: id,
         title: title,
         notes: notes,
         eventIds: eventIds,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [Investigation]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  Investigation copyWith({
    Object? id = _Undefined,
    String? title,
    Object? notes = _Undefined,
    List<String>? eventIds,
    DateTime? createdAt,
  }) {
    return Investigation(
      id: id is int? ? id : this.id,
      title: title ?? this.title,
      notes: notes is String? ? notes : this.notes,
      eventIds: eventIds ?? this.eventIds.map((e0) => e0).toList(),
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
