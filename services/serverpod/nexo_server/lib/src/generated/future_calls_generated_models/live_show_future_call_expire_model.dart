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

abstract class LiveShowFutureCallExpireModel
    implements _is.SerializableModel, _is.ProtocolSerialization {
  LiveShowFutureCallExpireModel._({required this.showId});

  factory LiveShowFutureCallExpireModel({required int showId}) =
      _LiveShowFutureCallExpireModelImpl;

  factory LiveShowFutureCallExpireModel.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return LiveShowFutureCallExpireModel(
      showId: jsonSerialization['showId'] as int,
    );
  }

  int showId;

  /// Returns a shallow copy of this [LiveShowFutureCallExpireModel]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  LiveShowFutureCallExpireModel copyWith({int? showId});
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'LiveShowFutureCallExpireModel',
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

class _LiveShowFutureCallExpireModelImpl extends LiveShowFutureCallExpireModel {
  _LiveShowFutureCallExpireModelImpl({required int showId})
    : super._(showId: showId);

  /// Returns a shallow copy of this [LiveShowFutureCallExpireModel]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  LiveShowFutureCallExpireModel copyWith({int? showId}) {
    return LiveShowFutureCallExpireModel(showId: showId ?? this.showId);
  }
}
