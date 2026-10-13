import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../app/theme/app_tokens.dart';
import '../../../../core/widgets/nexo_icon.dart';
import '../../../../core/widgets/pills.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../core/widgets/sticker.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../domain/entities/discovery.dart';

/// "Temas en tendencia": una plancha de stickers de hashtags.
///
/// Vive acá y no en el feed porque el diseño la muestra en tres lugares —
/// Explorar, el feed vacío y el panel de escritorio— y tres copias del mismo
/// bloque se separan.
class TrendingTopicsSection extends StatelessWidget {
  const TrendingTopicsSection({
    super.key,
    required this.topics,
    required this.onToggle,
    this.title = 'Temas en tendencia',
  });

  final List<TrendingTopic> topics;
  final ValueChanged<TrendingTopic> onToggle;
  final String title;

  @override
  Widget build(BuildContext context) {
    if (topics.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: title),
        // Wrap: los stickers bajan de renglón en vez de recortarse, y la
        // misma sección entra en el panel de escritorio de 288 de ancho.
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            for (final topic in topics)
              _TopicSticker(topic: topic, onTap: () => onToggle(topic)),
          ],
        ),
      ],
    );
  }
}

/// Un tema como sticker: vinilo con su troquel blanco mientras se puede
/// seguir, sticker blanco una vez seguido.
///
/// El "+" no es decoración: es lo que dice que tocarlo sigue el tema, y es
/// lo que separa los dos estados por forma y no sólo por color (un vinilo
/// cyan o lima está casi tan claro como el blanco).
class _TopicSticker extends StatelessWidget {
  const _TopicSticker({required this.topic, required this.onTap});

  final TrendingTopic topic;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final followed = topic.isFollowed;
    final text = Theme.of(context).textTheme;
    return Semantics(
      key: Key('topic-${topic.tag}'),
      button: true,
      selected: followed,
      // El troquel blanco suma 3 por lado: el chip de 38 queda en 44, que es
      // el mínimo de un blanco táctil.
      child: Container(
        padding: const EdgeInsets.all(AppStroke.kissCut),
        decoration: BoxDecoration(
          color: AppColors.cut,
          borderRadius: AppRadii.pill,
        ),
        child: Material(
          color: followed ? AppColors.sticker : vinylFor(topic.tag),
          shape: const StadiumBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Container(
              height: AppSizes.chipHeight,
              padding: EdgeInsets.only(
                left: followed ? AppSpacing.md : AppSpacing.sm,
                right: AppSpacing.md,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!followed) ...[
                    NexoIcon(NexoGlyph.add, size: 14, color: AppColors.ink),
                    const SizedBox(width: AppSpacing.xxs),
                  ],
                  Flexible(
                    child: Text(
                      '#${topic.tag}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.labelMedium?.copyWith(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    compactCount(topic.posts),
                    style: text.labelSmall?.copyWith(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w600,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// "Creadores recomendados": filas sobre el liner separadas por filetes.
///
/// Sin tarjeta alrededor: una lista densa se agrupa por espacio y filete, y
/// una tarjeta adentro de la página es un marco más que no dice nada.
class SuggestedCreatorsSection extends StatelessWidget {
  const SuggestedCreatorsSection({
    super.key,
    required this.creators,
    required this.onToggle,
    this.title = 'Creadores recomendados',
  });

  final List<SuggestedCreator> creators;
  final ValueChanged<SuggestedCreator> onToggle;
  final String title;

  @override
  Widget build(BuildContext context) {
    if (creators.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(title: title),
        for (final (index, creator) in creators.indexed) ...[
          if (index > 0) const Divider(height: 1),
          _CreatorRow(creator: creator, onToggle: () => onToggle(creator)),
        ],
      ],
    );
  }
}

class _CreatorRow extends StatelessWidget {
  const _CreatorRow({required this.creator, required this.onToggle});

  final SuggestedCreator creator;
  final VoidCallback onToggle;

  /// El lugar del avatar. Al aire el foil suma su anillo alrededor del
  /// sticker, así que la cara se achica para que todas las filas alineen el
  /// texto en la misma columna.
  static const _slot = 48.0;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return InkWell(
      onTap: () =>
          unawaited(context.push(AppRoutes.profileOf(creator.username))),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          children: [
            SizedBox.square(
              dimension: _slot,
              child: Center(
                child: UserAvatar(
                  name: creator.name,
                  imageUrl: creator.avatarUrl,
                  size: creator.isLive ? 40 : 44,
                  // El holo es la marca de "al aire" en toda la app: quien
                  // está transmitiendo se reconoce igual acá que en el feed.
                  onAir: creator.isLive,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          creator.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: text.titleSmall,
                        ),
                      ),
                      if (creator.isVerified) ...[
                        const SizedBox(width: AppSpacing.xxs),
                        NexoIcon(
                          NexoGlyph.verified,
                          size: 15,
                          color: AppColors.primary,
                          semanticLabel: 'Verificado',
                        ),
                      ],
                      if (creator.isPro) ...[
                        const SizedBox(width: 6),
                        StatusBadge(
                          label: 'Pro',
                          color: AppColors.vinylViolet,
                          foreground: AppColors.ink,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '@${creator.username} · ${creator.headline}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            _FollowButton(following: creator.isFollowed, onTap: onToggle),
          ],
        ),
      ),
    );
  }
}

/// Seguir/Siguiendo. Dos estilos, un solo control: sticker blanco mientras es
/// una invitación, contorno una vez aceptada — dejarlo blanco haría que la
/// fila siguiera pidiendo algo que ya se hizo.
///
/// Mismo ancho en los dos estados: si el botón cambiara de tamaño al tocarlo,
/// el nombre de al lado se reacomodaría bajo el dedo.
class _FollowButton extends StatelessWidget {
  const _FollowButton({required this.following, required this.onTap});

  final bool following;
  final VoidCallback onTap;

  static const _size = Size(104, AppSizes.buttonHeightDense);
  static const _padding = EdgeInsets.symmetric(horizontal: AppSpacing.sm);

  @override
  Widget build(BuildContext context) {
    final label = Theme.of(
      context,
    ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w800);
    return following
        ? OutlinedButton(
            onPressed: onTap,
            style: OutlinedButton.styleFrom(
              minimumSize: _size,
              padding: _padding,
              textStyle: label,
            ),
            child: const Text('Siguiendo'),
          )
        : FilledButton.icon(
            onPressed: onTap,
            icon: const NexoIcon(NexoGlyph.add, size: 16),
            label: const Text('Seguir'),
            style: FilledButton.styleFrom(
              minimumSize: _size,
              padding: _padding,
              textStyle: label,
            ),
          );
  }
}
