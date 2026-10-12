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
import '../../../modules/live/models/live_show_guest_status.dart' as _iw315j15;

/// Una cuenta invitada a co-conducir un show.
abstract class LiveShowGuest
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
  LiveShowGuest._({
    this.id,
    required this.showId,
    required this.userId,
    required this.status,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory LiveShowGuest({
    int? id,
    required int showId,
    required _is.UuidValue userId,
    required _iw315j15.LiveShowGuestStatus status,
    DateTime? createdAt,
  }) = _LiveShowGuestImpl;

  factory LiveShowGuest.fromJson(Map<String, dynamic> jsonSerialization) {
    return LiveShowGuest(
      id: jsonSerialization['id'] as int?,
      showId: jsonSerialization['showId'] as int,
      userId: _is.UuidValueJsonExtension.fromJson(jsonSerialization['userId']),
      status: _iw315j15.LiveShowGuestStatus.fromJson(
        (jsonSerialization['status'] as String),
      ),
      createdAt: jsonSerialization['createdAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['createdAt']),
    );
  }

  static final t = LiveShowGuestTable();

  static const db = LiveShowGuestRepository._();

  @override
  int? id;

  int showId;

  _is.UuidValue userId;

  _iw315j15.LiveShowGuestStatus status;

  DateTime createdAt;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [LiveShowGuest]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  LiveShowGuest copyWith({
    int? id,
    int? showId,
    _is.UuidValue? userId,
    _iw315j15.LiveShowGuestStatus? status,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'LiveShowGuest',
      if (id != null) 'id': id,
      'showId': showId,
      'userId': userId.toJson(),
      'status': status.toJson(),
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {};
  }

  static LiveShowGuestInclude include() {
    return LiveShowGuestInclude._();
  }

  static LiveShowGuestIncludeList includeList({
    _is.WhereExpressionBuilder<LiveShowGuestTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<LiveShowGuestTable>? orderBy,
    _is.OrderByListBuilder<LiveShowGuestTable>? orderByList,
    LiveShowGuestInclude? include,
  }) {
    return LiveShowGuestIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(LiveShowGuest.t),
      orderByList: orderByList?.call(LiveShowGuest.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _LiveShowGuestImpl extends LiveShowGuest {
  _LiveShowGuestImpl({
    int? id,
    required int showId,
    required _is.UuidValue userId,
    required _iw315j15.LiveShowGuestStatus status,
    DateTime? createdAt,
  }) : super._(
         id: id,
         showId: showId,
         userId: userId,
         status: status,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [LiveShowGuest]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  LiveShowGuest copyWith({
    Object? id = _Undefined,
    int? showId,
    _is.UuidValue? userId,
    _iw315j15.LiveShowGuestStatus? status,
    DateTime? createdAt,
  }) {
    return LiveShowGuest(
      id: id is int? ? id : this.id,
      showId: showId ?? this.showId,
      userId: userId ?? this.userId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class LiveShowGuestUpdateTable extends _is.UpdateTable<LiveShowGuestTable> {
  LiveShowGuestUpdateTable(super.table);

  _is.ColumnValue<int, int> showId(int value) => _is.ColumnValue(
    table.showId,
    value,
  );

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> userId(_is.UuidValue value) =>
      _is.ColumnValue(
        table.userId,
        value,
      );

  _is.ColumnValue<_iw315j15.LiveShowGuestStatus, _iw315j15.LiveShowGuestStatus>
  status(_iw315j15.LiveShowGuestStatus value) => _is.ColumnValue(
    table.status,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _is.ColumnValue(
        table.createdAt,
        value,
      );
}

class LiveShowGuestTable extends _is.Table<int?> {
  LiveShowGuestTable({super.tableRelation})
    : super(tableName: 'live_show_guest') {
    updateTable = LiveShowGuestUpdateTable(this);
    showId = _is.ColumnInt(
      'showId',
      this,
    );
    userId = _is.ColumnUuid(
      'userId',
      this,
    );
    status = _is.ColumnEnum(
      'status',
      this,
      _is.EnumSerialization.byName,
    );
    createdAt = _is.ColumnDateTime(
      'createdAt',
      this,
      hasDefault: true,
    );
  }

  late final LiveShowGuestUpdateTable updateTable;

  late final _is.ColumnInt showId;

  late final _is.ColumnUuid userId;

  late final _is.ColumnEnum<_iw315j15.LiveShowGuestStatus> status;

  late final _is.ColumnDateTime createdAt;

  @override
  List<_is.Column> get columns => [
    id,
    showId,
    userId,
    status,
    createdAt,
  ];
}

class LiveShowGuestInclude extends _is.IncludeObject {
  LiveShowGuestInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => LiveShowGuest.t;
}

class LiveShowGuestIncludeList extends _is.IncludeList {
  LiveShowGuestIncludeList._({
    _is.WhereExpressionBuilder<LiveShowGuestTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(LiveShowGuest.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => LiveShowGuest.t;
}

class LiveShowGuestRepository {
  const LiveShowGuestRepository._();

  /// Returns a list of [LiveShowGuest]s matching the given query parameters.
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
  Future<List<LiveShowGuest>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<LiveShowGuestTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<LiveShowGuestTable>? orderBy,
    _is.OrderByListBuilder<LiveShowGuestTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<LiveShowGuest>(
      where: where?.call(LiveShowGuest.t),
      orderBy: orderBy?.call(LiveShowGuest.t),
      orderByList: orderByList?.call(LiveShowGuest.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [LiveShowGuest] matching the given query parameters.
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
  Future<LiveShowGuest?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<LiveShowGuestTable>? where,
    int? offset,
    _is.OrderByBuilder<LiveShowGuestTable>? orderBy,
    _is.OrderByListBuilder<LiveShowGuestTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<LiveShowGuest>(
      where: where?.call(LiveShowGuest.t),
      orderBy: orderBy?.call(LiveShowGuest.t),
      orderByList: orderByList?.call(LiveShowGuest.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [LiveShowGuest] by its [id] or null if no such row exists.
  Future<LiveShowGuest?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<LiveShowGuest>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [LiveShowGuest]s in the list and returns the inserted rows.
  ///
  /// The returned [LiveShowGuest]s will have their `id` fields set.
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
  Future<List<LiveShowGuest>> insert(
    _is.DatabaseSession session,
    List<LiveShowGuest> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<LiveShowGuest>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [LiveShowGuest] and returns the inserted row.
  ///
  /// The returned [LiveShowGuest] will have its `id` field set.
  Future<LiveShowGuest> insertRow(
    _is.DatabaseSession session,
    LiveShowGuest row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<LiveShowGuest>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [LiveShowGuest]s in the list and returns the resulting rows.
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
  /// The returned [LiveShowGuest]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<LiveShowGuest>> upsert(
    _is.DatabaseSession session,
    List<LiveShowGuest> rows, {
    required _is.ColumnSelections<LiveShowGuestTable> conflictColumns,
    _is.ColumnSelections<LiveShowGuestTable>? updateColumns,
    _is.WhereExpressionBuilder<LiveShowGuestTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<LiveShowGuest>(
      rows,
      conflictColumns: conflictColumns(LiveShowGuest.t),
      updateColumns: updateColumns?.call(LiveShowGuest.t),
      updateWhere: updateWhere?.call(LiveShowGuest.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [LiveShowGuest] and returns the resulting row.
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
  /// The returned [LiveShowGuest] will have its `id` field set.
  Future<LiveShowGuest?> upsertRow(
    _is.DatabaseSession session,
    LiveShowGuest row, {
    required _is.ColumnSelections<LiveShowGuestTable> conflictColumns,
    _is.ColumnSelections<LiveShowGuestTable>? updateColumns,
    _is.WhereExpressionBuilder<LiveShowGuestTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<LiveShowGuest>(
      row,
      conflictColumns: conflictColumns(LiveShowGuest.t),
      updateColumns: updateColumns?.call(LiveShowGuest.t),
      updateWhere: updateWhere?.call(LiveShowGuest.t),
      transaction: transaction,
    );
  }

  /// Updates all [LiveShowGuest]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<LiveShowGuest>> update(
    _is.DatabaseSession session,
    List<LiveShowGuest> rows, {
    _is.ColumnSelections<LiveShowGuestTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<LiveShowGuest>(
      rows,
      columns: columns?.call(LiveShowGuest.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [LiveShowGuest]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<LiveShowGuest> updateRow(
    _is.DatabaseSession session,
    LiveShowGuest row, {
    _is.ColumnSelections<LiveShowGuestTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<LiveShowGuest>(
      row,
      columns: columns?.call(LiveShowGuest.t),
      transaction: transaction,
    );
  }

  /// Updates a single [LiveShowGuest] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<LiveShowGuest?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<LiveShowGuestUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<LiveShowGuest>(
      id,
      columnValues: columnValues(LiveShowGuest.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [LiveShowGuest]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<LiveShowGuest>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<LiveShowGuestUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<LiveShowGuestTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<LiveShowGuestTable>? orderBy,
    _is.OrderByListBuilder<LiveShowGuestTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<LiveShowGuest>(
      columnValues: columnValues(LiveShowGuest.t.updateTable),
      where: where(LiveShowGuest.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(LiveShowGuest.t),
      orderByList: orderByList?.call(LiveShowGuest.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [LiveShowGuest]s in the list and returns the deleted rows.
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
  Future<List<LiveShowGuest>> delete(
    _is.DatabaseSession session,
    List<LiveShowGuest> rows, {
    _is.OrderByBuilder<LiveShowGuestTable>? orderBy,
    _is.OrderByListBuilder<LiveShowGuestTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<LiveShowGuest>(
      rows,
      orderBy: orderBy?.call(LiveShowGuest.t),
      orderByList: orderByList?.call(LiveShowGuest.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [LiveShowGuest].
  Future<LiveShowGuest> deleteRow(
    _is.DatabaseSession session,
    LiveShowGuest row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<LiveShowGuest>(
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
  Future<List<LiveShowGuest>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<LiveShowGuestTable> where,
    _is.OrderByBuilder<LiveShowGuestTable>? orderBy,
    _is.OrderByListBuilder<LiveShowGuestTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<LiveShowGuest>(
      where: where(LiveShowGuest.t),
      orderBy: orderBy?.call(LiveShowGuest.t),
      orderByList: orderByList?.call(LiveShowGuest.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<LiveShowGuestTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<LiveShowGuest>(
      where: where?.call(LiveShowGuest.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [LiveShowGuest] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<LiveShowGuestTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<LiveShowGuest>(
      where: where(LiveShowGuest.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
