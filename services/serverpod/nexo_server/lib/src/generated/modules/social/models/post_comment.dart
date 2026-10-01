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

/// Comentario de un post, sin respuestas anidadas. Nunca se borra: eliminar
/// pone `deletedAt` y `deletedBy`, igual que un post.
abstract class PostComment
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
  PostComment._({
    this.id,
    required this.postId,
    required this.authorId,
    required this.body,
    DateTime? createdAt,
    this.deletedAt,
    this.deletedBy,
  }) : createdAt = createdAt ?? DateTime.now();

  factory PostComment({
    int? id,
    required int postId,
    required _is.UuidValue authorId,
    required String body,
    DateTime? createdAt,
    DateTime? deletedAt,
    _is.UuidValue? deletedBy,
  }) = _PostCommentImpl;

  factory PostComment.fromJson(Map<String, dynamic> jsonSerialization) {
    return PostComment(
      id: jsonSerialization['id'] as int?,
      postId: jsonSerialization['postId'] as int,
      authorId: _is.UuidValueJsonExtension.fromJson(
        jsonSerialization['authorId'],
      ),
      body: jsonSerialization['body'] as String,
      createdAt: jsonSerialization['createdAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['createdAt']),
      deletedAt: jsonSerialization['deletedAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['deletedAt']),
      deletedBy: jsonSerialization['deletedBy'] == null
          ? null
          : _is.UuidValueJsonExtension.fromJson(jsonSerialization['deletedBy']),
    );
  }

  static final t = PostCommentTable();

  static const db = PostCommentRepository._();

  @override
  int? id;

  int postId;

  _is.UuidValue authorId;

  String body;

  DateTime createdAt;

  DateTime? deletedAt;

  _is.UuidValue? deletedBy;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [PostComment]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  PostComment copyWith({
    int? id,
    int? postId,
    _is.UuidValue? authorId,
    String? body,
    DateTime? createdAt,
    DateTime? deletedAt,
    _is.UuidValue? deletedBy,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'PostComment',
      if (id != null) 'id': id,
      'postId': postId,
      'authorId': authorId.toJson(),
      'body': body,
      'createdAt': createdAt.toJson(),
      if (deletedAt != null) 'deletedAt': deletedAt?.toJson(),
      if (deletedBy != null) 'deletedBy': deletedBy?.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {};
  }

  static PostCommentInclude include() {
    return PostCommentInclude._();
  }

  static PostCommentIncludeList includeList({
    _is.WhereExpressionBuilder<PostCommentTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<PostCommentTable>? orderBy,
    _is.OrderByListBuilder<PostCommentTable>? orderByList,
    PostCommentInclude? include,
  }) {
    return PostCommentIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(PostComment.t),
      orderByList: orderByList?.call(PostComment.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _PostCommentImpl extends PostComment {
  _PostCommentImpl({
    int? id,
    required int postId,
    required _is.UuidValue authorId,
    required String body,
    DateTime? createdAt,
    DateTime? deletedAt,
    _is.UuidValue? deletedBy,
  }) : super._(
         id: id,
         postId: postId,
         authorId: authorId,
         body: body,
         createdAt: createdAt,
         deletedAt: deletedAt,
         deletedBy: deletedBy,
       );

  /// Returns a shallow copy of this [PostComment]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  PostComment copyWith({
    Object? id = _Undefined,
    int? postId,
    _is.UuidValue? authorId,
    String? body,
    DateTime? createdAt,
    Object? deletedAt = _Undefined,
    Object? deletedBy = _Undefined,
  }) {
    return PostComment(
      id: id is int? ? id : this.id,
      postId: postId ?? this.postId,
      authorId: authorId ?? this.authorId,
      body: body ?? this.body,
      createdAt: createdAt ?? this.createdAt,
      deletedAt: deletedAt is DateTime? ? deletedAt : this.deletedAt,
      deletedBy: deletedBy is _is.UuidValue? ? deletedBy : this.deletedBy,
    );
  }
}

class PostCommentUpdateTable extends _is.UpdateTable<PostCommentTable> {
  PostCommentUpdateTable(super.table);

  _is.ColumnValue<int, int> postId(int value) => _is.ColumnValue(
    table.postId,
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

class PostCommentTable extends _is.Table<int?> {
  PostCommentTable({super.tableRelation}) : super(tableName: 'post_comment') {
    updateTable = PostCommentUpdateTable(this);
    postId = _is.ColumnInt(
      'postId',
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
    deletedAt = _is.ColumnDateTime(
      'deletedAt',
      this,
    );
    deletedBy = _is.ColumnUuid(
      'deletedBy',
      this,
    );
  }

  late final PostCommentUpdateTable updateTable;

  late final _is.ColumnInt postId;

  late final _is.ColumnUuid authorId;

  late final _is.ColumnString body;

  late final _is.ColumnDateTime createdAt;

  late final _is.ColumnDateTime deletedAt;

  late final _is.ColumnUuid deletedBy;

  @override
  List<_is.Column> get columns => [
    id,
    postId,
    authorId,
    body,
    createdAt,
    deletedAt,
    deletedBy,
  ];
}

class PostCommentInclude extends _is.IncludeObject {
  PostCommentInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => PostComment.t;
}

class PostCommentIncludeList extends _is.IncludeList {
  PostCommentIncludeList._({
    _is.WhereExpressionBuilder<PostCommentTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(PostComment.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => PostComment.t;
}

class PostCommentRepository {
  const PostCommentRepository._();

  /// Returns a list of [PostComment]s matching the given query parameters.
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
  Future<List<PostComment>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<PostCommentTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<PostCommentTable>? orderBy,
    _is.OrderByListBuilder<PostCommentTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<PostComment>(
      where: where?.call(PostComment.t),
      orderBy: orderBy?.call(PostComment.t),
      orderByList: orderByList?.call(PostComment.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [PostComment] matching the given query parameters.
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
  Future<PostComment?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<PostCommentTable>? where,
    int? offset,
    _is.OrderByBuilder<PostCommentTable>? orderBy,
    _is.OrderByListBuilder<PostCommentTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<PostComment>(
      where: where?.call(PostComment.t),
      orderBy: orderBy?.call(PostComment.t),
      orderByList: orderByList?.call(PostComment.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [PostComment] by its [id] or null if no such row exists.
  Future<PostComment?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<PostComment>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [PostComment]s in the list and returns the inserted rows.
  ///
  /// The returned [PostComment]s will have their `id` fields set.
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
  Future<List<PostComment>> insert(
    _is.DatabaseSession session,
    List<PostComment> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<PostComment>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [PostComment] and returns the inserted row.
  ///
  /// The returned [PostComment] will have its `id` field set.
  Future<PostComment> insertRow(
    _is.DatabaseSession session,
    PostComment row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<PostComment>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [PostComment]s in the list and returns the resulting rows.
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
  /// The returned [PostComment]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<PostComment>> upsert(
    _is.DatabaseSession session,
    List<PostComment> rows, {
    required _is.ColumnSelections<PostCommentTable> conflictColumns,
    _is.ColumnSelections<PostCommentTable>? updateColumns,
    _is.WhereExpressionBuilder<PostCommentTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<PostComment>(
      rows,
      conflictColumns: conflictColumns(PostComment.t),
      updateColumns: updateColumns?.call(PostComment.t),
      updateWhere: updateWhere?.call(PostComment.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [PostComment] and returns the resulting row.
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
  /// The returned [PostComment] will have its `id` field set.
  Future<PostComment?> upsertRow(
    _is.DatabaseSession session,
    PostComment row, {
    required _is.ColumnSelections<PostCommentTable> conflictColumns,
    _is.ColumnSelections<PostCommentTable>? updateColumns,
    _is.WhereExpressionBuilder<PostCommentTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<PostComment>(
      row,
      conflictColumns: conflictColumns(PostComment.t),
      updateColumns: updateColumns?.call(PostComment.t),
      updateWhere: updateWhere?.call(PostComment.t),
      transaction: transaction,
    );
  }

  /// Updates all [PostComment]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<PostComment>> update(
    _is.DatabaseSession session,
    List<PostComment> rows, {
    _is.ColumnSelections<PostCommentTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<PostComment>(
      rows,
      columns: columns?.call(PostComment.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [PostComment]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<PostComment> updateRow(
    _is.DatabaseSession session,
    PostComment row, {
    _is.ColumnSelections<PostCommentTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<PostComment>(
      row,
      columns: columns?.call(PostComment.t),
      transaction: transaction,
    );
  }

  /// Updates a single [PostComment] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<PostComment?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<PostCommentUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<PostComment>(
      id,
      columnValues: columnValues(PostComment.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [PostComment]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<PostComment>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<PostCommentUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<PostCommentTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<PostCommentTable>? orderBy,
    _is.OrderByListBuilder<PostCommentTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<PostComment>(
      columnValues: columnValues(PostComment.t.updateTable),
      where: where(PostComment.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(PostComment.t),
      orderByList: orderByList?.call(PostComment.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [PostComment]s in the list and returns the deleted rows.
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
  Future<List<PostComment>> delete(
    _is.DatabaseSession session,
    List<PostComment> rows, {
    _is.OrderByBuilder<PostCommentTable>? orderBy,
    _is.OrderByListBuilder<PostCommentTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<PostComment>(
      rows,
      orderBy: orderBy?.call(PostComment.t),
      orderByList: orderByList?.call(PostComment.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [PostComment].
  Future<PostComment> deleteRow(
    _is.DatabaseSession session,
    PostComment row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<PostComment>(
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
  Future<List<PostComment>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<PostCommentTable> where,
    _is.OrderByBuilder<PostCommentTable>? orderBy,
    _is.OrderByListBuilder<PostCommentTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<PostComment>(
      where: where(PostComment.t),
      orderBy: orderBy?.call(PostComment.t),
      orderByList: orderByList?.call(PostComment.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<PostCommentTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<PostComment>(
      where: where?.call(PostComment.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [PostComment] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<PostCommentTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<PostComment>(
      where: where(PostComment.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
