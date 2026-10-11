import '../live_media_gateway.dart';
import 'agora_token_builder.dart';

/// Tokens de Agora firmados con el App Certificate.
///
/// El certificado vive en los secretos de Serverpod (`agoraAppCertificate`)
/// y nunca sale del servidor: el cliente recibe un token que vale para un
/// canal, un uid y un rol, y que vence.
class AgoraLiveMediaGateway implements LiveMediaGateway {
  const AgoraLiveMediaGateway({
    required this.appId,
    required this.appCertificate,
    this._now,
  });

  final String appId;
  final String appCertificate;
  final DateTime Function()? _now;

  @override
  Future<LiveMediaToken> issueToken({
    required String channel,
    required int uid,
    required bool isPublisher,
    required Duration ttl,
  }) async {
    final now = (_now ?? DateTime.now)().toUtc();
    final seconds = ttl.inSeconds;
    return LiveMediaToken(
      appId: appId,
      token: AgoraTokenBuilder.buildRtcToken(
        appId: appId,
        appCertificate: appCertificate,
        channel: channel,
        uid: uid,
        isPublisher: isPublisher,
        tokenExpire: seconds,
        privilegeExpire: seconds,
        issueTs: now.millisecondsSinceEpoch ~/ 1000,
      ),
      expiresAt: now.add(ttl),
    );
  }
}

/// Sin App Certificate: el modo de prueba de Agora, donde se entra con el
/// App ID solo y el token vacío. También es el gateway de los tests.
class FakeLiveMediaGateway implements LiveMediaGateway {
  const FakeLiveMediaGateway({this.appId = '', this._now});

  final String appId;
  final DateTime Function()? _now;

  @override
  Future<LiveMediaToken> issueToken({
    required String channel,
    required int uid,
    required bool isPublisher,
    required Duration ttl,
  }) async => LiveMediaToken(
    appId: appId,
    token: '',
    expiresAt: (_now ?? DateTime.now)().toUtc().add(ttl),
  );
}

/// Elige el gateway según los secretos: con App ID y certificado, tokens
/// reales; si falta alguno, modo de prueba.
LiveMediaGateway liveMediaGatewayFrom(Map<String, String> passwords) {
  final appId = passwords['agoraAppId'] ?? '';
  final certificate = passwords['agoraAppCertificate'] ?? '';
  if (appId.isEmpty || certificate.isEmpty) {
    return FakeLiveMediaGateway(appId: appId);
  }
  return AgoraLiveMediaGateway(appId: appId, appCertificate: certificate);
}
