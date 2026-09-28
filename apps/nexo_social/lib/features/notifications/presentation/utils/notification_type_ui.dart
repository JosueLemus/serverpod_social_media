import 'package:flutter/material.dart';

import '../../../../app/theme/app_tokens.dart';
import '../../domain/entities/app_notification.dart';

/// Ícono y color de cada tipo.
///
/// Presentación, no dominio: un `IconData` en el enum arrastraría
/// `package:flutter` a la capa de dominio, cuyo sentido es poder razonarse —y
/// testearse— sin un toolkit de UI.
extension NotificationTypeUI on NotificationType {
  IconData get icon => switch (this) {
    NotificationType.like => Icons.favorite_rounded,
    NotificationType.follow => Icons.person_add_alt_1_rounded,
    NotificationType.comment => Icons.chat_bubble_rounded,
    NotificationType.liveReminder => Icons.sensors_rounded,
    NotificationType.membership => Icons.workspace_premium_rounded,
    NotificationType.moderation => Icons.shield_rounded,
  };

  Color get color => switch (this) {
    NotificationType.like => AppColors.secondary,
    NotificationType.liveReminder => AppColors.secondary,
    NotificationType.membership => AppColors.tertiary,
    NotificationType.moderation => AppColors.warning,
    NotificationType.follow ||
    NotificationType.comment => AppColors.primaryDeep,
  };

  /// La insignia que la fila muestra junto al actor, cuando el tipo tiene algo
  /// urgente que declarar. Null en los que no: una insignia en todas las filas
  /// deja de destacar ninguna.
  String? get badge => switch (this) {
    NotificationType.liveReminder => 'En directo',
    NotificationType.membership => 'Miembro Pro',
    _ => null,
  };

  /// La acción inline. Es lo que convierte el centro de actividad en algo que
  /// se puede usar, y no sólo leer.
  String? get actionLabel => switch (this) {
    NotificationType.liveReminder => 'Ver ahora',
    NotificationType.follow => 'Seguir',
    NotificationType.comment => 'Responder',
    NotificationType.membership => 'Saludar',
    _ => null,
  };
}
