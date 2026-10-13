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
import '../../../modules/live/models/live_show_role.dart' as _isrlpwvf;

/// Alguien en el escenario.
abstract class LiveSpeakerView
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  LiveSpeakerView._({
    required this.userId,
    this.username,
    this.name,
    this.avatarUrl,
    required this.role,
    required this.micMuted,
    required this.cameraOn,
  });

  factory LiveSpeakerView({
    required _isc.UuidValue userId,
    String? username,
    String? name,
    String? avatarUrl,
    required _isrlpwvf.LiveShowRole role,
    required bool micMuted,
    required bool cameraOn,
  }) = _LiveSpeakerViewImpl;

  factory LiveSpeakerView.fromJson(Map<String, dynamic> jsonSerialization) {
    return LiveSpeakerView(
      userId: _isc.UuidValueJsonExtension.fromJson(jsonSerialization['userId']),
      username: jsonSerialization['username'] as String?,
      name: jsonSerialization['name'] as String?,
      avatarUrl: jsonSerialization['avatarUrl'] as String?,
      role: _isrlpwvf.LiveShowRole.fromJson(
        (jsonSerialization['role'] as String),
      ),
      micMuted: _isc.BoolJsonExtension.fromJson(jsonSerialization['micMuted']),
      cameraOn: _isc.BoolJsonExtension.fromJson(jsonSerialization['cameraOn']),
    );
  }

  _isc.UuidValue userId;

  String? username;

  String? name;

  String? avatarUrl;

  _isrlpwvf.LiveShowRole role;

  bool micMuted;

  bool cameraOn;

  /// Returns a shallow copy of this [LiveSpeakerView]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  LiveSpeakerView copyWith({
    _isc.UuidValue? userId,
    String? username,
    String? name,
    String? avatarUrl,
    _isrlpwvf.LiveShowRole? role,
    bool? micMuted,
    bool? cameraOn,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'LiveSpeakerView',
      'userId': userId.toJson(),
      if (username != null) 'username': username,
      if (name != null) 'name': name,
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
      'role': role.toJson(),
      'micMuted': micMuted,
      'cameraOn': cameraOn,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'LiveSpeakerView',
      'userId': userId.toJson(),
      if (username != null) 'username': username,
      if (name != null) 'name': name,
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
      'role': role.toJson(),
      'micMuted': micMuted,
      'cameraOn': cameraOn,
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _LiveSpeakerViewImpl extends LiveSpeakerView {
  _LiveSpeakerViewImpl({
    required _isc.UuidValue userId,
    String? username,
    String? name,
    String? avatarUrl,
    required _isrlpwvf.LiveShowRole role,
    required bool micMuted,
    required bool cameraOn,
  }) : super._(
         userId: userId,
         username: username,
         name: name,
         avatarUrl: avatarUrl,
         role: role,
         micMuted: micMuted,
         cameraOn: cameraOn,
       );

  /// Returns a shallow copy of this [LiveSpeakerView]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  LiveSpeakerView copyWith({
    _isc.UuidValue? userId,
    Object? username = _Undefined,
    Object? name = _Undefined,
    Object? avatarUrl = _Undefined,
    _isrlpwvf.LiveShowRole? role,
    bool? micMuted,
    bool? cameraOn,
  }) {
    return LiveSpeakerView(
      userId: userId ?? this.userId,
      username: username is String? ? username : this.username,
      name: name is String? ? name : this.name,
      avatarUrl: avatarUrl is String? ? avatarUrl : this.avatarUrl,
      role: role ?? this.role,
      micMuted: micMuted ?? this.micMuted,
      cameraOn: cameraOn ?? this.cameraOn,
    );
  }
}
