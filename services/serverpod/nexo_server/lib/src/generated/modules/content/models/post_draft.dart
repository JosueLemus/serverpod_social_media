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
import 'package:nexo_server/src/generated/protocol.dart' as _i8p6m2v0;
import 'package:serverpod/serverpod.dart' as _is;
import '../../../modules/content/models/post_visibility.dart' as _i6lvj3eo;

/// Lo que el cliente envía para publicar. [mediaKeys] son las claves que
/// devolvió `posts.requestMediaUpload`, ya subidas, en el orden de la galería
/// (lista vacía si el post es solo texto).
abstract class PostDraft
    implements _is.SerializableModel, _is.ProtocolSerialization {
  PostDraft._({
    required this.body,
    required this.tags,
    _i6lvj3eo.PostVisibility? visibility,
    bool? allowComments,
    required this.mediaKeys,
  }) : visibility = visibility ?? _i6lvj3eo.PostVisibility.public,
       allowComments = allowComments ?? true;

  factory PostDraft({
    required String body,
    required List<String> tags,
    _i6lvj3eo.PostVisibility? visibility,
    bool? allowComments,
    required List<String> mediaKeys,
  }) = _PostDraftImpl;

  factory PostDraft.fromJson(Map<String, dynamic> jsonSerialization) {
    return PostDraft(
      body: jsonSerialization['body'] as String,
      tags: _i8p6m2v0.Protocol().deserialize<List<String>>(
        jsonSerialization['tags'],
      ),
      visibility: jsonSerialization['visibility'] == null
          ? null
          : _i6lvj3eo.PostVisibility.fromJson(
              (jsonSerialization['visibility'] as String),
            ),
      allowComments: jsonSerialization['allowComments'] == null
          ? null
          : _is.BoolJsonExtension.fromJson(jsonSerialization['allowComments']),
      mediaKeys: _i8p6m2v0.Protocol().deserialize<List<String>>(
        jsonSerialization['mediaKeys'],
      ),
    );
  }

  String body;

  List<String> tags;

  _i6lvj3eo.PostVisibility visibility;

  bool allowComments;

  List<String> mediaKeys;

  /// Returns a shallow copy of this [PostDraft]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  PostDraft copyWith({
    String? body,
    List<String>? tags,
    _i6lvj3eo.PostVisibility? visibility,
    bool? allowComments,
    List<String>? mediaKeys,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'PostDraft',
      'body': body,
      'tags': tags.toJson(),
      'visibility': visibility.toJson(),
      'allowComments': allowComments,
      'mediaKeys': mediaKeys.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'PostDraft',
      'body': body,
      'tags': tags.toJson(),
      'visibility': visibility.toJson(),
      'allowComments': allowComments,
      'mediaKeys': mediaKeys.toJson(),
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _PostDraftImpl extends PostDraft {
  _PostDraftImpl({
    required String body,
    required List<String> tags,
    _i6lvj3eo.PostVisibility? visibility,
    bool? allowComments,
    required List<String> mediaKeys,
  }) : super._(
         body: body,
         tags: tags,
         visibility: visibility,
         allowComments: allowComments,
         mediaKeys: mediaKeys,
       );

  /// Returns a shallow copy of this [PostDraft]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  PostDraft copyWith({
    String? body,
    List<String>? tags,
    _i6lvj3eo.PostVisibility? visibility,
    bool? allowComments,
    List<String>? mediaKeys,
  }) {
    return PostDraft(
      body: body ?? this.body,
      tags: tags ?? this.tags.map((e0) => e0).toList(),
      visibility: visibility ?? this.visibility,
      allowComments: allowComments ?? this.allowComments,
      mediaKeys: mediaKeys ?? this.mediaKeys.map((e0) => e0).toList(),
    );
  }
}
