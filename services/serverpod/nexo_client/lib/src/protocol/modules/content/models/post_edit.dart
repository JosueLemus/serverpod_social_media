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
import '../../../modules/content/models/post_visibility.dart' as _i6lvj3eo;

/// Cambios a un post publicado. `null` deja el campo como está. Los adjuntos
/// no se editan.
abstract class PostEdit
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  PostEdit._({
    this.body,
    this.tags,
    this.visibility,
    this.allowComments,
  });

  factory PostEdit({
    String? body,
    List<String>? tags,
    _i6lvj3eo.PostVisibility? visibility,
    bool? allowComments,
  }) = _PostEditImpl;

  factory PostEdit.fromJson(Map<String, dynamic> jsonSerialization) {
    return PostEdit(
      body: jsonSerialization['body'] as String?,
      tags: jsonSerialization['tags'] == null
          ? null
          : _il0t1g31.Protocol().deserialize<List<String>>(
              jsonSerialization['tags'],
            ),
      visibility: jsonSerialization['visibility'] == null
          ? null
          : _i6lvj3eo.PostVisibility.fromJson(
              (jsonSerialization['visibility'] as String),
            ),
      allowComments: jsonSerialization['allowComments'] == null
          ? null
          : _isc.BoolJsonExtension.fromJson(jsonSerialization['allowComments']),
    );
  }

  String? body;

  List<String>? tags;

  _i6lvj3eo.PostVisibility? visibility;

  bool? allowComments;

  /// Returns a shallow copy of this [PostEdit]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  PostEdit copyWith({
    String? body,
    List<String>? tags,
    _i6lvj3eo.PostVisibility? visibility,
    bool? allowComments,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'PostEdit',
      if (body != null) 'body': body,
      if (tags != null) 'tags': tags?.toJson(),
      if (visibility != null) 'visibility': visibility?.toJson(),
      if (allowComments != null) 'allowComments': allowComments,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'PostEdit',
      if (body != null) 'body': body,
      if (tags != null) 'tags': tags?.toJson(),
      if (visibility != null) 'visibility': visibility?.toJson(),
      if (allowComments != null) 'allowComments': allowComments,
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _PostEditImpl extends PostEdit {
  _PostEditImpl({
    String? body,
    List<String>? tags,
    _i6lvj3eo.PostVisibility? visibility,
    bool? allowComments,
  }) : super._(
         body: body,
         tags: tags,
         visibility: visibility,
         allowComments: allowComments,
       );

  /// Returns a shallow copy of this [PostEdit]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  PostEdit copyWith({
    Object? body = _Undefined,
    Object? tags = _Undefined,
    Object? visibility = _Undefined,
    Object? allowComments = _Undefined,
  }) {
    return PostEdit(
      body: body is String? ? body : this.body,
      tags: tags is List<String>? ? tags : this.tags?.map((e0) => e0).toList(),
      visibility: visibility is _i6lvj3eo.PostVisibility?
          ? visibility
          : this.visibility,
      allowComments: allowComments is bool?
          ? allowComments
          : this.allowComments,
    );
  }
}
