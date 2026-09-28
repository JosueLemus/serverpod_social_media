import 'package:flutter/material.dart';

import '../../../../app/theme/app_tokens.dart';
import '../../domain/entities/live_session.dart';

/// How a [LiveStatus] is presented.
///
/// The list used to print `status.name` straight into the subtitle, so users
/// read "live", "scheduled", "recorded" — backend identifiers, in English, in a
/// Spanish app. A status is a domain value; its label and colour are a
/// presentation concern and belong in exactly one place.
extension LiveStatusUI on LiveStatus {
  String get label => switch (this) {
    LiveStatus.draft => 'Borrador',
    LiveStatus.scheduled => 'Programado',
    LiveStatus.live => 'En vivo',
    LiveStatus.ending => 'Finalizando',
    LiveStatus.recorded => 'Grabado',
    LiveStatus.published => 'Replay',
    LiveStatus.cancelled => 'Cancelado',
    LiveStatus.failed => 'Falló',
    LiveStatus.removed => 'Eliminado',
  };

  Color get color => switch (this) {
    LiveStatus.live || LiveStatus.ending => AppColors.error,
    LiveStatus.scheduled => AppColors.primary,
    LiveStatus.recorded || LiveStatus.published => AppColors.success,
    LiveStatus.cancelled ||
    LiveStatus.failed ||
    LiveStatus.removed => AppColors.textSecondary,
    LiveStatus.draft => AppColors.textSecondary,
  };

  /// Whether the session is broadcasting right now — drives the pulsing dot
  /// and whether the room offers "entrar" or "ver replay".
  bool get isOnAir => this == LiveStatus.live || this == LiveStatus.ending;

  /// A terminal state nobody can join or resume.
  bool get isClosed =>
      this == LiveStatus.cancelled ||
      this == LiveStatus.failed ||
      this == LiveStatus.removed;
}
