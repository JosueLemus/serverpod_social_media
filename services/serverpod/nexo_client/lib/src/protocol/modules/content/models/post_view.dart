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
import 'package:nexo_client/src/protocol/protocol.dart' as _il0t1g31;
import 'package:serverpod_client/serverpod_client.dart' as _isc;
import '../../../modules/content/models/post_media_view.dart' as _i528jcyz;
import '../../../modules/content/models/post_visibility.dart' as _i6lvj3eo;

/// Un post tal como lo ve quien lo pide. [canEdit] y [canDelete] los decide
/// el servidor: el cliente no ofrece una acción que se va a rechazar.
abstract class PostView
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  PostView._({
    required this.id,
    required this.authorId,
    this.authorUsername,
    this.authorName,
    required this.body,
    required this.tags,
    required this.visibility,
    required this.allowComments,
    required this.likeCount,
    bool? isLiked,
    required this.commentCount,
    required this.media,
    required this.createdAt,
    this.editedAt,
    required this.canEdit,
    required this.canDelete,
  }) : isLiked = isLiked ?? false;

  factory PostView({
    required int id,
    required _isc.UuidValue authorId,
    String? authorUsername,
    String? authorName,
    required String body,
    required List<String> tags,
    required _i6lvj3eo.PostVisibility visibility,
    required bool allowComments,
    required int likeCount,
    bool? isLiked,
    required int commentCount,
    required List<_i528jcyz.PostMediaView> media,
    required DateTime createdAt,
    DateTime? editedAt,
    required bool canEdit,
    required bool canDelete,
  }) = _PostViewImpl;

  factory PostView.fromJson(Map<String, dynamic> jsonSerialization) {
    return PostView(
      id: jsonSerialization['id'] as int,
      authorId: _isc.UuidValueJsonExtension.fromJson(
        jsonSerialization['authorId'],
      ),
      authorUsername: jsonSerialization['authorUsername'] as String?,
      authorName: jsonSerialization['authorName'] as String?,
      body: jsonSerialization['body'] as String,
      tags: _il0t1g31.Protocol().deserialize<List<String>>(
        jsonSerialization['tags'],
      ),
      visibility: _i6lvj3eo.PostVisibility.fromJson(
        (jsonSerialization['visibility'] as String),
      ),
      allowComments: _isc.BoolJsonExtension.fromJson(
        jsonSerialization['allowComments'],
      ),
      likeCount: jsonSerialization['likeCount'] as int,
      isLiked: jsonSerialization['isLiked'] == null
          ? null
          : _isc.BoolJsonExtension.fromJson(jsonSerialization['isLiked']),
      commentCount: jsonSerialization['commentCount'] as int,
      media: _il0t1g31.Protocol().deserialize<List<_i528jcyz.PostMediaView>>(
        jsonSerialization['media'],
      ),
      createdAt: _isc.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      editedAt: jsonSerialization['editedAt'] == null
          ? null
          : _isc.DateTimeJsonExtension.fromJson(jsonSerialization['editedAt']),
      canEdit: _isc.BoolJsonExtension.fromJson(jsonSerialization['canEdit']),
      canDelete: _isc.BoolJsonExtension.fromJson(
        jsonSerialization['canDelete'],
      ),
    );
  }

  int id;

  _isc.UuidValue authorId;

  String? authorUsername;

  String? authorName;

  String body;

  List<String> tags;

  _i6lvj3eo.PostVisibility visibility;

  bool allowComments;

  int likeCount;

  /// Si quien pide ya dio like. Siempre `false` para un invitado.
  bool isLiked;

  int commentCount;

  List<_i528jcyz.PostMediaView> media;

  DateTime createdAt;

  DateTime? editedAt;

  bool canEdit;

  bool canDelete;

  /// Returns a shallow copy of this [PostView]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  PostView copyWith({
    int? id,
    _isc.UuidValue? authorId,
    String? authorUsername,
    String? authorName,
    String? body,
    List<String>? tags,
    _i6lvj3eo.PostVisibility? visibility,
    bool? allowComments,
    int? likeCount,
    bool? isLiked,
    int? commentCount,
    List<_i528jcyz.PostMediaView>? media,
    DateTime? createdAt,
    DateTime? editedAt,
    bool? canEdit,
    bool? canDelete,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'PostView',
      'id': id,
      'authorId': authorId.toJson(),
      if (authorUsername != null) 'authorUsername': authorUsername,
      if (authorName != null) 'authorName': authorName,
      'body': body,
      'tags': tags.toJson(),
      'visibility': visibility.toJson(),
      'allowComments': allowComments,
      'likeCount': likeCount,
      'isLiked': isLiked,
      'commentCount': commentCount,
      'media': media.toJson(valueToJson: (v) => v.toJson()),
      'createdAt': createdAt.toJson(),
      if (editedAt != null) 'editedAt': editedAt?.toJson(),
      'canEdit': canEdit,
      'canDelete': canDelete,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'PostView',
      'id': id,
      'authorId': authorId.toJson(),
      if (authorUsername != null) 'authorUsername': authorUsername,
      if (authorName != null) 'authorName': authorName,
      'body': body,
      'tags': tags.toJson(),
      'visibility': visibility.toJson(),
      'allowComments': allowComments,
      'likeCount': likeCount,
      'isLiked': isLiked,
      'commentCount': commentCount,
      'media': media.toJson(valueToJson: (v) => v.toJsonForProtocol()),
      'createdAt': createdAt.toJson(),
      if (editedAt != null) 'editedAt': editedAt?.toJson(),
      'canEdit': canEdit,
      'canDelete': canDelete,
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _PostViewImpl extends PostView {
  _PostViewImpl({
    required int id,
    required _isc.UuidValue authorId,
    String? authorUsername,
    String? authorName,
    required String body,
    required List<String> tags,
    required _i6lvj3eo.PostVisibility visibility,
    required bool allowComments,
    required int likeCount,
    bool? isLiked,
    required int commentCount,
    required List<_i528jcyz.PostMediaView> media,
    required DateTime createdAt,
    DateTime? editedAt,
    required bool canEdit,
    required bool canDelete,
  }) : super._(
         id: id,
         authorId: authorId,
         authorUsername: authorUsername,
         authorName: authorName,
         body: body,
         tags: tags,
         visibility: visibility,
         allowComments: allowComments,
         likeCount: likeCount,
         isLiked: isLiked,
         commentCount: commentCount,
         media: media,
         createdAt: createdAt,
         editedAt: editedAt,
         canEdit: canEdit,
         canDelete: canDelete,
       );

  /// Returns a shallow copy of this [PostView]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  PostView copyWith({
    int? id,
    _isc.UuidValue? authorId,
    Object? authorUsername = _Undefined,
    Object? authorName = _Undefined,
    String? body,
    List<String>? tags,
    _i6lvj3eo.PostVisibility? visibility,
    bool? allowComments,
    int? likeCount,
    bool? isLiked,
    int? commentCount,
    List<_i528jcyz.PostMediaView>? media,
    DateTime? createdAt,
    Object? editedAt = _Undefined,
    bool? canEdit,
    bool? canDelete,
  }) {
    return PostView(
      id: id ?? this.id,
      authorId: authorId ?? this.authorId,
      authorUsername: authorUsername is String?
          ? authorUsername
          : this.authorUsername,
      authorName: authorName is String? ? authorName : this.authorName,
      body: body ?? this.body,
      tags: tags ?? this.tags.map((e0) => e0).toList(),
      visibility: visibility ?? this.visibility,
      allowComments: allowComments ?? this.allowComments,
      likeCount: likeCount ?? this.likeCount,
      isLiked: isLiked ?? this.isLiked,
      commentCount: commentCount ?? this.commentCount,
      media: media ?? this.media.map((e0) => e0.copyWith()).toList(),
      createdAt: createdAt ?? this.createdAt,
      editedAt: editedAt is DateTime? ? editedAt : this.editedAt,
      canEdit: canEdit ?? this.canEdit,
      canDelete: canDelete ?? this.canDelete,
    );
  }
}
