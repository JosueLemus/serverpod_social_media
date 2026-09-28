import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../app/theme/app_tokens.dart';
import '../../../../core/widgets/pills.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../domain/entities/discovery.dart';

/// "Temas en tendencia · TOCA PARA SEGUIR".
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
        SectionHeader(title: title, hint: 'Toca para seguir', icon: Icons.tag),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            for (final topic in topics)
              _TopicChip(topic: topic, onTap: () => onToggle(topic)),
          ],
        ),
      ],
    );
  }
}

class _TopicChip extends StatelessWidget {
  const _TopicChip({required this.topic, required this.onTap});

  final TrendingTopic topic;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => FilterPill(
    key: Key('topic-${topic.tag}'),
    label: '#${topic.tag}',
    selected: topic.isFollowed,
    onTap: onTap,
    count: topic.posts,
  );
}

/// "Creadores recomendados · N sugeridos".
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: title,
          hint: '${creators.length} sugeridos',
          icon: Icons.person_add_alt_1_outlined,
        ),
        Card(
          child: Column(
            children: [
              for (final (index, creator) in creators.indexed) ...[
                if (index > 0) const Divider(height: 1, indent: AppSpacing.md),
                _CreatorRow(
                  creator: creator,
                  onToggle: () => onToggle(creator),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _CreatorRow extends StatelessWidget {
  const _CreatorRow({required this.creator, required this.onToggle});

  final SuggestedCreator creator;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(AppSpacing.sm),
    child: Row(
      children: [
        UserAvatar(
          name: creator.name,
          size: 40,
          // El anillo rojo es el mismo lenguaje que las historias: quien está
          // al aire se reconoce igual en toda la app.
          ring: creator.isLive ? AppColors.secondary : null,
          ringWidth: 2,
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: InkWell(
            onTap: () => context.push(AppRoutes.profileOf(creator.username)),
            borderRadius: AppRadii.small,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        creator.name,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    if (creator.isVerified) ...[
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.verified_rounded,
                        size: 14,
                        color: AppColors.primary,
                      ),
                    ],
                    if (creator.isPro) ...[
                      const SizedBox(width: 6),
                      const StatusBadge(
                        label: 'Pro',
                        color: AppColors.primarySurface,
                        foreground: AppColors.textOnBrandSurface,
                      ),
                    ],
                  ],
                ),
                Text(
                  '@${creator.username} · ${creator.headline}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        _FollowButton(following: creator.isFollowed, onTap: onToggle),
      ],
    ),
  );
}

/// Seguir/Siguiendo. Dos estilos, un solo control: relleno mientras es una
/// invitación, plano una vez aceptada — dejarlo relleno haría que la fila
/// siguiera pidiendo algo que ya se hizo.
class _FollowButton extends StatelessWidget {
  const _FollowButton({required this.following, required this.onTap});

  final bool following;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 34,
    child: following
        ? OutlinedButton.icon(
            onPressed: onTap,
            icon: const Icon(Icons.check_rounded, size: 15),
            label: const Text('Siguiendo'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 34),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
              foregroundColor: AppColors.textSecondary,
              textStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          )
        : FilledButton.icon(
            onPressed: onTap,
            icon: const Icon(Icons.add_rounded, size: 16),
            label: const Text('Seguir'),
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 34),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
              textStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
  );
}
