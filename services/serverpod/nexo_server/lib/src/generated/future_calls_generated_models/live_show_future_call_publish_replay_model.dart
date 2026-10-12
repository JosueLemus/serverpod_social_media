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

abstract class LiveShowFutureCallPublishReplayModel
    implements _is.SerializableModel, _is.ProtocolSerialization {
  LiveShowFutureCallPublishReplayModel._({required this.showId});

  factory LiveShowFutureCallPublishReplayModel({required int showId}) =
      _LiveShowFutureCallPublishReplayModelImpl;

  factory LiveShowFutureCallPublishReplayModel.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return LiveShowFutureCallPublishReplayModel(
      showId: jsonSerialization['showId'] as int,
    );
  }

  int showId;

  /// Returns a shallow copy of this [LiveShowFutureCallPublishReplayModel]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  LiveShowFutureCallPublishReplayModel copyWith({int? showId});
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'LiveShowFutureCallPublishReplayModel',
      'showId': showId,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {};
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _LiveShowFutureCallPublishReplayModelImpl
    extends LiveShowFutureCallPublishReplayModel {
  _LiveShowFutureCallPublishReplayModelImpl({required int showId})
    : super._(showId: showId);

  /// Returns a shallow copy of this [LiveShowFutureCallPublishReplayModel]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  LiveShowFutureCallPublishReplayModel copyWith({int? showId}) {
    return LiveShowFutureCallPublishReplayModel(showId: showId ?? this.showId);
  }
}
