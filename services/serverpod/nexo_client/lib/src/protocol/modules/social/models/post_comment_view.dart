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
import 'package:serverpod_client/serverpod_client.dart' as _isc;

/// [canDelete] es `true` para el autor del comentario, el autor del post y
/// el staff de moderación.
abstract class PostCommentView
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  PostCommentView._({
    required this.id,
    required this.postId,
    required this.authorId,
    this.authorUsername,
    this.authorName,
    required this.body,
    required this.createdAt,
    required this.canDelete,
  });

  factory PostCommentView({
    required int id,
    required int postId,
    required _isc.UuidValue authorId,
    String? authorUsername,
    String? authorName,
    required String body,
    required DateTime createdAt,
    required bool canDelete,
  }) = _PostCommentViewImpl;

  factory PostCommentView.fromJson(Map<String, dynamic> jsonSerialization) {
    return PostCommentView(
      id: jsonSerialization['id'] as int,
      postId: jsonSerialization['postId'] as int,
      authorId: _isc.UuidValueJsonExtension.fromJson(
        jsonSerialization['authorId'],
      ),
      authorUsername: jsonSerialization['authorUsername'] as String?,
      authorName: jsonSerialization['authorName'] as String?,
      body: jsonSerialization['body'] as String,
      createdAt: _isc.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      canDelete: _isc.BoolJsonExtension.fromJson(
        jsonSerialization['canDelete'],
      ),
    );
  }

  int id;

  int postId;

  _isc.UuidValue authorId;

  String? authorUsername;

  String? authorName;

  String body;

  DateTime createdAt;

  bool canDelete;

  /// Returns a shallow copy of this [PostCommentView]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  PostCommentView copyWith({
    int? id,
    int? postId,
    _isc.UuidValue? authorId,
    String? authorUsername,
    String? authorName,
    String? body,
    DateTime? createdAt,
    bool? canDelete,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'PostCommentView',
      'id': id,
      'postId': postId,
      'authorId': authorId.toJson(),
      if (authorUsername != null) 'authorUsername': authorUsername,
      if (authorName != null) 'authorName': authorName,
      'body': body,
      'createdAt': createdAt.toJson(),
      'canDelete': canDelete,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'PostCommentView',
      'id': id,
      'postId': postId,
      'authorId': authorId.toJson(),
      if (authorUsername != null) 'authorUsername': authorUsername,
      if (authorName != null) 'authorName': authorName,
      'body': body,
      'createdAt': createdAt.toJson(),
      'canDelete': canDelete,
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _PostCommentViewImpl extends PostCommentView {
  _PostCommentViewImpl({
    required int id,
    required int postId,
    required _isc.UuidValue authorId,
    String? authorUsername,
    String? authorName,
    required String body,
    required DateTime createdAt,
    required bool canDelete,
  }) : super._(
         id: id,
         postId: postId,
         authorId: authorId,
         authorUsername: authorUsername,
         authorName: authorName,
         body: body,
         createdAt: createdAt,
         canDelete: canDelete,
       );

  /// Returns a shallow copy of this [PostCommentView]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  PostCommentView copyWith({
    int? id,
    int? postId,
    _isc.UuidValue? authorId,
    Object? authorUsername = _Undefined,
    Object? authorName = _Undefined,
    String? body,
    DateTime? createdAt,
    bool? canDelete,
  }) {
    return PostCommentView(
      id: id ?? this.id,
      postId: postId ?? this.postId,
      authorId: authorId ?? this.authorId,
      authorUsername: authorUsername is String?
          ? authorUsername
          : this.authorUsername,
      authorName: authorName is String? ? authorName : this.authorName,
      body: body ?? this.body,
      createdAt: createdAt ?? this.createdAt,
      canDelete: canDelete ?? this.canDelete,
    );
  }
}
