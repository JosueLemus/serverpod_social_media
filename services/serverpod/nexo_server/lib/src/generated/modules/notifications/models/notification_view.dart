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

/// Un aviso tal como lo ve su destinatario. [postExcerpt] y [showTitle]
/// alcanzan para dibujarlo sin otra consulta.
abstract class NotificationView
    implements _is.SerializableModel, _is.ProtocolSerialization {
  NotificationView._({
    required this.id,
    required this.kind,
    this.actorId,
    this.actorUsername,
    this.actorName,
    this.actorAvatarUrl,
    this.postId,
    this.postExcerpt,
    this.showId,
    this.showTitle,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationView({
    required int id,
    required _i1q1i3wt.NotificationKind kind,
    _is.UuidValue? actorId,
    String? actorUsername,
    String? actorName,
    String? actorAvatarUrl,
    int? postId,
    String? postExcerpt,
    int? showId,
    String? showTitle,
    required bool isRead,
    required DateTime createdAt,
  }) = _NotificationViewImpl;

  factory NotificationView.fromJson(Map<String, dynamic> jsonSerialization) {
    return NotificationView(
      id: jsonSerialization['id'] as int,
      kind: _i1q1i3wt.NotificationKind.fromJson(
        (jsonSerialization['kind'] as String),
      ),
      actorId: jsonSerialization['actorId'] == null
          ? null
          : _is.UuidValueJsonExtension.fromJson(jsonSerialization['actorId']),
      actorUsername: jsonSerialization['actorUsername'] as String?,
      actorName: jsonSerialization['actorName'] as String?,
      actorAvatarUrl: jsonSerialization['actorAvatarUrl'] as String?,
      postId: jsonSerialization['postId'] as int?,
      postExcerpt: jsonSerialization['postExcerpt'] as String?,
      showId: jsonSerialization['showId'] as int?,
      showTitle: jsonSerialization['showTitle'] as String?,
      isRead: _is.BoolJsonExtension.fromJson(jsonSerialization['isRead']),
      createdAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
    );
  }

  int id;

  _i1q1i3wt.NotificationKind kind;

  _is.UuidValue? actorId;

  String? actorUsername;

  String? actorName;

  String? actorAvatarUrl;

  int? postId;

  String? postExcerpt;

  int? showId;

  String? showTitle;

  bool isRead;

  DateTime createdAt;

  /// Returns a shallow copy of this [NotificationView]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  NotificationView copyWith({
    int? id,
    _i1q1i3wt.NotificationKind? kind,
    _is.UuidValue? actorId,
    String? actorUsername,
    String? actorName,
    String? actorAvatarUrl,
    int? postId,
    String? postExcerpt,
    int? showId,
    String? showTitle,
    bool? isRead,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'NotificationView',
      'id': id,
      'kind': kind.toJson(),
      if (actorId != null) 'actorId': actorId?.toJson(),
      if (actorUsername != null) 'actorUsername': actorUsername,
      if (actorName != null) 'actorName': actorName,
      if (actorAvatarUrl != null) 'actorAvatarUrl': actorAvatarUrl,
      if (postId != null) 'postId': postId,
      if (postExcerpt != null) 'postExcerpt': postExcerpt,
      if (showId != null) 'showId': showId,
      if (showTitle != null) 'showTitle': showTitle,
      'isRead': isRead,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'NotificationView',
      'id': id,
      'kind': kind.toJson(),
      if (actorId != null) 'actorId': actorId?.toJson(),
      if (actorUsername != null) 'actorUsername': actorUsername,
      if (actorName != null) 'actorName': actorName,
      if (actorAvatarUrl != null) 'actorAvatarUrl': actorAvatarUrl,
      if (postId != null) 'postId': postId,
      if (postExcerpt != null) 'postExcerpt': postExcerpt,
      if (showId != null) 'showId': showId,
      if (showTitle != null) 'showTitle': showTitle,
      'isRead': isRead,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _NotificationViewImpl extends NotificationView {
  _NotificationViewImpl({
    required int id,
    required _i1q1i3wt.NotificationKind kind,
    _is.UuidValue? actorId,
    String? actorUsername,
    String? actorName,
    String? actorAvatarUrl,
    int? postId,
    String? postExcerpt,
    int? showId,
    String? showTitle,
    required bool isRead,
    required DateTime createdAt,
  }) : super._(
         id: id,
         kind: kind,
         actorId: actorId,
         actorUsername: actorUsername,
         actorName: actorName,
         actorAvatarUrl: actorAvatarUrl,
         postId: postId,
         postExcerpt: postExcerpt,
         showId: showId,
         showTitle: showTitle,
         isRead: isRead,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [NotificationView]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  NotificationView copyWith({
    int? id,
    _i1q1i3wt.NotificationKind? kind,
    Object? actorId = _Undefined,
    Object? actorUsername = _Undefined,
    Object? actorName = _Undefined,
    Object? actorAvatarUrl = _Undefined,
    Object? postId = _Undefined,
    Object? postExcerpt = _Undefined,
    Object? showId = _Undefined,
    Object? showTitle = _Undefined,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return NotificationView(
      id: id ?? this.id,
      kind: kind ?? this.kind,
      actorId: actorId is _is.UuidValue? ? actorId : this.actorId,
      actorUsername: actorUsername is String?
          ? actorUsername
          : this.actorUsername,
      actorName: actorName is String? ? actorName : this.actorName,
      actorAvatarUrl: actorAvatarUrl is String?
          ? actorAvatarUrl
          : this.actorAvatarUrl,
      postId: postId is int? ? postId : this.postId,
      postExcerpt: postExcerpt is String? ? postExcerpt : this.postExcerpt,
      showId: showId is int? ? showId : this.showId,
      showTitle: showTitle is String? ? showTitle : this.showTitle,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
