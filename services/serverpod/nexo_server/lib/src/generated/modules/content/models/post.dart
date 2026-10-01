/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member
// ignore_for_file: dead_code, unnecessary_null_comparison

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:nexo_server/src/generated/protocol.dart' as _i8p6m2v0;
import 'package:serverpod/serverpod.dart' as _is;
import '../../../modules/content/models/post_media.dart' as _i6xja3gd;
import '../../../modules/content/models/post_visibility.dart' as _i6lvj3eo;

/// Publicación del feed. Nunca se borra: eliminar pone `deletedAt` y
/// `deletedBy`, y la acción queda en la auditoría. El cliente recibe
/// [PostView], nunca esta fila.
abstract class Post implements _is.TableRow<int?>, _is.ProtocolSerialization {
  Post._({
    this.id,
    required this.authorId,
    required this.body,
    required this.tags,
    required this.visibility,
    bool? allowComments,
    int? likeCount,
    int? commentCount,
    this.media,
    DateTime? createdAt,
    this.editedAt,
    this.deletedAt,
    this.deletedBy,
  }) : allowComments = allowComments ?? true,
       likeCount = likeCount ?? 0,
       commentCount = commentCount ?? 0,
       createdAt = createdAt ?? DateTime.now();

  factory Post({
    int? id,
    required _is.UuidValue authorId,
    required String body,
    required List<String> tags,
    required _i6lvj3eo.PostVisibility visibility,
    bool? allowComments,
    int? likeCount,
    int? commentCount,
    List<_i6xja3gd.PostMedia>? media,
    DateTime? createdAt,
    DateTime? editedAt,
    DateTime? deletedAt,
    _is.UuidValue? deletedBy,
  }) = _PostImpl;

  factory Post.fromJson(Map<String, dynamic> jsonSerialization) {
    return Post(
      id: jsonSerialization['id'] as int?,
      authorId: _is.UuidValueJsonExtension.fromJson(
        jsonSerialization['authorId'],
      ),
      body: jsonSerialization['body'] as String,
      tags: _i8p6m2v0.Protocol().deserialize<List<String>>(
        jsonSerialization['tags'],
      ),
      visibility: _i6lvj3eo.PostVisibility.fromJson(
        (jsonSerialization['visibility'] as String),
      ),
      allowComments: jsonSerialization['allowComments'] == null
          ? null
          : _is.BoolJsonExtension.fromJson(jsonSerialization['allowComments']),
      likeCount: jsonSerialization['likeCount'] as int?,
      commentCount: jsonSerialization['commentCount'] as int?,
      media: jsonSerialization['media'] == null
          ? null
          : _i8p6m2v0.Protocol().deserialize<List<_i6xja3gd.PostMedia>>(
              jsonSerialization['media'],
            ),
      createdAt: jsonSerialization['createdAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['createdAt']),
      editedAt: jsonSerialization['editedAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['editedAt']),
      deletedAt: jsonSerialization['deletedAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['deletedAt']),
      deletedBy: jsonSerialization['deletedBy'] == null
          ? null
          : _is.UuidValueJsonExtension.fromJson(jsonSerialization['deletedBy']),
    );
  }

  static final t = PostTable();

  static const db = PostRepository._();

  @override
  int? id;

  _is.UuidValue authorId;

  String body;

  List<String> tags;

  _i6lvj3eo.PostVisibility visibility;

  bool allowComments;

  /// Contadores desnormalizados. Los mantiene el módulo `social` en la misma
  /// transacción que crea o borra el like o el comentario.
  int likeCount;

  int commentCount;

  List<_i6xja3gd.PostMedia>? media;

  DateTime createdAt;

  DateTime? editedAt;

  DateTime? deletedAt;

  _is.UuidValue? deletedBy;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [Post]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  Post copyWith({
    int? id,
    _is.UuidValue? authorId,
    String? body,
    List<String>? tags,
    _i6lvj3eo.PostVisibility? visibility,
    bool? allowComments,
    int? likeCount,
    int? commentCount,
    List<_i6xja3gd.PostMedia>? media,
    DateTime? createdAt,
    DateTime? editedAt,
    DateTime? deletedAt,
    _is.UuidValue? deletedBy,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'Post',
      if (id != null) 'id': id,
      'authorId': authorId.toJson(),
      'body': body,
      'tags': tags.toJson(),
      'visibility': visibility.toJson(),
      'allowComments': allowComments,
      'likeCount': likeCount,
      'commentCount': commentCount,
      if (media != null) 'media': media?.toJson(valueToJson: (v) => v.toJson()),
      'createdAt': createdAt.toJson(),
      if (editedAt != null) 'editedAt': editedAt?.toJson(),
      if (deletedAt != null) 'deletedAt': deletedAt?.toJson(),
      if (deletedBy != null) 'deletedBy': deletedBy?.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {};
  }

  static PostInclude include({_i6xja3gd.PostMediaIncludeList? media}) {
    return PostInclude._(media: media);
  }

  static PostIncludeList includeList({
    _is.WhereExpressionBuilder<PostTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<PostTable>? orderBy,
    _is.OrderByListBuilder<PostTable>? orderByList,
    PostInclude? include,
  }) {
    return PostIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(Post.t),
      orderByList: orderByList?.call(Post.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _PostImpl extends Post {
  _PostImpl({
    int? id,
    required _is.UuidValue authorId,
    required String body,
    required List<String> tags,
    required _i6lvj3eo.PostVisibility visibility,
    bool? allowComments,
    int? likeCount,
    int? commentCount,
    List<_i6xja3gd.PostMedia>? media,
    DateTime? createdAt,
    DateTime? editedAt,
    DateTime? deletedAt,
    _is.UuidValue? deletedBy,
  }) : super._(
         id: id,
         authorId: authorId,
         body: body,
         tags: tags,
         visibility: visibility,
         allowComments: allowComments,
         likeCount: likeCount,
         commentCount: commentCount,
         media: media,
         createdAt: createdAt,
         editedAt: editedAt,
         deletedAt: deletedAt,
         deletedBy: deletedBy,
       );

  /// Returns a shallow copy of this [Post]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  Post copyWith({
    Object? id = _Undefined,
    _is.UuidValue? authorId,
    String? body,
    List<String>? tags,
    _i6lvj3eo.PostVisibility? visibility,
    bool? allowComments,
    int? likeCount,
    int? commentCount,
    Object? media = _Undefined,
    DateTime? createdAt,
    Object? editedAt = _Undefined,
    Object? deletedAt = _Undefined,
    Object? deletedBy = _Undefined,
  }) {
    return Post(
      id: id is int? ? id : this.id,
      authorId: authorId ?? this.authorId,
      body: body ?? this.body,
      tags: tags ?? this.tags.map((e0) => e0).toList(),
      visibility: visibility ?? this.visibility,
      allowComments: allowComments ?? this.allowComments,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      media: media is List<_i6xja3gd.PostMedia>?
          ? media
          : this.media?.map((e0) => e0.copyWith()).toList(),
      createdAt: createdAt ?? this.createdAt,
      editedAt: editedAt is DateTime? ? editedAt : this.editedAt,
      deletedAt: deletedAt is DateTime? ? deletedAt : this.deletedAt,
      deletedBy: deletedBy is _is.UuidValue? ? deletedBy : this.deletedBy,
    );
  }
}

class PostUpdateTable extends _is.UpdateTable<PostTable> {
  PostUpdateTable(super.table);

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> authorId(_is.UuidValue value) =>
      _is.ColumnValue(
        table.authorId,
        value,
      );

  _is.ColumnValue<String, String> body(String value) => _is.ColumnValue(
    table.body,
    value,
  );

  _is.ColumnValue<List<String>, List<String>> tags(List<String> value) =>
      _is.ColumnValue(
        table.tags,
        value,
      );

  _is.ColumnValue<_i6lvj3eo.PostVisibility, _i6lvj3eo.PostVisibility>
  visibility(_i6lvj3eo.PostVisibility value) => _is.ColumnValue(
    table.visibility,
    value,
  );

  _is.ColumnValue<bool, bool> allowComments(bool value) => _is.ColumnValue(
    table.allowComments,
    value,
  );

  _is.ColumnValue<int, int> likeCount(int value) => _is.ColumnValue(
    table.likeCount,
    value,
  );

  _is.ColumnValue<int, int> commentCount(int value) => _is.ColumnValue(
    table.commentCount,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _is.ColumnValue(
        table.createdAt,
        value,
      );

  _is.ColumnValue<DateTime, DateTime> editedAt(DateTime? value) =>
      _is.ColumnValue(
        table.editedAt,
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

class PostTable extends _is.Table<int?> {
  PostTable({super.tableRelation}) : super(tableName: 'post') {
    updateTable = PostUpdateTable(this);
    authorId = _is.ColumnUuid(
      'authorId',
      this,
    );
    body = _is.ColumnString(
      'body',
      this,
    );
    tags = _is.ColumnSerializable<List<String>>(
      'tags',
      this,
    );
    visibility = _is.ColumnEnum(
      'visibility',
      this,
      _is.EnumSerialization.byName,
    );
    allowComments = _is.ColumnBool(
      'allowComments',
      this,
      hasDefault: true,
    );
    likeCount = _is.ColumnInt(
      'likeCount',
      this,
      hasDefault: true,
    );
    commentCount = _is.ColumnInt(
      'commentCount',
      this,
      hasDefault: true,
    );
    createdAt = _is.ColumnDateTime(
      'createdAt',
      this,
      hasDefault: true,
    );
    editedAt = _is.ColumnDateTime(
      'editedAt',
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

  late final PostUpdateTable updateTable;

  late final _is.ColumnUuid authorId;

  late final _is.ColumnString body;

  late final _is.ColumnSerializable<List<String>> tags;

  late final _is.ColumnEnum<_i6lvj3eo.PostVisibility> visibility;

  late final _is.ColumnBool allowComments;

  /// Contadores desnormalizados. Los mantiene el módulo `social` en la misma
  /// transacción que crea o borra el like o el comentario.
  late final _is.ColumnInt likeCount;

  late final _is.ColumnInt commentCount;

  _i6xja3gd.PostMediaTable? ___media;

  _is.ManyRelation<_i6xja3gd.PostMediaTable>? _media;

  late final _is.ColumnDateTime createdAt;

  late final _is.ColumnDateTime editedAt;

  late final _is.ColumnDateTime deletedAt;

  late final _is.ColumnUuid deletedBy;

  _i6xja3gd.PostMediaTable get __media {
    if (___media != null) return ___media!;
    ___media = _is.createRelationTable(
      relationFieldName: '__media',
      field: Post.t.id,
      foreignField: _i6xja3gd.PostMedia.t.postId,
      tableRelation: tableRelation,
      createTable: (foreignTableRelation) =>
          _i6xja3gd.PostMediaTable(tableRelation: foreignTableRelation),
    );
    return ___media!;
  }

  _is.ManyRelation<_i6xja3gd.PostMediaTable> get media {
    if (_media != null) return _media!;
    var relationTable = _is.createRelationTable(
      relationFieldName: 'media',
      field: Post.t.id,
      foreignField: _i6xja3gd.PostMedia.t.postId,
      tableRelation: tableRelation,
      createTable: (foreignTableRelation) =>
          _i6xja3gd.PostMediaTable(tableRelation: foreignTableRelation),
    );
    _media = _is.ManyRelation<_i6xja3gd.PostMediaTable>(
      tableWithRelations: relationTable,
      table: _i6xja3gd.PostMediaTable(
        tableRelation: relationTable.tableRelation!.lastRelation,
      ),
    );
    return _media!;
  }

  @override
  List<_is.Column> get columns => [
    id,
    authorId,
    body,
    tags,
    visibility,
    allowComments,
    likeCount,
    commentCount,
    createdAt,
    editedAt,
    deletedAt,
    deletedBy,
  ];

  @override
  _is.Table? getRelationTable(String relationField) {
    if (relationField == 'media') {
      return __media;
    }
    return null;
  }
}

class PostInclude extends _is.IncludeObject {
  PostInclude._({_i6xja3gd.PostMediaIncludeList? media}) {
    _media = media;
  }

  _i6xja3gd.PostMediaIncludeList? _media;

  @override
  Map<String, _is.Include?> get includes => {'media': _media};

  @override
  _is.Table<int?> get table => Post.t;
}

class PostIncludeList extends _is.IncludeList {
  PostIncludeList._({
    _is.WhereExpressionBuilder<PostTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(Post.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => Post.t;
}

class PostRepository {
  const PostRepository._();

  final attach = const PostAttachRepository._();

  final attachRow = const PostAttachRowRepository._();

  /// Returns a list of [Post]s matching the given query parameters.
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
  Future<List<Post>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<PostTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<PostTable>? orderBy,
    _is.OrderByListBuilder<PostTable>? orderByList,
    _is.Transaction? transaction,
    PostInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<Post>(
      where: where?.call(Post.t),
      orderBy: orderBy?.call(Post.t),
      orderByList: orderByList?.call(Post.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [Post] matching the given query parameters.
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
  Future<Post?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<PostTable>? where,
    int? offset,
    _is.OrderByBuilder<PostTable>? orderBy,
    _is.OrderByListBuilder<PostTable>? orderByList,
    _is.Transaction? transaction,
    PostInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<Post>(
      where: where?.call(Post.t),
      orderBy: orderBy?.call(Post.t),
      orderByList: orderByList?.call(Post.t),
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [Post] by its [id] or null if no such row exists.
  Future<Post?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    PostInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<Post>(
      id,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [Post]s in the list and returns the inserted rows.
  ///
  /// The returned [Post]s will have their `id` fields set.
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
  Future<List<Post>> insert(
    _is.DatabaseSession session,
    List<Post> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<Post>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [Post] and returns the inserted row.
  ///
  /// The returned [Post] will have its `id` field set.
  Future<Post> insertRow(
    _is.DatabaseSession session,
    Post row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<Post>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [Post]s in the list and returns the resulting rows.
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
  /// The returned [Post]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<Post>> upsert(
    _is.DatabaseSession session,
    List<Post> rows, {
    required _is.ColumnSelections<PostTable> conflictColumns,
    _is.ColumnSelections<PostTable>? updateColumns,
    _is.WhereExpressionBuilder<PostTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<Post>(
      rows,
      conflictColumns: conflictColumns(Post.t),
      updateColumns: updateColumns?.call(Post.t),
      updateWhere: updateWhere?.call(Post.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [Post] and returns the resulting row.
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
  /// The returned [Post] will have its `id` field set.
  Future<Post?> upsertRow(
    _is.DatabaseSession session,
    Post row, {
    required _is.ColumnSelections<PostTable> conflictColumns,
    _is.ColumnSelections<PostTable>? updateColumns,
    _is.WhereExpressionBuilder<PostTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<Post>(
      row,
      conflictColumns: conflictColumns(Post.t),
      updateColumns: updateColumns?.call(Post.t),
      updateWhere: updateWhere?.call(Post.t),
      transaction: transaction,
    );
  }

  /// Updates all [Post]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<Post>> update(
    _is.DatabaseSession session,
    List<Post> rows, {
    _is.ColumnSelections<PostTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<Post>(
      rows,
      columns: columns?.call(Post.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [Post]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<Post> updateRow(
    _is.DatabaseSession session,
    Post row, {
    _is.ColumnSelections<PostTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<Post>(
      row,
      columns: columns?.call(Post.t),
      transaction: transaction,
    );
  }

  /// Updates a single [Post] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<Post?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<PostUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<Post>(
      id,
      columnValues: columnValues(Post.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [Post]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<Post>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<PostUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<PostTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<PostTable>? orderBy,
    _is.OrderByListBuilder<PostTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<Post>(
      columnValues: columnValues(Post.t.updateTable),
      where: where(Post.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(Post.t),
      orderByList: orderByList?.call(Post.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [Post]s in the list and returns the deleted rows.
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
  Future<List<Post>> delete(
    _is.DatabaseSession session,
    List<Post> rows, {
    _is.OrderByBuilder<PostTable>? orderBy,
    _is.OrderByListBuilder<PostTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<Post>(
      rows,
      orderBy: orderBy?.call(Post.t),
      orderByList: orderByList?.call(Post.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [Post].
  Future<Post> deleteRow(
    _is.DatabaseSession session,
    Post row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<Post>(
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
  Future<List<Post>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<PostTable> where,
    _is.OrderByBuilder<PostTable>? orderBy,
    _is.OrderByListBuilder<PostTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<Post>(
      where: where(Post.t),
      orderBy: orderBy?.call(Post.t),
      orderByList: orderByList?.call(Post.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<PostTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<Post>(
      where: where?.call(Post.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [Post] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<PostTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<Post>(
      where: where(Post.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}

class PostAttachRepository {
  const PostAttachRepository._();

  /// Creates a relation between this [Post] and the given [PostMedia]s
  /// by setting each [PostMedia]'s foreign key `postId` to refer to this [Post].
  Future<void> media(
    _is.DatabaseSession session,
    Post post,
    List<_i6xja3gd.PostMedia> postMedia, {
    _is.Transaction? transaction,
  }) async {
    if (postMedia.any((e) => e.id == null)) {
      throw ArgumentError.notNull('postMedia.id');
    }
    if (post.id == null) {
      throw ArgumentError.notNull('post.id');
    }

    var $postMedia = postMedia.map((e) => e.copyWith(postId: post.id)).toList();
    await session.db.update<_i6xja3gd.PostMedia>(
      $postMedia,
      columns: [_i6xja3gd.PostMedia.t.postId],
      transaction: transaction,
    );
  }
}

class PostAttachRowRepository {
  const PostAttachRowRepository._();

  /// Creates a relation between this [Post] and the given [PostMedia]
  /// by setting the [PostMedia]'s foreign key `postId` to refer to this [Post].
  Future<void> media(
    _is.DatabaseSession session,
    Post post,
    _i6xja3gd.PostMedia postMedia, {
    _is.Transaction? transaction,
  }) async {
    if (postMedia.id == null) {
      throw ArgumentError.notNull('postMedia.id');
    }
    if (post.id == null) {
      throw ArgumentError.notNull('post.id');
    }

    var $postMedia = postMedia.copyWith(postId: post.id);
    await session.db.updateRow<_i6xja3gd.PostMedia>(
      $postMedia,
      columns: [_i6xja3gd.PostMedia.t.postId],
      transaction: transaction,
    );
  }
}
