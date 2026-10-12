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
import '../../../modules/notifications/models/notification_kind.dart'
    as _i1q1i3wt;

/// Un aviso para una cuenta. Se crea en la misma transacción que la acción
/// que lo origina y se publica después del commit (SDD 0008, S11). No
/// `Notification`: en la app chocaría con la clase de Flutter.
abstract class UserNotification
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
  UserNotification._({
    this.id,
    required this.userId,
    required this.kind,
    this.actorId,
    this.postId,
    this.showId,
    this.readAt,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory UserNotification({
    int? id,
    required _is.UuidValue userId,
    required _i1q1i3wt.NotificationKind kind,
    _is.UuidValue? actorId,
    int? postId,
    int? showId,
    DateTime? readAt,
    DateTime? createdAt,
  }) = _UserNotificationImpl;

  factory UserNotification.fromJson(Map<String, dynamic> jsonSerialization) {
    return UserNotification(
      id: jsonSerialization['id'] as int?,
      userId: _is.UuidValueJsonExtension.fromJson(jsonSerialization['userId']),
      kind: _i1q1i3wt.NotificationKind.fromJson(
        (jsonSerialization['kind'] as String),
      ),
      actorId: jsonSerialization['actorId'] == null
          ? null
          : _is.UuidValueJsonExtension.fromJson(jsonSerialization['actorId']),
      postId: jsonSerialization['postId'] as int?,
      showId: jsonSerialization['showId'] as int?,
      readAt: jsonSerialization['readAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['readAt']),
      createdAt: jsonSerialization['createdAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['createdAt']),
    );
  }

  static final t = UserNotificationTable();

  static const db = UserNotificationRepository._();

  @override
  int? id;

  _is.UuidValue userId;

  _i1q1i3wt.NotificationKind kind;

  /// Quién lo causó. `null` para los avisos del sistema.
  _is.UuidValue? actorId;

  int? postId;

  int? showId;

  DateTime? readAt;

  DateTime createdAt;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [UserNotification]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  UserNotification copyWith({
    int? id,
    _is.UuidValue? userId,
    _i1q1i3wt.NotificationKind? kind,
    _is.UuidValue? actorId,
    int? postId,
    int? showId,
    DateTime? readAt,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'UserNotification',
      if (id != null) 'id': id,
      'userId': userId.toJson(),
      'kind': kind.toJson(),
      if (actorId != null) 'actorId': actorId?.toJson(),
      if (postId != null) 'postId': postId,
      if (showId != null) 'showId': showId,
      if (readAt != null) 'readAt': readAt?.toJson(),
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {};
  }

  static UserNotificationInclude include() {
    return UserNotificationInclude._();
  }

  static UserNotificationIncludeList includeList({
    _is.WhereExpressionBuilder<UserNotificationTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<UserNotificationTable>? orderBy,
    _is.OrderByListBuilder<UserNotificationTable>? orderByList,
    UserNotificationInclude? include,
  }) {
    return UserNotificationIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(UserNotification.t),
      orderByList: orderByList?.call(UserNotification.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _UserNotificationImpl extends UserNotification {
  _UserNotificationImpl({
    int? id,
    required _is.UuidValue userId,
    required _i1q1i3wt.NotificationKind kind,
    _is.UuidValue? actorId,
    int? postId,
    int? showId,
    DateTime? readAt,
    DateTime? createdAt,
  }) : super._(
         id: id,
         userId: userId,
         kind: kind,
         actorId: actorId,
         postId: postId,
         showId: showId,
         readAt: readAt,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [UserNotification]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  UserNotification copyWith({
    Object? id = _Undefined,
    _is.UuidValue? userId,
    _i1q1i3wt.NotificationKind? kind,
    Object? actorId = _Undefined,
    Object? postId = _Undefined,
    Object? showId = _Undefined,
    Object? readAt = _Undefined,
    DateTime? createdAt,
  }) {
    return UserNotification(
      id: id is int? ? id : this.id,
      userId: userId ?? this.userId,
      kind: kind ?? this.kind,
      actorId: actorId is _is.UuidValue? ? actorId : this.actorId,
      postId: postId is int? ? postId : this.postId,
      showId: showId is int? ? showId : this.showId,
      readAt: readAt is DateTime? ? readAt : this.readAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class UserNotificationUpdateTable
    extends _is.UpdateTable<UserNotificationTable> {
  UserNotificationUpdateTable(super.table);

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> userId(_is.UuidValue value) =>
      _is.ColumnValue(
        table.userId,
        value,
      );

  _is.ColumnValue<_i1q1i3wt.NotificationKind, _i1q1i3wt.NotificationKind> kind(
    _i1q1i3wt.NotificationKind value,
  ) => _is.ColumnValue(
    table.kind,
    value,
  );

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> actorId(_is.UuidValue? value) =>
      _is.ColumnValue(
        table.actorId,
        value,
      );

  _is.ColumnValue<int, int> postId(int? value) => _is.ColumnValue(
    table.postId,
    value,
  );

  _is.ColumnValue<int, int> showId(int? value) => _is.ColumnValue(
    table.showId,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> readAt(DateTime? value) =>
      _is.ColumnValue(
        table.readAt,
        value,
      );

  _is.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _is.ColumnValue(
        table.createdAt,
        value,
      );
}

class UserNotificationTable extends _is.Table<int?> {
  UserNotificationTable({super.tableRelation})
    : super(tableName: 'user_notification') {
    updateTable = UserNotificationUpdateTable(this);
    userId = _is.ColumnUuid(
      'userId',
      this,
    );
    kind = _is.ColumnEnum(
      'kind',
      this,
      _is.EnumSerialization.byName,
    );
    actorId = _is.ColumnUuid(
      'actorId',
      this,
    );
    postId = _is.ColumnInt(
      'postId',
      this,
    );
    showId = _is.ColumnInt(
      'showId',
      this,
    );
    readAt = _is.ColumnDateTime(
      'readAt',
      this,
    );
    createdAt = _is.ColumnDateTime(
      'createdAt',
      this,
      hasDefault: true,
    );
  }

  late final UserNotificationUpdateTable updateTable;

  late final _is.ColumnUuid userId;

  late final _is.ColumnEnum<_i1q1i3wt.NotificationKind> kind;

  /// Quién lo causó. `null` para los avisos del sistema.
  late final _is.ColumnUuid actorId;

  late final _is.ColumnInt postId;

  late final _is.ColumnInt showId;

  late final _is.ColumnDateTime readAt;

  late final _is.ColumnDateTime createdAt;

  @override
  List<_is.Column> get columns => [
    id,
    userId,
    kind,
    actorId,
    postId,
    showId,
    readAt,
    createdAt,
  ];
}

class UserNotificationInclude extends _is.IncludeObject {
  UserNotificationInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => UserNotification.t;
}

class UserNotificationIncludeList extends _is.IncludeList {
  UserNotificationIncludeList._({
    _is.WhereExpressionBuilder<UserNotificationTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(UserNotification.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => UserNotification.t;
}

class UserNotificationRepository {
  const UserNotificationRepository._();

  /// Returns a list of [UserNotification]s matching the given query parameters.
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
  Future<List<UserNotification>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<UserNotificationTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<UserNotificationTable>? orderBy,
    _is.OrderByListBuilder<UserNotificationTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<UserNotification>(
      where: where?.call(UserNotification.t),
      orderBy: orderBy?.call(UserNotification.t),
      orderByList: orderByList?.call(UserNotification.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [UserNotification] matching the given query parameters.
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
  Future<UserNotification?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<UserNotificationTable>? where,
    int? offset,
    _is.OrderByBuilder<UserNotificationTable>? orderBy,
    _is.OrderByListBuilder<UserNotificationTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<UserNotification>(
      where: where?.call(UserNotification.t),
      orderBy: orderBy?.call(UserNotification.t),
      orderByList: orderByList?.call(UserNotification.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [UserNotification] by its [id] or null if no such row exists.
  Future<UserNotification?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<UserNotification>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [UserNotification]s in the list and returns the inserted rows.
  ///
  /// The returned [UserNotification]s will have their `id` fields set.
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
  Future<List<UserNotification>> insert(
    _is.DatabaseSession session,
    List<UserNotification> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<UserNotification>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [UserNotification] and returns the inserted row.
  ///
  /// The returned [UserNotification] will have its `id` field set.
  Future<UserNotification> insertRow(
    _is.DatabaseSession session,
    UserNotification row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<UserNotification>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [UserNotification]s in the list and returns the resulting rows.
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
  /// The returned [UserNotification]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<UserNotification>> upsert(
    _is.DatabaseSession session,
    List<UserNotification> rows, {
    required _is.ColumnSelections<UserNotificationTable> conflictColumns,
    _is.ColumnSelections<UserNotificationTable>? updateColumns,
    _is.WhereExpressionBuilder<UserNotificationTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<UserNotification>(
      rows,
      conflictColumns: conflictColumns(UserNotification.t),
      updateColumns: updateColumns?.call(UserNotification.t),
      updateWhere: updateWhere?.call(UserNotification.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [UserNotification] and returns the resulting row.
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
  /// The returned [UserNotification] will have its `id` field set.
  Future<UserNotification?> upsertRow(
    _is.DatabaseSession session,
    UserNotification row, {
    required _is.ColumnSelections<UserNotificationTable> conflictColumns,
    _is.ColumnSelections<UserNotificationTable>? updateColumns,
    _is.WhereExpressionBuilder<UserNotificationTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<UserNotification>(
      row,
      conflictColumns: conflictColumns(UserNotification.t),
      updateColumns: updateColumns?.call(UserNotification.t),
      updateWhere: updateWhere?.call(UserNotification.t),
      transaction: transaction,
    );
  }

  /// Updates all [UserNotification]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<UserNotification>> update(
    _is.DatabaseSession session,
    List<UserNotification> rows, {
    _is.ColumnSelections<UserNotificationTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<UserNotification>(
      rows,
      columns: columns?.call(UserNotification.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [UserNotification]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<UserNotification> updateRow(
    _is.DatabaseSession session,
    UserNotification row, {
    _is.ColumnSelections<UserNotificationTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<UserNotification>(
      row,
      columns: columns?.call(UserNotification.t),
      transaction: transaction,
    );
  }

  /// Updates a single [UserNotification] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<UserNotification?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<UserNotificationUpdateTable>
    columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<UserNotification>(
      id,
      columnValues: columnValues(UserNotification.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [UserNotification]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<UserNotification>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<UserNotificationUpdateTable>
    columnValues,
    required _is.WhereExpressionBuilder<UserNotificationTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<UserNotificationTable>? orderBy,
    _is.OrderByListBuilder<UserNotificationTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<UserNotification>(
      columnValues: columnValues(UserNotification.t.updateTable),
      where: where(UserNotification.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(UserNotification.t),
      orderByList: orderByList?.call(UserNotification.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [UserNotification]s in the list and returns the deleted rows.
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
  Future<List<UserNotification>> delete(
    _is.DatabaseSession session,
    List<UserNotification> rows, {
    _is.OrderByBuilder<UserNotificationTable>? orderBy,
    _is.OrderByListBuilder<UserNotificationTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<UserNotification>(
      rows,
      orderBy: orderBy?.call(UserNotification.t),
      orderByList: orderByList?.call(UserNotification.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [UserNotification].
  Future<UserNotification> deleteRow(
    _is.DatabaseSession session,
    UserNotification row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<UserNotification>(
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
  Future<List<UserNotification>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<UserNotificationTable> where,
    _is.OrderByBuilder<UserNotificationTable>? orderBy,
    _is.OrderByListBuilder<UserNotificationTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<UserNotification>(
      where: where(UserNotification.t),
      orderBy: orderBy?.call(UserNotification.t),
      orderByList: orderByList?.call(UserNotification.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<UserNotificationTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<UserNotification>(
      where: where?.call(UserNotification.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [UserNotification] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<UserNotificationTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<UserNotification>(
      where: where(UserNotification.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
