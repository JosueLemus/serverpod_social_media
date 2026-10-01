import 'package:serverpod/serverpod.dart';

import '../../../generated/protocol.dart';
import '../services/moderation_service.dart';

/// Reportes y cola de moderación. Desde Flutter: `client.moderation`.
///
/// Reportar lo puede hacer cualquiera con sesión. La cola y resolver exigen
/// el scope `moderator` o `admin`; si no, `forbidden`.
class ModerationEndpoint extends Endpoint {
  static const _moderation = ModerationService();

  /// Reporta un post o un comentario. La severidad la decide el servidor
  /// según [reason]. Repetir el mismo reporte no crea otro. No se puede
  /// reportar contenido propio.
  Future<void> report(
    Session session, {
    required ReportTargetType targetType,
    required int targetId,
    required ModerationReason reason,
    String? details,
  }) => _moderation.report(
    session,
    targetType: targetType,
    targetId: targetId,
    reason: reason,
    details: details,
  );

  /// Contenidos con reportes abiertos, uno por contenido, primero los más
  /// graves. Staff de moderación.
  Future<List<ReportQueueItem>> queue(Session session, {int? limit}) =>
      _moderation.queue(session, limit: limit);

  /// Oculta el contenido o descarta, y cierra todos sus reportes abiertos en
  /// un paso. Queda auditado. Staff de moderación.
  Future<void> resolve(
    Session session,
    int reportId,
    ReportDecision decision,
  ) => _moderation.resolve(session, reportId, decision);
}
