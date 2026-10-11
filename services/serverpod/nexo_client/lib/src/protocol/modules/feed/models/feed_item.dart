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
import '../../../modules/content/models/post_view.dart' as _ido7bd9b;
import '../../../modules/feed/models/feed_item_kind.dart' as _ijf98zlw;
import '../../../modules/live/models/live_show_view.dart' as _idtyojf8;

/// Un elemento del feed: un post o un show, según [kind].
abstract class FeedItem
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  FeedItem._({
    required this.kind,
    this.post,
    this.liveShow,
  });

  factory FeedItem({
    required _ijf98zlw.FeedItemKind kind,
    _ido7bd9b.PostView? post,
    _idtyojf8.LiveShowView? liveShow,
  }) = _FeedItemImpl;

  factory FeedItem.fromJson(Map<String, dynamic> jsonSerialization) {
    return FeedItem(
      kind: _ijf98zlw.FeedItemKind.fromJson(
        (jsonSerialization['kind'] as String),
      ),
      post: jsonSerialization['post'] == null
          ? null
          : _il0t1g31.Protocol().deserialize<_ido7bd9b.PostView>(
              jsonSerialization['post'],
            ),
      liveShow: jsonSerialization['liveShow'] == null
          ? null
          : _il0t1g31.Protocol().deserialize<_idtyojf8.LiveShowView>(
              jsonSerialization['liveShow'],
            ),
    );
  }

  _ijf98zlw.FeedItemKind kind;

  _ido7bd9b.PostView? post;

  _idtyojf8.LiveShowView? liveShow;

  /// Returns a shallow copy of this [FeedItem]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  FeedItem copyWith({
    _ijf98zlw.FeedItemKind? kind,
    _ido7bd9b.PostView? post,
    _idtyojf8.LiveShowView? liveShow,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'FeedItem',
      'kind': kind.toJson(),
      if (post != null) 'post': post?.toJson(),
      if (liveShow != null) 'liveShow': liveShow?.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'FeedItem',
      'kind': kind.toJson(),
      if (post != null) 'post': post?.toJsonForProtocol(),
      if (liveShow != null) 'liveShow': liveShow?.toJsonForProtocol(),
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _FeedItemImpl extends FeedItem {
  _FeedItemImpl({
    required _ijf98zlw.FeedItemKind kind,
    _ido7bd9b.PostView? post,
    _idtyojf8.LiveShowView? liveShow,
  }) : super._(
         kind: kind,
         post: post,
         liveShow: liveShow,
       );

  /// Returns a shallow copy of this [FeedItem]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  FeedItem copyWith({
    _ijf98zlw.FeedItemKind? kind,
    Object? post = _Undefined,
    Object? liveShow = _Undefined,
  }) {
    return FeedItem(
      kind: kind ?? this.kind,
      post: post is _ido7bd9b.PostView? ? post : this.post?.copyWith(),
      liveShow: liveShow is _idtyojf8.LiveShowView?
          ? liveShow
          : this.liveShow?.copyWith(),
    );
  }
}
