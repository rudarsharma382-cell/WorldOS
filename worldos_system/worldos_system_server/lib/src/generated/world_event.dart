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

abstract class WorldEvent
    implements _i1.TableRow<int?>, _i1.ProtocolSerialization {
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

  static final t = WorldEventTable();

  static const db = WorldEventRepository._();

  @override
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

  @override
  _i1.Table<int?> get table => t;

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
  Map<String, dynamic> toJsonForProtocol() {
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

  static WorldEventInclude include() {
    return WorldEventInclude._();
  }

  static WorldEventIncludeList includeList({
    _i1.WhereExpressionBuilder<WorldEventTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<WorldEventTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<WorldEventTable>? orderByList,
    WorldEventInclude? include,
  }) {
    return WorldEventIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(WorldEvent.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(WorldEvent.t),
      include: include,
    );
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

class WorldEventUpdateTable extends _i1.UpdateTable<WorldEventTable> {
  WorldEventUpdateTable(super.table);

  _i1.ColumnValue<String, String> externalId(String value) => _i1.ColumnValue(
    table.externalId,
    value,
  );

  _i1.ColumnValue<String, String> type(String value) => _i1.ColumnValue(
    table.type,
    value,
  );

  _i1.ColumnValue<String, String> title(String value) => _i1.ColumnValue(
    table.title,
    value,
  );

  _i1.ColumnValue<String, String> description(String? value) => _i1.ColumnValue(
    table.description,
    value,
  );

  _i1.ColumnValue<double, double> latitude(double value) => _i1.ColumnValue(
    table.latitude,
    value,
  );

  _i1.ColumnValue<double, double> longitude(double value) => _i1.ColumnValue(
    table.longitude,
    value,
  );

  _i1.ColumnValue<double, double> altitude(double? value) => _i1.ColumnValue(
    table.altitude,
    value,
  );

  _i1.ColumnValue<DateTime, DateTime> timestamp(DateTime value) =>
      _i1.ColumnValue(
        table.timestamp,
        value,
      );

  _i1.ColumnValue<DateTime, DateTime> updatedAt(DateTime value) =>
      _i1.ColumnValue(
        table.updatedAt,
        value,
      );

  _i1.ColumnValue<String, String> source(String value) => _i1.ColumnValue(
    table.source,
    value,
  );

  _i1.ColumnValue<String, String> sourceUrl(String? value) => _i1.ColumnValue(
    table.sourceUrl,
    value,
  );

  _i1.ColumnValue<double, double> severity(double value) => _i1.ColumnValue(
    table.severity,
    value,
  );

  _i1.ColumnValue<double, double> confidence(double? value) => _i1.ColumnValue(
    table.confidence,
    value,
  );

  _i1.ColumnValue<String, String> country(String? value) => _i1.ColumnValue(
    table.country,
    value,
  );

  _i1.ColumnValue<String, String> region(String? value) => _i1.ColumnValue(
    table.region,
    value,
  );

  _i1.ColumnValue<String, String> city(String? value) => _i1.ColumnValue(
    table.city,
    value,
  );

  _i1.ColumnValue<String, String> rawMetadata(String? value) => _i1.ColumnValue(
    table.rawMetadata,
    value,
  );
}

class WorldEventTable extends _i1.Table<int?> {
  WorldEventTable({super.tableRelation}) : super(tableName: 'world_event') {
    updateTable = WorldEventUpdateTable(this);
    externalId = _i1.ColumnString(
      'externalId',
      this,
    );
    type = _i1.ColumnString(
      'type',
      this,
    );
    title = _i1.ColumnString(
      'title',
      this,
    );
    description = _i1.ColumnString(
      'description',
      this,
    );
    latitude = _i1.ColumnDouble(
      'latitude',
      this,
    );
    longitude = _i1.ColumnDouble(
      'longitude',
      this,
    );
    altitude = _i1.ColumnDouble(
      'altitude',
      this,
    );
    timestamp = _i1.ColumnDateTime(
      'timestamp',
      this,
    );
    updatedAt = _i1.ColumnDateTime(
      'updatedAt',
      this,
    );
    source = _i1.ColumnString(
      'source',
      this,
    );
    sourceUrl = _i1.ColumnString(
      'sourceUrl',
      this,
    );
    severity = _i1.ColumnDouble(
      'severity',
      this,
    );
    confidence = _i1.ColumnDouble(
      'confidence',
      this,
    );
    country = _i1.ColumnString(
      'country',
      this,
    );
    region = _i1.ColumnString(
      'region',
      this,
    );
    city = _i1.ColumnString(
      'city',
      this,
    );
    rawMetadata = _i1.ColumnString(
      'rawMetadata',
      this,
    );
  }

  late final WorldEventUpdateTable updateTable;

  late final _i1.ColumnString externalId;

  late final _i1.ColumnString type;

  late final _i1.ColumnString title;

  late final _i1.ColumnString description;

  late final _i1.ColumnDouble latitude;

  late final _i1.ColumnDouble longitude;

  late final _i1.ColumnDouble altitude;

  late final _i1.ColumnDateTime timestamp;

  late final _i1.ColumnDateTime updatedAt;

  late final _i1.ColumnString source;

  late final _i1.ColumnString sourceUrl;

  late final _i1.ColumnDouble severity;

  late final _i1.ColumnDouble confidence;

  late final _i1.ColumnString country;

  late final _i1.ColumnString region;

  late final _i1.ColumnString city;

  late final _i1.ColumnString rawMetadata;

  @override
  List<_i1.Column> get columns => [
    id,
    externalId,
    type,
    title,
    description,
    latitude,
    longitude,
    altitude,
    timestamp,
    updatedAt,
    source,
    sourceUrl,
    severity,
    confidence,
    country,
    region,
    city,
    rawMetadata,
  ];
}

class WorldEventInclude extends _i1.IncludeObject {
  WorldEventInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<int?> get table => WorldEvent.t;
}

class WorldEventIncludeList extends _i1.IncludeList {
  WorldEventIncludeList._({
    _i1.WhereExpressionBuilder<WorldEventTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(WorldEvent.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<int?> get table => WorldEvent.t;
}

class WorldEventRepository {
  const WorldEventRepository._();

  /// Returns a list of [WorldEvent]s matching the given query parameters.
  ///
  /// Use [where] to specify which items to include in the return value.
  /// If none is specified, all items will be returned.
  ///
  /// To specify the order of the items use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// The maximum number of items can be set by [limit]. If no limit is set,
  /// all items matching the query will be returned.
  ///
  /// [offset] defines how many items to skip, after which [limit] (or all)
  /// items are read from the database.
  ///
  /// ```dart
  /// var persons = await Persons.db.find(
  ///   session,
  ///   where: (t) => t.lastName.equals('Jones'),
  ///   orderBy: (t) => t.firstName,
  ///   limit: 100,
  /// );
  /// ```
  Future<List<WorldEvent>> find(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<WorldEventTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<WorldEventTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<WorldEventTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<WorldEvent>(
      where: where?.call(WorldEvent.t),
      orderBy: orderBy?.call(WorldEvent.t),
      orderByList: orderByList?.call(WorldEvent.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [WorldEvent] matching the given query parameters.
  ///
  /// Use [where] to specify which items to include in the return value.
  /// If none is specified, all items will be returned.
  ///
  /// To specify the order use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// [offset] defines how many items to skip, after which the next one will be picked.
  ///
  /// ```dart
  /// var youngestPerson = await Persons.db.findFirstRow(
  ///   session,
  ///   where: (t) => t.lastName.equals('Jones'),
  ///   orderBy: (t) => t.age,
  /// );
  /// ```
  Future<WorldEvent?> findFirstRow(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<WorldEventTable>? where,
    int? offset,
    _i1.OrderByBuilder<WorldEventTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<WorldEventTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<WorldEvent>(
      where: where?.call(WorldEvent.t),
      orderBy: orderBy?.call(WorldEvent.t),
      orderByList: orderByList?.call(WorldEvent.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [WorldEvent] by its [id] or null if no such row exists.
  Future<WorldEvent?> findById(
    _i1.DatabaseSession session,
    int id, {
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<WorldEvent>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [WorldEvent]s in the list and returns the inserted rows.
  ///
  /// The returned [WorldEvent]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  ///
  /// If [ignoreConflicts] is set to `true`, rows that conflict with existing
  /// rows are silently skipped, and only the successfully inserted rows are
  /// returned.
  Future<List<WorldEvent>> insert(
    _i1.DatabaseSession session,
    List<WorldEvent> rows, {
    _i1.Transaction? transaction,
    bool ignoreConflicts = false,
  }) async {
    return session.db.insert<WorldEvent>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
    );
  }

  /// Inserts a single [WorldEvent] and returns the inserted row.
  ///
  /// The returned [WorldEvent] will have its `id` field set.
  Future<WorldEvent> insertRow(
    _i1.DatabaseSession session,
    WorldEvent row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<WorldEvent>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [WorldEvent]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<WorldEvent>> update(
    _i1.DatabaseSession session,
    List<WorldEvent> rows, {
    _i1.ColumnSelections<WorldEventTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<WorldEvent>(
      rows,
      columns: columns?.call(WorldEvent.t),
      transaction: transaction,
    );
  }

  /// Updates a single [WorldEvent]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<WorldEvent> updateRow(
    _i1.DatabaseSession session,
    WorldEvent row, {
    _i1.ColumnSelections<WorldEventTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<WorldEvent>(
      row,
      columns: columns?.call(WorldEvent.t),
      transaction: transaction,
    );
  }

  /// Updates a single [WorldEvent] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<WorldEvent?> updateById(
    _i1.DatabaseSession session,
    int id, {
    required _i1.ColumnValueListBuilder<WorldEventUpdateTable> columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<WorldEvent>(
      id,
      columnValues: columnValues(WorldEvent.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [WorldEvent]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  Future<List<WorldEvent>> updateWhere(
    _i1.DatabaseSession session, {
    required _i1.ColumnValueListBuilder<WorldEventUpdateTable> columnValues,
    required _i1.WhereExpressionBuilder<WorldEventTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<WorldEventTable>? orderBy,
    _i1.OrderByListBuilder<WorldEventTable>? orderByList,
    bool orderDescending = false,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateWhere<WorldEvent>(
      columnValues: columnValues(WorldEvent.t.updateTable),
      where: where(WorldEvent.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(WorldEvent.t),
      orderByList: orderByList?.call(WorldEvent.t),
      orderDescending: orderDescending,
      transaction: transaction,
    );
  }

  /// Deletes all [WorldEvent]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<WorldEvent>> delete(
    _i1.DatabaseSession session,
    List<WorldEvent> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<WorldEvent>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [WorldEvent].
  Future<WorldEvent> deleteRow(
    _i1.DatabaseSession session,
    WorldEvent row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<WorldEvent>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<WorldEvent>> deleteWhere(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<WorldEventTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<WorldEvent>(
      where: where(WorldEvent.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<WorldEventTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<WorldEvent>(
      where: where?.call(WorldEvent.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [WorldEvent] rows matching the [where] expression.
  Future<void> lockRows(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<WorldEventTable> where,
    required _i1.LockMode lockMode,
    required _i1.Transaction transaction,
    _i1.LockBehavior lockBehavior = _i1.LockBehavior.wait,
  }) async {
    return session.db.lockRows<WorldEvent>(
      where: where(WorldEvent.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
