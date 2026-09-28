import 'package:flutter/material.dart';

import '../../../../app/theme/app_tokens.dart';
import '../../../../core/widgets/pills.dart';
import '../../domain/entities/live_session.dart';
import '../utils/live_status_ui.dart';

/// Una sesión en una lista: miniatura, estado y audiencia de un vistazo.
class LiveCard extends StatelessWidget {
  const LiveCard({super.key, required this.session, required this.onTap});

  final LiveSession session;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    key: Key('live-${session.id}'),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LiveThumbnail(session: session),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.xxs),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        session.hostName,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    if (session.isPremium)
                      const StatusBadge(
                        label: 'Pro',
                        color: AppColors.primarySurface,
                        foreground: AppColors.textOnBrandSurface,
                        icon: Icons.workspace_premium_outlined,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

/// La miniatura con su chrome. Pública porque la comparten la tarjeta de lista
/// y la tarjeta destacada del feed.
class LiveThumbnail extends StatelessWidget {
  const LiveThumbnail({
    super.key,
    required this.session,
    this.aspectRatio = 16 / 9,
  });

  final LiveSession session;
  final double aspectRatio;

  @override
  Widget build(BuildContext context) => AspectRatio(
    aspectRatio: aspectRatio,
    child: Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primaryDeep, AppColors.primary],
            ),
          ),
        ),
        Center(
          child: Icon(
            session.status.isOnAir
                ? Icons.sensors_rounded
                : Icons.play_circle_outline_rounded,
            size: 46,
            color: Colors.white.withValues(alpha: .85),
          ),
        ),
        Positioned(
          top: AppSpacing.xs,
          left: AppSpacing.xs,
          child: StatusBadge(
            label: session.status.label,
            color: session.status.color,
            // Sólo late lo que está al aire.
            pulse: session.status.isOnAir,
          ),
        ),
        // Una sesión programada no tiene audiencia todavía. Su `viewers` es
        // interés, no reproducciones, y mostrarlo tras un ícono de play se lee
        // como "120 personas ya lo vieron" de algo que no empezó.
        if (session.status != LiveStatus.scheduled)
          Positioned(
            bottom: AppSpacing.xs,
            right: AppSpacing.xs,
            child: ViewerPill(
              viewers: session.viewers,
              isOnAir: session.status.isOnAir,
            ),
          ),
      ],
    ),
  );
}

class ViewerPill extends StatelessWidget {
  const ViewerPill({
    super.key,
    required this.viewers,
    required this.isOnAir,
    this.light = false,
  });

  final int viewers;
  final bool isOnAir;

  /// Sobre una superficie clara en vez de sobre video.
  final bool light;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: 4),
    decoration: BoxDecoration(
      color: light
          ? AppColors.primarySurface
          : AppColors.neutral.withValues(alpha: .55),
      borderRadius: AppRadii.pill,
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isOnAir ? Icons.visibility_outlined : Icons.play_arrow_rounded,
          size: 13,
          color: light ? AppColors.textOnBrandSurface : Colors.white,
        ),
        const SizedBox(width: 4),
        Text(
          compactCount(viewers),
          style: TextStyle(
            color: light ? AppColors.textOnBrandSurface : Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}
