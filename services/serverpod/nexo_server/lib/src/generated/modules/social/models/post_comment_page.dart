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
import '../../../modules/social/models/post_comment_view.dart' as _i4t39aup;
import '../../../shared/pagination/page_cursor.dart' as _i1sbovtz;

/// Comentarios de un post, del más viejo al más nuevo: se leen como una
/// conversación.
abstract class PostCommentPage
    implements _is.SerializableModel, _is.ProtocolSerialization {
  PostCommentPage._({
    required this.items,
    this.nextCursor,
  });

  factory PostCommentPage({
    required List<_i4t39aup.PostCommentView> items,
    _i1sbovtz.PageCursor? nextCursor,
  }) = _PostCommentPageImpl;

  factory PostCommentPage.fromJson(Map<String, dynamic> jsonSerialization) {
    return PostCommentPage(
      items: _i8p6m2v0.Protocol().deserialize<List<_i4t39aup.PostCommentView>>(
        jsonSerialization['items'],
      ),
      nextCursor: jsonSerialization['nextCursor'] == null
          ? null
          : _i8p6m2v0.Protocol().deserialize<_i1sbovtz.PageCursor>(
              jsonSerialization['nextCursor'],
            ),
    );
  }

  List<_i4t39aup.PostCommentView> items;

  _i1sbovtz.PageCursor? nextCursor;

  /// Returns a shallow copy of this [PostCommentPage]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  PostCommentPage copyWith({
    List<_i4t39aup.PostCommentView>? items,
    _i1sbovtz.PageCursor? nextCursor,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'PostCommentPage',
      'items': items.toJson(valueToJson: (v) => v.toJson()),
      if (nextCursor != null) 'nextCursor': nextCursor?.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'PostCommentPage',
      'items': items.toJson(valueToJson: (v) => v.toJsonForProtocol()),
      if (nextCursor != null) 'nextCursor': nextCursor?.toJsonForProtocol(),
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _PostCommentPageImpl extends PostCommentPage {
  _PostCommentPageImpl({
    required List<_i4t39aup.PostCommentView> items,
    _i1sbovtz.PageCursor? nextCursor,
  }) : super._(
         items: items,
         nextCursor: nextCursor,
       );

  /// Returns a shallow copy of this [PostCommentPage]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  PostCommentPage copyWith({
    List<_i4t39aup.PostCommentView>? items,
    Object? nextCursor = _Undefined,
  }) {
    return PostCommentPage(
      items: items ?? this.items.map((e0) => e0.copyWith()).toList(),
      nextCursor: nextCursor is _i1sbovtz.PageCursor?
          ? nextCursor
          : this.nextCursor?.copyWith(),
    );
  }
}
