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
import 'package:worldos_system_server/src/generated/protocol.dart' as _i2;

abstract class WatchZone
    implements _i1.TableRow<int?>, _i1.ProtocolSerialization {
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

  static final t = WatchZoneTable();

  static const db = WatchZoneRepository._();

  @override
  int? id;

  String name;

  double latitude;

  double longitude;

  double radiusKm;

  List<String> trackedTypes;

  DateTime createdAt;

  @override
  _i1.Table<int?> get table => t;

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
  Map<String, dynamic> toJsonForProtocol() {
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

  static WatchZoneInclude include() {
    return WatchZoneInclude._();
  }

  static WatchZoneIncludeList includeList({
    _i1.WhereExpressionBuilder<WatchZoneTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<WatchZoneTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<WatchZoneTable>? orderByList,
    WatchZoneInclude? include,
  }) {
    return WatchZoneIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(WatchZone.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(WatchZone.t),
      include: include,
    );
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

class WatchZoneUpdateTable extends _i1.UpdateTable<WatchZoneTable> {
  WatchZoneUpdateTable(super.table);

  _i1.ColumnValue<String, String> name(String value) => _i1.ColumnValue(
    table.name,
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

  _i1.ColumnValue<double, double> radiusKm(double value) => _i1.ColumnValue(
    table.radiusKm,
    value,
  );

  _i1.ColumnValue<List<String>, List<String>> trackedTypes(
    List<String> value,
  ) => _i1.ColumnValue(
    table.trackedTypes,
    value,
  );

  _i1.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _i1.ColumnValue(
        table.createdAt,
        value,
      );
}

class WatchZoneTable extends _i1.Table<int?> {
  WatchZoneTable({super.tableRelation}) : super(tableName: 'watch_zone') {
    updateTable = WatchZoneUpdateTable(this);
    name = _i1.ColumnString(
      'name',
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
    radiusKm = _i1.ColumnDouble(
      'radiusKm',
      this,
    );
    trackedTypes = _i1.ColumnSerializable<List<String>>(
      'trackedTypes',
      this,
    );
    createdAt = _i1.ColumnDateTime(
      'createdAt',
      this,
    );
  }

  late final WatchZoneUpdateTable updateTable;

  late final _i1.ColumnString name;

  late final _i1.ColumnDouble latitude;

  late final _i1.ColumnDouble longitude;

  late final _i1.ColumnDouble radiusKm;

  late final _i1.ColumnSerializable<List<String>> trackedTypes;

  late final _i1.ColumnDateTime createdAt;

  @override
  List<_i1.Column> get columns => [
    id,
    name,
    latitude,
    longitude,
    radiusKm,
    trackedTypes,
    createdAt,
  ];
}

class WatchZoneInclude extends _i1.IncludeObject {
  WatchZoneInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<int?> get table => WatchZone.t;
}

class WatchZoneIncludeList extends _i1.IncludeList {
  WatchZoneIncludeList._({
    _i1.WhereExpressionBuilder<WatchZoneTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(WatchZone.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<int?> get table => WatchZone.t;
}

class WatchZoneRepository {
  const WatchZoneRepository._();

  /// Returns a list of [WatchZone]s matching the given query parameters.
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
  Future<List<WatchZone>> find(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<WatchZoneTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<WatchZoneTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<WatchZoneTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<WatchZone>(
      where: where?.call(WatchZone.t),
      orderBy: orderBy?.call(WatchZone.t),
      orderByList: orderByList?.call(WatchZone.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [WatchZone] matching the given query parameters.
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
  Future<WatchZone?> findFirstRow(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<WatchZoneTable>? where,
    int? offset,
    _i1.OrderByBuilder<WatchZoneTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<WatchZoneTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<WatchZone>(
      where: where?.call(WatchZone.t),
      orderBy: orderBy?.call(WatchZone.t),
      orderByList: orderByList?.call(WatchZone.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [WatchZone] by its [id] or null if no such row exists.
  Future<WatchZone?> findById(
    _i1.DatabaseSession session,
    int id, {
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<WatchZone>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [WatchZone]s in the list and returns the inserted rows.
  ///
  /// The returned [WatchZone]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  ///
  /// If [ignoreConflicts] is set to `true`, rows that conflict with existing
  /// rows are silently skipped, and only the successfully inserted rows are
  /// returned.
  Future<List<WatchZone>> insert(
    _i1.DatabaseSession session,
    List<WatchZone> rows, {
    _i1.Transaction? transaction,
    bool ignoreConflicts = false,
  }) async {
    return session.db.insert<WatchZone>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
    );
  }

  /// Inserts a single [WatchZone] and returns the inserted row.
  ///
  /// The returned [WatchZone] will have its `id` field set.
  Future<WatchZone> insertRow(
    _i1.DatabaseSession session,
    WatchZone row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<WatchZone>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [WatchZone]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<WatchZone>> update(
    _i1.DatabaseSession session,
    List<WatchZone> rows, {
    _i1.ColumnSelections<WatchZoneTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<WatchZone>(
      rows,
      columns: columns?.call(WatchZone.t),
      transaction: transaction,
    );
  }

  /// Updates a single [WatchZone]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<WatchZone> updateRow(
    _i1.DatabaseSession session,
    WatchZone row, {
    _i1.ColumnSelections<WatchZoneTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<WatchZone>(
      row,
      columns: columns?.call(WatchZone.t),
      transaction: transaction,
    );
  }

  /// Updates a single [WatchZone] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<WatchZone?> updateById(
    _i1.DatabaseSession session,
    int id, {
    required _i1.ColumnValueListBuilder<WatchZoneUpdateTable> columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<WatchZone>(
      id,
      columnValues: columnValues(WatchZone.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [WatchZone]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  Future<List<WatchZone>> updateWhere(
    _i1.DatabaseSession session, {
    required _i1.ColumnValueListBuilder<WatchZoneUpdateTable> columnValues,
    required _i1.WhereExpressionBuilder<WatchZoneTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<WatchZoneTable>? orderBy,
    _i1.OrderByListBuilder<WatchZoneTable>? orderByList,
    bool orderDescending = false,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateWhere<WatchZone>(
      columnValues: columnValues(WatchZone.t.updateTable),
      where: where(WatchZone.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(WatchZone.t),
      orderByList: orderByList?.call(WatchZone.t),
      orderDescending: orderDescending,
      transaction: transaction,
    );
  }

  /// Deletes all [WatchZone]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<WatchZone>> delete(
    _i1.DatabaseSession session,
    List<WatchZone> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<WatchZone>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [WatchZone].
  Future<WatchZone> deleteRow(
    _i1.DatabaseSession session,
    WatchZone row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<WatchZone>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<WatchZone>> deleteWhere(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<WatchZoneTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<WatchZone>(
      where: where(WatchZone.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<WatchZoneTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<WatchZone>(
      where: where?.call(WatchZone.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [WatchZone] rows matching the [where] expression.
  Future<void> lockRows(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<WatchZoneTable> where,
    required _i1.LockMode lockMode,
    required _i1.Transaction transaction,
    _i1.LockBehavior lockBehavior = _i1.LockBehavior.wait,
  }) async {
    return session.db.lockRows<WatchZone>(
      where: where(WatchZone.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
