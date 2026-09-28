/// Emite credenciales de media en tiempo real (Agora u otro proveedor).
/// Serverpod decide el rol; el gateway solo firma el token.
abstract interface class LiveMediaGateway {
  Future<LiveMediaToken> issueToken({
    required String channel,
    required int uid,
    required bool isPublisher,
    required Duration ttl,
  });
}

class LiveMediaToken {
  const LiveMediaToken({
    required this.appId,
    required this.token,
    required this.expiresAt,
  });

  final String appId;
  final String token;
  final DateTime expiresAt;
}
