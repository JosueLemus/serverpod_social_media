import 'package:flutter/material.dart';

import '../../../../app/theme/app_tokens.dart';
import '../../../../core/widgets/nexo_icon.dart';
import '../../domain/entities/app_notification.dart';

/// Ícono, color y copy de cada tipo.
///
/// Presentación, no dominio: un `Color` o un glifo en el enum arrastraría
/// `package:flutter` a la capa de dominio, cuyo sentido es poder razonarse —y
/// testearse— sin un toolkit de UI.
extension NotificationTypeUI on NotificationType {
  NexoGlyph get glyph => switch (this) {
    NotificationType.like => NexoGlyph.heart,
    NotificationType.follow => NexoGlyph.profile,
    NotificationType.comment => NexoGlyph.comment,
    NotificationType.liveReminder => NexoGlyph.live,
    NotificationType.showSoon => NexoGlyph.calendar,
    NotificationType.membership => NexoGlyph.crown,
    NotificationType.moderation => NexoGlyph.moderation,
  };

  /// El vinilo del disco y de la insignia. Rojo sólo para lo que está al
  /// aire y para la reacción: es la marca de en vivo, no un color de relleno
  /// cualquiera. Moderación va en lima, el color del staff, y no en ámbar:
  /// un reporte resuelto no es una advertencia.
  Color get color => switch (this) {
    NotificationType.like => AppColors.secondary,
    NotificationType.liveReminder => AppColors.secondary,
    NotificationType.showSoon => AppColors.vinylCyan,
    NotificationType.membership => AppColors.vinylGreen,
    NotificationType.moderation => AppColors.vinylLime,
    NotificationType.follow => AppColors.vinylViolet,
    NotificationType.comment => AppColors.vinylBlue,
  };

  /// El texto de la insignia encima de [color]. Los vinilos llevan tinta; el
  /// rojo de "En vivo", blanco. El glifo del disco va siempre en tinta.
  Color get foreground => switch (this) {
    NotificationType.like || NotificationType.liveReminder => AppColors.sticker,
    _ => AppColors.ink,
  };

  /// La insignia que la fila muestra junto al actor, cuando el tipo tiene algo
  /// urgente que declarar. Null en los que no: una insignia en todas las filas
  /// deja de destacar ninguna.
  String? get badge => switch (this) {
    NotificationType.liveReminder => 'En vivo',
    NotificationType.showSoon => 'Empieza pronto',
    NotificationType.membership => 'Miembro Pro',
    _ => null,
  };
}

/// La frase de cada aviso. La arma la View con los datos del aviso: el
/// servidor manda qué pasó, no cómo decirlo.
extension AppNotificationUI on AppNotification {
  /// Quién aparece en la fila. Los avisos del sistema no tienen actor.
  String get actorLabel => actor ?? 'Nexo';

  String get sentence {
    final about = subject;
    return switch (type) {
      NotificationType.like =>
        about == null
            ? 'Le gustó tu publicación'
            : 'Le gustó tu publicación "$about"',
      NotificationType.follow => 'Comenzó a seguirte',
      NotificationType.comment =>
        about == null
            ? 'Comentó tu publicación'
            : 'Comentó tu publicación "$about"',
      NotificationType.liveReminder =>
        about == null ? 'Está en vivo ahora' : 'Está en vivo: "$about"',
      NotificationType.showSoon =>
        about == null
            ? 'Su show empieza en 15 minutos'
            : '"$about" empieza en 15 minutos',
      NotificationType.membership => 'Se unió a tu comunidad',
      NotificationType.moderation => 'Se resolvió un reporte que hiciste',
    };
  }

  /// Hacia dónde lleva tocarlo. Null es que el aviso se lee y no lleva a
  /// ningún lado.
  NotificationDestination? get destination => switch (type) {
    NotificationType.liveReminder || NotificationType.showSoon =>
      showId == null ? null : NotificationDestination.live,
    NotificationType.follow =>
      actorUsername == null ? null : NotificationDestination.actorProfile,
    // A la publicación que recibió el like o el comentario. Sin id (un aviso
    // del mock), al perfil propio, donde está la publicación.
    NotificationType.like || NotificationType.comment =>
      postId == null
          ? NotificationDestination.ownProfile
          : NotificationDestination.post,
    NotificationType.membership || NotificationType.moderation => null,
  };

  /// El botón de la fila. Hace lo mismo que tocarla, dicho con la acción
  /// concreta.
  String? get actionLabel => switch (destination) {
    NotificationDestination.live => 'Ver ahora',
    NotificationDestination.actorProfile => 'Ver perfil',
    NotificationDestination.post => 'Ver publicación',
    NotificationDestination.ownProfile || null => null,
  };
}

enum NotificationDestination { live, actorProfile, post, ownProfile }
