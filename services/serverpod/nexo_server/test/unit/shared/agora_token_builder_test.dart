import 'dart:convert';
import 'dart:io';

import 'package:nexo_server/src/shared/gateways/agora/agora_token_builder.dart';
import 'package:test/test.dart';

/// Vectores del `AccessToken2Test.py` oficial de Agora (`AgoraIO/Tools`,
/// `DynamicKey/AgoraDynamicKey/python3`): mismo App ID, certificado, canal,
/// `issue_ts = 1111111`, `salt = 1` y 600 s. El de publicador lo generó el
/// mismo código oficial con esos datos y los cuatro permisos RTC.
///
/// Un byte distinto y Agora contesta `errInvalidToken`, que es exactamente
/// el fallo que este builder vino a arreglar.
///
/// Se compara el contenido descomprimido y no la cadena: zlib puede
/// comprimir distinto según la versión (el de publicador ya difiere entre
/// Python y Dart con el mismo contenido), y Agora descomprime antes de
/// verificar la firma.
void main() {
  const appId = '970CA35de60c44645bbae8a215061b33';
  const appCertificate = '5CFd2fd1755d40ecb72977518be15d3b';
  const channel = '7d72365eb983485397e3e3f9d460bdda';

  String build({required int uid, required bool isPublisher}) =>
      AgoraTokenBuilder.buildRtcToken(
        appId: appId,
        appCertificate: appCertificate,
        channel: channel,
        uid: uid,
        isPublisher: isPublisher,
        tokenExpire: 600,
        privilegeExpire: 600,
        issueTs: 1111111,
        salt: 1,
      );

  List<int> payload(String token) {
    expect(token, startsWith(AgoraTokenBuilder.version));
    return ZLibCodec().decode(base64.decode(token.substring(3)));
  }

  Matcher sameTokenAs(String expected) => predicate<String>(
    (actual) => _equalBytes(payload(actual), payload(expected)),
    'the same AccessToken2 payload as $expected',
  );

  group('Given the official AccessToken2 vectors', () {
    test('then a join-only token for a numeric uid has the same bytes', () {
      expect(
        build(uid: 2882341273, isPublisher: false),
        sameTokenAs(
          '007eJxTYBBbsMMnKq7p9Hf/HcIX5kce9b518kCiQgSr5Zrp4X1Tu6UUGCzNDZwdjU1TUs0'
          'Mkk1MzExMk5ISUy0SjQxNDcwMk4yN3b8IMEQwMTAwMoAwBIL4CgzmKeZGxmamqUmWFsY'
          'mFqbGluapxqnGaZYpJmYGSSkpiVwMRhYWRsYmhkbmxgDCaiTj',
        ),
      );
    });

    test('then uid 0 travels as an empty string', () {
      expect(
        build(uid: 0, isPublisher: false),
        sameTokenAs(
          '007eJxTYLhzZP08Lxa1Pg57+TcXb/3cZ3wi4V6kbpbOog0G2dOYk20UGCzNDZwdjU1TUs0'
          'Mkk1MzExMk5ISUy0SjQxNDcwMk4yN3b8IMEQwMTAwMoAwBIL4CgzmKeZGxmamqUmWFsY'
          'mFqbGluapxqnGaZYpJmYGSSkpiQwMADacImo=',
        ),
      );
    });

    test('then a publisher token carries the four RTC privileges', () {
      expect(
        build(uid: 2882341273, isPublisher: true),
        sameTokenAs(
          '007eJxTYDhuGCT90E3Yo2+N3efJV5hX1K1MZAqae/Sa8UP9VXvOhfArMFiaGzg7Gpum'
          'pJoZJJuYmJmYJiUlplokGhmaGpgZJhkbu38RYIhgYmBgZABhRgYWIAbxmcAkM5hkAZMK'
          'DOYp5kbGZqapSZYWxiYWpsaW5qnGqcZplikmZgZJKSmJXAxGFhZGxiaGRubGAKizJcs=',
        ),
      );
    });
  });

  test('Given an id that is not 32 hex chars, then it refuses to sign', () {
    expect(
      () => AgoraTokenBuilder.buildRtcToken(
        appId: 'not-an-app-id',
        appCertificate: appCertificate,
        channel: channel,
        uid: 1,
        isPublisher: true,
        tokenExpire: 600,
        privilegeExpire: 600,
      ),
      throwsArgumentError,
    );
  });
}

bool _equalBytes(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
