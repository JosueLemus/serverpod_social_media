import '../entities/moderation_action.dart';

/// Moderación sobre la plataforma. Cada método verifica el rol de quien
/// llama y lanza `ForbiddenFailure`: el guard del router es layout, no
/// seguridad.
abstract interface class ModerationRepository {
  /// Open reports, highest severity first. Moderator or operator.
  Future<List<ModerationReport>> reports();

  /// The moderation audit trail, newest first.
  Future<List<ModerationAction>> list();

  /// Cualquier cuenta activa puede reportar un comentario.
  Future<void> reportComment({
    required String liveId,
    required String commentId,
    required ModerationReason reason,
  });

  /// Aplica la decisión y cierra el reporte **en un paso**. Dos llamadas
  /// sueltas dejan ocultar un comentario sin cerrar su reporte, y el siguiente
  /// moderador revisa algo ya resuelto.
  Future<ModerationAction> resolve(
    String reportId,
    ModerationDecision decision,
  );

  /// Cierra el reporte como infundado. Queda auditado igual.
  Future<void> dismiss(String reportId);

  /// Emite cada vez que cambia algo que la cola o la auditoría muestran.
  Stream<void> changes();
}
