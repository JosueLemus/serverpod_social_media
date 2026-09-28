import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/router/app_routes.dart';
import '../../../../app/theme/app_tokens.dart';
import '../../../../core/animations/app_motion.dart';
import '../../../../core/widgets/pills.dart';
import '../../../explore/presentation/bloc/explore_cubit.dart';
import '../../../explore/presentation/widgets/discovery_sections.dart';
import '../../domain/entities/feed_filter.dart';

/// El feed vacío, que es en realidad el onboarding.
///
/// No es un estado vacío genérico: alguien que no sigue a nadie no necesita
/// que le digan que no hay nada, necesita a quién seguir. Por eso trae los
/// mismos temas y creadores que Explorar, en vez de una ilustración y un
/// botón que lleva a otra pantalla a empezar de nuevo.
class EmptyFeedView extends StatelessWidget {
  const EmptyFeedView({
    super.key,
    required this.filter,
    required this.onShowAll,
  });

  final FeedFilter filter;
  final VoidCallback onShowAll;

  @override
  Widget build(BuildContext context) {
    // Un filtro sin resultados es otra cosa que un feed sin seguidos: hay
    // contenido, simplemente no de este tipo. Ahí alcanza con la salida.
    if (filter != FeedFilter.forYou) {
      return _FilterEmpty(filter: filter, onShowAll: onShowAll);
    }

    return BlocProvider(
      create: (_) => ExploreCubit(sl(), sl())..load(),
      child: const _OnboardingEmpty(),
    );
  }
}

class _FilterEmpty extends StatelessWidget {
  const _FilterEmpty({required this.filter, required this.onShowAll});

  final FeedFilter filter;
  final VoidCallback onShowAll;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
    child: Column(
      children: [
        const CircleAvatar(
          radius: 32,
          backgroundColor: AppColors.primarySurface,
          child: Icon(
            Icons.filter_list_rounded,
            color: AppColors.primaryDeep,
            size: 28,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Nada en ${filter.label}',
          style: Theme.of(context).textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Prueba con otro filtro o vuelve más tarde.',
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.md),
        FilledButton(onPressed: onShowAll, child: const Text('Ver todo')),
      ],
    ),
  );
}

class _OnboardingEmpty extends StatelessWidget {
  const _OnboardingEmpty();

  @override
  Widget build(BuildContext context) => BlocBuilder<ExploreCubit, ExploreState>(
    builder: (context, state) {
      final cubit = context.read<ExploreCubit>();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.lg),
          const Enter(child: Center(child: _PrimerosPasos())),
          const SizedBox(height: AppSpacing.md),
          const Enter(index: 1, child: Center(child: _CommunityGlyph())),
          const SizedBox(height: AppSpacing.md),
          Enter(
            index: 2,
            child: Text(
              'Tu feed está esperando por ti',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Enter(
            index: 3,
            child: Text(
              'Aún no sigues a ningún creador ni tema. Explora los perfiles '
              'más influyentes de diseño, desarrollo y tecnología para '
              'personalizar tu experiencia.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
                height: 1.45,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          // Sólo opacidad: es el CTA de la pantalla y tiene que ser tocable en
          // el frame en que aparece.
          EnterStatic(
            index: 4,
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                key: const Key('empty-feed-explore'),
                onPressed: () => context.go(AppRoutes.explore),
                iconAlignment: IconAlignment.end,
                icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                label: const Text('Explorar creadores destacados'),
              ),
            ),
          ),
          TrendingTopicsSection(
            topics: state.topics,
            onToggle: cubit.toggleTopic,
          ),
          SuggestedCreatorsSection(
            creators: state.creators,
            onToggle: cubit.toggleCreator,
          ),
        ],
      );
    },
  );
}

class _PrimerosPasos extends StatelessWidget {
  const _PrimerosPasos();

  @override
  Widget build(BuildContext context) => const StatusBadge(
    label: 'Primeros pasos',
    color: AppColors.primarySurface,
    foreground: AppColors.textOnBrandSurface,
    icon: Icons.flag_outlined,
  );
}

class _CommunityGlyph extends StatelessWidget {
  const _CommunityGlyph();

  @override
  Widget build(BuildContext context) => Container(
    width: 84,
    height: 84,
    decoration: const BoxDecoration(
      color: AppColors.primarySurface,
      shape: BoxShape.circle,
    ),
    alignment: Alignment.center,
    child: const Icon(
      Icons.groups_rounded,
      size: 40,
      color: AppColors.primaryDeep,
    ),
  );
}
