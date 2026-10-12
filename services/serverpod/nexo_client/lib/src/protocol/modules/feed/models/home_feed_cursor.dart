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
import '../../../shared/pagination/page_cursor.dart' as _i1sbovtz;

/// Dónde sigue el feed de inicio: primero se agota `following` y después
/// `discover`, cada una con su propio keyset.
abstract class HomeFeedCursor
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  HomeFeedCursor._({
    this.followingAfter,
    required this.followingDone,
    this.discoverAfter,
    required this.discoverDone,
  });

  factory HomeFeedCursor({
    _i1sbovtz.PageCursor? followingAfter,
    required bool followingDone,
    _i1sbovtz.PageCursor? discoverAfter,
    required bool discoverDone,
  }) = _HomeFeedCursorImpl;

  factory HomeFeedCursor.fromJson(Map<String, dynamic> jsonSerialization) {
    return HomeFeedCursor(
      followingAfter: jsonSerialization['followingAfter'] == null
          ? null
          : _il0t1g31.Protocol().deserialize<_i1sbovtz.PageCursor>(
              jsonSerialization['followingAfter'],
            ),
      followingDone: _isc.BoolJsonExtension.fromJson(
        jsonSerialization['followingDone'],
      ),
      discoverAfter: jsonSerialization['discoverAfter'] == null
          ? null
          : _il0t1g31.Protocol().deserialize<_i1sbovtz.PageCursor>(
              jsonSerialization['discoverAfter'],
            ),
      discoverDone: _isc.BoolJsonExtension.fromJson(
        jsonSerialization['discoverDone'],
      ),
    );
  }

  _i1sbovtz.PageCursor? followingAfter;

  bool followingDone;

  _i1sbovtz.PageCursor? discoverAfter;

  bool discoverDone;

  /// Returns a shallow copy of this [HomeFeedCursor]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  HomeFeedCursor copyWith({
    _i1sbovtz.PageCursor? followingAfter,
    bool? followingDone,
    _i1sbovtz.PageCursor? discoverAfter,
    bool? discoverDone,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'HomeFeedCursor',
      if (followingAfter != null) 'followingAfter': followingAfter?.toJson(),
      'followingDone': followingDone,
      if (discoverAfter != null) 'discoverAfter': discoverAfter?.toJson(),
      'discoverDone': discoverDone,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'HomeFeedCursor',
      if (followingAfter != null)
        'followingAfter': followingAfter?.toJsonForProtocol(),
      'followingDone': followingDone,
      if (discoverAfter != null)
        'discoverAfter': discoverAfter?.toJsonForProtocol(),
      'discoverDone': discoverDone,
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _HomeFeedCursorImpl extends HomeFeedCursor {
  _HomeFeedCursorImpl({
    _i1sbovtz.PageCursor? followingAfter,
    required bool followingDone,
    _i1sbovtz.PageCursor? discoverAfter,
    required bool discoverDone,
  }) : super._(
         followingAfter: followingAfter,
         followingDone: followingDone,
         discoverAfter: discoverAfter,
         discoverDone: discoverDone,
       );

  /// Returns a shallow copy of this [HomeFeedCursor]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  HomeFeedCursor copyWith({
    Object? followingAfter = _Undefined,
    bool? followingDone,
    Object? discoverAfter = _Undefined,
    bool? discoverDone,
  }) {
    return HomeFeedCursor(
      followingAfter: followingAfter is _i1sbovtz.PageCursor?
          ? followingAfter
          : this.followingAfter?.copyWith(),
      followingDone: followingDone ?? this.followingDone,
      discoverAfter: discoverAfter is _i1sbovtz.PageCursor?
          ? discoverAfter
          : this.discoverAfter?.copyWith(),
      discoverDone: discoverDone ?? this.discoverDone,
    );
  }
}
