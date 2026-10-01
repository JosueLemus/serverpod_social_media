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
import '../../../modules/content/models/post_view.dart' as _ido7bd9b;
import '../../../shared/pagination/page_cursor.dart' as _i1sbovtz;

/// Una página del feed. [nextCursor] es `null` cuando no hay más.
abstract class PostPage
    implements _is.SerializableModel, _is.ProtocolSerialization {
  PostPage._({
    required this.items,
    this.nextCursor,
  });

  factory PostPage({
    required List<_ido7bd9b.PostView> items,
    _i1sbovtz.PageCursor? nextCursor,
  }) = _PostPageImpl;

  factory PostPage.fromJson(Map<String, dynamic> jsonSerialization) {
    return PostPage(
      items: _i8p6m2v0.Protocol().deserialize<List<_ido7bd9b.PostView>>(
        jsonSerialization['items'],
      ),
      nextCursor: jsonSerialization['nextCursor'] == null
          ? null
          : _i8p6m2v0.Protocol().deserialize<_i1sbovtz.PageCursor>(
              jsonSerialization['nextCursor'],
            ),
    );
  }

  List<_ido7bd9b.PostView> items;

  _i1sbovtz.PageCursor? nextCursor;

  /// Returns a shallow copy of this [PostPage]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  PostPage copyWith({
    List<_ido7bd9b.PostView>? items,
    _i1sbovtz.PageCursor? nextCursor,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'PostPage',
      'items': items.toJson(valueToJson: (v) => v.toJson()),
      if (nextCursor != null) 'nextCursor': nextCursor?.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'PostPage',
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

class _PostPageImpl extends PostPage {
  _PostPageImpl({
    required List<_ido7bd9b.PostView> items,
    _i1sbovtz.PageCursor? nextCursor,
  }) : super._(
         items: items,
         nextCursor: nextCursor,
       );

  /// Returns a shallow copy of this [PostPage]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  PostPage copyWith({
    List<_ido7bd9b.PostView>? items,
    Object? nextCursor = _Undefined,
  }) {
    return PostPage(
      items: items ?? this.items.map((e0) => e0.copyWith()).toList(),
      nextCursor: nextCursor is _i1sbovtz.PageCursor?
          ? nextCursor
          : this.nextCursor?.copyWith(),
    );
  }
}
