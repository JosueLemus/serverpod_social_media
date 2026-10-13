import 'package:flutter/material.dart';

import '../../../../app/theme/app_tokens.dart';
import '../../../../core/widgets/nexo_icon.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../domain/entities/account_detail.dart';
import '../../domain/entities/audit_entry.dart';
import '../bloc/admin_feedback.dart';

/// Cómo se presentan los valores de dominio de la consola. Un enum nunca se
/// pinta con `.name`: es el identificador de Dart, en inglés.
///
/// Cada estado trae su par vinilo/tinta: `color` es el relleno de la
/// insignia y `foreground` lo que va encima. Los vinilos claros llevan tinta;
/// sólo el rojo lleva blanco, porque la tinta sobre rojo no llega al
/// contraste.
extension UserRoleUI on UserRole {
  String get label => switch (this) {
    UserRole.visitor => 'Invitado',
    UserRole.user => 'Usuario',
    UserRole.moderator => 'Moderador',
    UserRole.operator => 'Operador',
  };

  /// El glifo del scope: el mismo que la entrada del rail a la que da acceso.
  NexoGlyph get glyph => switch (this) {
    UserRole.visitor || UserRole.user => NexoGlyph.profile,
    UserRole.moderator => NexoGlyph.moderation,
    UserRole.operator => NexoGlyph.console,
  };
}

extension AccountStatusUI on AccountStatus {
  String get label => switch (this) {
    AccountStatus.active => 'Activa',
    AccountStatus.suspended => 'Suspendida',
    AccountStatus.banned => 'Baneada',
  };

  Color get color => switch (this) {
    AccountStatus.active => AppColors.vinylGreen,
    AccountStatus.suspended => AppColors.warning,
    AccountStatus.banned => AppColors.error,
  };

  Color get foreground => switch (this) {
    AccountStatus.banned => AppColors.sticker,
    AccountStatus.active || AccountStatus.suspended => AppColors.ink,
  };
}

extension VerificationStatusUI on VerificationStatus {
  String get label => switch (this) {
    VerificationStatus.none => 'Sin verificar',
    VerificationStatus.verified => 'Verificado',
    VerificationStatus.revoked => 'Verificación revocada',
  };

  Color get color => switch (this) {
    VerificationStatus.verified => AppColors.vinylCyan,
    VerificationStatus.revoked => AppColors.error,
    VerificationStatus.none => AppColors.textSecondary,
  };

  Color get foreground => switch (this) {
    VerificationStatus.revoked => AppColors.sticker,
    VerificationStatus.verified || VerificationStatus.none => AppColors.ink,
  };
}

/// Una sanción en el historial. La suspensión es el candado abierto a
/// revisión (contorno); el baneo, el candado cerrado del todo (relleno).
extension SanctionKindUI on SanctionKind {
  NexoGlyph get glyph => switch (this) {
    SanctionKind.mute => NexoGlyph.micOff,
    SanctionKind.suspension || SanctionKind.ban => NexoGlyph.lock,
  };

  bool get glyphFilled => this == SanctionKind.ban;

  Color get color => switch (this) {
    SanctionKind.mute => AppColors.vinylViolet,
    SanctionKind.suspension => AppColors.warning,
    SanctionKind.ban => AppColors.error,
  };

  Color get foreground => switch (this) {
    SanctionKind.ban => AppColors.sticker,
    SanctionKind.mute || SanctionKind.suspension => AppColors.ink,
  };
}

/// Una fila de la auditoría. Sólo las acciones que cambian lo que alguien
/// puede hacer llevan color; el resto queda en gris, para que una página de
/// registro se lea de un vistazo y no como una plancha de alarmas.
extension AuditActionUI on AuditAction {
  NexoGlyph get glyph => switch (this) {
    AuditAction.reportFiled || AuditAction.reportDismissed => NexoGlyph.flag,
    AuditAction.commentHidden => NexoGlyph.hidden,
    AuditAction.userMuted => NexoGlyph.micOff,
    AuditAction.userKicked => NexoGlyph.close,
    AuditAction.accountSuspended || AuditAction.accountBanned => NexoGlyph.lock,
    AuditAction.accountRestored => NexoGlyph.profile,
    AuditAction.verificationGranted ||
    AuditAction.verificationRevoked => NexoGlyph.verified,
    AuditAction.liveStarted ||
    AuditAction.liveEnded ||
    AuditAction.liveForceEnded => NexoGlyph.live,
  };

  bool get glyphFilled => this == AuditAction.accountBanned;

  Color get tone => switch (this) {
    AuditAction.accountSuspended || AuditAction.userMuted => AppColors.warning,
    AuditAction.accountBanned ||
    AuditAction.verificationRevoked ||
    AuditAction.liveForceEnded ||
    AuditAction.userKicked => AppColors.error,
    AuditAction.accountRestored ||
    AuditAction.verificationGranted => AppColors.vinylGreen,
    _ => AppColors.textSecondary,
  };
}

/// Los botones de la consola. Una consola es densa (44 de alto, no 52) y
/// separa sin ambigüedad lo seguro de lo destructivo: el sticker blanco del
/// tema es la acción segura; lo que saca a alguien de la app va en rojo, con
/// relleno si es la acción principal o contorneado si no lo es. Nunca un
/// sticker blanco para algo que no se deshace solo.
abstract final class AdminButtons {
  /// Sticker blanco denso: la acción segura de una fila.
  static final safe = FilledButton.styleFrom(
    minimumSize: const Size(0, AppSizes.buttonHeightDense),
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
  );

  /// Contorno neutro denso: una acción segura secundaria.
  static final quiet = OutlinedButton.styleFrom(
    minimumSize: const Size(0, AppSizes.buttonHeightDense),
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
  );

  /// Relleno rojo con blanco: la acción destructiva principal.
  static ButtonStyle get destructiveFill => FilledButton.styleFrom(
    backgroundColor: AppColors.error,
    foregroundColor: AppColors.onError,
    iconColor: AppColors.onError,
    minimumSize: const Size(0, AppSizes.buttonHeightDense),
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
  );

  /// Contorno rojo: lo destructivo que no es la acción principal.
  static ButtonStyle get destructiveOutline => OutlinedButton.styleFrom(
    foregroundColor: AppColors.error,
    iconColor: AppColors.error,
    side: BorderSide(color: AppColors.error, width: 1.6),
    minimumSize: const Size(0, AppSizes.buttonHeightDense),
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
  );
}

extension AdminIssueUI on AdminIssue {
  String get message => switch (this) {
    AdminIssue.forbidden =>
      'Tu cuenta no tiene permisos de operador. El servidor rechazó la '
          'solicitud.',
    AdminIssue.conflict =>
      'Esa acción no es posible desde el estado actual de la cuenta.',
    AdminIssue.notFound => 'Lo que buscas ya no existe.',
    AdminIssue.other => 'No pudimos completar la acción.',
  };
}

extension AdminNoticeUI on AdminNotice {
  String get message => switch (this) {
    AdminNotice.suspended =>
      'Cuenta suspendida. Sus sesiones activas se cerraron.',
    AdminNotice.banned => 'Cuenta baneada de forma permanente.',
    AdminNotice.restored => 'Cuenta restaurada.',
    AdminNotice.verified => 'Verificación otorgada.',
    AdminNotice.verificationRevoked =>
      'Verificación revocada. Ya no puede iniciar vivos.',
    AdminNotice.liveEnded => 'Vivo finalizado. Quedó registrado.',
    AdminNotice.demoReset =>
      'Datos de la demo reiniciados. Las cuentas vuelven a su estado inicial.',
  };
}
