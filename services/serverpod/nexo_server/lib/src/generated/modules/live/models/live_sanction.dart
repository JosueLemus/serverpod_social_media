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
import '../../../modules/live/models/live_sanction_kind.dart' as _iocsdvds;

/// Un silencio o una expulsión dentro de un show. El baneo vive aparte
/// (`LiveHostBan`) porque no es de un show sino de un host.
abstract class LiveSanction
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
  LiveSanction._({
    this.id,
    required this.showId,
    required this.targetId,
    required this.kind,
    this.until,
    required this.actorId,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory LiveSanction({
    int? id,
    required int showId,
    required _is.UuidValue targetId,
    required _iocsdvds.LiveSanctionKind kind,
    DateTime? until,
    required _is.UuidValue actorId,
    DateTime? createdAt,
  }) = _LiveSanctionImpl;

  factory LiveSanction.fromJson(Map<String, dynamic> jsonSerialization) {
    return LiveSanction(
      id: jsonSerialization['id'] as int?,
      showId: jsonSerialization['showId'] as int,
      targetId: _is.UuidValueJsonExtension.fromJson(
        jsonSerialization['targetId'],
      ),
      kind: _iocsdvds.LiveSanctionKind.fromJson(
        (jsonSerialization['kind'] as String),
      ),
      until: jsonSerialization['until'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['until']),
      actorId: _is.UuidValueJsonExtension.fromJson(
        jsonSerialization['actorId'],
      ),
      createdAt: jsonSerialization['createdAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['createdAt']),
    );
  }

  static final t = LiveSanctionTable();

  static const db = LiveSanctionRepository._();

  @override
  int? id;

  int showId;

  _is.UuidValue targetId;

  _iocsdvds.LiveSanctionKind kind;

  /// Hasta cuándo. Null: el resto del vivo (un silencio) o para siempre en
  /// este show (una expulsión).
  DateTime? until;

  _is.UuidValue actorId;

  DateTime createdAt;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [LiveSanction]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  LiveSanction copyWith({
    int? id,
    int? showId,
    _is.UuidValue? targetId,
    _iocsdvds.LiveSanctionKind? kind,
    DateTime? until,
    _is.UuidValue? actorId,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'LiveSanction',
      if (id != null) 'id': id,
      'showId': showId,
      'targetId': targetId.toJson(),
      'kind': kind.toJson(),
      if (until != null) 'until': until?.toJson(),
      'actorId': actorId.toJson(),
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {};
  }

  static LiveSanctionInclude include() {
    return LiveSanctionInclude._();
  }

  static LiveSanctionIncludeList includeList({
    _is.WhereExpressionBuilder<LiveSanctionTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<LiveSanctionTable>? orderBy,
    _is.OrderByListBuilder<LiveSanctionTable>? orderByList,
    LiveSanctionInclude? include,
  }) {
    return LiveSanctionIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(LiveSanction.t),
      orderByList: orderByList?.call(LiveSanction.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _LiveSanctionImpl extends LiveSanction {
  _LiveSanctionImpl({
    int? id,
    required int showId,
    required _is.UuidValue targetId,
    required _iocsdvds.LiveSanctionKind kind,
    DateTime? until,
    required _is.UuidValue actorId,
    DateTime? createdAt,
  }) : super._(
         id: id,
         showId: showId,
         targetId: targetId,
         kind: kind,
         until: until,
         actorId: actorId,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [LiveSanction]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  LiveSanction copyWith({
    Object? id = _Undefined,
    int? showId,
    _is.UuidValue? targetId,
    _iocsdvds.LiveSanctionKind? kind,
    Object? until = _Undefined,
    _is.UuidValue? actorId,
    DateTime? createdAt,
  }) {
    return LiveSanction(
      id: id is int? ? id : this.id,
      showId: showId ?? this.showId,
      targetId: targetId ?? this.targetId,
      kind: kind ?? this.kind,
      until: until is DateTime? ? until : this.until,
      actorId: actorId ?? this.actorId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class LiveSanctionUpdateTable extends _is.UpdateTable<LiveSanctionTable> {
  LiveSanctionUpdateTable(super.table);

  _is.ColumnValue<int, int> showId(int value) => _is.ColumnValue(
    table.showId,
    value,
  );

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> targetId(_is.UuidValue value) =>
      _is.ColumnValue(
        table.targetId,
        value,
      );

  _is.ColumnValue<_iocsdvds.LiveSanctionKind, _iocsdvds.LiveSanctionKind> kind(
    _iocsdvds.LiveSanctionKind value,
  ) => _is.ColumnValue(
    table.kind,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> until(DateTime? value) => _is.ColumnValue(
    table.until,
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

class LiveSanctionTable extends _is.Table<int?> {
  LiveSanctionTable({super.tableRelation}) : super(tableName: 'live_sanction') {
    updateTable = LiveSanctionUpdateTable(this);
    showId = _is.ColumnInt(
      'showId',
      this,
    );
    targetId = _is.ColumnUuid(
      'targetId',
      this,
    );
    kind = _is.ColumnEnum(
      'kind',
      this,
      _is.EnumSerialization.byName,
    );
    until = _is.ColumnDateTime(
      'until',
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

  late final LiveSanctionUpdateTable updateTable;

  late final _is.ColumnInt showId;

  late final _is.ColumnUuid targetId;

  late final _is.ColumnEnum<_iocsdvds.LiveSanctionKind> kind;

  /// Hasta cuándo. Null: el resto del vivo (un silencio) o para siempre en
  /// este show (una expulsión).
  late final _is.ColumnDateTime until;

  late final _is.ColumnUuid actorId;

  late final _is.ColumnDateTime createdAt;

  @override
  List<_is.Column> get columns => [
    id,
    showId,
    targetId,
    kind,
    until,
    actorId,
    createdAt,
  ];
}

class LiveSanctionInclude extends _is.IncludeObject {
  LiveSanctionInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => LiveSanction.t;
}

class LiveSanctionIncludeList extends _is.IncludeList {
  LiveSanctionIncludeList._({
    _is.WhereExpressionBuilder<LiveSanctionTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(LiveSanction.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => LiveSanction.t;
}

class LiveSanctionRepository {
  const LiveSanctionRepository._();

  /// Returns a list of [LiveSanction]s matching the given query parameters.
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
  Future<List<LiveSanction>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<LiveSanctionTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<LiveSanctionTable>? orderBy,
    _is.OrderByListBuilder<LiveSanctionTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<LiveSanction>(
      where: where?.call(LiveSanction.t),
      orderBy: orderBy?.call(LiveSanction.t),
      orderByList: orderByList?.call(LiveSanction.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [LiveSanction] matching the given query parameters.
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
  Future<LiveSanction?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<LiveSanctionTable>? where,
    int? offset,
    _is.OrderByBuilder<LiveSanctionTable>? orderBy,
    _is.OrderByListBuilder<LiveSanctionTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<LiveSanction>(
      where: where?.call(LiveSanction.t),
      orderBy: orderBy?.call(LiveSanction.t),
      orderByList: orderByList?.call(LiveSanction.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [LiveSanction] by its [id] or null if no such row exists.
  Future<LiveSanction?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<LiveSanction>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [LiveSanction]s in the list and returns the inserted rows.
  ///
  /// The returned [LiveSanction]s will have their `id` fields set.
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
  Future<List<LiveSanction>> insert(
    _is.DatabaseSession session,
    List<LiveSanction> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<LiveSanction>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [LiveSanction] and returns the inserted row.
  ///
  /// The returned [LiveSanction] will have its `id` field set.
  Future<LiveSanction> insertRow(
    _is.DatabaseSession session,
    LiveSanction row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<LiveSanction>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [LiveSanction]s in the list and returns the resulting rows.
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
  /// The returned [LiveSanction]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<LiveSanction>> upsert(
    _is.DatabaseSession session,
    List<LiveSanction> rows, {
    required _is.ColumnSelections<LiveSanctionTable> conflictColumns,
    _is.ColumnSelections<LiveSanctionTable>? updateColumns,
    _is.WhereExpressionBuilder<LiveSanctionTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<LiveSanction>(
      rows,
      conflictColumns: conflictColumns(LiveSanction.t),
      updateColumns: updateColumns?.call(LiveSanction.t),
      updateWhere: updateWhere?.call(LiveSanction.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [LiveSanction] and returns the resulting row.
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
  /// The returned [LiveSanction] will have its `id` field set.
  Future<LiveSanction?> upsertRow(
    _is.DatabaseSession session,
    LiveSanction row, {
    required _is.ColumnSelections<LiveSanctionTable> conflictColumns,
    _is.ColumnSelections<LiveSanctionTable>? updateColumns,
    _is.WhereExpressionBuilder<LiveSanctionTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<LiveSanction>(
      row,
      conflictColumns: conflictColumns(LiveSanction.t),
      updateColumns: updateColumns?.call(LiveSanction.t),
      updateWhere: updateWhere?.call(LiveSanction.t),
      transaction: transaction,
    );
  }

  /// Updates all [LiveSanction]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<LiveSanction>> update(
    _is.DatabaseSession session,
    List<LiveSanction> rows, {
    _is.ColumnSelections<LiveSanctionTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<LiveSanction>(
      rows,
      columns: columns?.call(LiveSanction.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [LiveSanction]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<LiveSanction> updateRow(
    _is.DatabaseSession session,
    LiveSanction row, {
    _is.ColumnSelections<LiveSanctionTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<LiveSanction>(
      row,
      columns: columns?.call(LiveSanction.t),
      transaction: transaction,
    );
  }

  /// Updates a single [LiveSanction] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<LiveSanction?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<LiveSanctionUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<LiveSanction>(
      id,
      columnValues: columnValues(LiveSanction.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [LiveSanction]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<LiveSanction>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<LiveSanctionUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<LiveSanctionTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<LiveSanctionTable>? orderBy,
    _is.OrderByListBuilder<LiveSanctionTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<LiveSanction>(
      columnValues: columnValues(LiveSanction.t.updateTable),
      where: where(LiveSanction.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(LiveSanction.t),
      orderByList: orderByList?.call(LiveSanction.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [LiveSanction]s in the list and returns the deleted rows.
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
  Future<List<LiveSanction>> delete(
    _is.DatabaseSession session,
    List<LiveSanction> rows, {
    _is.OrderByBuilder<LiveSanctionTable>? orderBy,
    _is.OrderByListBuilder<LiveSanctionTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<LiveSanction>(
      rows,
      orderBy: orderBy?.call(LiveSanction.t),
      orderByList: orderByList?.call(LiveSanction.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [LiveSanction].
  Future<LiveSanction> deleteRow(
    _is.DatabaseSession session,
    LiveSanction row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<LiveSanction>(
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
  Future<List<LiveSanction>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<LiveSanctionTable> where,
    _is.OrderByBuilder<LiveSanctionTable>? orderBy,
    _is.OrderByListBuilder<LiveSanctionTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<LiveSanction>(
      where: where(LiveSanction.t),
      orderBy: orderBy?.call(LiveSanction.t),
      orderByList: orderByList?.call(LiveSanction.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<LiveSanctionTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<LiveSanction>(
      where: where?.call(LiveSanction.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [LiveSanction] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<LiveSanctionTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<LiveSanction>(
      where: where(LiveSanction.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
