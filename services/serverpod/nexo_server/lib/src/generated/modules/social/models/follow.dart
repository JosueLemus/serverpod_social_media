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

/// Una cuenta que sigue a otra. Una fila por par: seguir dos veces no suma
/// dos. Dejar de seguir borra la fila; no es contenido que haya que conservar.
abstract class Follow implements _is.TableRow<int?>, _is.ProtocolSerialization {
  Follow._({
    this.id,
    required this.followerId,
    required this.followeeId,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory Follow({
    int? id,
    required _is.UuidValue followerId,
    required _is.UuidValue followeeId,
    DateTime? createdAt,
  }) = _FollowImpl;

  factory Follow.fromJson(Map<String, dynamic> jsonSerialization) {
    return Follow(
      id: jsonSerialization['id'] as int?,
      followerId: _is.UuidValueJsonExtension.fromJson(
        jsonSerialization['followerId'],
      ),
      followeeId: _is.UuidValueJsonExtension.fromJson(
        jsonSerialization['followeeId'],
      ),
      createdAt: jsonSerialization['createdAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['createdAt']),
    );
  }

  static final t = FollowTable();

  static const db = FollowRepository._();

  @override
  int? id;

  _is.UuidValue followerId;

  _is.UuidValue followeeId;

  DateTime createdAt;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [Follow]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  Follow copyWith({
    int? id,
    _is.UuidValue? followerId,
    _is.UuidValue? followeeId,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'Follow',
      if (id != null) 'id': id,
      'followerId': followerId.toJson(),
      'followeeId': followeeId.toJson(),
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {};
  }

  static FollowInclude include() {
    return FollowInclude._();
  }

  static FollowIncludeList includeList({
    _is.WhereExpressionBuilder<FollowTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<FollowTable>? orderBy,
    _is.OrderByListBuilder<FollowTable>? orderByList,
    FollowInclude? include,
  }) {
    return FollowIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(Follow.t),
      orderByList: orderByList?.call(Follow.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _FollowImpl extends Follow {
  _FollowImpl({
    int? id,
    required _is.UuidValue followerId,
    required _is.UuidValue followeeId,
    DateTime? createdAt,
  }) : super._(
         id: id,
         followerId: followerId,
         followeeId: followeeId,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [Follow]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  Follow copyWith({
    Object? id = _Undefined,
    _is.UuidValue? followerId,
    _is.UuidValue? followeeId,
    DateTime? createdAt,
  }) {
    return Follow(
      id: id is int? ? id : this.id,
      followerId: followerId ?? this.followerId,
      followeeId: followeeId ?? this.followeeId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class FollowUpdateTable extends _is.UpdateTable<FollowTable> {
  FollowUpdateTable(super.table);

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> followerId(
    _is.UuidValue value,
  ) => _is.ColumnValue(
    table.followerId,
    value,
  );

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> followeeId(
    _is.UuidValue value,
  ) => _is.ColumnValue(
    table.followeeId,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _is.ColumnValue(
        table.createdAt,
        value,
      );
}

class FollowTable extends _is.Table<int?> {
  FollowTable({super.tableRelation}) : super(tableName: 'follow') {
    updateTable = FollowUpdateTable(this);
    followerId = _is.ColumnUuid(
      'followerId',
      this,
    );
    followeeId = _is.ColumnUuid(
      'followeeId',
      this,
    );
    createdAt = _is.ColumnDateTime(
      'createdAt',
      this,
      hasDefault: true,
    );
  }

  late final FollowUpdateTable updateTable;

  late final _is.ColumnUuid followerId;

  late final _is.ColumnUuid followeeId;

  late final _is.ColumnDateTime createdAt;

  @override
  List<_is.Column> get columns => [
    id,
    followerId,
    followeeId,
    createdAt,
  ];
}

class FollowInclude extends _is.IncludeObject {
  FollowInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => Follow.t;
}

class FollowIncludeList extends _is.IncludeList {
  FollowIncludeList._({
    _is.WhereExpressionBuilder<FollowTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(Follow.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => Follow.t;
}

class FollowRepository {
  const FollowRepository._();

  /// Returns a list of [Follow]s matching the given query parameters.
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
  Future<List<Follow>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<FollowTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<FollowTable>? orderBy,
    _is.OrderByListBuilder<FollowTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<Follow>(
      where: where?.call(Follow.t),
      orderBy: orderBy?.call(Follow.t),
      orderByList: orderByList?.call(Follow.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [Follow] matching the given query parameters.
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
  Future<Follow?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<FollowTable>? where,
    int? offset,
    _is.OrderByBuilder<FollowTable>? orderBy,
    _is.OrderByListBuilder<FollowTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<Follow>(
      where: where?.call(Follow.t),
      orderBy: orderBy?.call(Follow.t),
      orderByList: orderByList?.call(Follow.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [Follow] by its [id] or null if no such row exists.
  Future<Follow?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<Follow>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [Follow]s in the list and returns the inserted rows.
  ///
  /// The returned [Follow]s will have their `id` fields set.
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
  Future<List<Follow>> insert(
    _is.DatabaseSession session,
    List<Follow> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<Follow>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [Follow] and returns the inserted row.
  ///
  /// The returned [Follow] will have its `id` field set.
  Future<Follow> insertRow(
    _is.DatabaseSession session,
    Follow row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<Follow>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [Follow]s in the list and returns the resulting rows.
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
  /// The returned [Follow]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<Follow>> upsert(
    _is.DatabaseSession session,
    List<Follow> rows, {
    required _is.ColumnSelections<FollowTable> conflictColumns,
    _is.ColumnSelections<FollowTable>? updateColumns,
    _is.WhereExpressionBuilder<FollowTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<Follow>(
      rows,
      conflictColumns: conflictColumns(Follow.t),
      updateColumns: updateColumns?.call(Follow.t),
      updateWhere: updateWhere?.call(Follow.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [Follow] and returns the resulting row.
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
  /// The returned [Follow] will have its `id` field set.
  Future<Follow?> upsertRow(
    _is.DatabaseSession session,
    Follow row, {
    required _is.ColumnSelections<FollowTable> conflictColumns,
    _is.ColumnSelections<FollowTable>? updateColumns,
    _is.WhereExpressionBuilder<FollowTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<Follow>(
      row,
      conflictColumns: conflictColumns(Follow.t),
      updateColumns: updateColumns?.call(Follow.t),
      updateWhere: updateWhere?.call(Follow.t),
      transaction: transaction,
    );
  }

  /// Updates all [Follow]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<Follow>> update(
    _is.DatabaseSession session,
    List<Follow> rows, {
    _is.ColumnSelections<FollowTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<Follow>(
      rows,
      columns: columns?.call(Follow.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [Follow]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<Follow> updateRow(
    _is.DatabaseSession session,
    Follow row, {
    _is.ColumnSelections<FollowTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<Follow>(
      row,
      columns: columns?.call(Follow.t),
      transaction: transaction,
    );
  }

  /// Updates a single [Follow] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<Follow?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<FollowUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<Follow>(
      id,
      columnValues: columnValues(Follow.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [Follow]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<Follow>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<FollowUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<FollowTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<FollowTable>? orderBy,
    _is.OrderByListBuilder<FollowTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<Follow>(
      columnValues: columnValues(Follow.t.updateTable),
      where: where(Follow.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(Follow.t),
      orderByList: orderByList?.call(Follow.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [Follow]s in the list and returns the deleted rows.
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
  Future<List<Follow>> delete(
    _is.DatabaseSession session,
    List<Follow> rows, {
    _is.OrderByBuilder<FollowTable>? orderBy,
    _is.OrderByListBuilder<FollowTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<Follow>(
      rows,
      orderBy: orderBy?.call(Follow.t),
      orderByList: orderByList?.call(Follow.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [Follow].
  Future<Follow> deleteRow(
    _is.DatabaseSession session,
    Follow row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<Follow>(
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
  Future<List<Follow>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<FollowTable> where,
    _is.OrderByBuilder<FollowTable>? orderBy,
    _is.OrderByListBuilder<FollowTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<Follow>(
      where: where(Follow.t),
      orderBy: orderBy?.call(Follow.t),
      orderByList: orderByList?.call(Follow.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<FollowTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<Follow>(
      where: where?.call(Follow.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [Follow] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<FollowTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<Follow>(
      where: where(Follow.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
