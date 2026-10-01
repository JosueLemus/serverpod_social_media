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

/// Un like de un usuario a un post. Uno por usuario y post: dar like dos
/// veces no suma dos. Quitar el like borra la fila; no es contenido que haya
/// que conservar.
abstract class PostLike
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
  PostLike._({
    this.id,
    required this.postId,
    required this.userId,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory PostLike({
    int? id,
    required int postId,
    required _is.UuidValue userId,
    DateTime? createdAt,
  }) = _PostLikeImpl;

  factory PostLike.fromJson(Map<String, dynamic> jsonSerialization) {
    return PostLike(
      id: jsonSerialization['id'] as int?,
      postId: jsonSerialization['postId'] as int,
      userId: _is.UuidValueJsonExtension.fromJson(jsonSerialization['userId']),
      createdAt: jsonSerialization['createdAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['createdAt']),
    );
  }

  static final t = PostLikeTable();

  static const db = PostLikeRepository._();

  @override
  int? id;

  int postId;

  _is.UuidValue userId;

  DateTime createdAt;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [PostLike]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  PostLike copyWith({
    int? id,
    int? postId,
    _is.UuidValue? userId,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'PostLike',
      if (id != null) 'id': id,
      'postId': postId,
      'userId': userId.toJson(),
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {};
  }

  static PostLikeInclude include() {
    return PostLikeInclude._();
  }

  static PostLikeIncludeList includeList({
    _is.WhereExpressionBuilder<PostLikeTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<PostLikeTable>? orderBy,
    _is.OrderByListBuilder<PostLikeTable>? orderByList,
    PostLikeInclude? include,
  }) {
    return PostLikeIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(PostLike.t),
      orderByList: orderByList?.call(PostLike.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _PostLikeImpl extends PostLike {
  _PostLikeImpl({
    int? id,
    required int postId,
    required _is.UuidValue userId,
    DateTime? createdAt,
  }) : super._(
         id: id,
         postId: postId,
         userId: userId,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [PostLike]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  PostLike copyWith({
    Object? id = _Undefined,
    int? postId,
    _is.UuidValue? userId,
    DateTime? createdAt,
  }) {
    return PostLike(
      id: id is int? ? id : this.id,
      postId: postId ?? this.postId,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class PostLikeUpdateTable extends _is.UpdateTable<PostLikeTable> {
  PostLikeUpdateTable(super.table);

  _is.ColumnValue<int, int> postId(int value) => _is.ColumnValue(
    table.postId,
    value,
  );

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> userId(_is.UuidValue value) =>
      _is.ColumnValue(
        table.userId,
        value,
      );

  _is.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _is.ColumnValue(
        table.createdAt,
        value,
      );
}

class PostLikeTable extends _is.Table<int?> {
  PostLikeTable({super.tableRelation}) : super(tableName: 'post_like') {
    updateTable = PostLikeUpdateTable(this);
    postId = _is.ColumnInt(
      'postId',
      this,
    );
    userId = _is.ColumnUuid(
      'userId',
      this,
    );
    createdAt = _is.ColumnDateTime(
      'createdAt',
      this,
      hasDefault: true,
    );
  }

  late final PostLikeUpdateTable updateTable;

  late final _is.ColumnInt postId;

  late final _is.ColumnUuid userId;

  late final _is.ColumnDateTime createdAt;

  @override
  List<_is.Column> get columns => [
    id,
    postId,
    userId,
    createdAt,
  ];
}

class PostLikeInclude extends _is.IncludeObject {
  PostLikeInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => PostLike.t;
}

class PostLikeIncludeList extends _is.IncludeList {
  PostLikeIncludeList._({
    _is.WhereExpressionBuilder<PostLikeTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(PostLike.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => PostLike.t;
}

class PostLikeRepository {
  const PostLikeRepository._();

  /// Returns a list of [PostLike]s matching the given query parameters.
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
  Future<List<PostLike>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<PostLikeTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<PostLikeTable>? orderBy,
    _is.OrderByListBuilder<PostLikeTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<PostLike>(
      where: where?.call(PostLike.t),
      orderBy: orderBy?.call(PostLike.t),
      orderByList: orderByList?.call(PostLike.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [PostLike] matching the given query parameters.
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
  Future<PostLike?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<PostLikeTable>? where,
    int? offset,
    _is.OrderByBuilder<PostLikeTable>? orderBy,
    _is.OrderByListBuilder<PostLikeTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<PostLike>(
      where: where?.call(PostLike.t),
      orderBy: orderBy?.call(PostLike.t),
      orderByList: orderByList?.call(PostLike.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [PostLike] by its [id] or null if no such row exists.
  Future<PostLike?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<PostLike>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [PostLike]s in the list and returns the inserted rows.
  ///
  /// The returned [PostLike]s will have their `id` fields set.
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
  Future<List<PostLike>> insert(
    _is.DatabaseSession session,
    List<PostLike> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<PostLike>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [PostLike] and returns the inserted row.
  ///
  /// The returned [PostLike] will have its `id` field set.
  Future<PostLike> insertRow(
    _is.DatabaseSession session,
    PostLike row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<PostLike>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [PostLike]s in the list and returns the resulting rows.
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
  /// The returned [PostLike]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<PostLike>> upsert(
    _is.DatabaseSession session,
    List<PostLike> rows, {
    required _is.ColumnSelections<PostLikeTable> conflictColumns,
    _is.ColumnSelections<PostLikeTable>? updateColumns,
    _is.WhereExpressionBuilder<PostLikeTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<PostLike>(
      rows,
      conflictColumns: conflictColumns(PostLike.t),
      updateColumns: updateColumns?.call(PostLike.t),
      updateWhere: updateWhere?.call(PostLike.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [PostLike] and returns the resulting row.
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
  /// The returned [PostLike] will have its `id` field set.
  Future<PostLike?> upsertRow(
    _is.DatabaseSession session,
    PostLike row, {
    required _is.ColumnSelections<PostLikeTable> conflictColumns,
    _is.ColumnSelections<PostLikeTable>? updateColumns,
    _is.WhereExpressionBuilder<PostLikeTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<PostLike>(
      row,
      conflictColumns: conflictColumns(PostLike.t),
      updateColumns: updateColumns?.call(PostLike.t),
      updateWhere: updateWhere?.call(PostLike.t),
      transaction: transaction,
    );
  }

  /// Updates all [PostLike]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<PostLike>> update(
    _is.DatabaseSession session,
    List<PostLike> rows, {
    _is.ColumnSelections<PostLikeTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<PostLike>(
      rows,
      columns: columns?.call(PostLike.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [PostLike]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<PostLike> updateRow(
    _is.DatabaseSession session,
    PostLike row, {
    _is.ColumnSelections<PostLikeTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<PostLike>(
      row,
      columns: columns?.call(PostLike.t),
      transaction: transaction,
    );
  }

  /// Updates a single [PostLike] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<PostLike?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<PostLikeUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<PostLike>(
      id,
      columnValues: columnValues(PostLike.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [PostLike]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<PostLike>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<PostLikeUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<PostLikeTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<PostLikeTable>? orderBy,
    _is.OrderByListBuilder<PostLikeTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<PostLike>(
      columnValues: columnValues(PostLike.t.updateTable),
      where: where(PostLike.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(PostLike.t),
      orderByList: orderByList?.call(PostLike.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [PostLike]s in the list and returns the deleted rows.
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
  Future<List<PostLike>> delete(
    _is.DatabaseSession session,
    List<PostLike> rows, {
    _is.OrderByBuilder<PostLikeTable>? orderBy,
    _is.OrderByListBuilder<PostLikeTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<PostLike>(
      rows,
      orderBy: orderBy?.call(PostLike.t),
      orderByList: orderByList?.call(PostLike.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [PostLike].
  Future<PostLike> deleteRow(
    _is.DatabaseSession session,
    PostLike row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<PostLike>(
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
  Future<List<PostLike>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<PostLikeTable> where,
    _is.OrderByBuilder<PostLikeTable>? orderBy,
    _is.OrderByListBuilder<PostLikeTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<PostLike>(
      where: where(PostLike.t),
      orderBy: orderBy?.call(PostLike.t),
      orderByList: orderByList?.call(PostLike.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<PostLikeTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<PostLike>(
      where: where?.call(PostLike.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [PostLike] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<PostLikeTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<PostLike>(
      where: where(PostLike.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
