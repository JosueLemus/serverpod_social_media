import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/theme/app_tokens.dart';
import '../../../../core/animations/app_motion.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../live/domain/entities/live_session.dart';
import '../../../live/presentation/utils/live_navigation.dart';
import '../../../live/presentation/widgets/live_card.dart';
import '../bloc/explore_cubit.dart';
import 'discovery_sections.dart';

/// Lo de descubrir que el feed no tenía: los próximos vivos, los replays y los
/// temas en tendencia. Vivía en la pestaña Explorar; desde que esa pestaña
/// dejó de existir, se lee al final de "Para ti", en Inicio.
///
/// Los vivos al aire no van acá: ya están arriba, en las historias, la
/// tarjeta destacada y el chip "En vivo". Repetirlos al final los mostraría
/// dos veces en la misma pantalla.
///
/// Lee su propio [ExploreCubit], así que un fallo al listar vivos o temas no
/// deja al feed sin posts: la sección simplemente no aparece.
class DiscoverMoreSections extends StatelessWidget {
  const DiscoverMoreSections({super.key});

  @override
  Widget build(BuildContext context) => BlocBuilder<ExploreCubit, ExploreState>(
    builder: (context, state) {
      if (state.isLoading || state.hasFailed) {
        return const SizedBox.shrink();
      }
      final cubit = context.read<ExploreCubit>();
      // Un índice corrido entre secciones, para que el escalonado se lea
      // como una sola secuencia y no como dos que arrancan de nuevo.
      var index = 0;
      // Sólo aparecen: la tarjeta entera se toca, y una traslación dejaría
      // el hit test corrido mientras dura.
      Widget card(LiveSession session) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.md),
        child: EnterStatic(
          key: ValueKey('discover-${session.id}'),
          index: index++,
          child: LiveCard(
            session: session,
            onTap: () => openLive(context, session),
          ),
        ),
      );

      // Sin ícono delante del título: el borde de cada tarjeta (punteado
      // el programado, troquel el replay) ya dice en qué estado está.
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (state.upcoming.isNotEmpty) ...[
            const SectionHeader(
              key: Key('feed-section-upcoming'),
              title: 'Próximos vivos',
            ),
            ...state.upcoming.map(card),
          ],
          if (state.replays.isNotEmpty) ...[
            const SectionHeader(
              key: Key('feed-section-replays'),
              title: 'Replays',
            ),
            ...state.replays.map(card),
          ],
          if (state.topics.isNotEmpty)
            TrendingTopicsSection(
              topics: state.topics,
              onToggle: cubit.toggleTopic,
            ),
        ],
      );
    },
  );
}
