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
import '../../../modules/live/models/live_show_role.dart' as _isrlpwvf;

/// Quién tiene un lugar en la sala además de mirar (SDD 0011, §4.1): el host,
/// los que están en el escenario, el moderador y quien pidió la palabra.
/// El rol y el escenario son dos ejes (S5): `role` dice qué autoridad tiene,
/// `onStage` si tiene micrófono. Una fila existente manda sobre `LiveShowGuest`:
/// un invitado de la agenda que se baja vuelve a ser oyente.
abstract class LiveParticipant
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
  LiveParticipant._({
    this.id,
    required this.showId,
    required this.userId,
    required this.role,
    bool? onStage,
    this.handRaisedAt,
    bool? micMuted,
    bool? cameraOn,
    DateTime? updatedAt,
  }) : onStage = onStage ?? false,
       micMuted = micMuted ?? false,
       cameraOn = cameraOn ?? false,
       updatedAt = updatedAt ?? DateTime.now();

  factory LiveParticipant({
    int? id,
    required int showId,
    required _is.UuidValue userId,
    required _isrlpwvf.LiveShowRole role,
    bool? onStage,
    DateTime? handRaisedAt,
    bool? micMuted,
    bool? cameraOn,
    DateTime? updatedAt,
  }) = _LiveParticipantImpl;

  factory LiveParticipant.fromJson(Map<String, dynamic> jsonSerialization) {
    return LiveParticipant(
      id: jsonSerialization['id'] as int?,
      showId: jsonSerialization['showId'] as int,
      userId: _is.UuidValueJsonExtension.fromJson(jsonSerialization['userId']),
      role: _isrlpwvf.LiveShowRole.fromJson(
        (jsonSerialization['role'] as String),
      ),
      onStage: jsonSerialization['onStage'] == null
          ? null
          : _is.BoolJsonExtension.fromJson(jsonSerialization['onStage']),
      handRaisedAt: jsonSerialization['handRaisedAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(
              jsonSerialization['handRaisedAt'],
            ),
      micMuted: jsonSerialization['micMuted'] == null
          ? null
          : _is.BoolJsonExtension.fromJson(jsonSerialization['micMuted']),
      cameraOn: jsonSerialization['cameraOn'] == null
          ? null
          : _is.BoolJsonExtension.fromJson(jsonSerialization['cameraOn']),
      updatedAt: jsonSerialization['updatedAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['updatedAt']),
    );
  }

  static final t = LiveParticipantTable();

  static const db = LiveParticipantRepository._();

  @override
  int? id;

  int showId;

  _is.UuidValue userId;

  _isrlpwvf.LiveShowRole role;

  bool onStage;

  /// Pidió la palabra y nadie respondió todavía. Ordena la cola.
  DateTime? handRaisedAt;

  bool micMuted;

  bool cameraOn;

  DateTime updatedAt;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [LiveParticipant]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  LiveParticipant copyWith({
    int? id,
    int? showId,
    _is.UuidValue? userId,
    _isrlpwvf.LiveShowRole? role,
    bool? onStage,
    DateTime? handRaisedAt,
    bool? micMuted,
    bool? cameraOn,
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'LiveParticipant',
      if (id != null) 'id': id,
      'showId': showId,
      'userId': userId.toJson(),
      'role': role.toJson(),
      'onStage': onStage,
      if (handRaisedAt != null) 'handRaisedAt': handRaisedAt?.toJson(),
      'micMuted': micMuted,
      'cameraOn': cameraOn,
      'updatedAt': updatedAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {};
  }

  static LiveParticipantInclude include() {
    return LiveParticipantInclude._();
  }

  static LiveParticipantIncludeList includeList({
    _is.WhereExpressionBuilder<LiveParticipantTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<LiveParticipantTable>? orderBy,
    _is.OrderByListBuilder<LiveParticipantTable>? orderByList,
    LiveParticipantInclude? include,
  }) {
    return LiveParticipantIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(LiveParticipant.t),
      orderByList: orderByList?.call(LiveParticipant.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _LiveParticipantImpl extends LiveParticipant {
  _LiveParticipantImpl({
    int? id,
    required int showId,
    required _is.UuidValue userId,
    required _isrlpwvf.LiveShowRole role,
    bool? onStage,
    DateTime? handRaisedAt,
    bool? micMuted,
    bool? cameraOn,
    DateTime? updatedAt,
  }) : super._(
         id: id,
         showId: showId,
         userId: userId,
         role: role,
         onStage: onStage,
         handRaisedAt: handRaisedAt,
         micMuted: micMuted,
         cameraOn: cameraOn,
         updatedAt: updatedAt,
       );

  /// Returns a shallow copy of this [LiveParticipant]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  LiveParticipant copyWith({
    Object? id = _Undefined,
    int? showId,
    _is.UuidValue? userId,
    _isrlpwvf.LiveShowRole? role,
    bool? onStage,
    Object? handRaisedAt = _Undefined,
    bool? micMuted,
    bool? cameraOn,
    DateTime? updatedAt,
  }) {
    return LiveParticipant(
      id: id is int? ? id : this.id,
      showId: showId ?? this.showId,
      userId: userId ?? this.userId,
      role: role ?? this.role,
      onStage: onStage ?? this.onStage,
      handRaisedAt: handRaisedAt is DateTime?
          ? handRaisedAt
          : this.handRaisedAt,
      micMuted: micMuted ?? this.micMuted,
      cameraOn: cameraOn ?? this.cameraOn,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class LiveParticipantUpdateTable extends _is.UpdateTable<LiveParticipantTable> {
  LiveParticipantUpdateTable(super.table);

  _is.ColumnValue<int, int> showId(int value) => _is.ColumnValue(
    table.showId,
    value,
  );

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> userId(_is.UuidValue value) =>
      _is.ColumnValue(
        table.userId,
        value,
      );

  _is.ColumnValue<_isrlpwvf.LiveShowRole, _isrlpwvf.LiveShowRole> role(
    _isrlpwvf.LiveShowRole value,
  ) => _is.ColumnValue(
    table.role,
    value,
  );

  _is.ColumnValue<bool, bool> onStage(bool value) => _is.ColumnValue(
    table.onStage,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> handRaisedAt(DateTime? value) =>
      _is.ColumnValue(
        table.handRaisedAt,
        value,
      );

  _is.ColumnValue<bool, bool> micMuted(bool value) => _is.ColumnValue(
    table.micMuted,
    value,
  );

  _is.ColumnValue<bool, bool> cameraOn(bool value) => _is.ColumnValue(
    table.cameraOn,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> updatedAt(DateTime value) =>
      _is.ColumnValue(
        table.updatedAt,
        value,
      );
}

class LiveParticipantTable extends _is.Table<int?> {
  LiveParticipantTable({super.tableRelation})
    : super(tableName: 'live_participant') {
    updateTable = LiveParticipantUpdateTable(this);
    showId = _is.ColumnInt(
      'showId',
      this,
    );
    userId = _is.ColumnUuid(
      'userId',
      this,
    );
    role = _is.ColumnEnum(
      'role',
      this,
      _is.EnumSerialization.byName,
    );
    onStage = _is.ColumnBool(
      'onStage',
      this,
      hasDefault: true,
    );
    handRaisedAt = _is.ColumnDateTime(
      'handRaisedAt',
      this,
    );
    micMuted = _is.ColumnBool(
      'micMuted',
      this,
      hasDefault: true,
    );
    cameraOn = _is.ColumnBool(
      'cameraOn',
      this,
      hasDefault: true,
    );
    updatedAt = _is.ColumnDateTime(
      'updatedAt',
      this,
      hasDefault: true,
    );
  }

  late final LiveParticipantUpdateTable updateTable;

  late final _is.ColumnInt showId;

  late final _is.ColumnUuid userId;

  late final _is.ColumnEnum<_isrlpwvf.LiveShowRole> role;

  late final _is.ColumnBool onStage;

  /// Pidió la palabra y nadie respondió todavía. Ordena la cola.
  late final _is.ColumnDateTime handRaisedAt;

  late final _is.ColumnBool micMuted;

  late final _is.ColumnBool cameraOn;

  late final _is.ColumnDateTime updatedAt;

  @override
  List<_is.Column> get columns => [
    id,
    showId,
    userId,
    role,
    onStage,
    handRaisedAt,
    micMuted,
    cameraOn,
    updatedAt,
  ];
}

class LiveParticipantInclude extends _is.IncludeObject {
  LiveParticipantInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => LiveParticipant.t;
}

class LiveParticipantIncludeList extends _is.IncludeList {
  LiveParticipantIncludeList._({
    _is.WhereExpressionBuilder<LiveParticipantTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(LiveParticipant.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => LiveParticipant.t;
}

class LiveParticipantRepository {
  const LiveParticipantRepository._();

  /// Returns a list of [LiveParticipant]s matching the given query parameters.
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
  Future<List<LiveParticipant>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<LiveParticipantTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<LiveParticipantTable>? orderBy,
    _is.OrderByListBuilder<LiveParticipantTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<LiveParticipant>(
      where: where?.call(LiveParticipant.t),
      orderBy: orderBy?.call(LiveParticipant.t),
      orderByList: orderByList?.call(LiveParticipant.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [LiveParticipant] matching the given query parameters.
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
  Future<LiveParticipant?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<LiveParticipantTable>? where,
    int? offset,
    _is.OrderByBuilder<LiveParticipantTable>? orderBy,
    _is.OrderByListBuilder<LiveParticipantTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<LiveParticipant>(
      where: where?.call(LiveParticipant.t),
      orderBy: orderBy?.call(LiveParticipant.t),
      orderByList: orderByList?.call(LiveParticipant.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [LiveParticipant] by its [id] or null if no such row exists.
  Future<LiveParticipant?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<LiveParticipant>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [LiveParticipant]s in the list and returns the inserted rows.
  ///
  /// The returned [LiveParticipant]s will have their `id` fields set.
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
  Future<List<LiveParticipant>> insert(
    _is.DatabaseSession session,
    List<LiveParticipant> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<LiveParticipant>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [LiveParticipant] and returns the inserted row.
  ///
  /// The returned [LiveParticipant] will have its `id` field set.
  Future<LiveParticipant> insertRow(
    _is.DatabaseSession session,
    LiveParticipant row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<LiveParticipant>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [LiveParticipant]s in the list and returns the resulting rows.
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
  /// The returned [LiveParticipant]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<LiveParticipant>> upsert(
    _is.DatabaseSession session,
    List<LiveParticipant> rows, {
    required _is.ColumnSelections<LiveParticipantTable> conflictColumns,
    _is.ColumnSelections<LiveParticipantTable>? updateColumns,
    _is.WhereExpressionBuilder<LiveParticipantTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<LiveParticipant>(
      rows,
      conflictColumns: conflictColumns(LiveParticipant.t),
      updateColumns: updateColumns?.call(LiveParticipant.t),
      updateWhere: updateWhere?.call(LiveParticipant.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [LiveParticipant] and returns the resulting row.
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
  /// The returned [LiveParticipant] will have its `id` field set.
  Future<LiveParticipant?> upsertRow(
    _is.DatabaseSession session,
    LiveParticipant row, {
    required _is.ColumnSelections<LiveParticipantTable> conflictColumns,
    _is.ColumnSelections<LiveParticipantTable>? updateColumns,
    _is.WhereExpressionBuilder<LiveParticipantTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<LiveParticipant>(
      row,
      conflictColumns: conflictColumns(LiveParticipant.t),
      updateColumns: updateColumns?.call(LiveParticipant.t),
      updateWhere: updateWhere?.call(LiveParticipant.t),
      transaction: transaction,
    );
  }

  /// Updates all [LiveParticipant]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<LiveParticipant>> update(
    _is.DatabaseSession session,
    List<LiveParticipant> rows, {
    _is.ColumnSelections<LiveParticipantTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<LiveParticipant>(
      rows,
      columns: columns?.call(LiveParticipant.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [LiveParticipant]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<LiveParticipant> updateRow(
    _is.DatabaseSession session,
    LiveParticipant row, {
    _is.ColumnSelections<LiveParticipantTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<LiveParticipant>(
      row,
      columns: columns?.call(LiveParticipant.t),
      transaction: transaction,
    );
  }

  /// Updates a single [LiveParticipant] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<LiveParticipant?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<LiveParticipantUpdateTable>
    columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<LiveParticipant>(
      id,
      columnValues: columnValues(LiveParticipant.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [LiveParticipant]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<LiveParticipant>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<LiveParticipantUpdateTable>
    columnValues,
    required _is.WhereExpressionBuilder<LiveParticipantTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<LiveParticipantTable>? orderBy,
    _is.OrderByListBuilder<LiveParticipantTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<LiveParticipant>(
      columnValues: columnValues(LiveParticipant.t.updateTable),
      where: where(LiveParticipant.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(LiveParticipant.t),
      orderByList: orderByList?.call(LiveParticipant.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [LiveParticipant]s in the list and returns the deleted rows.
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
  Future<List<LiveParticipant>> delete(
    _is.DatabaseSession session,
    List<LiveParticipant> rows, {
    _is.OrderByBuilder<LiveParticipantTable>? orderBy,
    _is.OrderByListBuilder<LiveParticipantTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<LiveParticipant>(
      rows,
      orderBy: orderBy?.call(LiveParticipant.t),
      orderByList: orderByList?.call(LiveParticipant.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [LiveParticipant].
  Future<LiveParticipant> deleteRow(
    _is.DatabaseSession session,
    LiveParticipant row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<LiveParticipant>(
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
  Future<List<LiveParticipant>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<LiveParticipantTable> where,
    _is.OrderByBuilder<LiveParticipantTable>? orderBy,
    _is.OrderByListBuilder<LiveParticipantTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<LiveParticipant>(
      where: where(LiveParticipant.t),
      orderBy: orderBy?.call(LiveParticipant.t),
      orderByList: orderByList?.call(LiveParticipant.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<LiveParticipantTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<LiveParticipant>(
      where: where?.call(LiveParticipant.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [LiveParticipant] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<LiveParticipantTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<LiveParticipant>(
      where: where(LiveParticipant.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
