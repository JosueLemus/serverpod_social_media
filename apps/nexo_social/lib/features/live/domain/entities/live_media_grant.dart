import 'package:equatable/equatable.dart';

/// Qué puede hacer la cuenta en el canal de video. Lo decide el servidor al
/// emitir el token; el cliente nunca pide ser publicador.
enum LiveMediaGrantRole { publisher, subscriber }

/// La credencial para entrar al canal de video de un vivo.
///
/// [token] vacío es el modo de prueba de Agora (proyecto sin certificado).
/// [appId] vacío quiere decir que el servidor no tiene App ID configurado y
/// la app usa el suyo.
class LiveMediaGrant extends Equatable {
  const LiveMediaGrant({
    required this.channel,
    required this.role,
    this.appId = '',
    this.uid = 0,
    this.token = '',
    this.expiresAt,
  });

  final String appId;
  final String channel;

  /// 0 deja que Agora asigne uno.
  final int uid;
  final String token;
  final LiveMediaGrantRole role;
  final DateTime? expiresAt;

  bool get isPublisher => role == LiveMediaGrantRole.publisher;

  @override
  List<Object?> get props => [appId, channel, uid, token, role, expiresAt];
}
