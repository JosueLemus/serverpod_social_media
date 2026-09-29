import '../entities/live_comment.dart';
import '../entities/live_session.dart';

abstract interface class LiveRepository {
  Future<List<LiveSession>> list();

  /// Null when the id does not resolve — a deep link to a removed session is
  /// a normal case, not an error the room should crash on.
  Future<LiveSession?> byId(String id);

  /// La máquina de estados es del servidor. Pasar a [LiveStatus.live] exige
  /// ser el host, creador **verificado** y con la cuenta activa; si no, lanza
  /// `CreatorNotVerifiedFailure` o `ForbiddenFailure`. Una transición ilegal
  /// desde el estado actual lanza `ConflictFailure`.
  Future<LiveSession> transition(String id, LiveStatus status);

  /// Visible comments, oldest first. Hidden ones never leave the server.
  Future<List<LiveComment>> comments(String liveId);

  /// Lanza `MutedFailure` si la cuenta tiene un silenciamiento vigente.
  Future<LiveComment> postComment(String liveId, String body);

  /// Oculta para toda la audiencia y conserva la evidencia. Host, moderador u
  /// operador.
  Future<void> hideComment(String liveId, String commentId);

  /// El rol de la sesión actual en esta sala.
  Future<LiveRole> roleIn(String liveId);

  /// Emite cada vez que cambia un vivo o su chat.
  Stream<void> changes();
}
