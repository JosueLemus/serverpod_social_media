import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// Arma tokens AccessToken2 (`007…`) para RTC, el formato que exige un
/// proyecto de Agora con App Certificate.
///
/// Es una transcripción del `AccessToken2` oficial de Agora
/// (`AgoraIO/Tools`, `DynamicKey/AgoraDynamicKey/python3`), validada contra
/// sus vectores de prueba en `agora_token_builder_test.dart`. Se escribe acá
/// y no se trae de un paquete porque firma con el certificado: un paquete
/// chico de la comunidad tendría el secreto en la mano.
///
/// El formato, en little-endian:
/// `"007" + base64(zlib(pack_string(firma) + signing_info))`, con
/// `signing_info = pack_string(appId) + u32 issueTs + u32 expire + u32 salt
/// + u16 cantidad de servicios + servicios`.
abstract final class AgoraTokenBuilder {
  static const version = '007';

  /// Tipo del servicio RTC dentro del token.
  static const serviceRtc = 1;

  static const privilegeJoinChannel = 1;
  static const privilegePublishAudioStream = 2;
  static const privilegePublishVideoStream = 3;
  static const privilegePublishDataStream = 4;

  /// Un token RTC para [uid] en [channel]. Un publicador suma los permisos
  /// de publicar audio, video y datos; un suscriptor sólo entra.
  ///
  /// [tokenExpire] y [privilegeExpire] son **segundos desde ahora**, no
  /// timestamps: así lo define Agora. [issueTs] y [salt] existen para los
  /// tests; en producción salen del reloj y de un aleatorio seguro.
  static String buildRtcToken({
    required String appId,
    required String appCertificate,
    required String channel,
    required int uid,
    required bool isPublisher,
    required int tokenExpire,
    required int privilegeExpire,
    int? issueTs,
    int? salt,
  }) {
    if (!_isHexId(appId) || !_isHexId(appCertificate)) {
      throw ArgumentError('App ID y App Certificate son 32 caracteres hex.');
    }
    final privileges = <int, int>{
      privilegeJoinChannel: privilegeExpire,
      if (isPublisher) ...{
        privilegePublishAudioStream: privilegeExpire,
        privilegePublishVideoStream: privilegeExpire,
        privilegePublishDataStream: privilegeExpire,
      },
    };
    return _build(
      appId: appId,
      appCertificate: appCertificate,
      issueTs: issueTs ?? DateTime.now().millisecondsSinceEpoch ~/ 1000,
      expire: tokenExpire,
      salt: salt ?? Random.secure().nextInt(99999999) + 1,
      service: _rtcService(channel, uid, privileges),
    );
  }

  static String _build({
    required String appId,
    required String appCertificate,
    required int issueTs,
    required int expire,
    required int salt,
    required List<int> service,
  }) {
    final signingInfo = BytesBuilder()
      ..add(_string(utf8.encode(appId)))
      ..add(_u32(issueTs))
      ..add(_u32(expire))
      ..add(_u32(salt))
      ..add(_u16(1))
      ..add(service);
    final info = signingInfo.toBytes();

    // La clave de firma se deriva del timestamp y del salt: dos tokens del
    // mismo certificado nunca comparten clave.
    final signingKey =
        Hmac(
          sha256,
          _u32(salt),
        ).convert(
          Hmac(
            sha256,
            _u32(issueTs),
          ).convert(utf8.encode(appCertificate)).bytes,
        );
    final signature = Hmac(sha256, signingKey.bytes).convert(info).bytes;

    final payload = BytesBuilder()
      ..add(_string(signature))
      ..add(info);
    final compressed = ZLibCodec().encode(payload.toBytes());
    return '$version${base64.encode(compressed)}';
  }

  static List<int> _rtcService(
    String channel,
    int uid,
    Map<int, int> privileges,
  ) {
    final sorted = privileges.keys.toList()..sort();
    final out = BytesBuilder()
      ..add(_u16(serviceRtc))
      ..add(_u16(sorted.length));
    for (final key in sorted) {
      out
        ..add(_u16(key))
        ..add(_u32(privileges[key]!));
    }
    out
      ..add(_string(utf8.encode(channel)))
      // uid 0 viaja vacío: Agora lo interpreta como "cualquier uid".
      ..add(_string(uid == 0 ? const [] : utf8.encode('$uid')));
    return out.toBytes();
  }

  static List<int> _u16(int value) =>
      (ByteData(2)..setUint16(0, value, Endian.little)).buffer.asUint8List();

  static List<int> _u32(int value) =>
      (ByteData(4)..setUint32(0, value, Endian.little)).buffer.asUint8List();

  static List<int> _string(List<int> bytes) => [
    ..._u16(bytes.length),
    ...bytes,
  ];

  static bool _isHexId(String value) =>
      RegExp(r'^[0-9a-fA-F]{32}$').hasMatch(value);
}
