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

/// Una conversación 1 a 1. El par se guarda ordenado (`userA` < `userB` como
/// texto) con un índice único: una sola conversación por par (SDD 0010, M2).
abstract class DmConversation
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
  DmConversation._({
    this.id,
    required this.userA,
    required this.userB,
    this.lastReadA,
    this.lastReadB,
    this.lastMessageId,
    DateTime? lastActivityAt,
    DateTime? createdAt,
  }) : lastActivityAt = lastActivityAt ?? DateTime.now(),
       createdAt = createdAt ?? DateTime.now();

  factory DmConversation({
    int? id,
    required _is.UuidValue userA,
    required _is.UuidValue userB,
    int? lastReadA,
    int? lastReadB,
    int? lastMessageId,
    DateTime? lastActivityAt,
    DateTime? createdAt,
  }) = _DmConversationImpl;

  factory DmConversation.fromJson(Map<String, dynamic> jsonSerialization) {
    return DmConversation(
      id: jsonSerialization['id'] as int?,
      userA: _is.UuidValueJsonExtension.fromJson(jsonSerialization['userA']),
      userB: _is.UuidValueJsonExtension.fromJson(jsonSerialization['userB']),
      lastReadA: jsonSerialization['lastReadA'] as int?,
      lastReadB: jsonSerialization['lastReadB'] as int?,
      lastMessageId: jsonSerialization['lastMessageId'] as int?,
      lastActivityAt: jsonSerialization['lastActivityAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(
              jsonSerialization['lastActivityAt'],
            ),
      createdAt: jsonSerialization['createdAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['createdAt']),
    );
  }

  static final t = DmConversationTable();

  static const db = DmConversationRepository._();

  @override
  int? id;

  _is.UuidValue userA;

  _is.UuidValue userB;

  /// El id del último mensaje que cada miembro leyó. `null` = nada leído.
  int? lastReadA;

  int? lastReadB;

  /// Para ordenar la bandeja y saber si hay algo sin leer sin contar filas.
  int? lastMessageId;

  DateTime lastActivityAt;

  DateTime createdAt;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [DmConversation]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  DmConversation copyWith({
    int? id,
    _is.UuidValue? userA,
    _is.UuidValue? userB,
    int? lastReadA,
    int? lastReadB,
    int? lastMessageId,
    DateTime? lastActivityAt,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'DmConversation',
      if (id != null) 'id': id,
      'userA': userA.toJson(),
      'userB': userB.toJson(),
      if (lastReadA != null) 'lastReadA': lastReadA,
      if (lastReadB != null) 'lastReadB': lastReadB,
      if (lastMessageId != null) 'lastMessageId': lastMessageId,
      'lastActivityAt': lastActivityAt.toJson(),
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {};
  }

  static DmConversationInclude include() {
    return DmConversationInclude._();
  }

  static DmConversationIncludeList includeList({
    _is.WhereExpressionBuilder<DmConversationTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<DmConversationTable>? orderBy,
    _is.OrderByListBuilder<DmConversationTable>? orderByList,
    DmConversationInclude? include,
  }) {
    return DmConversationIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(DmConversation.t),
      orderByList: orderByList?.call(DmConversation.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _DmConversationImpl extends DmConversation {
  _DmConversationImpl({
    int? id,
    required _is.UuidValue userA,
    required _is.UuidValue userB,
    int? lastReadA,
    int? lastReadB,
    int? lastMessageId,
    DateTime? lastActivityAt,
    DateTime? createdAt,
  }) : super._(
         id: id,
         userA: userA,
         userB: userB,
         lastReadA: lastReadA,
         lastReadB: lastReadB,
         lastMessageId: lastMessageId,
         lastActivityAt: lastActivityAt,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [DmConversation]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  DmConversation copyWith({
    Object? id = _Undefined,
    _is.UuidValue? userA,
    _is.UuidValue? userB,
    Object? lastReadA = _Undefined,
    Object? lastReadB = _Undefined,
    Object? lastMessageId = _Undefined,
    DateTime? lastActivityAt,
    DateTime? createdAt,
  }) {
    return DmConversation(
      id: id is int? ? id : this.id,
      userA: userA ?? this.userA,
      userB: userB ?? this.userB,
      lastReadA: lastReadA is int? ? lastReadA : this.lastReadA,
      lastReadB: lastReadB is int? ? lastReadB : this.lastReadB,
      lastMessageId: lastMessageId is int? ? lastMessageId : this.lastMessageId,
      lastActivityAt: lastActivityAt ?? this.lastActivityAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class DmConversationUpdateTable extends _is.UpdateTable<DmConversationTable> {
  DmConversationUpdateTable(super.table);

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> userA(_is.UuidValue value) =>
      _is.ColumnValue(
        table.userA,
        value,
      );

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> userB(_is.UuidValue value) =>
      _is.ColumnValue(
        table.userB,
        value,
      );

  _is.ColumnValue<int, int> lastReadA(int? value) => _is.ColumnValue(
    table.lastReadA,
    value,
  );

  _is.ColumnValue<int, int> lastReadB(int? value) => _is.ColumnValue(
    table.lastReadB,
    value,
  );

  _is.ColumnValue<int, int> lastMessageId(int? value) => _is.ColumnValue(
    table.lastMessageId,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> lastActivityAt(DateTime value) =>
      _is.ColumnValue(
        table.lastActivityAt,
        value,
      );

  _is.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _is.ColumnValue(
        table.createdAt,
        value,
      );
}

class DmConversationTable extends _is.Table<int?> {
  DmConversationTable({super.tableRelation})
    : super(tableName: 'dm_conversation') {
    updateTable = DmConversationUpdateTable(this);
    userA = _is.ColumnUuid(
      'userA',
      this,
    );
    userB = _is.ColumnUuid(
      'userB',
      this,
    );
    lastReadA = _is.ColumnInt(
      'lastReadA',
      this,
    );
    lastReadB = _is.ColumnInt(
      'lastReadB',
      this,
    );
    lastMessageId = _is.ColumnInt(
      'lastMessageId',
      this,
    );
    lastActivityAt = _is.ColumnDateTime(
      'lastActivityAt',
      this,
      hasDefault: true,
    );
    createdAt = _is.ColumnDateTime(
      'createdAt',
      this,
      hasDefault: true,
    );
  }

  late final DmConversationUpdateTable updateTable;

  late final _is.ColumnUuid userA;

  late final _is.ColumnUuid userB;

  /// El id del último mensaje que cada miembro leyó. `null` = nada leído.
  late final _is.ColumnInt lastReadA;

  late final _is.ColumnInt lastReadB;

  /// Para ordenar la bandeja y saber si hay algo sin leer sin contar filas.
  late final _is.ColumnInt lastMessageId;

  late final _is.ColumnDateTime lastActivityAt;

  late final _is.ColumnDateTime createdAt;

  @override
  List<_is.Column> get columns => [
    id,
    userA,
    userB,
    lastReadA,
    lastReadB,
    lastMessageId,
    lastActivityAt,
    createdAt,
  ];
}

class DmConversationInclude extends _is.IncludeObject {
  DmConversationInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => DmConversation.t;
}

class DmConversationIncludeList extends _is.IncludeList {
  DmConversationIncludeList._({
    _is.WhereExpressionBuilder<DmConversationTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(DmConversation.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => DmConversation.t;
}

class DmConversationRepository {
  const DmConversationRepository._();

  /// Returns a list of [DmConversation]s matching the given query parameters.
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
  Future<List<DmConversation>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<DmConversationTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<DmConversationTable>? orderBy,
    _is.OrderByListBuilder<DmConversationTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<DmConversation>(
      where: where?.call(DmConversation.t),
      orderBy: orderBy?.call(DmConversation.t),
      orderByList: orderByList?.call(DmConversation.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [DmConversation] matching the given query parameters.
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
  Future<DmConversation?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<DmConversationTable>? where,
    int? offset,
    _is.OrderByBuilder<DmConversationTable>? orderBy,
    _is.OrderByListBuilder<DmConversationTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<DmConversation>(
      where: where?.call(DmConversation.t),
      orderBy: orderBy?.call(DmConversation.t),
      orderByList: orderByList?.call(DmConversation.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [DmConversation] by its [id] or null if no such row exists.
  Future<DmConversation?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<DmConversation>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [DmConversation]s in the list and returns the inserted rows.
  ///
  /// The returned [DmConversation]s will have their `id` fields set.
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
  Future<List<DmConversation>> insert(
    _is.DatabaseSession session,
    List<DmConversation> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<DmConversation>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [DmConversation] and returns the inserted row.
  ///
  /// The returned [DmConversation] will have its `id` field set.
  Future<DmConversation> insertRow(
    _is.DatabaseSession session,
    DmConversation row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<DmConversation>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [DmConversation]s in the list and returns the resulting rows.
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
  /// The returned [DmConversation]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<DmConversation>> upsert(
    _is.DatabaseSession session,
    List<DmConversation> rows, {
    required _is.ColumnSelections<DmConversationTable> conflictColumns,
    _is.ColumnSelections<DmConversationTable>? updateColumns,
    _is.WhereExpressionBuilder<DmConversationTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<DmConversation>(
      rows,
      conflictColumns: conflictColumns(DmConversation.t),
      updateColumns: updateColumns?.call(DmConversation.t),
      updateWhere: updateWhere?.call(DmConversation.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [DmConversation] and returns the resulting row.
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
  /// The returned [DmConversation] will have its `id` field set.
  Future<DmConversation?> upsertRow(
    _is.DatabaseSession session,
    DmConversation row, {
    required _is.ColumnSelections<DmConversationTable> conflictColumns,
    _is.ColumnSelections<DmConversationTable>? updateColumns,
    _is.WhereExpressionBuilder<DmConversationTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<DmConversation>(
      row,
      conflictColumns: conflictColumns(DmConversation.t),
      updateColumns: updateColumns?.call(DmConversation.t),
      updateWhere: updateWhere?.call(DmConversation.t),
      transaction: transaction,
    );
  }

  /// Updates all [DmConversation]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<DmConversation>> update(
    _is.DatabaseSession session,
    List<DmConversation> rows, {
    _is.ColumnSelections<DmConversationTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<DmConversation>(
      rows,
      columns: columns?.call(DmConversation.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [DmConversation]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<DmConversation> updateRow(
    _is.DatabaseSession session,
    DmConversation row, {
    _is.ColumnSelections<DmConversationTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<DmConversation>(
      row,
      columns: columns?.call(DmConversation.t),
      transaction: transaction,
    );
  }

  /// Updates a single [DmConversation] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<DmConversation?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<DmConversationUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<DmConversation>(
      id,
      columnValues: columnValues(DmConversation.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [DmConversation]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<DmConversation>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<DmConversationUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<DmConversationTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<DmConversationTable>? orderBy,
    _is.OrderByListBuilder<DmConversationTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<DmConversation>(
      columnValues: columnValues(DmConversation.t.updateTable),
      where: where(DmConversation.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(DmConversation.t),
      orderByList: orderByList?.call(DmConversation.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [DmConversation]s in the list and returns the deleted rows.
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
  Future<List<DmConversation>> delete(
    _is.DatabaseSession session,
    List<DmConversation> rows, {
    _is.OrderByBuilder<DmConversationTable>? orderBy,
    _is.OrderByListBuilder<DmConversationTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<DmConversation>(
      rows,
      orderBy: orderBy?.call(DmConversation.t),
      orderByList: orderByList?.call(DmConversation.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [DmConversation].
  Future<DmConversation> deleteRow(
    _is.DatabaseSession session,
    DmConversation row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<DmConversation>(
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
  Future<List<DmConversation>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<DmConversationTable> where,
    _is.OrderByBuilder<DmConversationTable>? orderBy,
    _is.OrderByListBuilder<DmConversationTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<DmConversation>(
      where: where(DmConversation.t),
      orderBy: orderBy?.call(DmConversation.t),
      orderByList: orderByList?.call(DmConversation.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<DmConversationTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<DmConversation>(
      where: where?.call(DmConversation.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [DmConversation] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<DmConversationTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<DmConversation>(
      where: where(DmConversation.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
