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
import '../../../modules/content/models/post_media_kind.dart' as _ib68txho;

/// Archivo adjunto a un post. La base guarda la clave del storage, nunca el
/// binario. Es inmutable: editar un post no cambia sus adjuntos.
abstract class PostMedia
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
  PostMedia._({
    this.id,
    required this.postId,
    required this.kind,
    required this.storageKey,
    required this.contentType,
    required this.position,
  });

  factory PostMedia({
    int? id,
    required int postId,
    required _ib68txho.PostMediaKind kind,
    required String storageKey,
    required String contentType,
    required int position,
  }) = _PostMediaImpl;

  factory PostMedia.fromJson(Map<String, dynamic> jsonSerialization) {
    return PostMedia(
      id: jsonSerialization['id'] as int?,
      postId: jsonSerialization['postId'] as int,
      kind: _ib68txho.PostMediaKind.fromJson(
        (jsonSerialization['kind'] as String),
      ),
      storageKey: jsonSerialization['storageKey'] as String,
      contentType: jsonSerialization['contentType'] as String,
      position: jsonSerialization['position'] as int,
    );
  }

  static final t = PostMediaTable();

  static const db = PostMediaRepository._();

  @override
  int? id;

  int postId;

  _ib68txho.PostMediaKind kind;

  String storageKey;

  String contentType;

  int position;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [PostMedia]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  PostMedia copyWith({
    int? id,
    int? postId,
    _ib68txho.PostMediaKind? kind,
    String? storageKey,
    String? contentType,
    int? position,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'PostMedia',
      if (id != null) 'id': id,
      'postId': postId,
      'kind': kind.toJson(),
      'storageKey': storageKey,
      'contentType': contentType,
      'position': position,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {};
  }

  static PostMediaInclude include() {
    return PostMediaInclude._();
  }

  static PostMediaIncludeList includeList({
    _is.WhereExpressionBuilder<PostMediaTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<PostMediaTable>? orderBy,
    _is.OrderByListBuilder<PostMediaTable>? orderByList,
    PostMediaInclude? include,
  }) {
    return PostMediaIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(PostMedia.t),
      orderByList: orderByList?.call(PostMedia.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _PostMediaImpl extends PostMedia {
  _PostMediaImpl({
    int? id,
    required int postId,
    required _ib68txho.PostMediaKind kind,
    required String storageKey,
    required String contentType,
    required int position,
  }) : super._(
         id: id,
         postId: postId,
         kind: kind,
         storageKey: storageKey,
         contentType: contentType,
         position: position,
       );

  /// Returns a shallow copy of this [PostMedia]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  PostMedia copyWith({
    Object? id = _Undefined,
    int? postId,
    _ib68txho.PostMediaKind? kind,
    String? storageKey,
    String? contentType,
    int? position,
  }) {
    return PostMedia(
      id: id is int? ? id : this.id,
      postId: postId ?? this.postId,
      kind: kind ?? this.kind,
      storageKey: storageKey ?? this.storageKey,
      contentType: contentType ?? this.contentType,
      position: position ?? this.position,
    );
  }
}

class PostMediaUpdateTable extends _is.UpdateTable<PostMediaTable> {
  PostMediaUpdateTable(super.table);

  _is.ColumnValue<int, int> postId(int value) => _is.ColumnValue(
    table.postId,
    value,
  );

  _is.ColumnValue<_ib68txho.PostMediaKind, _ib68txho.PostMediaKind> kind(
    _ib68txho.PostMediaKind value,
  ) => _is.ColumnValue(
    table.kind,
    value,
  );

  _is.ColumnValue<String, String> storageKey(String value) => _is.ColumnValue(
    table.storageKey,
    value,
  );

  _is.ColumnValue<String, String> contentType(String value) => _is.ColumnValue(
    table.contentType,
    value,
  );

  _is.ColumnValue<int, int> position(int value) => _is.ColumnValue(
    table.position,
    value,
  );
}

class PostMediaTable extends _is.Table<int?> {
  PostMediaTable({super.tableRelation}) : super(tableName: 'post_media') {
    updateTable = PostMediaUpdateTable(this);
    postId = _is.ColumnInt(
      'postId',
      this,
    );
    kind = _is.ColumnEnum(
      'kind',
      this,
      _is.EnumSerialization.byName,
    );
    storageKey = _is.ColumnString(
      'storageKey',
      this,
    );
    contentType = _is.ColumnString(
      'contentType',
      this,
    );
    position = _is.ColumnInt(
      'position',
      this,
    );
  }

  late final PostMediaUpdateTable updateTable;

  late final _is.ColumnInt postId;

  late final _is.ColumnEnum<_ib68txho.PostMediaKind> kind;

  late final _is.ColumnString storageKey;

  late final _is.ColumnString contentType;

  late final _is.ColumnInt position;

  @override
  List<_is.Column> get columns => [
    id,
    postId,
    kind,
    storageKey,
    contentType,
    position,
  ];
}

class PostMediaInclude extends _is.IncludeObject {
  PostMediaInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => PostMedia.t;
}

class PostMediaIncludeList extends _is.IncludeList {
  PostMediaIncludeList._({
    _is.WhereExpressionBuilder<PostMediaTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(PostMedia.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => PostMedia.t;
}

class PostMediaRepository {
  const PostMediaRepository._();

  /// Returns a list of [PostMedia]s matching the given query parameters.
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
  Future<List<PostMedia>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<PostMediaTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<PostMediaTable>? orderBy,
    _is.OrderByListBuilder<PostMediaTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<PostMedia>(
      where: where?.call(PostMedia.t),
      orderBy: orderBy?.call(PostMedia.t),
      orderByList: orderByList?.call(PostMedia.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [PostMedia] matching the given query parameters.
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
  Future<PostMedia?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<PostMediaTable>? where,
    int? offset,
    _is.OrderByBuilder<PostMediaTable>? orderBy,
    _is.OrderByListBuilder<PostMediaTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<PostMedia>(
      where: where?.call(PostMedia.t),
      orderBy: orderBy?.call(PostMedia.t),
      orderByList: orderByList?.call(PostMedia.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [PostMedia] by its [id] or null if no such row exists.
  Future<PostMedia?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<PostMedia>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [PostMedia]s in the list and returns the inserted rows.
  ///
  /// The returned [PostMedia]s will have their `id` fields set.
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
  Future<List<PostMedia>> insert(
    _is.DatabaseSession session,
    List<PostMedia> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<PostMedia>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [PostMedia] and returns the inserted row.
  ///
  /// The returned [PostMedia] will have its `id` field set.
  Future<PostMedia> insertRow(
    _is.DatabaseSession session,
    PostMedia row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<PostMedia>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [PostMedia]s in the list and returns the resulting rows.
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
  /// The returned [PostMedia]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<PostMedia>> upsert(
    _is.DatabaseSession session,
    List<PostMedia> rows, {
    required _is.ColumnSelections<PostMediaTable> conflictColumns,
    _is.ColumnSelections<PostMediaTable>? updateColumns,
    _is.WhereExpressionBuilder<PostMediaTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<PostMedia>(
      rows,
      conflictColumns: conflictColumns(PostMedia.t),
      updateColumns: updateColumns?.call(PostMedia.t),
      updateWhere: updateWhere?.call(PostMedia.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [PostMedia] and returns the resulting row.
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
  /// The returned [PostMedia] will have its `id` field set.
  Future<PostMedia?> upsertRow(
    _is.DatabaseSession session,
    PostMedia row, {
    required _is.ColumnSelections<PostMediaTable> conflictColumns,
    _is.ColumnSelections<PostMediaTable>? updateColumns,
    _is.WhereExpressionBuilder<PostMediaTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<PostMedia>(
      row,
      conflictColumns: conflictColumns(PostMedia.t),
      updateColumns: updateColumns?.call(PostMedia.t),
      updateWhere: updateWhere?.call(PostMedia.t),
      transaction: transaction,
    );
  }

  /// Updates all [PostMedia]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<PostMedia>> update(
    _is.DatabaseSession session,
    List<PostMedia> rows, {
    _is.ColumnSelections<PostMediaTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<PostMedia>(
      rows,
      columns: columns?.call(PostMedia.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [PostMedia]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<PostMedia> updateRow(
    _is.DatabaseSession session,
    PostMedia row, {
    _is.ColumnSelections<PostMediaTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<PostMedia>(
      row,
      columns: columns?.call(PostMedia.t),
      transaction: transaction,
    );
  }

  /// Updates a single [PostMedia] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<PostMedia?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<PostMediaUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<PostMedia>(
      id,
      columnValues: columnValues(PostMedia.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [PostMedia]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<PostMedia>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<PostMediaUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<PostMediaTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<PostMediaTable>? orderBy,
    _is.OrderByListBuilder<PostMediaTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<PostMedia>(
      columnValues: columnValues(PostMedia.t.updateTable),
      where: where(PostMedia.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(PostMedia.t),
      orderByList: orderByList?.call(PostMedia.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [PostMedia]s in the list and returns the deleted rows.
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
  Future<List<PostMedia>> delete(
    _is.DatabaseSession session,
    List<PostMedia> rows, {
    _is.OrderByBuilder<PostMediaTable>? orderBy,
    _is.OrderByListBuilder<PostMediaTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<PostMedia>(
      rows,
      orderBy: orderBy?.call(PostMedia.t),
      orderByList: orderByList?.call(PostMedia.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [PostMedia].
  Future<PostMedia> deleteRow(
    _is.DatabaseSession session,
    PostMedia row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<PostMedia>(
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
  Future<List<PostMedia>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<PostMediaTable> where,
    _is.OrderByBuilder<PostMediaTable>? orderBy,
    _is.OrderByListBuilder<PostMediaTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<PostMedia>(
      where: where(PostMedia.t),
      orderBy: orderBy?.call(PostMedia.t),
      orderByList: orderByList?.call(PostMedia.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<PostMediaTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<PostMedia>(
      where: where?.call(PostMedia.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [PostMedia] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<PostMediaTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<PostMedia>(
      where: where(PostMedia.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
