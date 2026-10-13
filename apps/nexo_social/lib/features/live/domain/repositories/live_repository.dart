import '../entities/live_comment.dart';
import '../entities/live_media_grant.dart';
import '../entities/live_moderation.dart';
import '../entities/live_room_event.dart';
import '../entities/live_session.dart';
import '../entities/live_stage.dart';

abstract interface class LiveRepository {
  Future<List<LiveSession>> list();

  /// Los vivos de la cuenta en sesión, en cualquier estado. Quién es la
  /// cuenta lo sabe el servidor por la sesión; el cliente no manda un id de
  /// host. Vacío si no hay sesión.
  Future<List<LiveSession>> mine();

  /// Null when the id does not resolve — a deep link to a removed session is
  /// a normal case, not an error the room should crash on.
  Future<LiveSession?> byId(String id);

  /// La máquina de estados es del servidor. Pasar a [LiveStatus.live] exige
  /// ser el host, creador **verificado** y con la cuenta activa; si no, lanza
  /// `CreatorNotVerifiedFailure` o `ForbiddenFailure`. Una transición ilegal
  /// desde el estado actual lanza `ConflictFailure`.
  Future<LiveSession> transition(String id, LiveStatus status);

  /// "Transmitir ahora": crea el vivo y lo pone al aire en un paso. El mismo
  /// gate que pasar a [LiveStatus.live]: `CreatorNotVerifiedFailure`,
  /// `AccountSuspendedFailure` o `ConflictFailure` si ya hay otro al aire.
  Future<LiveSession> goLive(String title);

  /// La credencial de video para [liveId]. El rol lo decide el servidor:
  /// con el vivo al aire publican el host y quien esté en el escenario. `ConflictFailure` si el vivo
  /// ya terminó.
  Future<LiveMediaGrant> mediaToken(String liveId);

  /// Visible comments, oldest first. Hidden ones never leave the server.
  Future<List<LiveComment>> comments(String liveId);

  /// Lanza `MutedFailure` si la cuenta tiene un silenciamiento vigente.
  Future<LiveComment> postComment(String liveId, String body);

  /// Oculta para toda la audiencia y conserva la evidencia. Host, moderador u
  /// operador.
  Future<void> hideComment(String liveId, String commentId);

  /// El rol de la sesión actual en esta sala.
  Future<LiveRole> roleIn(String liveId);

  // --- Escenario (SDD 0011) -----------------------------------------------
  //
  // Todo exige el vivo al aire (`ConflictFailure` si no) y lanza
  // `ForbiddenFailure` si el rol en la sala no lo permite: la tabla de
  // `LivePermissions`. Lo que cambia llega por [watch].

  /// Quién está en el escenario y quién pidió la palabra.
  Future<LiveStage> stage(String liveId);

  Future<void> raiseHand(String liveId);
  Future<void> lowerHand(String liveId);

  /// `ConflictFailure` si no pidió la palabra o si el escenario está lleno.
  Future<void> approveRequest(String liveId, String userId);
  Future<void> denyRequest(String liveId, String userId);

  /// Sólo el host. `ConflictFailure` si el escenario está lleno.
  Future<void> inviteToStage(String liveId, String userId);

  /// Sólo el host.
  Future<void> removeFromStage(String liveId, String userId);
  Future<void> leaveStage(String liveId);

  /// El micrófono propio, o silenciar el de otro (host o moderador, sólo
  /// para apagarlo: reactivarlo es de la persona).
  Future<void> setMicMuted(String liveId, String userId, {required bool muted});

  /// La cámara propia, estando en el escenario.
  Future<void> setCamera(String liveId, {required bool on});

  // --- Moderación de la sala (SDD 0011, Etapa 3) ---------------------------
  //
  // Mismas reglas: `ForbiddenFailure` si el rol no lo permite sobre esa
  // persona. Lo que cambia llega por [watch].

  /// Nombra al moderador, o lo quita con [userId] null. Sólo el host; también
  /// con el vivo programado.
  Future<void> assignModerator(String liveId, String? userId);

  Future<void> muteChat(
    String liveId,
    String userId,
    LiveMuteDuration duration,
  );
  Future<void> unmuteChat(String liveId, String userId);

  /// Fuera de este vivo.
  Future<void> kick(String liveId, String userId);

  /// Fuera de todos los vivos del host. Sólo el host.
  Future<void> ban(String liveId, String userId);

  /// Levanta un baneo de los vivos propios.
  Future<void> unban(String userId);

  /// Devuelve un comentario oculto. Uno borrado no vuelve.
  Future<void> unhideComment(String liveId, String commentId);

  /// Borra para todos y del replay; la evidencia queda en el servidor.
  Future<void> deleteComment(String liveId, String commentId);

  /// Fija un comentario, o lo despega con [commentId] null.
  Future<void> pinComment(String liveId, String? commentId);

  /// Destaca una pregunta, o la quita con [commentId] null.
  Future<void> highlightQuestion(String liveId, String? commentId);

  /// La sala en tiempo real. Lo primero es un [LiveRoomSnapshot]; después,
  /// cambios puntuales. Mientras alguien escucha, cuenta como espectador. Un
  /// vivo que no existe termina el stream con `NotFoundFailure`; un corte de
  /// red, con otro `Failure`, y la sala decide si reconecta.
  Stream<LiveRoomEvent> watch(String liveId);

  /// Emite cada vez que cambia un vivo: es lo que hace que la lista de "en
  /// vivo" de otro dispositivo se actualice sin recargar.
  Stream<void> changes();
}
