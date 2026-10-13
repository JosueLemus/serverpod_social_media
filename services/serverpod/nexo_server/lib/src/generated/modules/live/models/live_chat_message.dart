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

/// Un mensaje del chat de un show. Ocultar no borra: pone [hiddenAt] y
/// [hiddenBy], y la acción queda en la auditoría.
abstract class LiveChatMessage
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
  LiveChatMessage._({
    this.id,
    required this.showId,
    required this.authorId,
    required this.body,
    DateTime? createdAt,
    this.hiddenAt,
    this.hiddenBy,
    this.deletedAt,
    this.deletedBy,
  }) : createdAt = createdAt ?? DateTime.now();

  factory LiveChatMessage({
    int? id,
    required int showId,
    required _is.UuidValue authorId,
    required String body,
    DateTime? createdAt,
    DateTime? hiddenAt,
    _is.UuidValue? hiddenBy,
    DateTime? deletedAt,
    _is.UuidValue? deletedBy,
  }) = _LiveChatMessageImpl;

  factory LiveChatMessage.fromJson(Map<String, dynamic> jsonSerialization) {
    return LiveChatMessage(
      id: jsonSerialization['id'] as int?,
      showId: jsonSerialization['showId'] as int,
      authorId: _is.UuidValueJsonExtension.fromJson(
        jsonSerialization['authorId'],
      ),
      body: jsonSerialization['body'] as String,
      createdAt: jsonSerialization['createdAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['createdAt']),
      hiddenAt: jsonSerialization['hiddenAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['hiddenAt']),
      hiddenBy: jsonSerialization['hiddenBy'] == null
          ? null
          : _is.UuidValueJsonExtension.fromJson(jsonSerialization['hiddenBy']),
      deletedAt: jsonSerialization['deletedAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['deletedAt']),
      deletedBy: jsonSerialization['deletedBy'] == null
          ? null
          : _is.UuidValueJsonExtension.fromJson(jsonSerialization['deletedBy']),
    );
  }

  static final t = LiveChatMessageTable();

  static const db = LiveChatMessageRepository._();

  @override
  int? id;

  int showId;

  _is.UuidValue authorId;

  String body;

  DateTime createdAt;

  DateTime? hiddenAt;

  _is.UuidValue? hiddenBy;

  /// Borrado: desaparece para todos y del replay, pero la fila queda para la
  /// auditoría (SDD 0011, S12). Ocultar es reversible; borrar, no.
  DateTime? deletedAt;

  _is.UuidValue? deletedBy;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [LiveChatMessage]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  LiveChatMessage copyWith({
    int? id,
    int? showId,
    _is.UuidValue? authorId,
    String? body,
    DateTime? createdAt,
    DateTime? hiddenAt,
    _is.UuidValue? hiddenBy,
    DateTime? deletedAt,
    _is.UuidValue? deletedBy,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'LiveChatMessage',
      if (id != null) 'id': id,
      'showId': showId,
      'authorId': authorId.toJson(),
      'body': body,
      'createdAt': createdAt.toJson(),
      if (hiddenAt != null) 'hiddenAt': hiddenAt?.toJson(),
      if (hiddenBy != null) 'hiddenBy': hiddenBy?.toJson(),
      if (deletedAt != null) 'deletedAt': deletedAt?.toJson(),
      if (deletedBy != null) 'deletedBy': deletedBy?.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {};
  }

  static LiveChatMessageInclude include() {
    return LiveChatMessageInclude._();
  }

  static LiveChatMessageIncludeList includeList({
    _is.WhereExpressionBuilder<LiveChatMessageTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<LiveChatMessageTable>? orderBy,
    _is.OrderByListBuilder<LiveChatMessageTable>? orderByList,
    LiveChatMessageInclude? include,
  }) {
    return LiveChatMessageIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(LiveChatMessage.t),
      orderByList: orderByList?.call(LiveChatMessage.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _LiveChatMessageImpl extends LiveChatMessage {
  _LiveChatMessageImpl({
    int? id,
    required int showId,
    required _is.UuidValue authorId,
    required String body,
    DateTime? createdAt,
    DateTime? hiddenAt,
    _is.UuidValue? hiddenBy,
    DateTime? deletedAt,
    _is.UuidValue? deletedBy,
  }) : super._(
         id: id,
         showId: showId,
         authorId: authorId,
         body: body,
         createdAt: createdAt,
         hiddenAt: hiddenAt,
         hiddenBy: hiddenBy,
         deletedAt: deletedAt,
         deletedBy: deletedBy,
       );

  /// Returns a shallow copy of this [LiveChatMessage]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  LiveChatMessage copyWith({
    Object? id = _Undefined,
    int? showId,
    _is.UuidValue? authorId,
    String? body,
    DateTime? createdAt,
    Object? hiddenAt = _Undefined,
    Object? hiddenBy = _Undefined,
    Object? deletedAt = _Undefined,
    Object? deletedBy = _Undefined,
  }) {
    return LiveChatMessage(
      id: id is int? ? id : this.id,
      showId: showId ?? this.showId,
      authorId: authorId ?? this.authorId,
      body: body ?? this.body,
      createdAt: createdAt ?? this.createdAt,
      hiddenAt: hiddenAt is DateTime? ? hiddenAt : this.hiddenAt,
      hiddenBy: hiddenBy is _is.UuidValue? ? hiddenBy : this.hiddenBy,
      deletedAt: deletedAt is DateTime? ? deletedAt : this.deletedAt,
      deletedBy: deletedBy is _is.UuidValue? ? deletedBy : this.deletedBy,
    );
  }
}

class LiveChatMessageUpdateTable extends _is.UpdateTable<LiveChatMessageTable> {
  LiveChatMessageUpdateTable(super.table);

  _is.ColumnValue<int, int> showId(int value) => _is.ColumnValue(
    table.showId,
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

  _is.ColumnValue<DateTime, DateTime> hiddenAt(DateTime? value) =>
      _is.ColumnValue(
        table.hiddenAt,
        value,
      );

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> hiddenBy(
    _is.UuidValue? value,
  ) => _is.ColumnValue(
    table.hiddenBy,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> deletedAt(DateTime? value) =>
      _is.ColumnValue(
        table.deletedAt,
        value,
      );

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> deletedBy(
    _is.UuidValue? value,
  ) => _is.ColumnValue(
    table.deletedBy,
    value,
  );
}

class LiveChatMessageTable extends _is.Table<int?> {
  LiveChatMessageTable({super.tableRelation})
    : super(tableName: 'live_chat_message') {
    updateTable = LiveChatMessageUpdateTable(this);
    showId = _is.ColumnInt(
      'showId',
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
    hiddenAt = _is.ColumnDateTime(
      'hiddenAt',
      this,
    );
    hiddenBy = _is.ColumnUuid(
      'hiddenBy',
      this,
    );
    deletedAt = _is.ColumnDateTime(
      'deletedAt',
      this,
    );
    deletedBy = _is.ColumnUuid(
      'deletedBy',
      this,
    );
  }

  late final LiveChatMessageUpdateTable updateTable;

  late final _is.ColumnInt showId;

  late final _is.ColumnUuid authorId;

  late final _is.ColumnString body;

  late final _is.ColumnDateTime createdAt;

  late final _is.ColumnDateTime hiddenAt;

  late final _is.ColumnUuid hiddenBy;

  /// Borrado: desaparece para todos y del replay, pero la fila queda para la
  /// auditoría (SDD 0011, S12). Ocultar es reversible; borrar, no.
  late final _is.ColumnDateTime deletedAt;

  late final _is.ColumnUuid deletedBy;

  @override
  List<_is.Column> get columns => [
    id,
    showId,
    authorId,
    body,
    createdAt,
    hiddenAt,
    hiddenBy,
    deletedAt,
    deletedBy,
  ];
}

class LiveChatMessageInclude extends _is.IncludeObject {
  LiveChatMessageInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => LiveChatMessage.t;
}

class LiveChatMessageIncludeList extends _is.IncludeList {
  LiveChatMessageIncludeList._({
    _is.WhereExpressionBuilder<LiveChatMessageTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(LiveChatMessage.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => LiveChatMessage.t;
}

class LiveChatMessageRepository {
  const LiveChatMessageRepository._();

  /// Returns a list of [LiveChatMessage]s matching the given query parameters.
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
  Future<List<LiveChatMessage>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<LiveChatMessageTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<LiveChatMessageTable>? orderBy,
    _is.OrderByListBuilder<LiveChatMessageTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<LiveChatMessage>(
      where: where?.call(LiveChatMessage.t),
      orderBy: orderBy?.call(LiveChatMessage.t),
      orderByList: orderByList?.call(LiveChatMessage.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [LiveChatMessage] matching the given query parameters.
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
  Future<LiveChatMessage?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<LiveChatMessageTable>? where,
    int? offset,
    _is.OrderByBuilder<LiveChatMessageTable>? orderBy,
    _is.OrderByListBuilder<LiveChatMessageTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<LiveChatMessage>(
      where: where?.call(LiveChatMessage.t),
      orderBy: orderBy?.call(LiveChatMessage.t),
      orderByList: orderByList?.call(LiveChatMessage.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [LiveChatMessage] by its [id] or null if no such row exists.
  Future<LiveChatMessage?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<LiveChatMessage>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [LiveChatMessage]s in the list and returns the inserted rows.
  ///
  /// The returned [LiveChatMessage]s will have their `id` fields set.
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
  Future<List<LiveChatMessage>> insert(
    _is.DatabaseSession session,
    List<LiveChatMessage> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<LiveChatMessage>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [LiveChatMessage] and returns the inserted row.
  ///
  /// The returned [LiveChatMessage] will have its `id` field set.
  Future<LiveChatMessage> insertRow(
    _is.DatabaseSession session,
    LiveChatMessage row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<LiveChatMessage>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [LiveChatMessage]s in the list and returns the resulting rows.
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
  /// The returned [LiveChatMessage]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<LiveChatMessage>> upsert(
    _is.DatabaseSession session,
    List<LiveChatMessage> rows, {
    required _is.ColumnSelections<LiveChatMessageTable> conflictColumns,
    _is.ColumnSelections<LiveChatMessageTable>? updateColumns,
    _is.WhereExpressionBuilder<LiveChatMessageTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<LiveChatMessage>(
      rows,
      conflictColumns: conflictColumns(LiveChatMessage.t),
      updateColumns: updateColumns?.call(LiveChatMessage.t),
      updateWhere: updateWhere?.call(LiveChatMessage.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [LiveChatMessage] and returns the resulting row.
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
  /// The returned [LiveChatMessage] will have its `id` field set.
  Future<LiveChatMessage?> upsertRow(
    _is.DatabaseSession session,
    LiveChatMessage row, {
    required _is.ColumnSelections<LiveChatMessageTable> conflictColumns,
    _is.ColumnSelections<LiveChatMessageTable>? updateColumns,
    _is.WhereExpressionBuilder<LiveChatMessageTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<LiveChatMessage>(
      row,
      conflictColumns: conflictColumns(LiveChatMessage.t),
      updateColumns: updateColumns?.call(LiveChatMessage.t),
      updateWhere: updateWhere?.call(LiveChatMessage.t),
      transaction: transaction,
    );
  }

  /// Updates all [LiveChatMessage]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<LiveChatMessage>> update(
    _is.DatabaseSession session,
    List<LiveChatMessage> rows, {
    _is.ColumnSelections<LiveChatMessageTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<LiveChatMessage>(
      rows,
      columns: columns?.call(LiveChatMessage.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [LiveChatMessage]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<LiveChatMessage> updateRow(
    _is.DatabaseSession session,
    LiveChatMessage row, {
    _is.ColumnSelections<LiveChatMessageTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<LiveChatMessage>(
      row,
      columns: columns?.call(LiveChatMessage.t),
      transaction: transaction,
    );
  }

  /// Updates a single [LiveChatMessage] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<LiveChatMessage?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<LiveChatMessageUpdateTable>
    columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<LiveChatMessage>(
      id,
      columnValues: columnValues(LiveChatMessage.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [LiveChatMessage]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<LiveChatMessage>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<LiveChatMessageUpdateTable>
    columnValues,
    required _is.WhereExpressionBuilder<LiveChatMessageTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<LiveChatMessageTable>? orderBy,
    _is.OrderByListBuilder<LiveChatMessageTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<LiveChatMessage>(
      columnValues: columnValues(LiveChatMessage.t.updateTable),
      where: where(LiveChatMessage.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(LiveChatMessage.t),
      orderByList: orderByList?.call(LiveChatMessage.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [LiveChatMessage]s in the list and returns the deleted rows.
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
  Future<List<LiveChatMessage>> delete(
    _is.DatabaseSession session,
    List<LiveChatMessage> rows, {
    _is.OrderByBuilder<LiveChatMessageTable>? orderBy,
    _is.OrderByListBuilder<LiveChatMessageTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<LiveChatMessage>(
      rows,
      orderBy: orderBy?.call(LiveChatMessage.t),
      orderByList: orderByList?.call(LiveChatMessage.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [LiveChatMessage].
  Future<LiveChatMessage> deleteRow(
    _is.DatabaseSession session,
    LiveChatMessage row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<LiveChatMessage>(
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
  Future<List<LiveChatMessage>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<LiveChatMessageTable> where,
    _is.OrderByBuilder<LiveChatMessageTable>? orderBy,
    _is.OrderByListBuilder<LiveChatMessageTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<LiveChatMessage>(
      where: where(LiveChatMessage.t),
      orderBy: orderBy?.call(LiveChatMessage.t),
      orderByList: orderByList?.call(LiveChatMessage.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<LiveChatMessageTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<LiveChatMessage>(
      where: where?.call(LiveChatMessage.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [LiveChatMessage] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<LiveChatMessageTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<LiveChatMessage>(
      where: where(LiveChatMessage.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
