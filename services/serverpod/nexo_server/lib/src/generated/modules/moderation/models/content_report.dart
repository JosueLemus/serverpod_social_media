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
import '../../../modules/moderation/models/moderation_reason.dart' as _i9getqdy;
import '../../../modules/moderation/models/report_decision.dart' as _iqb04qeg;
import '../../../modules/moderation/models/report_severity.dart' as _icd6twrz;
import '../../../modules/moderation/models/report_target_type.dart'
    as _ia1tgea5;

/// Un reporte de un usuario sobre un contenido. Resolver cierra todos los
/// reportes abiertos del mismo contenido a la vez: que diez personas
/// reporten el mismo post no son diez revisiones.
abstract class ContentReport
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
  ContentReport._({
    this.id,
    required this.targetType,
    required this.targetId,
    required this.targetAuthorId,
    required this.reporterId,
    required this.reason,
    required this.severity,
    this.details,
    DateTime? createdAt,
    this.resolvedAt,
    this.resolvedBy,
    this.decision,
  }) : createdAt = createdAt ?? DateTime.now();

  factory ContentReport({
    int? id,
    required _ia1tgea5.ReportTargetType targetType,
    required int targetId,
    required _is.UuidValue targetAuthorId,
    required _is.UuidValue reporterId,
    required _i9getqdy.ModerationReason reason,
    required _icd6twrz.ReportSeverity severity,
    String? details,
    DateTime? createdAt,
    DateTime? resolvedAt,
    _is.UuidValue? resolvedBy,
    _iqb04qeg.ReportDecision? decision,
  }) = _ContentReportImpl;

  factory ContentReport.fromJson(Map<String, dynamic> jsonSerialization) {
    return ContentReport(
      id: jsonSerialization['id'] as int?,
      targetType: _ia1tgea5.ReportTargetType.fromJson(
        (jsonSerialization['targetType'] as String),
      ),
      targetId: jsonSerialization['targetId'] as int,
      targetAuthorId: _is.UuidValueJsonExtension.fromJson(
        jsonSerialization['targetAuthorId'],
      ),
      reporterId: _is.UuidValueJsonExtension.fromJson(
        jsonSerialization['reporterId'],
      ),
      reason: _i9getqdy.ModerationReason.fromJson(
        (jsonSerialization['reason'] as String),
      ),
      severity: _icd6twrz.ReportSeverity.fromJson(
        (jsonSerialization['severity'] as int),
      ),
      details: jsonSerialization['details'] as String?,
      createdAt: jsonSerialization['createdAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['createdAt']),
      resolvedAt: jsonSerialization['resolvedAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['resolvedAt']),
      resolvedBy: jsonSerialization['resolvedBy'] == null
          ? null
          : _is.UuidValueJsonExtension.fromJson(
              jsonSerialization['resolvedBy'],
            ),
      decision: jsonSerialization['decision'] == null
          ? null
          : _iqb04qeg.ReportDecision.fromJson(
              (jsonSerialization['decision'] as String),
            ),
    );
  }

  static final t = ContentReportTable();

  static const db = ContentReportRepository._();

  @override
  int? id;

  _ia1tgea5.ReportTargetType targetType;

  int targetId;

  /// Autor del contenido al reportarlo, para la cola y para sanciones futuras.
  _is.UuidValue targetAuthorId;

  _is.UuidValue reporterId;

  _i9getqdy.ModerationReason reason;

  _icd6twrz.ReportSeverity severity;

  String? details;

  DateTime createdAt;

  DateTime? resolvedAt;

  _is.UuidValue? resolvedBy;

  _iqb04qeg.ReportDecision? decision;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [ContentReport]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  ContentReport copyWith({
    int? id,
    _ia1tgea5.ReportTargetType? targetType,
    int? targetId,
    _is.UuidValue? targetAuthorId,
    _is.UuidValue? reporterId,
    _i9getqdy.ModerationReason? reason,
    _icd6twrz.ReportSeverity? severity,
    String? details,
    DateTime? createdAt,
    DateTime? resolvedAt,
    _is.UuidValue? resolvedBy,
    _iqb04qeg.ReportDecision? decision,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ContentReport',
      if (id != null) 'id': id,
      'targetType': targetType.toJson(),
      'targetId': targetId,
      'targetAuthorId': targetAuthorId.toJson(),
      'reporterId': reporterId.toJson(),
      'reason': reason.toJson(),
      'severity': severity.toJson(),
      if (details != null) 'details': details,
      'createdAt': createdAt.toJson(),
      if (resolvedAt != null) 'resolvedAt': resolvedAt?.toJson(),
      if (resolvedBy != null) 'resolvedBy': resolvedBy?.toJson(),
      if (decision != null) 'decision': decision?.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {};
  }

  static ContentReportInclude include() {
    return ContentReportInclude._();
  }

  static ContentReportIncludeList includeList({
    _is.WhereExpressionBuilder<ContentReportTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ContentReportTable>? orderBy,
    _is.OrderByListBuilder<ContentReportTable>? orderByList,
    ContentReportInclude? include,
  }) {
    return ContentReportIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(ContentReport.t),
      orderByList: orderByList?.call(ContentReport.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ContentReportImpl extends ContentReport {
  _ContentReportImpl({
    int? id,
    required _ia1tgea5.ReportTargetType targetType,
    required int targetId,
    required _is.UuidValue targetAuthorId,
    required _is.UuidValue reporterId,
    required _i9getqdy.ModerationReason reason,
    required _icd6twrz.ReportSeverity severity,
    String? details,
    DateTime? createdAt,
    DateTime? resolvedAt,
    _is.UuidValue? resolvedBy,
    _iqb04qeg.ReportDecision? decision,
  }) : super._(
         id: id,
         targetType: targetType,
         targetId: targetId,
         targetAuthorId: targetAuthorId,
         reporterId: reporterId,
         reason: reason,
         severity: severity,
         details: details,
         createdAt: createdAt,
         resolvedAt: resolvedAt,
         resolvedBy: resolvedBy,
         decision: decision,
       );

  /// Returns a shallow copy of this [ContentReport]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  ContentReport copyWith({
    Object? id = _Undefined,
    _ia1tgea5.ReportTargetType? targetType,
    int? targetId,
    _is.UuidValue? targetAuthorId,
    _is.UuidValue? reporterId,
    _i9getqdy.ModerationReason? reason,
    _icd6twrz.ReportSeverity? severity,
    Object? details = _Undefined,
    DateTime? createdAt,
    Object? resolvedAt = _Undefined,
    Object? resolvedBy = _Undefined,
    Object? decision = _Undefined,
  }) {
    return ContentReport(
      id: id is int? ? id : this.id,
      targetType: targetType ?? this.targetType,
      targetId: targetId ?? this.targetId,
      targetAuthorId: targetAuthorId ?? this.targetAuthorId,
      reporterId: reporterId ?? this.reporterId,
      reason: reason ?? this.reason,
      severity: severity ?? this.severity,
      details: details is String? ? details : this.details,
      createdAt: createdAt ?? this.createdAt,
      resolvedAt: resolvedAt is DateTime? ? resolvedAt : this.resolvedAt,
      resolvedBy: resolvedBy is _is.UuidValue? ? resolvedBy : this.resolvedBy,
      decision: decision is _iqb04qeg.ReportDecision?
          ? decision
          : this.decision,
    );
  }
}

class ContentReportUpdateTable extends _is.UpdateTable<ContentReportTable> {
  ContentReportUpdateTable(super.table);

  _is.ColumnValue<_ia1tgea5.ReportTargetType, _ia1tgea5.ReportTargetType>
  targetType(_ia1tgea5.ReportTargetType value) => _is.ColumnValue(
    table.targetType,
    value,
  );

  _is.ColumnValue<int, int> targetId(int value) => _is.ColumnValue(
    table.targetId,
    value,
  );

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> targetAuthorId(
    _is.UuidValue value,
  ) => _is.ColumnValue(
    table.targetAuthorId,
    value,
  );

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> reporterId(
    _is.UuidValue value,
  ) => _is.ColumnValue(
    table.reporterId,
    value,
  );

  _is.ColumnValue<_i9getqdy.ModerationReason, _i9getqdy.ModerationReason>
  reason(_i9getqdy.ModerationReason value) => _is.ColumnValue(
    table.reason,
    value,
  );

  _is.ColumnValue<_icd6twrz.ReportSeverity, _icd6twrz.ReportSeverity> severity(
    _icd6twrz.ReportSeverity value,
  ) => _is.ColumnValue(
    table.severity,
    value,
  );

  _is.ColumnValue<String, String> details(String? value) => _is.ColumnValue(
    table.details,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _is.ColumnValue(
        table.createdAt,
        value,
      );

  _is.ColumnValue<DateTime, DateTime> resolvedAt(DateTime? value) =>
      _is.ColumnValue(
        table.resolvedAt,
        value,
      );

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> resolvedBy(
    _is.UuidValue? value,
  ) => _is.ColumnValue(
    table.resolvedBy,
    value,
  );

  _is.ColumnValue<_iqb04qeg.ReportDecision, _iqb04qeg.ReportDecision> decision(
    _iqb04qeg.ReportDecision? value,
  ) => _is.ColumnValue(
    table.decision,
    value,
  );
}

class ContentReportTable extends _is.Table<int?> {
  ContentReportTable({super.tableRelation})
    : super(tableName: 'content_report') {
    updateTable = ContentReportUpdateTable(this);
    targetType = _is.ColumnEnum(
      'targetType',
      this,
      _is.EnumSerialization.byName,
    );
    targetId = _is.ColumnInt(
      'targetId',
      this,
    );
    targetAuthorId = _is.ColumnUuid(
      'targetAuthorId',
      this,
    );
    reporterId = _is.ColumnUuid(
      'reporterId',
      this,
    );
    reason = _is.ColumnEnum(
      'reason',
      this,
      _is.EnumSerialization.byName,
    );
    severity = _is.ColumnEnum(
      'severity',
      this,
      _is.EnumSerialization.byIndex,
    );
    details = _is.ColumnString(
      'details',
      this,
    );
    createdAt = _is.ColumnDateTime(
      'createdAt',
      this,
      hasDefault: true,
    );
    resolvedAt = _is.ColumnDateTime(
      'resolvedAt',
      this,
    );
    resolvedBy = _is.ColumnUuid(
      'resolvedBy',
      this,
    );
    decision = _is.ColumnEnum(
      'decision',
      this,
      _is.EnumSerialization.byName,
    );
  }

  late final ContentReportUpdateTable updateTable;

  late final _is.ColumnEnum<_ia1tgea5.ReportTargetType> targetType;

  late final _is.ColumnInt targetId;

  /// Autor del contenido al reportarlo, para la cola y para sanciones futuras.
  late final _is.ColumnUuid targetAuthorId;

  late final _is.ColumnUuid reporterId;

  late final _is.ColumnEnum<_i9getqdy.ModerationReason> reason;

  late final _is.ColumnEnum<_icd6twrz.ReportSeverity> severity;

  late final _is.ColumnString details;

  late final _is.ColumnDateTime createdAt;

  late final _is.ColumnDateTime resolvedAt;

  late final _is.ColumnUuid resolvedBy;

  late final _is.ColumnEnum<_iqb04qeg.ReportDecision> decision;

  @override
  List<_is.Column> get columns => [
    id,
    targetType,
    targetId,
    targetAuthorId,
    reporterId,
    reason,
    severity,
    details,
    createdAt,
    resolvedAt,
    resolvedBy,
    decision,
  ];
}

class ContentReportInclude extends _is.IncludeObject {
  ContentReportInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => ContentReport.t;
}

class ContentReportIncludeList extends _is.IncludeList {
  ContentReportIncludeList._({
    _is.WhereExpressionBuilder<ContentReportTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(ContentReport.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => ContentReport.t;
}

class ContentReportRepository {
  const ContentReportRepository._();

  /// Returns a list of [ContentReport]s matching the given query parameters.
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
  Future<List<ContentReport>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ContentReportTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ContentReportTable>? orderBy,
    _is.OrderByListBuilder<ContentReportTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<ContentReport>(
      where: where?.call(ContentReport.t),
      orderBy: orderBy?.call(ContentReport.t),
      orderByList: orderByList?.call(ContentReport.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [ContentReport] matching the given query parameters.
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
  Future<ContentReport?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ContentReportTable>? where,
    int? offset,
    _is.OrderByBuilder<ContentReportTable>? orderBy,
    _is.OrderByListBuilder<ContentReportTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<ContentReport>(
      where: where?.call(ContentReport.t),
      orderBy: orderBy?.call(ContentReport.t),
      orderByList: orderByList?.call(ContentReport.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [ContentReport] by its [id] or null if no such row exists.
  Future<ContentReport?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<ContentReport>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [ContentReport]s in the list and returns the inserted rows.
  ///
  /// The returned [ContentReport]s will have their `id` fields set.
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
  Future<List<ContentReport>> insert(
    _is.DatabaseSession session,
    List<ContentReport> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<ContentReport>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [ContentReport] and returns the inserted row.
  ///
  /// The returned [ContentReport] will have its `id` field set.
  Future<ContentReport> insertRow(
    _is.DatabaseSession session,
    ContentReport row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<ContentReport>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [ContentReport]s in the list and returns the resulting rows.
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
  /// The returned [ContentReport]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ContentReport>> upsert(
    _is.DatabaseSession session,
    List<ContentReport> rows, {
    required _is.ColumnSelections<ContentReportTable> conflictColumns,
    _is.ColumnSelections<ContentReportTable>? updateColumns,
    _is.WhereExpressionBuilder<ContentReportTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<ContentReport>(
      rows,
      conflictColumns: conflictColumns(ContentReport.t),
      updateColumns: updateColumns?.call(ContentReport.t),
      updateWhere: updateWhere?.call(ContentReport.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [ContentReport] and returns the resulting row.
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
  /// The returned [ContentReport] will have its `id` field set.
  Future<ContentReport?> upsertRow(
    _is.DatabaseSession session,
    ContentReport row, {
    required _is.ColumnSelections<ContentReportTable> conflictColumns,
    _is.ColumnSelections<ContentReportTable>? updateColumns,
    _is.WhereExpressionBuilder<ContentReportTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<ContentReport>(
      row,
      conflictColumns: conflictColumns(ContentReport.t),
      updateColumns: updateColumns?.call(ContentReport.t),
      updateWhere: updateWhere?.call(ContentReport.t),
      transaction: transaction,
    );
  }

  /// Updates all [ContentReport]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ContentReport>> update(
    _is.DatabaseSession session,
    List<ContentReport> rows, {
    _is.ColumnSelections<ContentReportTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<ContentReport>(
      rows,
      columns: columns?.call(ContentReport.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [ContentReport]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<ContentReport> updateRow(
    _is.DatabaseSession session,
    ContentReport row, {
    _is.ColumnSelections<ContentReportTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<ContentReport>(
      row,
      columns: columns?.call(ContentReport.t),
      transaction: transaction,
    );
  }

  /// Updates a single [ContentReport] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<ContentReport?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<ContentReportUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<ContentReport>(
      id,
      columnValues: columnValues(ContentReport.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [ContentReport]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ContentReport>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<ContentReportUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<ContentReportTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ContentReportTable>? orderBy,
    _is.OrderByListBuilder<ContentReportTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<ContentReport>(
      columnValues: columnValues(ContentReport.t.updateTable),
      where: where(ContentReport.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(ContentReport.t),
      orderByList: orderByList?.call(ContentReport.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [ContentReport]s in the list and returns the deleted rows.
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
  Future<List<ContentReport>> delete(
    _is.DatabaseSession session,
    List<ContentReport> rows, {
    _is.OrderByBuilder<ContentReportTable>? orderBy,
    _is.OrderByListBuilder<ContentReportTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<ContentReport>(
      rows,
      orderBy: orderBy?.call(ContentReport.t),
      orderByList: orderByList?.call(ContentReport.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [ContentReport].
  Future<ContentReport> deleteRow(
    _is.DatabaseSession session,
    ContentReport row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<ContentReport>(
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
  Future<List<ContentReport>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<ContentReportTable> where,
    _is.OrderByBuilder<ContentReportTable>? orderBy,
    _is.OrderByListBuilder<ContentReportTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<ContentReport>(
      where: where(ContentReport.t),
      orderBy: orderBy?.call(ContentReport.t),
      orderByList: orderByList?.call(ContentReport.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ContentReportTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<ContentReport>(
      where: where?.call(ContentReport.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [ContentReport] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<ContentReportTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<ContentReport>(
      where: where(ContentReport.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
