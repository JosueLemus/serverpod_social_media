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

/// Cómo quedó el like tras dar o quitar: el contador ya incluye el cambio.
abstract class LikeState
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  LikeState._({
    required this.postId,
    required this.isLiked,
    required this.likeCount,
  });

  factory LikeState({
    required int postId,
    required bool isLiked,
    required int likeCount,
  }) = _LikeStateImpl;

  factory LikeState.fromJson(Map<String, dynamic> jsonSerialization) {
    return LikeState(
      postId: jsonSerialization['postId'] as int,
      isLiked: _isc.BoolJsonExtension.fromJson(jsonSerialization['isLiked']),
      likeCount: jsonSerialization['likeCount'] as int,
    );
  }

  int postId;

  bool isLiked;

  int likeCount;

  /// Returns a shallow copy of this [LikeState]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  LikeState copyWith({
    int? postId,
    bool? isLiked,
    int? likeCount,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'LikeState',
      'postId': postId,
      'isLiked': isLiked,
      'likeCount': likeCount,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'LikeState',
      'postId': postId,
      'isLiked': isLiked,
      'likeCount': likeCount,
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _LikeStateImpl extends LikeState {
  _LikeStateImpl({
    required int postId,
    required bool isLiked,
    required int likeCount,
  }) : super._(
         postId: postId,
         isLiked: isLiked,
         likeCount: likeCount,
       );

  /// Returns a shallow copy of this [LikeState]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  LikeState copyWith({
    int? postId,
    bool? isLiked,
    int? likeCount,
  }) {
    return LikeState(
      postId: postId ?? this.postId,
      isLiked: isLiked ?? this.isLiked,
      likeCount: likeCount ?? this.likeCount,
    );
  }
}
