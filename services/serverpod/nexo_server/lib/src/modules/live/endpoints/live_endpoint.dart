import 'package:serverpod/serverpod.dart';

import '../../../generated/protocol.dart';
import '../services/live_rules.dart';
import '../services/live_service.dart';

/// Vivos: programar, iniciar, terminar, mirar y chatear. Desde Flutter:
/// `client.live`.
///
/// Mirar es público: un invitado ve los shows y su chat. Todo lo que escribe
/// exige sesión y responde [NexoException] con el código del motivo. Lo que
/// cambia llega en tiempo real por [watch] y [watchIndex].
class LiveEndpoint extends Endpoint {
  static final _live = LiveService();

  /// Programa un show. Sólo un creador verificado con la cuenta activa.
  Future<LiveShowView> schedule(Session session, LiveShowDraft draft) =>
      _live.schedule(session, draft);

  /// Pone el show al aire. Sólo el host, creador verificado y activo, y sin
  /// otro vivo al aire.
  Future<LiveShowView> start(Session session, int showId) =>
      _live.start(session, showId);

  /// Termina el vivo y lo deja como replay. El host o un operador.
  Future<LiveShowView> end(Session session, int showId) =>
      _live.end(session, showId);

  /// Publica el replay. El host o un operador, si el show guarda replay.
  Future<LiveShowView> publish(Session session, int showId) =>
      _live.publish(session, showId);

  /// Cancela un show que todavía no arrancó. El host o un operador.
  Future<LiveShowView> cancel(Session session, int showId) =>
      _live.cancel(session, showId);

  /// "Transmitir ahora": crea el show y lo pone al aire en un paso. El mismo
  /// gate que [start]: creador verificado, activo y sin otro vivo al aire.
  Future<LiveShowView> goLive(Session session, String title) =>
      _live.goLive(session, title);

  /// La credencial para entrar al canal de video del show. El servidor
  /// decide el rol: publica sólo el host con el show al aire.
  Future<LiveMediaGrant> mediaToken(Session session, int showId) =>
      _live.mediaToken(session, showId);

  /// Un show. `notFound` si no existe o se retiró.
  Future<LiveShowView> get(Session session, int showId) =>
      _live.get(session, showId);

  /// Al aire, programados y replays, en ese orden (hasta 50).
  Future<List<LiveShowView>> list(Session session) => _live.list(session);

  /// Los shows de la cuenta de la sesión, en cualquier estado.
  Future<List<LiveShowView>> mine(Session session) => _live.mine(session);

  /// El rol de quien pide dentro del show. Sin sesión, `audience`.
  Future<LiveShowRole> roleIn(Session session, int showId) =>
      _live.roleIn(session, showId);

  /// Chat sin los mensajes ocultos, del más viejo al más nuevo (50 por
  /// página). [beforeId] para pedir los anteriores.
  Future<List<LiveChatMessageView>> chatHistory(
    Session session,
    int showId, {
    int? beforeId,
  }) => _live.chatHistory(session, showId, beforeId: beforeId);

  /// Manda un mensaje al chat. El show tiene que estar al aire; un mensaje
  /// por segundo por cuenta.
  Future<LiveChatMessageView> sendChat(
    Session session,
    int showId,
    String body,
  ) => _live.sendChat(session, showId, body);

  /// Oculta un mensaje. El host del show, un moderador o un operador.
  Future<void> hideChat(Session session, int messageId) =>
      _live.hideChat(session, messageId);

  // --- Escenario (SDD 0011) -------------------------------------------------
  //
  // Todo exige sesión activa y el show al aire, y responde `forbidden` si el
  // rol en la sala no lo permite (la tabla de `LivePermissions`). Los cambios
  // llegan por [watch] como `stage` y, si cambió un rol, `roleChanged`.

  /// Quién está en el escenario y quién pidió la palabra.
  Future<LiveStageView> stage(Session session, int showId) =>
      _live.stage(session, showId);

  /// Pedir la palabra. Oyentes y moderador.
  Future<void> raiseHand(Session session, int showId) =>
      _live.stageService.raiseHand(session, showId);

  /// Retirar el pedido propio.
  Future<void> lowerHand(Session session, int showId) =>
      _live.stageService.lowerHand(session, showId);

  /// Subir a quien pidió la palabra. Host o moderador; `conflict` si no la
  /// pidió o si el escenario está lleno.
  Future<void> approveRequest(Session session, int showId, UuidValue userId) =>
      _live.stageService.approveRequest(session, showId, userId);

  /// Rechazar un pedido de palabra. Host o moderador.
  Future<void> denyRequest(Session session, int showId, UuidValue userId) =>
      _live.stageService.denyRequest(session, showId, userId);

  /// Subir a alguien directo. Sólo el host.
  Future<void> inviteToStage(Session session, int showId, UuidValue userId) =>
      _live.stageService.inviteToStage(session, showId, userId);

  /// Bajar a alguien del escenario. Sólo el host.
  Future<void> removeFromStage(
    Session session,
    int showId,
    UuidValue userId,
  ) => _live.stageService.removeFromStage(session, showId, userId);

  /// Bajarse del escenario.
  Future<void> leaveStage(Session session, int showId) =>
      _live.stageService.leaveStage(session, showId);

  /// El micrófono propio, o silenciar el de otro (host o moderador, sólo
  /// para apagarlo).
  Future<void> setMicMuted(
    Session session,
    int showId,
    UuidValue userId,
    bool muted,
  ) => _live.stageService.setMicMuted(session, showId, userId, muted);

  /// La cámara propia, estando en el escenario.
  Future<void> setCamera(Session session, int showId, bool on) =>
      _live.stageService.setCamera(session, showId, on);

  /// Lo que pasa en un show, en tiempo real. El primer evento es
  /// `snapshot`; después llegan `status`, `viewers`, `chat`, `chatHidden`,
  /// `stage` y `roleChanged`.
  /// Mientras la conexión está abierta, cuenta como espectador.
  Stream<LiveEvent> watch(Session session, int showId) async* {
    // Primero la suscripción y después la foto: en el orden inverso, un
    // mensaje que llega entre leer la historia y suscribirse se pierde.
    // `createStream` guarda lo que llega hasta que se lo escucha.
    final events = session.messages.createStream<LiveEvent>(
      LiveChannels.show(showId),
    );
    final show = await _live.requireVisible(session, showId);

    // La baja se registra dos veces a propósito: el listener corre aunque la
    // sesión se cierre sin cancelar el stream, y el `finally` cubre la
    // cancelación normal. `leaveAudience` es idempotente.
    session.addWillCloseListener(
      (closing) => _live.leaveAudience(closing, showId),
    );
    await _live.joinAudience(session, show);
    try {
      yield await _live.snapshot(session, show);
      yield* events;
    } finally {
      await _live.leaveAudience(session, showId);
    }
  }

  /// Cada cambio de estado de cualquier show: para que la lista de "en vivo"
  /// se actualice sola en todos los dispositivos.
  Stream<LiveShowView> watchIndex(Session session) =>
      session.messages.createStream<LiveShowView>(LiveChannels.index);
}
