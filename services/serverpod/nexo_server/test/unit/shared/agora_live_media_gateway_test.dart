import 'dart:convert';
import 'dart:io';

import 'package:nexo_server/src/shared/gateways/agora/agora_live_media_gateway.dart';
import 'package:test/test.dart';

/// Valores de mentira con el formato de Agora (32 hex). El certificado real
/// vive sólo en `config/passwords.yaml`, que no se versiona.
void main() {
  const appId = 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
  const certificate = 'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';

  group('Given the configured secrets', () {
    test('then App ID and certificate give signed tokens', () {
      final gateway = liveMediaGatewayFrom({
        'agoraAppId': appId,
        'agoraAppCertificate': certificate,
      });

      expect(gateway, isA<AgoraLiveMediaGateway>());
    });

    test('then a missing certificate falls back to test mode', () async {
      final gateway = liveMediaGatewayFrom({'agoraAppId': appId});
      final token = await gateway.issueToken(
        channel: 'nexo_live_1',
        uid: 7,
        isPublisher: true,
        ttl: const Duration(hours: 2),
      );

      expect(gateway, isA<FakeLiveMediaGateway>());
      expect(token.token, isEmpty);
      expect(token.appId, appId);
    });
  });

  test('Given a signed token, then it names the channel and the uid', () async {
    final now = DateTime.utc(2026, 10, 11, 20);
    final gateway = AgoraLiveMediaGateway(
      appId: appId,
      appCertificate: certificate,
      now: () => now,
    );

    final token = await gateway.issueToken(
      channel: 'nexo_live_12',
      uid: 4242,
      isPublisher: true,
      ttl: const Duration(hours: 2),
    );

    expect(token.token, startsWith('007'));
    expect(token.appId, appId);
    expect(token.expiresAt, now.add(const Duration(hours: 2)));
    final payload = latin1.decode(
      ZLibCodec().decode(base64.decode(token.token.substring(3))),
    );
    expect(payload, contains('nexo_live_12'));
    expect(payload, contains('4242'));
    expect(payload, contains(appId));
    // El certificado firma, pero nunca viaja en el token.
    expect(payload, isNot(contains(certificate)));
  });
}
