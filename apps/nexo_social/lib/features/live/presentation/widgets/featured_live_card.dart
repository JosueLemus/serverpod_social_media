import 'package:flutter/material.dart';

import '../../../../app/theme/app_tokens.dart';
import '../../../../core/widgets/pills.dart';
import '../../domain/entities/live_session.dart';
import '../utils/live_status_ui.dart';
import 'live_card.dart';

/// La tarjeta destacada que abre el feed cuando alguien está transmitiendo.
///
/// Es la única tarjeta del feed con un CTA propio: entrar a un vivo es
/// urgente de un modo que ninguna otra fila lo es, y enterrarla entre posts
/// hace que se pierda justo mientras está pasando.
class FeaturedLiveCard extends StatelessWidget {
  const FeaturedLiveCard({
    super.key,
    required this.session,
    required this.hostUsername,
    required this.onJoin,
  });

  final LiveSession session;
  final String hostUsername;
  final VoidCallback onJoin;

  @override
  Widget build(BuildContext context) => Card(
    key: Key('featured-live-${session.id}'),
    clipBehavior: Clip.antiAlias,
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Wrap y no Row: a 320 las tres insignias no entran en una línea, y
          // un Row recorta la última en silencio. Acá baja de renglón.
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              StatusBadge(label: session.status.label, pulse: true),
              ViewerPill(viewers: session.viewers, isOnAir: true, light: true),
              const StatusBadge(
                label: 'Destacado',
                color: AppColors.primarySurface,
                foreground: AppColors.textOnBrandSurface,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: AppRadii.small,
                child: SizedBox(
                  width: 96,
                  // Sin el chrome de la miniatura de lista: los badges ya
                  // están arriba y repetirlos sobre una imagen de 96 px los
                  // deja ilegibles.
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: DecoratedBox(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [AppColors.primaryDeep, AppColors.primary],
                        ),
                      ),
                      child: Icon(
                        Icons.play_circle_fill_rounded,
                        color: Colors.white.withValues(alpha: .9),
                        size: 30,
                      ),
                    ),
                  ),
                ),
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
                      style: Theme.of(
                        context,
                      ).textTheme.titleLarge?.copyWith(fontSize: 16),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            'por @$hostUsername',
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.verified_rounded,
                          size: 13,
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  key: const Key('join-featured-live'),
                  onPressed: onJoin,
                  icon: const Icon(Icons.sensors_rounded, size: 18),
                  label: const Text('Unirme al Live'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, AppSizes.buttonHeightDense),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              IconButton(
                tooltip: 'Compartir',
                onPressed: () {},
                icon: const Icon(Icons.ios_share_rounded, size: 20),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
