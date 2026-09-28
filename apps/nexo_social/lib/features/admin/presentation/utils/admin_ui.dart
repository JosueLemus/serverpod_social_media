import 'package:flutter/material.dart';

import '../../../../app/theme/app_tokens.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../bloc/admin_feedback.dart';

/// Cómo se presentan los valores de dominio de la consola. Un enum nunca se
/// pinta con `.name`: es el identificador de Dart, en inglés.
extension UserRoleUI on UserRole {
  String get label => switch (this) {
    UserRole.visitor => 'Invitado',
    UserRole.user => 'Usuario',
    UserRole.moderator => 'Moderador',
    UserRole.operator => 'Operador',
  };
}

extension AccountStatusUI on AccountStatus {
  String get label => switch (this) {
    AccountStatus.active => 'Activa',
    AccountStatus.suspended => 'Suspendida',
    AccountStatus.banned => 'Baneada',
  };

  Color get color => switch (this) {
    AccountStatus.active => AppColors.success,
    AccountStatus.suspended => AppColors.warning,
    AccountStatus.banned => AppColors.error,
  };
}

extension VerificationStatusUI on VerificationStatus {
  String get label => switch (this) {
    VerificationStatus.none => 'Sin verificar',
    VerificationStatus.verified => 'Verificado',
    VerificationStatus.revoked => 'Verificación revocada',
  };

  Color get color => switch (this) {
    VerificationStatus.verified => AppColors.primaryDeep,
    VerificationStatus.revoked => AppColors.error,
    VerificationStatus.none => AppColors.textSecondary,
  };
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
  };
}
