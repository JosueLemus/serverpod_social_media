import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/router/app_routes.dart';
import '../../../../app/theme/app_tokens.dart';
import '../../../../core/animations/app_motion.dart';
import '../../../../core/layout/nexo_page.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../../core/widgets/search_field.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../live/domain/entities/live_session.dart';
import '../../../live/presentation/widgets/live_card.dart';
import '../bloc/explore_cubit.dart';
import '../widgets/discovery_sections.dart';

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
            const Padding(
              padding: EdgeInsets.only(top: AppSpacing.md),
              child: FeedSkeleton(count: 2),
            )
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
    Widget card(LiveSession session) => Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Enter(
        key: ValueKey(session.id),
        index: index++,
        child: LiveCard(
          session: session,
          onTap: () => context.go(AppRoutes.liveRoom(session.id)),
        ),
      ),
    );

    if (state.sessions.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.only(top: AppSpacing.md),
          child: AppEmptyView(
            icon: Icons.sensors_outlined,
            title: 'Todavía no hay vivos',
            message:
                'Cuando alguien que sigues empiece a transmitir aparecerá aquí.',
            actionLabel: 'Ver temas en tendencia',
            onAction: () {},
          ),
        ),
      ];
    }

    return [
      if (state.onAir.isNotEmpty) ...[
        const SectionHeader(
          title: 'En vivo ahora',
          icon: Icons.sensors_rounded,
        ),
        ...state.onAir.map(card),
      ],
      if (state.upcoming.isNotEmpty) ...[
        const SectionHeader(title: 'Próximos', icon: Icons.schedule_rounded),
        ...state.upcoming.map(card),
      ],
      if (state.replays.isNotEmpty) ...[
        const SectionHeader(
          title: 'Replays',
          icon: Icons.play_circle_outline_rounded,
        ),
        ...state.replays.map(card),
      ],
    ];
  }
}
