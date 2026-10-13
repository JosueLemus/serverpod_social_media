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
import 'package:serverpod/serverpod.dart' as _is;

/// Alguien que no entra a ningún vivo de [hostId] hasta que el host lo
/// levante. Sólo el host banea (SDD 0011, §3).
abstract class LiveHostBan
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
  LiveHostBan._({
    this.id,
    required this.hostId,
    required this.userId,
    required this.actorId,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory LiveHostBan({
    int? id,
    required _is.UuidValue hostId,
    required _is.UuidValue userId,
    required _is.UuidValue actorId,
    DateTime? createdAt,
  }) = _LiveHostBanImpl;

  factory LiveHostBan.fromJson(Map<String, dynamic> jsonSerialization) {
    return LiveHostBan(
      id: jsonSerialization['id'] as int?,
      hostId: _is.UuidValueJsonExtension.fromJson(jsonSerialization['hostId']),
      userId: _is.UuidValueJsonExtension.fromJson(jsonSerialization['userId']),
      actorId: _is.UuidValueJsonExtension.fromJson(
        jsonSerialization['actorId'],
      ),
      createdAt: jsonSerialization['createdAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['createdAt']),
    );
  }

  static final t = LiveHostBanTable();

  static const db = LiveHostBanRepository._();

  @override
  int? id;

  _is.UuidValue hostId;

  _is.UuidValue userId;

  _is.UuidValue actorId;

  DateTime createdAt;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [LiveHostBan]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  LiveHostBan copyWith({
    int? id,
    _is.UuidValue? hostId,
    _is.UuidValue? userId,
    _is.UuidValue? actorId,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'LiveHostBan',
      if (id != null) 'id': id,
      'hostId': hostId.toJson(),
      'userId': userId.toJson(),
      'actorId': actorId.toJson(),
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {};
  }

  static LiveHostBanInclude include() {
    return LiveHostBanInclude._();
  }

  static LiveHostBanIncludeList includeList({
    _is.WhereExpressionBuilder<LiveHostBanTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<LiveHostBanTable>? orderBy,
    _is.OrderByListBuilder<LiveHostBanTable>? orderByList,
    LiveHostBanInclude? include,
  }) {
    return LiveHostBanIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(LiveHostBan.t),
      orderByList: orderByList?.call(LiveHostBan.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _LiveHostBanImpl extends LiveHostBan {
  _LiveHostBanImpl({
    int? id,
    required _is.UuidValue hostId,
    required _is.UuidValue userId,
    required _is.UuidValue actorId,
    DateTime? createdAt,
  }) : super._(
         id: id,
         hostId: hostId,
         userId: userId,
         actorId: actorId,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [LiveHostBan]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  LiveHostBan copyWith({
    Object? id = _Undefined,
    _is.UuidValue? hostId,
    _is.UuidValue? userId,
    _is.UuidValue? actorId,
    DateTime? createdAt,
  }) {
    return LiveHostBan(
      id: id is int? ? id : this.id,
      hostId: hostId ?? this.hostId,
      userId: userId ?? this.userId,
      actorId: actorId ?? this.actorId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class LiveHostBanUpdateTable extends _is.UpdateTable<LiveHostBanTable> {
  LiveHostBanUpdateTable(super.table);

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> hostId(_is.UuidValue value) =>
      _is.ColumnValue(
        table.hostId,
        value,
      );

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> userId(_is.UuidValue value) =>
      _is.ColumnValue(
        table.userId,
        value,
      );

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> actorId(_is.UuidValue value) =>
      _is.ColumnValue(
        table.actorId,
        value,
      );

  _is.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _is.ColumnValue(
        table.createdAt,
        value,
      );
}

class LiveHostBanTable extends _is.Table<int?> {
  LiveHostBanTable({super.tableRelation}) : super(tableName: 'live_host_ban') {
    updateTable = LiveHostBanUpdateTable(this);
    hostId = _is.ColumnUuid(
      'hostId',
      this,
    );
    userId = _is.ColumnUuid(
      'userId',
      this,
    );
    actorId = _is.ColumnUuid(
      'actorId',
      this,
    );
    createdAt = _is.ColumnDateTime(
      'createdAt',
      this,
      hasDefault: true,
    );
  }

  late final LiveHostBanUpdateTable updateTable;

  late final _is.ColumnUuid hostId;

  late final _is.ColumnUuid userId;

  late final _is.ColumnUuid actorId;

  late final _is.ColumnDateTime createdAt;

  @override
  List<_is.Column> get columns => [
    id,
    hostId,
    userId,
    actorId,
    createdAt,
  ];
}

class LiveHostBanInclude extends _is.IncludeObject {
  LiveHostBanInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => LiveHostBan.t;
}

class LiveHostBanIncludeList extends _is.IncludeList {
  LiveHostBanIncludeList._({
    _is.WhereExpressionBuilder<LiveHostBanTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(LiveHostBan.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => LiveHostBan.t;
}

class LiveHostBanRepository {
  const LiveHostBanRepository._();

  /// Returns a list of [LiveHostBan]s matching the given query parameters.
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
  Future<List<LiveHostBan>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<LiveHostBanTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<LiveHostBanTable>? orderBy,
    _is.OrderByListBuilder<LiveHostBanTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<LiveHostBan>(
      where: where?.call(LiveHostBan.t),
      orderBy: orderBy?.call(LiveHostBan.t),
      orderByList: orderByList?.call(LiveHostBan.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [LiveHostBan] matching the given query parameters.
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
  Future<LiveHostBan?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<LiveHostBanTable>? where,
    int? offset,
    _is.OrderByBuilder<LiveHostBanTable>? orderBy,
    _is.OrderByListBuilder<LiveHostBanTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<LiveHostBan>(
      where: where?.call(LiveHostBan.t),
      orderBy: orderBy?.call(LiveHostBan.t),
      orderByList: orderByList?.call(LiveHostBan.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [LiveHostBan] by its [id] or null if no such row exists.
  Future<LiveHostBan?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<LiveHostBan>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [LiveHostBan]s in the list and returns the inserted rows.
  ///
  /// The returned [LiveHostBan]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  ///
  /// If [ignoreConflicts] is set to `true`, rows that conflict with existing
  /// rows are silently skipped, and only the successfully inserted rows are
  /// returned.
  ///
  /// If [noReturn] is set to `true`, the inserted rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<LiveHostBan>> insert(
    _is.DatabaseSession session,
    List<LiveHostBan> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<LiveHostBan>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [LiveHostBan] and returns the inserted row.
  ///
  /// The returned [LiveHostBan] will have its `id` field set.
  Future<LiveHostBan> insertRow(
    _is.DatabaseSession session,
    LiveHostBan row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<LiveHostBan>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [LiveHostBan]s in the list and returns the resulting rows.
  ///
  /// If a row conflicts on the given [conflictColumns], the existing row is
  /// updated with the new values. Otherwise, a new row is inserted.
  ///
  /// If [updateColumns] is provided, only those columns will be updated on
  /// conflict. If null, all non-conflict, non-id columns are updated.
  ///
  /// If [updateWhere] is provided, the update only applies to rows matching the
  /// given expression. Conflicting rows that don't match are skipped and not
  /// returned, so the resulting list may be shorter than [rows].
  ///
  /// The returned [LiveHostBan]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<LiveHostBan>> upsert(
    _is.DatabaseSession session,
    List<LiveHostBan> rows, {
    required _is.ColumnSelections<LiveHostBanTable> conflictColumns,
    _is.ColumnSelections<LiveHostBanTable>? updateColumns,
    _is.WhereExpressionBuilder<LiveHostBanTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<LiveHostBan>(
      rows,
      conflictColumns: conflictColumns(LiveHostBan.t),
      updateColumns: updateColumns?.call(LiveHostBan.t),
      updateWhere: updateWhere?.call(LiveHostBan.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [LiveHostBan] and returns the resulting row.
  ///
  /// If the row conflicts on the given [conflictColumns], the existing row is
  /// updated. Otherwise, a new row is inserted.
  ///
  /// If [updateColumns] is provided, only those columns will be updated on
  /// conflict. If null, all non-conflict, non-id columns are updated.
  ///
  /// If [updateWhere] is provided, the update only applies when the existing
  /// row matches the expression. Returns `null` if no row was affected — for
  /// example when [updateWhere] does not match the conflicting row.
  ///
  /// The returned [LiveHostBan] will have its `id` field set.
  Future<LiveHostBan?> upsertRow(
    _is.DatabaseSession session,
    LiveHostBan row, {
    required _is.ColumnSelections<LiveHostBanTable> conflictColumns,
    _is.ColumnSelections<LiveHostBanTable>? updateColumns,
    _is.WhereExpressionBuilder<LiveHostBanTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<LiveHostBan>(
      row,
      conflictColumns: conflictColumns(LiveHostBan.t),
      updateColumns: updateColumns?.call(LiveHostBan.t),
      updateWhere: updateWhere?.call(LiveHostBan.t),
      transaction: transaction,
    );
  }

  /// Updates all [LiveHostBan]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<LiveHostBan>> update(
    _is.DatabaseSession session,
    List<LiveHostBan> rows, {
    _is.ColumnSelections<LiveHostBanTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<LiveHostBan>(
      rows,
      columns: columns?.call(LiveHostBan.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [LiveHostBan]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<LiveHostBan> updateRow(
    _is.DatabaseSession session,
    LiveHostBan row, {
    _is.ColumnSelections<LiveHostBanTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<LiveHostBan>(
      row,
      columns: columns?.call(LiveHostBan.t),
      transaction: transaction,
    );
  }

  /// Updates a single [LiveHostBan] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<LiveHostBan?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<LiveHostBanUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<LiveHostBan>(
      id,
      columnValues: columnValues(LiveHostBan.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [LiveHostBan]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<LiveHostBan>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<LiveHostBanUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<LiveHostBanTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<LiveHostBanTable>? orderBy,
    _is.OrderByListBuilder<LiveHostBanTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<LiveHostBan>(
      columnValues: columnValues(LiveHostBan.t.updateTable),
      where: where(LiveHostBan.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(LiveHostBan.t),
      orderByList: orderByList?.call(LiveHostBan.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [LiveHostBan]s in the list and returns the deleted rows.
  ///
  /// To specify the order of the returned rows use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  ///
  /// If [noReturn] is set to `true`, the deleted rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<LiveHostBan>> delete(
    _is.DatabaseSession session,
    List<LiveHostBan> rows, {
    _is.OrderByBuilder<LiveHostBanTable>? orderBy,
    _is.OrderByListBuilder<LiveHostBanTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<LiveHostBan>(
      rows,
      orderBy: orderBy?.call(LiveHostBan.t),
      orderByList: orderByList?.call(LiveHostBan.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [LiveHostBan].
  Future<LiveHostBan> deleteRow(
    _is.DatabaseSession session,
    LiveHostBan row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<LiveHostBan>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  ///
  /// To specify the order of the returned rows use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// If [noReturn] is set to `true`, the deleted rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<LiveHostBan>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<LiveHostBanTable> where,
    _is.OrderByBuilder<LiveHostBanTable>? orderBy,
    _is.OrderByListBuilder<LiveHostBanTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<LiveHostBan>(
      where: where(LiveHostBan.t),
      orderBy: orderBy?.call(LiveHostBan.t),
      orderByList: orderByList?.call(LiveHostBan.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<LiveHostBanTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<LiveHostBan>(
      where: where?.call(LiveHostBan.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [LiveHostBan] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<LiveHostBanTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<LiveHostBan>(
      where: where(LiveHostBan.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
