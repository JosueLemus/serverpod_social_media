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

abstract class PostLiker
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  PostLiker._({
    required this.userId,
    this.username,
    this.name,
    required this.likedAt,
  });

  factory PostLiker({
    required _isc.UuidValue userId,
    String? username,
    String? name,
    required DateTime likedAt,
  }) = _PostLikerImpl;

  factory PostLiker.fromJson(Map<String, dynamic> jsonSerialization) {
    return PostLiker(
      userId: _isc.UuidValueJsonExtension.fromJson(jsonSerialization['userId']),
      username: jsonSerialization['username'] as String?,
      name: jsonSerialization['name'] as String?,
      likedAt: _isc.DateTimeJsonExtension.fromJson(
        jsonSerialization['likedAt'],
      ),
    );
  }

  _isc.UuidValue userId;

  String? username;

  String? name;

  DateTime likedAt;

  /// Returns a shallow copy of this [PostLiker]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  PostLiker copyWith({
    _isc.UuidValue? userId,
    String? username,
    String? name,
    DateTime? likedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'PostLiker',
      'userId': userId.toJson(),
      if (username != null) 'username': username,
      if (name != null) 'name': name,
      'likedAt': likedAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'PostLiker',
      'userId': userId.toJson(),
      if (username != null) 'username': username,
      if (name != null) 'name': name,
      'likedAt': likedAt.toJson(),
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _PostLikerImpl extends PostLiker {
  _PostLikerImpl({
    required _isc.UuidValue userId,
    String? username,
    String? name,
    required DateTime likedAt,
  }) : super._(
         userId: userId,
         username: username,
         name: name,
         likedAt: likedAt,
       );

  /// Returns a shallow copy of this [PostLiker]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  PostLiker copyWith({
    _isc.UuidValue? userId,
    Object? username = _Undefined,
    Object? name = _Undefined,
    DateTime? likedAt,
  }) {
    return PostLiker(
      userId: userId ?? this.userId,
      username: username is String? ? username : this.username,
      name: name is String? ? name : this.name,
      likedAt: likedAt ?? this.likedAt,
    );
  }
}
