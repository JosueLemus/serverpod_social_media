import 'package:flutter/material.dart';

import '../../../../app/theme/app_tokens.dart';
import '../../../../core/widgets/nexo_icon.dart';
import '../../../../core/widgets/nexo_mascot.dart';
import '../../../../core/widgets/pills.dart';
import '../../../../core/widgets/sticker.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../domain/entities/live_session.dart';
import '../children/schedule_show/presentation/utils/show_date_format.dart';
import '../utils/live_status_ui.dart';

/// El borde de sticker que le toca a cada estado de un vivo.
///
/// Es el mismo vocabulario de toda la app: el foil holográfico es sólo para
/// lo que está al aire, la línea punteada para lo que sigue en la plancha, el
/// troquel blanco para el replay, y lo cerrado queda del dorso.
extension LiveStatusSticker on LiveStatus {
  StickerEdge get stickerEdge => switch (this) {
    LiveStatus.live || LiveStatus.ending => StickerEdge.holo,
    LiveStatus.draft || LiveStatus.scheduled => StickerEdge.dashed,
    LiveStatus.recorded || LiveStatus.published => StickerEdge.kissCut,
    LiveStatus.cancelled ||
    LiveStatus.failed ||
    LiveStatus.removed => StickerEdge.none,
  };
}

/// Una sesión en una lista: la media como sticker con el borde de su estado,
/// y debajo título y host, directo sobre el liner.
class LiveCard extends StatelessWidget {
  const LiveCard({super.key, required this.session, required this.onTap});

  final LiveSession session;

  /// Null la deja quieta: la vista previa de "Programar show" dibuja la misma
  /// tarjeta, pero ahí todavía no hay nada que abrir.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    // Sin recorte en el Material: la insignia asoma por encima del borde de
    // la media, y un recorte redondeado se comería su esquina. El InkWell
    // recorta su propia onda con el radio.
    return Material(
      key: Key('live-${session.id}'),
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.medium,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LiveThumbnail(session: session),
            const SizedBox(height: AppSpacing.sm),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                UserAvatar(
                  name: session.hostName,
                  imageUrl: session.hostAvatarUrl,
                  size: 36,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        session.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: text.titleMedium,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        session.hostName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.bodySmall,
                      ),
                    ],
                  ),
                ),
                if (session.isPremium) ...[
                  const SizedBox(width: AppSpacing.xs),
                  // Dentro de la fila de texto: derecha, no torcida.
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: StatusBadge(
                      label: 'Pro',
                      color: AppColors.vinylLime,
                      foreground: AppColors.ink,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: AppSpacing.xxs),
          ],
        ),
      ),
    );
  }
}

/// La media de un vivo como sticker: el borde dice el estado y la insignia va
/// pegada encima de la esquina. Pública porque la comparten la tarjeta de
/// lista y la destacada del feed.
class LiveThumbnail extends StatelessWidget {
  const LiveThumbnail({
    super.key,
    required this.session,
    this.aspectRatio = 16 / 9,
    this.featured = false,
  });

  final LiveSession session;
  final double aspectRatio;

  /// La destacada del feed: escenario oscuro con el gato en vez del glifo.
  final bool featured;

  /// Cuánto asoma la insignia por encima del borde.
  static const badgeOverhang = 10.0;

  @override
  Widget build(BuildContext context) {
    final status = session.status;
    final media = AspectRatio(
      aspectRatio: aspectRatio,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // TODO(backend): la miniatura real cuando el vivo tenga portada.
          if (featured)
            _StagePlaceholder(status: status)
          else
            _GlyphPlaceholder(session: session),
          // Una sesión programada no tiene audiencia todavía. Su `viewers` es
          // interés, no reproducciones, y mostrarlo tras un ícono de play se
          // lee como "120 personas ya lo vieron" de algo que no empezó.
          if (status != LiveStatus.scheduled && !status.isClosed)
            Positioned(
              bottom: AppSpacing.xs,
              right: AppSpacing.xs,
              child: ViewerPill(
                viewers: session.viewers,
                isOnAir: status.isOnAir,
              ),
            ),
        ],
      ),
    );
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: badgeOverhang),
          child: StickerFrame(
            edge: status.stickerEdge,
            fill: featured && !status.isClosed
                ? AppColors.stageDark
                : AppColors.linerHigh,
            child: media,
          ),
        ),
        Positioned(
          top: 0,
          left: AppSpacing.sm,
          child: LiveStatusBadge(status: status),
        ),
      ],
    );
  }
}

/// La insignia de estado de un vivo. Pegada sobre la media va torcida, como
/// pegada a mano; sólo la de lo que está al aire late.
class LiveStatusBadge extends StatelessWidget {
  const LiveStatusBadge({super.key, required this.status, this.tilt = -.06});

  final LiveStatus status;
  final double tilt;

  @override
  Widget build(BuildContext context) => StatusBadge(
    label: status.label,
    // El rojo con blanco es sólo para EN VIVO. El resto es vinilo con tinta.
    color: status.isOnAir ? AppColors.secondary : status.color,
    foreground: status.isOnAir ? AppColors.sticker : AppColors.ink,
    pulse: status.isOnAir,
    tilt: tilt,
  );
}

/// Sin portada, la media de la destacada es el escenario con el gato.
class _StagePlaceholder extends StatelessWidget {
  const _StagePlaceholder({required this.status});

  final LiveStatus status;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final side = (constraints.maxHeight * .64).clamp(48.0, 150.0);
      return Center(
        child: status.isClosed
            ? const NexoIcon(
                NexoGlyph.hidden,
                size: 40,
                color: AppColors.textSecondary,
              )
            : MascotIllustration(
                status == LiveStatus.scheduled || status == LiveStatus.draft
                    ? NexoMascot.calendar
                    : NexoMascot.camera,
                size: side,
              ),
      );
    },
  );
}

/// Sin portada, la media de una tarjeta de lista es el glifo de su estado.
class _GlyphPlaceholder extends StatelessWidget {
  const _GlyphPlaceholder({required this.session});

  final LiveSession session;

  @override
  Widget build(BuildContext context) {
    final status = session.status;
    final glyph = switch (status) {
      LiveStatus.live || LiveStatus.ending => NexoGlyph.live,
      LiveStatus.draft || LiveStatus.scheduled => NexoGlyph.calendar,
      LiveStatus.recorded || LiveStatus.published => NexoGlyph.play,
      LiveStatus.cancelled ||
      LiveStatus.failed ||
      LiveStatus.removed => NexoGlyph.hidden,
    };
    final startsAt = session.scheduledAt;
    final minutes = session.durationMinutes;
    final scheduled = status == LiveStatus.scheduled && startsAt != null;
    final text = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            NexoIcon(
              glyph,
              size: scheduled ? 30 : 40,
              color: AppColors.textSecondary,
            ),
            if (scheduled) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                '${ShowDateFormat.shortDate(startsAt)} · '
                '${ShowDateFormat.time(startsAt)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: text.titleLarge?.copyWith(
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              if (minutes != null) ...[
                const SizedBox(height: 2),
                Text(
                  ShowDateFormat.duration(minutes),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.labelSmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

/// La audiencia sobre la media: una pastilla oscura que se lee sobre video.
class ViewerPill extends StatelessWidget {
  const ViewerPill({
    super.key,
    required this.viewers,
    required this.isOnAir,
    this.light = false,
  });

  final int viewers;
  final bool isOnAir;

  /// Sobre el liner en vez de sobre video.
  final bool light;

  @override
  Widget build(BuildContext context) {
    final foreground = light ? AppColors.textPrimary : AppColors.sticker;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: light ? AppColors.linerHigh : AppColors.stageScrim,
        borderRadius: AppRadii.pill,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          NexoIcon(
            isOnAir ? NexoGlyph.profile : NexoGlyph.play,
            filled: true,
            size: 12,
            color: foreground,
          ),
          const SizedBox(width: 4),
          Text(
            compactCount(viewers),
            style: TextStyle(
              color: foreground,
              fontSize: 11,
              height: 1.1,
              fontWeight: FontWeight.w900,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
