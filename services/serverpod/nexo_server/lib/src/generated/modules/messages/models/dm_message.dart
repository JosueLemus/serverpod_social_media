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

/// Un mensaje de texto. Se ordena por id: es el orden de llegada y no empata.
abstract class DmMessage
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
  DmMessage._({
    this.id,
    required this.conversationId,
    required this.authorId,
    required this.body,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory DmMessage({
    int? id,
    required int conversationId,
    required _is.UuidValue authorId,
    required String body,
    DateTime? createdAt,
  }) = _DmMessageImpl;

  factory DmMessage.fromJson(Map<String, dynamic> jsonSerialization) {
    return DmMessage(
      id: jsonSerialization['id'] as int?,
      conversationId: jsonSerialization['conversationId'] as int,
      authorId: _is.UuidValueJsonExtension.fromJson(
        jsonSerialization['authorId'],
      ),
      body: jsonSerialization['body'] as String,
      createdAt: jsonSerialization['createdAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['createdAt']),
    );
  }

  static final t = DmMessageTable();

  static const db = DmMessageRepository._();

  @override
  int? id;

  int conversationId;

  _is.UuidValue authorId;

  String body;

  DateTime createdAt;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [DmMessage]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  DmMessage copyWith({
    int? id,
    int? conversationId,
    _is.UuidValue? authorId,
    String? body,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'DmMessage',
      if (id != null) 'id': id,
      'conversationId': conversationId,
      'authorId': authorId.toJson(),
      'body': body,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {};
  }

  static DmMessageInclude include() {
    return DmMessageInclude._();
  }

  static DmMessageIncludeList includeList({
    _is.WhereExpressionBuilder<DmMessageTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<DmMessageTable>? orderBy,
    _is.OrderByListBuilder<DmMessageTable>? orderByList,
    DmMessageInclude? include,
  }) {
    return DmMessageIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(DmMessage.t),
      orderByList: orderByList?.call(DmMessage.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _DmMessageImpl extends DmMessage {
  _DmMessageImpl({
    int? id,
    required int conversationId,
    required _is.UuidValue authorId,
    required String body,
    DateTime? createdAt,
  }) : super._(
         id: id,
         conversationId: conversationId,
         authorId: authorId,
         body: body,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [DmMessage]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  DmMessage copyWith({
    Object? id = _Undefined,
    int? conversationId,
    _is.UuidValue? authorId,
    String? body,
    DateTime? createdAt,
  }) {
    return DmMessage(
      id: id is int? ? id : this.id,
      conversationId: conversationId ?? this.conversationId,
      authorId: authorId ?? this.authorId,
      body: body ?? this.body,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class DmMessageUpdateTable extends _is.UpdateTable<DmMessageTable> {
  DmMessageUpdateTable(super.table);

  _is.ColumnValue<int, int> conversationId(int value) => _is.ColumnValue(
    table.conversationId,
    value,
  );

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> authorId(_is.UuidValue value) =>
      _is.ColumnValue(
        table.authorId,
        value,
      );

  _is.ColumnValue<String, String> body(String value) => _is.ColumnValue(
    table.body,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _is.ColumnValue(
        table.createdAt,
        value,
      );
}

class DmMessageTable extends _is.Table<int?> {
  DmMessageTable({super.tableRelation}) : super(tableName: 'dm_message') {
    updateTable = DmMessageUpdateTable(this);
    conversationId = _is.ColumnInt(
      'conversationId',
      this,
    );
    authorId = _is.ColumnUuid(
      'authorId',
      this,
    );
    body = _is.ColumnString(
      'body',
      this,
    );
    createdAt = _is.ColumnDateTime(
      'createdAt',
      this,
      hasDefault: true,
    );
  }

  late final DmMessageUpdateTable updateTable;

  late final _is.ColumnInt conversationId;

  late final _is.ColumnUuid authorId;

  late final _is.ColumnString body;

  late final _is.ColumnDateTime createdAt;

  @override
  List<_is.Column> get columns => [
    id,
    conversationId,
    authorId,
    body,
    createdAt,
  ];
}

class DmMessageInclude extends _is.IncludeObject {
  DmMessageInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => DmMessage.t;
}

class DmMessageIncludeList extends _is.IncludeList {
  DmMessageIncludeList._({
    _is.WhereExpressionBuilder<DmMessageTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(DmMessage.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => DmMessage.t;
}

class DmMessageRepository {
  const DmMessageRepository._();

  /// Returns a list of [DmMessage]s matching the given query parameters.
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
  Future<List<DmMessage>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<DmMessageTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<DmMessageTable>? orderBy,
    _is.OrderByListBuilder<DmMessageTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<DmMessage>(
      where: where?.call(DmMessage.t),
      orderBy: orderBy?.call(DmMessage.t),
      orderByList: orderByList?.call(DmMessage.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [DmMessage] matching the given query parameters.
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
  Future<DmMessage?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<DmMessageTable>? where,
    int? offset,
    _is.OrderByBuilder<DmMessageTable>? orderBy,
    _is.OrderByListBuilder<DmMessageTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<DmMessage>(
      where: where?.call(DmMessage.t),
      orderBy: orderBy?.call(DmMessage.t),
      orderByList: orderByList?.call(DmMessage.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [DmMessage] by its [id] or null if no such row exists.
  Future<DmMessage?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<DmMessage>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [DmMessage]s in the list and returns the inserted rows.
  ///
  /// The returned [DmMessage]s will have their `id` fields set.
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
  Future<List<DmMessage>> insert(
    _is.DatabaseSession session,
    List<DmMessage> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<DmMessage>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [DmMessage] and returns the inserted row.
  ///
  /// The returned [DmMessage] will have its `id` field set.
  Future<DmMessage> insertRow(
    _is.DatabaseSession session,
    DmMessage row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<DmMessage>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [DmMessage]s in the list and returns the resulting rows.
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
  /// The returned [DmMessage]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<DmMessage>> upsert(
    _is.DatabaseSession session,
    List<DmMessage> rows, {
    required _is.ColumnSelections<DmMessageTable> conflictColumns,
    _is.ColumnSelections<DmMessageTable>? updateColumns,
    _is.WhereExpressionBuilder<DmMessageTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<DmMessage>(
      rows,
      conflictColumns: conflictColumns(DmMessage.t),
      updateColumns: updateColumns?.call(DmMessage.t),
      updateWhere: updateWhere?.call(DmMessage.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [DmMessage] and returns the resulting row.
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
  /// The returned [DmMessage] will have its `id` field set.
  Future<DmMessage?> upsertRow(
    _is.DatabaseSession session,
    DmMessage row, {
    required _is.ColumnSelections<DmMessageTable> conflictColumns,
    _is.ColumnSelections<DmMessageTable>? updateColumns,
    _is.WhereExpressionBuilder<DmMessageTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<DmMessage>(
      row,
      conflictColumns: conflictColumns(DmMessage.t),
      updateColumns: updateColumns?.call(DmMessage.t),
      updateWhere: updateWhere?.call(DmMessage.t),
      transaction: transaction,
    );
  }

  /// Updates all [DmMessage]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<DmMessage>> update(
    _is.DatabaseSession session,
    List<DmMessage> rows, {
    _is.ColumnSelections<DmMessageTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<DmMessage>(
      rows,
      columns: columns?.call(DmMessage.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [DmMessage]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<DmMessage> updateRow(
    _is.DatabaseSession session,
    DmMessage row, {
    _is.ColumnSelections<DmMessageTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<DmMessage>(
      row,
      columns: columns?.call(DmMessage.t),
      transaction: transaction,
    );
  }

  /// Updates a single [DmMessage] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<DmMessage?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<DmMessageUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<DmMessage>(
      id,
      columnValues: columnValues(DmMessage.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [DmMessage]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<DmMessage>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<DmMessageUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<DmMessageTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<DmMessageTable>? orderBy,
    _is.OrderByListBuilder<DmMessageTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<DmMessage>(
      columnValues: columnValues(DmMessage.t.updateTable),
      where: where(DmMessage.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(DmMessage.t),
      orderByList: orderByList?.call(DmMessage.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [DmMessage]s in the list and returns the deleted rows.
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
  Future<List<DmMessage>> delete(
    _is.DatabaseSession session,
    List<DmMessage> rows, {
    _is.OrderByBuilder<DmMessageTable>? orderBy,
    _is.OrderByListBuilder<DmMessageTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<DmMessage>(
      rows,
      orderBy: orderBy?.call(DmMessage.t),
      orderByList: orderByList?.call(DmMessage.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [DmMessage].
  Future<DmMessage> deleteRow(
    _is.DatabaseSession session,
    DmMessage row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<DmMessage>(
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
  Future<List<DmMessage>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<DmMessageTable> where,
    _is.OrderByBuilder<DmMessageTable>? orderBy,
    _is.OrderByListBuilder<DmMessageTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<DmMessage>(
      where: where(DmMessage.t),
      orderBy: orderBy?.call(DmMessage.t),
      orderByList: orderByList?.call(DmMessage.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<DmMessageTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<DmMessage>(
      where: where?.call(DmMessage.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [DmMessage] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<DmMessageTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<DmMessage>(
      where: where(DmMessage.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
