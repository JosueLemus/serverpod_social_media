import '../../../auth/domain/entities/app_user.dart';
import '../../../live/domain/entities/live_session.dart';
import '../../../moderation/domain/entities/moderation_action.dart';
import '../entities/account_detail.dart';
import '../entities/audit_entry.dart';

/// La consola del operador. **Cada método exige el rol de operador** y lanza
/// `ForbiddenFailure` si quien llama no lo tiene — aunque haya llegado a la
/// pantalla escribiendo la URL a mano.
///
/// Toda mutación queda auditada en la misma operación: se aplican las dos
/// cosas o ninguna.
abstract interface class AdminRepository {
  /// Por correo, usuario o id. Vacío devuelve todas las cuentas.
  Future<ResultPage<AppUser>> searchAccounts(String query, {String? cursor});

  Future<AccountDetail> account(String accountId);

  /// Revoca las sesiones activas de la cuenta: quien está adentro queda
  /// afuera en ese momento.
  Future<void> suspend(String accountId, ModerationReason reason);

  /// Permanente. No se restaura desde la consola.
  Future<void> ban(String accountId, ModerationReason reason);

  /// Levanta una suspensión. Lanza `ConflictFailure` sobre un baneo.
  Future<void> restore(String accountId);

  /// Revocar exige [reason]; otorgar no.
  Future<void> setVerification(
    String accountId, {
    required bool verified,
    ModerationReason? reason,
  });

  /// Creadores con su estado de verificación, los no verificados primero.
  Future<List<AppUser>> creators();

  Future<List<LiveSession>> activeLives();

  Future<void> forceEndLive(String liveId, ModerationReason reason);

  /// Más reciente primero.
  Future<ResultPage<AuditEntry>> audit(AuditFilter filter, {String? cursor});

  /// Emite cada vez que cambia algo que la consola muestra.
  Stream<void> changes();
}
