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

/// Cómo quedó el seguimiento tras seguir o dejar de seguir: el contador ya
/// incluye el cambio.
abstract class FollowState
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  FollowState._({
    required this.userId,
    required this.viewerFollows,
    required this.followerCount,
  });

  factory FollowState({
    required _isc.UuidValue userId,
    required bool viewerFollows,
    required int followerCount,
  }) = _FollowStateImpl;

  factory FollowState.fromJson(Map<String, dynamic> jsonSerialization) {
    return FollowState(
      userId: _isc.UuidValueJsonExtension.fromJson(jsonSerialization['userId']),
      viewerFollows: _isc.BoolJsonExtension.fromJson(
        jsonSerialization['viewerFollows'],
      ),
      followerCount: jsonSerialization['followerCount'] as int,
    );
  }

  _isc.UuidValue userId;

  bool viewerFollows;

  int followerCount;

  /// Returns a shallow copy of this [FollowState]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  FollowState copyWith({
    _isc.UuidValue? userId,
    bool? viewerFollows,
    int? followerCount,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'FollowState',
      'userId': userId.toJson(),
      'viewerFollows': viewerFollows,
      'followerCount': followerCount,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'FollowState',
      'userId': userId.toJson(),
      'viewerFollows': viewerFollows,
      'followerCount': followerCount,
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _FollowStateImpl extends FollowState {
  _FollowStateImpl({
    required _isc.UuidValue userId,
    required bool viewerFollows,
    required int followerCount,
  }) : super._(
         userId: userId,
         viewerFollows: viewerFollows,
         followerCount: followerCount,
       );

  /// Returns a shallow copy of this [FollowState]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  FollowState copyWith({
    _isc.UuidValue? userId,
    bool? viewerFollows,
    int? followerCount,
  }) {
    return FollowState(
      userId: userId ?? this.userId,
      viewerFollows: viewerFollows ?? this.viewerFollows,
      followerCount: followerCount ?? this.followerCount,
    );
  }
}
