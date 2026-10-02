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
import '../../../modules/identity/models/account_status.dart' as _ijvat8p8;
import '../../../modules/identity/models/verification_status.dart' as _il3i3d2n;

/// Lo que Nexo sabe de una cuenta y Serverpod no: el nombre de usuario
/// único, si crea contenido, su verificación y si puede operar.
///
/// El `UserProfile` de Serverpod se queda con el nombre visible, el correo y
/// la imagen. `username` vive acá porque necesita un índice único que la
/// tabla de Serverpod no tiene, y se copia a `UserProfile.userName` para que
/// los módulos que ya muestran autores lo sigan leyendo de ahí.
abstract class AccountProfile
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
  AccountProfile._({
    this.id,
    required this.authUserId,
    required this.username,
    this.bio,
    bool? isCreator,
    _il3i3d2n.VerificationStatus? verification,
    _ijvat8p8.AccountStatus? status,
    DateTime? createdAt,
    this.updatedAt,
  }) : isCreator = isCreator ?? false,
       verification = verification ?? _il3i3d2n.VerificationStatus.none,
       status = status ?? _ijvat8p8.AccountStatus.active,
       createdAt = createdAt ?? DateTime.now();

  factory AccountProfile({
    int? id,
    required _is.UuidValue authUserId,
    required String username,
    String? bio,
    bool? isCreator,
    _il3i3d2n.VerificationStatus? verification,
    _ijvat8p8.AccountStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _AccountProfileImpl;

  factory AccountProfile.fromJson(Map<String, dynamic> jsonSerialization) {
    return AccountProfile(
      id: jsonSerialization['id'] as int?,
      authUserId: _is.UuidValueJsonExtension.fromJson(
        jsonSerialization['authUserId'],
      ),
      username: jsonSerialization['username'] as String,
      bio: jsonSerialization['bio'] as String?,
      isCreator: jsonSerialization['isCreator'] == null
          ? null
          : _is.BoolJsonExtension.fromJson(jsonSerialization['isCreator']),
      verification: jsonSerialization['verification'] == null
          ? null
          : _il3i3d2n.VerificationStatus.fromJson(
              (jsonSerialization['verification'] as String),
            ),
      status: jsonSerialization['status'] == null
          ? null
          : _ijvat8p8.AccountStatus.fromJson(
              (jsonSerialization['status'] as String),
            ),
      createdAt: jsonSerialization['createdAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['createdAt']),
      updatedAt: jsonSerialization['updatedAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['updatedAt']),
    );
  }

  static final t = AccountProfileTable();

  static const db = AccountProfileRepository._();

  @override
  int? id;

  _is.UuidValue authUserId;

  /// Siempre en minúsculas. Ver `UsernameRules`.
  String username;

  String? bio;

  /// "Creador" no es un scope: es un dato del perfil.
  bool isCreator;

  _il3i3d2n.VerificationStatus verification;

  _ijvat8p8.AccountStatus status;

  DateTime createdAt;

  DateTime? updatedAt;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [AccountProfile]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  AccountProfile copyWith({
    int? id,
    _is.UuidValue? authUserId,
    String? username,
    String? bio,
    bool? isCreator,
    _il3i3d2n.VerificationStatus? verification,
    _ijvat8p8.AccountStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'AccountProfile',
      if (id != null) 'id': id,
      'authUserId': authUserId.toJson(),
      'username': username,
      if (bio != null) 'bio': bio,
      'isCreator': isCreator,
      'verification': verification.toJson(),
      'status': status.toJson(),
      'createdAt': createdAt.toJson(),
      if (updatedAt != null) 'updatedAt': updatedAt?.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {};
  }

  static AccountProfileInclude include() {
    return AccountProfileInclude._();
  }

  static AccountProfileIncludeList includeList({
    _is.WhereExpressionBuilder<AccountProfileTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<AccountProfileTable>? orderBy,
    _is.OrderByListBuilder<AccountProfileTable>? orderByList,
    AccountProfileInclude? include,
  }) {
    return AccountProfileIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(AccountProfile.t),
      orderByList: orderByList?.call(AccountProfile.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _AccountProfileImpl extends AccountProfile {
  _AccountProfileImpl({
    int? id,
    required _is.UuidValue authUserId,
    required String username,
    String? bio,
    bool? isCreator,
    _il3i3d2n.VerificationStatus? verification,
    _ijvat8p8.AccountStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : super._(
         id: id,
         authUserId: authUserId,
         username: username,
         bio: bio,
         isCreator: isCreator,
         verification: verification,
         status: status,
         createdAt: createdAt,
         updatedAt: updatedAt,
       );

  /// Returns a shallow copy of this [AccountProfile]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  AccountProfile copyWith({
    Object? id = _Undefined,
    _is.UuidValue? authUserId,
    String? username,
    Object? bio = _Undefined,
    bool? isCreator,
    _il3i3d2n.VerificationStatus? verification,
    _ijvat8p8.AccountStatus? status,
    DateTime? createdAt,
    Object? updatedAt = _Undefined,
  }) {
    return AccountProfile(
      id: id is int? ? id : this.id,
      authUserId: authUserId ?? this.authUserId,
      username: username ?? this.username,
      bio: bio is String? ? bio : this.bio,
      isCreator: isCreator ?? this.isCreator,
      verification: verification ?? this.verification,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt is DateTime? ? updatedAt : this.updatedAt,
    );
  }
}

class AccountProfileUpdateTable extends _is.UpdateTable<AccountProfileTable> {
  AccountProfileUpdateTable(super.table);

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> authUserId(
    _is.UuidValue value,
  ) => _is.ColumnValue(
    table.authUserId,
    value,
  );

  _is.ColumnValue<String, String> username(String value) => _is.ColumnValue(
    table.username,
    value,
  );

  _is.ColumnValue<String, String> bio(String? value) => _is.ColumnValue(
    table.bio,
    value,
  );

  _is.ColumnValue<bool, bool> isCreator(bool value) => _is.ColumnValue(
    table.isCreator,
    value,
  );

  _is.ColumnValue<_il3i3d2n.VerificationStatus, _il3i3d2n.VerificationStatus>
  verification(_il3i3d2n.VerificationStatus value) => _is.ColumnValue(
    table.verification,
    value,
  );

  _is.ColumnValue<_ijvat8p8.AccountStatus, _ijvat8p8.AccountStatus> status(
    _ijvat8p8.AccountStatus value,
  ) => _is.ColumnValue(
    table.status,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _is.ColumnValue(
        table.createdAt,
        value,
      );

  _is.ColumnValue<DateTime, DateTime> updatedAt(DateTime? value) =>
      _is.ColumnValue(
        table.updatedAt,
        value,
      );
}

class AccountProfileTable extends _is.Table<int?> {
  AccountProfileTable({super.tableRelation})
    : super(tableName: 'account_profile') {
    updateTable = AccountProfileUpdateTable(this);
    authUserId = _is.ColumnUuid(
      'authUserId',
      this,
    );
    username = _is.ColumnString(
      'username',
      this,
    );
    bio = _is.ColumnString(
      'bio',
      this,
    );
    isCreator = _is.ColumnBool(
      'isCreator',
      this,
      hasDefault: true,
    );
    verification = _is.ColumnEnum(
      'verification',
      this,
      _is.EnumSerialization.byName,
      hasDefault: true,
    );
    status = _is.ColumnEnum(
      'status',
      this,
      _is.EnumSerialization.byName,
      hasDefault: true,
    );
    createdAt = _is.ColumnDateTime(
      'createdAt',
      this,
      hasDefault: true,
    );
    updatedAt = _is.ColumnDateTime(
      'updatedAt',
      this,
    );
  }

  late final AccountProfileUpdateTable updateTable;

  late final _is.ColumnUuid authUserId;

  /// Siempre en minúsculas. Ver `UsernameRules`.
  late final _is.ColumnString username;

  late final _is.ColumnString bio;

  /// "Creador" no es un scope: es un dato del perfil.
  late final _is.ColumnBool isCreator;

  late final _is.ColumnEnum<_il3i3d2n.VerificationStatus> verification;

  late final _is.ColumnEnum<_ijvat8p8.AccountStatus> status;

  late final _is.ColumnDateTime createdAt;

  late final _is.ColumnDateTime updatedAt;

  @override
  List<_is.Column> get columns => [
    id,
    authUserId,
    username,
    bio,
    isCreator,
    verification,
    status,
    createdAt,
    updatedAt,
  ];
}

class AccountProfileInclude extends _is.IncludeObject {
  AccountProfileInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => AccountProfile.t;
}

class AccountProfileIncludeList extends _is.IncludeList {
  AccountProfileIncludeList._({
    _is.WhereExpressionBuilder<AccountProfileTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(AccountProfile.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => AccountProfile.t;
}

class AccountProfileRepository {
  const AccountProfileRepository._();

  /// Returns a list of [AccountProfile]s matching the given query parameters.
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
  Future<List<AccountProfile>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<AccountProfileTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<AccountProfileTable>? orderBy,
    _is.OrderByListBuilder<AccountProfileTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<AccountProfile>(
      where: where?.call(AccountProfile.t),
      orderBy: orderBy?.call(AccountProfile.t),
      orderByList: orderByList?.call(AccountProfile.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [AccountProfile] matching the given query parameters.
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
  Future<AccountProfile?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<AccountProfileTable>? where,
    int? offset,
    _is.OrderByBuilder<AccountProfileTable>? orderBy,
    _is.OrderByListBuilder<AccountProfileTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<AccountProfile>(
      where: where?.call(AccountProfile.t),
      orderBy: orderBy?.call(AccountProfile.t),
      orderByList: orderByList?.call(AccountProfile.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [AccountProfile] by its [id] or null if no such row exists.
  Future<AccountProfile?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<AccountProfile>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [AccountProfile]s in the list and returns the inserted rows.
  ///
  /// The returned [AccountProfile]s will have their `id` fields set.
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
  Future<List<AccountProfile>> insert(
    _is.DatabaseSession session,
    List<AccountProfile> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<AccountProfile>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [AccountProfile] and returns the inserted row.
  ///
  /// The returned [AccountProfile] will have its `id` field set.
  Future<AccountProfile> insertRow(
    _is.DatabaseSession session,
    AccountProfile row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<AccountProfile>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [AccountProfile]s in the list and returns the resulting rows.
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
  /// The returned [AccountProfile]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<AccountProfile>> upsert(
    _is.DatabaseSession session,
    List<AccountProfile> rows, {
    required _is.ColumnSelections<AccountProfileTable> conflictColumns,
    _is.ColumnSelections<AccountProfileTable>? updateColumns,
    _is.WhereExpressionBuilder<AccountProfileTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<AccountProfile>(
      rows,
      conflictColumns: conflictColumns(AccountProfile.t),
      updateColumns: updateColumns?.call(AccountProfile.t),
      updateWhere: updateWhere?.call(AccountProfile.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [AccountProfile] and returns the resulting row.
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
  /// The returned [AccountProfile] will have its `id` field set.
  Future<AccountProfile?> upsertRow(
    _is.DatabaseSession session,
    AccountProfile row, {
    required _is.ColumnSelections<AccountProfileTable> conflictColumns,
    _is.ColumnSelections<AccountProfileTable>? updateColumns,
    _is.WhereExpressionBuilder<AccountProfileTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<AccountProfile>(
      row,
      conflictColumns: conflictColumns(AccountProfile.t),
      updateColumns: updateColumns?.call(AccountProfile.t),
      updateWhere: updateWhere?.call(AccountProfile.t),
      transaction: transaction,
    );
  }

  /// Updates all [AccountProfile]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<AccountProfile>> update(
    _is.DatabaseSession session,
    List<AccountProfile> rows, {
    _is.ColumnSelections<AccountProfileTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<AccountProfile>(
      rows,
      columns: columns?.call(AccountProfile.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [AccountProfile]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<AccountProfile> updateRow(
    _is.DatabaseSession session,
    AccountProfile row, {
    _is.ColumnSelections<AccountProfileTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<AccountProfile>(
      row,
      columns: columns?.call(AccountProfile.t),
      transaction: transaction,
    );
  }

  /// Updates a single [AccountProfile] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<AccountProfile?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<AccountProfileUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<AccountProfile>(
      id,
      columnValues: columnValues(AccountProfile.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [AccountProfile]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<AccountProfile>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<AccountProfileUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<AccountProfileTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<AccountProfileTable>? orderBy,
    _is.OrderByListBuilder<AccountProfileTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<AccountProfile>(
      columnValues: columnValues(AccountProfile.t.updateTable),
      where: where(AccountProfile.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(AccountProfile.t),
      orderByList: orderByList?.call(AccountProfile.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [AccountProfile]s in the list and returns the deleted rows.
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
  Future<List<AccountProfile>> delete(
    _is.DatabaseSession session,
    List<AccountProfile> rows, {
    _is.OrderByBuilder<AccountProfileTable>? orderBy,
    _is.OrderByListBuilder<AccountProfileTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<AccountProfile>(
      rows,
      orderBy: orderBy?.call(AccountProfile.t),
      orderByList: orderByList?.call(AccountProfile.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [AccountProfile].
  Future<AccountProfile> deleteRow(
    _is.DatabaseSession session,
    AccountProfile row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<AccountProfile>(
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
  Future<List<AccountProfile>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<AccountProfileTable> where,
    _is.OrderByBuilder<AccountProfileTable>? orderBy,
    _is.OrderByListBuilder<AccountProfileTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<AccountProfile>(
      where: where(AccountProfile.t),
      orderBy: orderBy?.call(AccountProfile.t),
      orderByList: orderByList?.call(AccountProfile.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<AccountProfileTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<AccountProfile>(
      where: where?.call(AccountProfile.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [AccountProfile] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<AccountProfileTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<AccountProfile>(
      where: where(AccountProfile.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
