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
import '../../../modules/live/models/live_show_access.dart' as _ihhtmjkk;
import '../../../modules/live/models/live_show_status.dart' as _iba8cpgl;

/// Un show: programado, al aire o terminado. El estado lo cambia sólo
/// `LiveService`, que valida la transición y la deja auditada.
abstract class LiveShow
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
  LiveShow._({
    this.id,
    required this.hostId,
    required this.title,
    String? description,
    required this.startsAt,
    int? durationMinutes,
    required this.access,
    bool? allowQuestions,
    bool? recordReplay,
    required this.status,
    this.startedAt,
    this.endedAt,
    this.endedBy,
    bool? endedByModeration,
    int? viewerPeak,
    this.pinnedMessageId,
    this.highlightedMessageId,
    DateTime? createdAt,
  }) : description = description ?? '',
       durationMinutes = durationMinutes ?? 60,
       allowQuestions = allowQuestions ?? true,
       recordReplay = recordReplay ?? true,
       endedByModeration = endedByModeration ?? false,
       viewerPeak = viewerPeak ?? 0,
       createdAt = createdAt ?? DateTime.now();

  factory LiveShow({
    int? id,
    required _is.UuidValue hostId,
    required String title,
    String? description,
    required DateTime startsAt,
    int? durationMinutes,
    required _ihhtmjkk.LiveShowAccess access,
    bool? allowQuestions,
    bool? recordReplay,
    required _iba8cpgl.LiveShowStatus status,
    DateTime? startedAt,
    DateTime? endedAt,
    _is.UuidValue? endedBy,
    bool? endedByModeration,
    int? viewerPeak,
    int? pinnedMessageId,
    int? highlightedMessageId,
    DateTime? createdAt,
  }) = _LiveShowImpl;

  factory LiveShow.fromJson(Map<String, dynamic> jsonSerialization) {
    return LiveShow(
      id: jsonSerialization['id'] as int?,
      hostId: _is.UuidValueJsonExtension.fromJson(jsonSerialization['hostId']),
      title: jsonSerialization['title'] as String,
      description: jsonSerialization['description'] as String?,
      startsAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['startsAt'],
      ),
      durationMinutes: jsonSerialization['durationMinutes'] as int?,
      access: _ihhtmjkk.LiveShowAccess.fromJson(
        (jsonSerialization['access'] as String),
      ),
      allowQuestions: jsonSerialization['allowQuestions'] == null
          ? null
          : _is.BoolJsonExtension.fromJson(jsonSerialization['allowQuestions']),
      recordReplay: jsonSerialization['recordReplay'] == null
          ? null
          : _is.BoolJsonExtension.fromJson(jsonSerialization['recordReplay']),
      status: _iba8cpgl.LiveShowStatus.fromJson(
        (jsonSerialization['status'] as String),
      ),
      startedAt: jsonSerialization['startedAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['startedAt']),
      endedAt: jsonSerialization['endedAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['endedAt']),
      endedBy: jsonSerialization['endedBy'] == null
          ? null
          : _is.UuidValueJsonExtension.fromJson(jsonSerialization['endedBy']),
      endedByModeration: jsonSerialization['endedByModeration'] == null
          ? null
          : _is.BoolJsonExtension.fromJson(
              jsonSerialization['endedByModeration'],
            ),
      viewerPeak: jsonSerialization['viewerPeak'] as int?,
      pinnedMessageId: jsonSerialization['pinnedMessageId'] as int?,
      highlightedMessageId: jsonSerialization['highlightedMessageId'] as int?,
      createdAt: jsonSerialization['createdAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['createdAt']),
    );
  }

  static final t = LiveShowTable();

  static const db = LiveShowRepository._();

  @override
  int? id;

  _is.UuidValue hostId;

  String title;

  String description;

  DateTime startsAt;

  int durationMinutes;

  _ihhtmjkk.LiveShowAccess access;

  bool allowQuestions;

  bool recordReplay;

  _iba8cpgl.LiveShowStatus status;

  DateTime? startedAt;

  DateTime? endedAt;

  _is.UuidValue? endedBy;

  /// Lo terminó alguien que no era el host (un operador).
  bool endedByModeration;

  int viewerPeak;

  /// El mensaje fijado arriba del chat. Uno solo.
  int? pinnedMessageId;

  /// La pregunta destacada para la conversación. Una sola.
  int? highlightedMessageId;

  DateTime createdAt;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [LiveShow]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  LiveShow copyWith({
    int? id,
    _is.UuidValue? hostId,
    String? title,
    String? description,
    DateTime? startsAt,
    int? durationMinutes,
    _ihhtmjkk.LiveShowAccess? access,
    bool? allowQuestions,
    bool? recordReplay,
    _iba8cpgl.LiveShowStatus? status,
    DateTime? startedAt,
    DateTime? endedAt,
    _is.UuidValue? endedBy,
    bool? endedByModeration,
    int? viewerPeak,
    int? pinnedMessageId,
    int? highlightedMessageId,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'LiveShow',
      if (id != null) 'id': id,
      'hostId': hostId.toJson(),
      'title': title,
      'description': description,
      'startsAt': startsAt.toJson(),
      'durationMinutes': durationMinutes,
      'access': access.toJson(),
      'allowQuestions': allowQuestions,
      'recordReplay': recordReplay,
      'status': status.toJson(),
      if (startedAt != null) 'startedAt': startedAt?.toJson(),
      if (endedAt != null) 'endedAt': endedAt?.toJson(),
      if (endedBy != null) 'endedBy': endedBy?.toJson(),
      'endedByModeration': endedByModeration,
      'viewerPeak': viewerPeak,
      if (pinnedMessageId != null) 'pinnedMessageId': pinnedMessageId,
      if (highlightedMessageId != null)
        'highlightedMessageId': highlightedMessageId,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {};
  }

  static LiveShowInclude include() {
    return LiveShowInclude._();
  }

  static LiveShowIncludeList includeList({
    _is.WhereExpressionBuilder<LiveShowTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<LiveShowTable>? orderBy,
    _is.OrderByListBuilder<LiveShowTable>? orderByList,
    LiveShowInclude? include,
  }) {
    return LiveShowIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(LiveShow.t),
      orderByList: orderByList?.call(LiveShow.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _LiveShowImpl extends LiveShow {
  _LiveShowImpl({
    int? id,
    required _is.UuidValue hostId,
    required String title,
    String? description,
    required DateTime startsAt,
    int? durationMinutes,
    required _ihhtmjkk.LiveShowAccess access,
    bool? allowQuestions,
    bool? recordReplay,
    required _iba8cpgl.LiveShowStatus status,
    DateTime? startedAt,
    DateTime? endedAt,
    _is.UuidValue? endedBy,
    bool? endedByModeration,
    int? viewerPeak,
    int? pinnedMessageId,
    int? highlightedMessageId,
    DateTime? createdAt,
  }) : super._(
         id: id,
         hostId: hostId,
         title: title,
         description: description,
         startsAt: startsAt,
         durationMinutes: durationMinutes,
         access: access,
         allowQuestions: allowQuestions,
         recordReplay: recordReplay,
         status: status,
         startedAt: startedAt,
         endedAt: endedAt,
         endedBy: endedBy,
         endedByModeration: endedByModeration,
         viewerPeak: viewerPeak,
         pinnedMessageId: pinnedMessageId,
         highlightedMessageId: highlightedMessageId,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [LiveShow]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  LiveShow copyWith({
    Object? id = _Undefined,
    _is.UuidValue? hostId,
    String? title,
    String? description,
    DateTime? startsAt,
    int? durationMinutes,
    _ihhtmjkk.LiveShowAccess? access,
    bool? allowQuestions,
    bool? recordReplay,
    _iba8cpgl.LiveShowStatus? status,
    Object? startedAt = _Undefined,
    Object? endedAt = _Undefined,
    Object? endedBy = _Undefined,
    bool? endedByModeration,
    int? viewerPeak,
    Object? pinnedMessageId = _Undefined,
    Object? highlightedMessageId = _Undefined,
    DateTime? createdAt,
  }) {
    return LiveShow(
      id: id is int? ? id : this.id,
      hostId: hostId ?? this.hostId,
      title: title ?? this.title,
      description: description ?? this.description,
      startsAt: startsAt ?? this.startsAt,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      access: access ?? this.access,
      allowQuestions: allowQuestions ?? this.allowQuestions,
      recordReplay: recordReplay ?? this.recordReplay,
      status: status ?? this.status,
      startedAt: startedAt is DateTime? ? startedAt : this.startedAt,
      endedAt: endedAt is DateTime? ? endedAt : this.endedAt,
      endedBy: endedBy is _is.UuidValue? ? endedBy : this.endedBy,
      endedByModeration: endedByModeration ?? this.endedByModeration,
      viewerPeak: viewerPeak ?? this.viewerPeak,
      pinnedMessageId: pinnedMessageId is int?
          ? pinnedMessageId
          : this.pinnedMessageId,
      highlightedMessageId: highlightedMessageId is int?
          ? highlightedMessageId
          : this.highlightedMessageId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class LiveShowUpdateTable extends _is.UpdateTable<LiveShowTable> {
  LiveShowUpdateTable(super.table);

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> hostId(_is.UuidValue value) =>
      _is.ColumnValue(
        table.hostId,
        value,
      );

  _is.ColumnValue<String, String> title(String value) => _is.ColumnValue(
    table.title,
    value,
  );

  _is.ColumnValue<String, String> description(String value) => _is.ColumnValue(
    table.description,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> startsAt(DateTime value) =>
      _is.ColumnValue(
        table.startsAt,
        value,
      );

  _is.ColumnValue<int, int> durationMinutes(int value) => _is.ColumnValue(
    table.durationMinutes,
    value,
  );

  _is.ColumnValue<_ihhtmjkk.LiveShowAccess, _ihhtmjkk.LiveShowAccess> access(
    _ihhtmjkk.LiveShowAccess value,
  ) => _is.ColumnValue(
    table.access,
    value,
  );

  _is.ColumnValue<bool, bool> allowQuestions(bool value) => _is.ColumnValue(
    table.allowQuestions,
    value,
  );

  _is.ColumnValue<bool, bool> recordReplay(bool value) => _is.ColumnValue(
    table.recordReplay,
    value,
  );

  _is.ColumnValue<_iba8cpgl.LiveShowStatus, _iba8cpgl.LiveShowStatus> status(
    _iba8cpgl.LiveShowStatus value,
  ) => _is.ColumnValue(
    table.status,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> startedAt(DateTime? value) =>
      _is.ColumnValue(
        table.startedAt,
        value,
      );

  _is.ColumnValue<DateTime, DateTime> endedAt(DateTime? value) =>
      _is.ColumnValue(
        table.endedAt,
        value,
      );

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> endedBy(_is.UuidValue? value) =>
      _is.ColumnValue(
        table.endedBy,
        value,
      );

  _is.ColumnValue<bool, bool> endedByModeration(bool value) => _is.ColumnValue(
    table.endedByModeration,
    value,
  );

  _is.ColumnValue<int, int> viewerPeak(int value) => _is.ColumnValue(
    table.viewerPeak,
    value,
  );

  _is.ColumnValue<int, int> pinnedMessageId(int? value) => _is.ColumnValue(
    table.pinnedMessageId,
    value,
  );

  _is.ColumnValue<int, int> highlightedMessageId(int? value) => _is.ColumnValue(
    table.highlightedMessageId,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _is.ColumnValue(
        table.createdAt,
        value,
      );
}

class LiveShowTable extends _is.Table<int?> {
  LiveShowTable({super.tableRelation}) : super(tableName: 'live_show') {
    updateTable = LiveShowUpdateTable(this);
    hostId = _is.ColumnUuid(
      'hostId',
      this,
    );
    title = _is.ColumnString(
      'title',
      this,
    );
    description = _is.ColumnString(
      'description',
      this,
      hasDefault: true,
    );
    startsAt = _is.ColumnDateTime(
      'startsAt',
      this,
    );
    durationMinutes = _is.ColumnInt(
      'durationMinutes',
      this,
      hasDefault: true,
    );
    access = _is.ColumnEnum(
      'access',
      this,
      _is.EnumSerialization.byName,
    );
    allowQuestions = _is.ColumnBool(
      'allowQuestions',
      this,
      hasDefault: true,
    );
    recordReplay = _is.ColumnBool(
      'recordReplay',
      this,
      hasDefault: true,
    );
    status = _is.ColumnEnum(
      'status',
      this,
      _is.EnumSerialization.byName,
    );
    startedAt = _is.ColumnDateTime(
      'startedAt',
      this,
    );
    endedAt = _is.ColumnDateTime(
      'endedAt',
      this,
    );
    endedBy = _is.ColumnUuid(
      'endedBy',
      this,
    );
    endedByModeration = _is.ColumnBool(
      'endedByModeration',
      this,
      hasDefault: true,
    );
    viewerPeak = _is.ColumnInt(
      'viewerPeak',
      this,
      hasDefault: true,
    );
    pinnedMessageId = _is.ColumnInt(
      'pinnedMessageId',
      this,
    );
    highlightedMessageId = _is.ColumnInt(
      'highlightedMessageId',
      this,
    );
    createdAt = _is.ColumnDateTime(
      'createdAt',
      this,
      hasDefault: true,
    );
  }

  late final LiveShowUpdateTable updateTable;

  late final _is.ColumnUuid hostId;

  late final _is.ColumnString title;

  late final _is.ColumnString description;

  late final _is.ColumnDateTime startsAt;

  late final _is.ColumnInt durationMinutes;

  late final _is.ColumnEnum<_ihhtmjkk.LiveShowAccess> access;

  late final _is.ColumnBool allowQuestions;

  late final _is.ColumnBool recordReplay;

  late final _is.ColumnEnum<_iba8cpgl.LiveShowStatus> status;

  late final _is.ColumnDateTime startedAt;

  late final _is.ColumnDateTime endedAt;

  late final _is.ColumnUuid endedBy;

  /// Lo terminó alguien que no era el host (un operador).
  late final _is.ColumnBool endedByModeration;

  late final _is.ColumnInt viewerPeak;

  /// El mensaje fijado arriba del chat. Uno solo.
  late final _is.ColumnInt pinnedMessageId;

  /// La pregunta destacada para la conversación. Una sola.
  late final _is.ColumnInt highlightedMessageId;

  late final _is.ColumnDateTime createdAt;

  @override
  List<_is.Column> get columns => [
    id,
    hostId,
    title,
    description,
    startsAt,
    durationMinutes,
    access,
    allowQuestions,
    recordReplay,
    status,
    startedAt,
    endedAt,
    endedBy,
    endedByModeration,
    viewerPeak,
    pinnedMessageId,
    highlightedMessageId,
    createdAt,
  ];
}

class LiveShowInclude extends _is.IncludeObject {
  LiveShowInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => LiveShow.t;
}

class LiveShowIncludeList extends _is.IncludeList {
  LiveShowIncludeList._({
    _is.WhereExpressionBuilder<LiveShowTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(LiveShow.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => LiveShow.t;
}

class LiveShowRepository {
  const LiveShowRepository._();

  /// Returns a list of [LiveShow]s matching the given query parameters.
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
  Future<List<LiveShow>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<LiveShowTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<LiveShowTable>? orderBy,
    _is.OrderByListBuilder<LiveShowTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<LiveShow>(
      where: where?.call(LiveShow.t),
      orderBy: orderBy?.call(LiveShow.t),
      orderByList: orderByList?.call(LiveShow.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [LiveShow] matching the given query parameters.
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
  Future<LiveShow?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<LiveShowTable>? where,
    int? offset,
    _is.OrderByBuilder<LiveShowTable>? orderBy,
    _is.OrderByListBuilder<LiveShowTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<LiveShow>(
      where: where?.call(LiveShow.t),
      orderBy: orderBy?.call(LiveShow.t),
      orderByList: orderByList?.call(LiveShow.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [LiveShow] by its [id] or null if no such row exists.
  Future<LiveShow?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<LiveShow>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [LiveShow]s in the list and returns the inserted rows.
  ///
  /// The returned [LiveShow]s will have their `id` fields set.
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
  Future<List<LiveShow>> insert(
    _is.DatabaseSession session,
    List<LiveShow> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<LiveShow>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [LiveShow] and returns the inserted row.
  ///
  /// The returned [LiveShow] will have its `id` field set.
  Future<LiveShow> insertRow(
    _is.DatabaseSession session,
    LiveShow row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<LiveShow>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [LiveShow]s in the list and returns the resulting rows.
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
  /// The returned [LiveShow]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<LiveShow>> upsert(
    _is.DatabaseSession session,
    List<LiveShow> rows, {
    required _is.ColumnSelections<LiveShowTable> conflictColumns,
    _is.ColumnSelections<LiveShowTable>? updateColumns,
    _is.WhereExpressionBuilder<LiveShowTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<LiveShow>(
      rows,
      conflictColumns: conflictColumns(LiveShow.t),
      updateColumns: updateColumns?.call(LiveShow.t),
      updateWhere: updateWhere?.call(LiveShow.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [LiveShow] and returns the resulting row.
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
  /// The returned [LiveShow] will have its `id` field set.
  Future<LiveShow?> upsertRow(
    _is.DatabaseSession session,
    LiveShow row, {
    required _is.ColumnSelections<LiveShowTable> conflictColumns,
    _is.ColumnSelections<LiveShowTable>? updateColumns,
    _is.WhereExpressionBuilder<LiveShowTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<LiveShow>(
      row,
      conflictColumns: conflictColumns(LiveShow.t),
      updateColumns: updateColumns?.call(LiveShow.t),
      updateWhere: updateWhere?.call(LiveShow.t),
      transaction: transaction,
    );
  }

  /// Updates all [LiveShow]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<LiveShow>> update(
    _is.DatabaseSession session,
    List<LiveShow> rows, {
    _is.ColumnSelections<LiveShowTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<LiveShow>(
      rows,
      columns: columns?.call(LiveShow.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [LiveShow]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<LiveShow> updateRow(
    _is.DatabaseSession session,
    LiveShow row, {
    _is.ColumnSelections<LiveShowTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<LiveShow>(
      row,
      columns: columns?.call(LiveShow.t),
      transaction: transaction,
    );
  }

  /// Updates a single [LiveShow] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<LiveShow?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<LiveShowUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<LiveShow>(
      id,
      columnValues: columnValues(LiveShow.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [LiveShow]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<LiveShow>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<LiveShowUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<LiveShowTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<LiveShowTable>? orderBy,
    _is.OrderByListBuilder<LiveShowTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<LiveShow>(
      columnValues: columnValues(LiveShow.t.updateTable),
      where: where(LiveShow.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(LiveShow.t),
      orderByList: orderByList?.call(LiveShow.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [LiveShow]s in the list and returns the deleted rows.
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
  Future<List<LiveShow>> delete(
    _is.DatabaseSession session,
    List<LiveShow> rows, {
    _is.OrderByBuilder<LiveShowTable>? orderBy,
    _is.OrderByListBuilder<LiveShowTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<LiveShow>(
      rows,
      orderBy: orderBy?.call(LiveShow.t),
      orderByList: orderByList?.call(LiveShow.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [LiveShow].
  Future<LiveShow> deleteRow(
    _is.DatabaseSession session,
    LiveShow row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<LiveShow>(
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
  Future<List<LiveShow>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<LiveShowTable> where,
    _is.OrderByBuilder<LiveShowTable>? orderBy,
    _is.OrderByListBuilder<LiveShowTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<LiveShow>(
      where: where(LiveShow.t),
      orderBy: orderBy?.call(LiveShow.t),
      orderByList: orderByList?.call(LiveShow.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<LiveShowTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<LiveShow>(
      where: where?.call(LiveShow.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [LiveShow] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<LiveShowTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<LiveShow>(
      where: where(LiveShow.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
