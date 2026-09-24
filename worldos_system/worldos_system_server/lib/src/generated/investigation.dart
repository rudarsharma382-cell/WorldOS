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

abstract class Investigation
    implements _i1.TableRow<int?>, _i1.ProtocolSerialization {
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

  static final t = InvestigationTable();

  static const db = InvestigationRepository._();

  @override
  int? id;

  String title;

  String? notes;

  List<String> eventIds;

  DateTime createdAt;

  @override
  _i1.Table<int?> get table => t;

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
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'Investigation',
      if (id != null) 'id': id,
      'title': title,
      if (notes != null) 'notes': notes,
      'eventIds': eventIds.toJson(),
      'createdAt': createdAt.toJson(),
    };
  }

  static InvestigationInclude include() {
    return InvestigationInclude._();
  }

  static InvestigationIncludeList includeList({
    _i1.WhereExpressionBuilder<InvestigationTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<InvestigationTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<InvestigationTable>? orderByList,
    InvestigationInclude? include,
  }) {
    return InvestigationIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(Investigation.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(Investigation.t),
      include: include,
    );
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

class InvestigationUpdateTable extends _i1.UpdateTable<InvestigationTable> {
  InvestigationUpdateTable(super.table);

  _i1.ColumnValue<String, String> title(String value) => _i1.ColumnValue(
    table.title,
    value,
  );

  _i1.ColumnValue<String, String> notes(String? value) => _i1.ColumnValue(
    table.notes,
    value,
  );

  _i1.ColumnValue<List<String>, List<String>> eventIds(List<String> value) =>
      _i1.ColumnValue(
        table.eventIds,
        value,
      );

  _i1.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _i1.ColumnValue(
        table.createdAt,
        value,
      );
}

class InvestigationTable extends _i1.Table<int?> {
  InvestigationTable({super.tableRelation})
    : super(tableName: 'investigation') {
    updateTable = InvestigationUpdateTable(this);
    title = _i1.ColumnString(
      'title',
      this,
    );
    notes = _i1.ColumnString(
      'notes',
      this,
    );
    eventIds = _i1.ColumnSerializable<List<String>>(
      'eventIds',
      this,
    );
    createdAt = _i1.ColumnDateTime(
      'createdAt',
      this,
    );
  }

  late final InvestigationUpdateTable updateTable;

  late final _i1.ColumnString title;

  late final _i1.ColumnString notes;

  late final _i1.ColumnSerializable<List<String>> eventIds;

  late final _i1.ColumnDateTime createdAt;

  @override
  List<_i1.Column> get columns => [
    id,
    title,
    notes,
    eventIds,
    createdAt,
  ];
}

class InvestigationInclude extends _i1.IncludeObject {
  InvestigationInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<int?> get table => Investigation.t;
}

class InvestigationIncludeList extends _i1.IncludeList {
  InvestigationIncludeList._({
    _i1.WhereExpressionBuilder<InvestigationTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(Investigation.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<int?> get table => Investigation.t;
}

class InvestigationRepository {
  const InvestigationRepository._();

  /// Returns a list of [Investigation]s matching the given query parameters.
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
  Future<List<Investigation>> find(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<InvestigationTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<InvestigationTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<InvestigationTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<Investigation>(
      where: where?.call(Investigation.t),
      orderBy: orderBy?.call(Investigation.t),
      orderByList: orderByList?.call(Investigation.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [Investigation] matching the given query parameters.
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
  Future<Investigation?> findFirstRow(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<InvestigationTable>? where,
    int? offset,
    _i1.OrderByBuilder<InvestigationTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<InvestigationTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<Investigation>(
      where: where?.call(Investigation.t),
      orderBy: orderBy?.call(Investigation.t),
      orderByList: orderByList?.call(Investigation.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [Investigation] by its [id] or null if no such row exists.
  Future<Investigation?> findById(
    _i1.DatabaseSession session,
    int id, {
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<Investigation>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [Investigation]s in the list and returns the inserted rows.
  ///
  /// The returned [Investigation]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  ///
  /// If [ignoreConflicts] is set to `true`, rows that conflict with existing
  /// rows are silently skipped, and only the successfully inserted rows are
  /// returned.
  Future<List<Investigation>> insert(
    _i1.DatabaseSession session,
    List<Investigation> rows, {
    _i1.Transaction? transaction,
    bool ignoreConflicts = false,
  }) async {
    return session.db.insert<Investigation>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
    );
  }

  /// Inserts a single [Investigation] and returns the inserted row.
  ///
  /// The returned [Investigation] will have its `id` field set.
  Future<Investigation> insertRow(
    _i1.DatabaseSession session,
    Investigation row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<Investigation>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [Investigation]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<Investigation>> update(
    _i1.DatabaseSession session,
    List<Investigation> rows, {
    _i1.ColumnSelections<InvestigationTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<Investigation>(
      rows,
      columns: columns?.call(Investigation.t),
      transaction: transaction,
    );
  }

  /// Updates a single [Investigation]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<Investigation> updateRow(
    _i1.DatabaseSession session,
    Investigation row, {
    _i1.ColumnSelections<InvestigationTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<Investigation>(
      row,
      columns: columns?.call(Investigation.t),
      transaction: transaction,
    );
  }

  /// Updates a single [Investigation] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<Investigation?> updateById(
    _i1.DatabaseSession session,
    int id, {
    required _i1.ColumnValueListBuilder<InvestigationUpdateTable> columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<Investigation>(
      id,
      columnValues: columnValues(Investigation.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [Investigation]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  Future<List<Investigation>> updateWhere(
    _i1.DatabaseSession session, {
    required _i1.ColumnValueListBuilder<InvestigationUpdateTable> columnValues,
    required _i1.WhereExpressionBuilder<InvestigationTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<InvestigationTable>? orderBy,
    _i1.OrderByListBuilder<InvestigationTable>? orderByList,
    bool orderDescending = false,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateWhere<Investigation>(
      columnValues: columnValues(Investigation.t.updateTable),
      where: where(Investigation.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(Investigation.t),
      orderByList: orderByList?.call(Investigation.t),
      orderDescending: orderDescending,
      transaction: transaction,
    );
  }

  /// Deletes all [Investigation]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<Investigation>> delete(
    _i1.DatabaseSession session,
    List<Investigation> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<Investigation>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [Investigation].
  Future<Investigation> deleteRow(
    _i1.DatabaseSession session,
    Investigation row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<Investigation>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<Investigation>> deleteWhere(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<InvestigationTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<Investigation>(
      where: where(Investigation.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<InvestigationTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<Investigation>(
      where: where?.call(Investigation.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [Investigation] rows matching the [where] expression.
  Future<void> lockRows(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<InvestigationTable> where,
    required _i1.LockMode lockMode,
    required _i1.Transaction transaction,
    _i1.LockBehavior lockBehavior = _i1.LockBehavior.wait,
  }) async {
    return session.db.lockRows<Investigation>(
      where: where(Investigation.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
