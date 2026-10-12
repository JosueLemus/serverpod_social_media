import 'package:flutter/material.dart';

import '../../../../app/theme/app_tokens.dart';
import '../../../../core/widgets/sticker.dart';
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

  /// The badge fill. On air is the live red (`secondary`): it is the mark of
  /// "happening now", not a failure, so it is not named `error`.
  Color get color => switch (this) {
    LiveStatus.live || LiveStatus.ending => AppColors.secondary,
    LiveStatus.scheduled => AppColors.primary,
    LiveStatus.recorded || LiveStatus.published => AppColors.success,
    LiveStatus.cancelled ||
    LiveStatus.failed ||
    LiveStatus.removed => AppColors.textSecondary,
    LiveStatus.draft => AppColors.textSecondary,
  };

  /// The text on top of [color]. White only on the live red; every other
  /// fill is light enough to carry ink.
  Color get foreground => isOnAir ? AppColors.sticker : AppColors.ink;

  /// The sticker edge that says this state: holo only while on air, the
  /// dashed cut line while it is still on the sheet (scheduled or a draft),
  /// and the plain kiss-cut once it is over.
  StickerEdge get edge => switch (this) {
    LiveStatus.live || LiveStatus.ending => StickerEdge.holo,
    LiveStatus.draft || LiveStatus.scheduled => StickerEdge.dashed,
    LiveStatus.recorded ||
    LiveStatus.published ||
    LiveStatus.cancelled ||
    LiveStatus.failed ||
    LiveStatus.removed => StickerEdge.kissCut,
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
