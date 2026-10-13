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

/// Alguien que pidió la palabra.
abstract class LiveHandView
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  LiveHandView._({
    required this.userId,
    this.username,
    this.name,
    this.avatarUrl,
    required this.raisedAt,
  });

  factory LiveHandView({
    required _isc.UuidValue userId,
    String? username,
    String? name,
    String? avatarUrl,
    required DateTime raisedAt,
  }) = _LiveHandViewImpl;

  factory LiveHandView.fromJson(Map<String, dynamic> jsonSerialization) {
    return LiveHandView(
      userId: _isc.UuidValueJsonExtension.fromJson(jsonSerialization['userId']),
      username: jsonSerialization['username'] as String?,
      name: jsonSerialization['name'] as String?,
      avatarUrl: jsonSerialization['avatarUrl'] as String?,
      raisedAt: _isc.DateTimeJsonExtension.fromJson(
        jsonSerialization['raisedAt'],
      ),
    );
  }

  _isc.UuidValue userId;

  String? username;

  String? name;

  String? avatarUrl;

  DateTime raisedAt;

  /// Returns a shallow copy of this [LiveHandView]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  LiveHandView copyWith({
    _isc.UuidValue? userId,
    String? username,
    String? name,
    String? avatarUrl,
    DateTime? raisedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'LiveHandView',
      'userId': userId.toJson(),
      if (username != null) 'username': username,
      if (name != null) 'name': name,
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
      'raisedAt': raisedAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'LiveHandView',
      'userId': userId.toJson(),
      if (username != null) 'username': username,
      if (name != null) 'name': name,
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
      'raisedAt': raisedAt.toJson(),
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _LiveHandViewImpl extends LiveHandView {
  _LiveHandViewImpl({
    required _isc.UuidValue userId,
    String? username,
    String? name,
    String? avatarUrl,
    required DateTime raisedAt,
  }) : super._(
         userId: userId,
         username: username,
         name: name,
         avatarUrl: avatarUrl,
         raisedAt: raisedAt,
       );

  /// Returns a shallow copy of this [LiveHandView]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  LiveHandView copyWith({
    _isc.UuidValue? userId,
    Object? username = _Undefined,
    Object? name = _Undefined,
    Object? avatarUrl = _Undefined,
    DateTime? raisedAt,
  }) {
    return LiveHandView(
      userId: userId ?? this.userId,
      username: username is String? ? username : this.username,
      name: name is String? ? name : this.name,
      avatarUrl: avatarUrl is String? ? avatarUrl : this.avatarUrl,
      raisedAt: raisedAt ?? this.raisedAt,
    );
  }
}
