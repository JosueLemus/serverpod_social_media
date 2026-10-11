import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/theme/app_tokens.dart';
import '../../../../core/animations/app_motion.dart';
import '../../../../core/layout/nexo_page.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../../core/widgets/nexo_mascot.dart';
import '../../../../core/widgets/search_field.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../live/domain/entities/live_session.dart';
import '../../../live/presentation/widgets/live_card.dart';
import '../bloc/explore_cubit.dart';
import '../widgets/discovery_sections.dart';
import '../../../live/presentation/utils/live_navigation.dart';

/// Descubrimiento: vivos, temas y creadores.
///
/// Es la segunda pestaña, donde antes estaba "En vivo". Los vivos son un tipo
/// de contenido dentro del descubrimiento, no una sección hermana del feed —
/// una pestaña dedicada sólo a ellos dejaba sin entrada a perfiles y
/// categorías, que es justamente lo que el Notion pone en Explorar.
class ExplorePage extends StatelessWidget {
  const ExplorePage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => ExploreCubit(sl(), sl())..load(),
    child: const _ExploreView(),
  );
}

class _ExploreView extends StatelessWidget {
  const _ExploreView();

  @override
  Widget build(BuildContext context) => BlocBuilder<ExploreCubit, ExploreState>(
    builder: (context, state) {
      final cubit = context.read<ExploreCubit>();
      return NexoPage(
        section: 'Explorar',
        onRefresh: cubit.load,
        children: [
          const SearchField(hint: 'Buscar creadores, temas o transmisiones…'),
          if (state.isLoading)
            const _ExploreSkeleton()
          else if (state.hasFailed)
            AppErrorView(onRetry: cubit.load)
          else ...[
            ..._liveSections(context, state),
            TrendingTopicsSection(
              topics: state.topics,
              onToggle: cubit.toggleTopic,
            ),
            SuggestedCreatorsSection(
              creators: state.creators,
              onToggle: cubit.toggleCreator,
            ),
          ],
        ],
      );
    },
  );

  /// Agrupados por lo que el usuario puede hacer con cada uno: entrar ahora,
  /// que le avisen, o ver el replay. Una lista plana hace imposible encontrar
  /// el que está realmente al aire.
  List<Widget> _liveSections(BuildContext context, ExploreState state) {
    // Un índice corrido entre secciones, para que el escalonado se lea como
    // una sola secuencia y no como tres que arrancan de nuevo.
    var index = 0;
    // Sólo aparecen: la tarjeta entera se toca, y una traslación dejaría el
    // hit test corrido mientras dura.
    Widget card(LiveSession session) => Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: EnterStatic(
        key: ValueKey(session.id),
        index: index++,
        child: LiveCard(
          session: session,
          onTap: () => openLive(context, session),
        ),
      ),
    );

    if (state.sessions.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.only(top: AppSpacing.md),
          child: AppEmptyView(
            mascot: NexoMascot.mic,
            title: 'Todavía no hay vivos',
            message:
                'Cuando alguien que sigues empiece a transmitir aparecerá aquí.',
            actionLabel: 'Ver temas en tendencia',
            onAction: () {},
          ),
        ),
      ];
    }

    // Sin ícono delante del título: el borde de cada tarjeta (holo, punteado,
    // troquel) ya dice en qué estado está cada vivo, y un ícono de Material
    // al lado de la tipografía de display es otro trazo y otra mano.
    return [
      if (state.onAir.isNotEmpty) ...[
        const SectionHeader(title: 'En vivo ahora'),
        ...state.onAir.map(card),
      ],
      if (state.upcoming.isNotEmpty) ...[
        const SectionHeader(title: 'Próximos'),
        ...state.upcoming.map(card),
      ],
      if (state.replays.isNotEmpty) ...[
        const SectionHeader(title: 'Replays'),
        ...state.replays.map(card),
      ],
    ];
  }
}

/// La carga con la forma de Explorar: dos medias de vivo y una plancha de
/// temas. Un esqueleto de post le prometería a la pantalla un contenido que
/// no va a tener.
class _ExploreSkeleton extends StatelessWidget {
  const _ExploreSkeleton();

  @override
  Widget build(BuildContext context) => PulsingSkeleton(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.xl),
        const AppSkeleton(width: 150, height: 20),
        const SizedBox(height: AppSpacing.sm),
        for (var index = 0; index < 2; index++) ...[
          const ClipRRect(
            borderRadius: AppRadii.medium,
            child: AppSkeleton(height: 190),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        const SizedBox(height: AppSpacing.md),
        const AppSkeleton(width: 180, height: 20),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            for (final width in [96.0, 120.0, 84.0, 132.0, 104.0])
              ClipRRect(
                borderRadius: AppRadii.pill,
                child: AppSkeleton(width: width, height: 44),
              ),
          ],
        ),
      ],
    ),
  );
}
