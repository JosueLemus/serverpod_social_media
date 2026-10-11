import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/router/app_routes.dart';
import '../../../../app/theme/app_tokens.dart';
import '../../../../core/animations/app_motion.dart';
import '../../../../core/widgets/nexo_icon.dart';
import '../../../../core/widgets/nexo_mascot.dart';
import '../../../explore/presentation/bloc/explore_cubit.dart';
import '../../../explore/presentation/widgets/discovery_sections.dart';
import '../../domain/entities/feed_filter.dart';

/// El feed vacío, que es en realidad el onboarding.
///
/// No es un estado vacío genérico: alguien que no sigue a nadie no necesita
/// que le digan que no hay nada, necesita a quién seguir. Por eso trae los
/// mismos temas y creadores que Explorar debajo del gato, en vez de sólo un
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
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
      child: Column(
        children: [
          const MascotIllustration(NexoMascot.empty, size: 132),
          const SizedBox(height: AppSpacing.md),
          Text(
            filter == FeedFilter.following
                ? 'Nada de quienes sigues'
                : 'Nada en ${filter.label}',
            style: text.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            // "Siguiendo" vacío casi siempre es no seguir a nadie todavía: la
            // salida es seguir a alguien, no esperar.
            filter == FeedFilter.following
                ? 'Sigue a alguien para ver sus publicaciones acá.'
                : 'Prueba con otro filtro o vuelve más tarde.',
            style: text.bodyMedium?.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          FilledButton(onPressed: onShowAll, child: const Text('Ver todo')),
        ],
      ),
    );
  }
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
          // La plancha en blanco: el gato acompaña el momento vacío en vez de
          // un ícono gris en un círculo.
          const Enter(
            child: Center(child: MascotIllustration(NexoMascot.empty)),
          ),
          const SizedBox(height: AppSpacing.md),
          Enter(
            index: 1,
            child: Text(
              'Tu feed está esperando por ti',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Enter(
            index: 2,
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
          const SizedBox(height: AppSpacing.lg),
          // Sólo opacidad: es el CTA de la pantalla y tiene que ser tocable en
          // el frame en que aparece.
          EnterStatic(
            index: 3,
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                key: const Key('empty-feed-explore'),
                onPressed: () => context.go(AppRoutes.explore),
                iconAlignment: IconAlignment.end,
                icon: const NexoIcon(NexoGlyph.forward, size: 18),
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
