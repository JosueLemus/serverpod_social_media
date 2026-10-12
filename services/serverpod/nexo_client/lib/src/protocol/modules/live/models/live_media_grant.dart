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
import '../../../modules/live/models/live_media_grant_role.dart' as _incqhehd;

/// Credencial para entrar al canal de video de un show. El token lo firma el
/// servidor con el App Certificate, que nunca sale de acá. `token` vacío
/// quiere decir modo de prueba: el proyecto de Agora no tiene certificado.
abstract class LiveMediaGrant
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  LiveMediaGrant._({
    required this.appId,
    required this.channel,
    required this.uid,
    required this.token,
    required this.role,
    required this.expiresAt,
  });

  factory LiveMediaGrant({
    required String appId,
    required String channel,
    required int uid,
    required String token,
    required _incqhehd.LiveMediaGrantRole role,
    required DateTime expiresAt,
  }) = _LiveMediaGrantImpl;

  factory LiveMediaGrant.fromJson(Map<String, dynamic> jsonSerialization) {
    return LiveMediaGrant(
      appId: jsonSerialization['appId'] as String,
      channel: jsonSerialization['channel'] as String,
      uid: jsonSerialization['uid'] as int,
      token: jsonSerialization['token'] as String,
      role: _incqhehd.LiveMediaGrantRole.fromJson(
        (jsonSerialization['role'] as String),
      ),
      expiresAt: _isc.DateTimeJsonExtension.fromJson(
        jsonSerialization['expiresAt'],
      ),
    );
  }

  String appId;

  String channel;

  int uid;

  String token;

  _incqhehd.LiveMediaGrantRole role;

  DateTime expiresAt;

  /// Returns a shallow copy of this [LiveMediaGrant]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  LiveMediaGrant copyWith({
    String? appId,
    String? channel,
    int? uid,
    String? token,
    _incqhehd.LiveMediaGrantRole? role,
    DateTime? expiresAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'LiveMediaGrant',
      'appId': appId,
      'channel': channel,
      'uid': uid,
      'token': token,
      'role': role.toJson(),
      'expiresAt': expiresAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'LiveMediaGrant',
      'appId': appId,
      'channel': channel,
      'uid': uid,
      'token': token,
      'role': role.toJson(),
      'expiresAt': expiresAt.toJson(),
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _LiveMediaGrantImpl extends LiveMediaGrant {
  _LiveMediaGrantImpl({
    required String appId,
    required String channel,
    required int uid,
    required String token,
    required _incqhehd.LiveMediaGrantRole role,
    required DateTime expiresAt,
  }) : super._(
         appId: appId,
         channel: channel,
         uid: uid,
         token: token,
         role: role,
         expiresAt: expiresAt,
       );

  /// Returns a shallow copy of this [LiveMediaGrant]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  LiveMediaGrant copyWith({
    String? appId,
    String? channel,
    int? uid,
    String? token,
    _incqhehd.LiveMediaGrantRole? role,
    DateTime? expiresAt,
  }) {
    return LiveMediaGrant(
      appId: appId ?? this.appId,
      channel: channel ?? this.channel,
      uid: uid ?? this.uid,
      token: token ?? this.token,
      role: role ?? this.role,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }
}
