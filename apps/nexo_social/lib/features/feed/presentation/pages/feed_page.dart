import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/router/app_routes.dart';
import '../../../../app/theme/app_tokens.dart';
import '../../../../core/animations/app_motion.dart';
import '../../../../core/layout/nexo_page.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../../core/widgets/pills.dart';
import '../../../../core/widgets/search_field.dart';
import '../../../live/domain/entities/live_session.dart';
import '../../../live/presentation/bloc/live_list_cubit.dart';
import '../../../live/presentation/widgets/featured_live_card.dart';
import '../../../live/presentation/widgets/live_stories_row.dart';
import '../../domain/entities/feed_filter.dart';
import '../bloc/feed_cubit.dart';
import '../widgets/empty_feed_view.dart';
import '../widgets/post_card.dart';

class FeedPage extends StatelessWidget {
  const FeedPage({super.key});

  @override
  Widget build(BuildContext context) => MultiBlocProvider(
    providers: [
      BlocProvider(create: (_) => sl<FeedCubit>()..load()),
      // El rail de vivos del feed —historias y tarjeta destacada— es la misma
      // lectura que hace Explorar, así que reusa su cubit en vez de que el
      // feed conozca el repositorio de live por su cuenta.
      BlocProvider(create: (_) => sl<LiveListCubit>()..load()),
    ],
    child: const _FeedView(),
  );
}

class _FeedView extends StatelessWidget {
  const _FeedView();

  @override
  Widget build(BuildContext context) => BlocBuilder<FeedCubit, FeedState>(
    builder: (context, state) {
      final cubit = context.read<FeedCubit>();
      final loaded = state is FeedLoaded ? state : null;

      return NexoPage(
        section: 'Feed',
        actions: [
          IconButton(
            tooltip: 'Mensajes',
            onPressed: () {},
            icon: const Icon(Icons.mail_outline_rounded, size: 22),
          ),
        ],
        // Los dos cubits se resuelven antes del await: después de él este
        // context puede estar desmontado, y leer un provider desde un Element
        // muerto revienta sin mensaje legible.
        onRefresh: () {
          final live = context.read<LiveListCubit>();
          return Future.wait([cubit.refresh(), live.load()]);
        },
        children: [
          const SearchField(hint: 'Buscar creadores, temas o transmisiones…'),
          const SizedBox(height: AppSpacing.sm),
          // La fila de filtros queda montada en todos los estados: perder el
          // control que acabás de tocar mientras refresca se lee como que el
          // tap rompió algo.
          _FilterRow(
            selected: loaded?.filter ?? FeedFilter.forYou,
            onSelected: cubit.selectFilter,
            liveCount: loaded?.posts.where((post) => post.isLive).length,
          ),
          const _LiveRail(),
          ..._body(context, state),
        ],
      );
    },
  );

  List<Widget> _body(BuildContext context, FeedState state) {
    final cubit = context.read<FeedCubit>();

    if (state is FeedLoading || state is FeedInitial) {
      return const [SizedBox(height: AppSpacing.md), FeedSkeleton()];
    }
    if (state is FeedFailure) {
      return [AppErrorView(onRetry: cubit.load)];
    }

    final loaded = state as FeedLoaded;
    final posts = loaded.visible;

    if (posts.isEmpty) {
      return [
        EmptyFeedView(
          filter: loaded.filter,
          onShowAll: () => cubit.selectFilter(FeedFilter.forYou),
        ),
      ];
    }

    return [
      const SizedBox(height: AppSpacing.md),
      for (final (index, post) in posts.indexed)
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: Enter(
            // Keyed por post para que un like no reinicie la entrada de toda
            // la columna: animate_do vuelve a correr cuando su subárbol se
            // reconstruye desde cero, y una key por índice hace que cada
            // tarjeta sea un subárbol nuevo apenas se filtra la lista.
            key: ValueKey(post.id),
            index: index,
            child: PostCard(
              post: post,
              onLike: () => cubit.toggleLike(post.id),
              onSave: () => cubit.toggleSave(post.id),
            ),
          ),
        ),
    ];
  }
}

/// Historias + la transmisión destacada. Lee su propio cubit, así que un fallo
/// al listar vivos no deja al feed sin posts.
class _LiveRail extends StatelessWidget {
  const _LiveRail();

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<LiveListCubit, LiveListState>(
        builder: (context, state) {
          if (state is! LiveListLoaded) return const SizedBox.shrink();

          final stories = state.sessions
              .where((session) => session.status != LiveStatus.cancelled)
              .toList();
          final featured = state.sessions
              .where((session) => session.status == LiveStatus.live)
              .firstOrNull;

          return Column(
            children: [
              const SizedBox(height: AppSpacing.md),
              LiveStoriesRow(
                sessions: stories,
                onCreate: () => context.push(AppRoutes.create),
                onTap: (session) => context.go(AppRoutes.liveRoom(session.id)),
              ),
              if (featured != null) ...[
                const SizedBox(height: AppSpacing.md),
                Enter(
                  child: FeaturedLiveCard(
                    session: featured,
                    // Mock: el handle del host llega con el modelo real de
                    // identidad. Derivarlo del nombre acá inventaría un
                    // usuario que puede no existir.
                    hostUsername: 'elena_ux',
                    onJoin: () => context.go(AppRoutes.liveRoom(featured.id)),
                  ),
                ),
              ],
            ],
          );
        },
      );
}

/// Scrollea en horizontal para que un teléfono angosto nunca corte el último
/// chip — la fila anterior era un `Wrap` dentro de una lista sin margen, y
/// "Comunidades" se salía por la derecha.
class _FilterRow extends StatelessWidget {
  const _FilterRow({
    required this.selected,
    required this.onSelected,
    this.liveCount,
  });

  final FeedFilter selected;
  final ValueChanged<FeedFilter> onSelected;
  final int? liveCount;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: AppSizes.chipHeight,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: FeedFilter.values.length,
      separatorBuilder: (context, index) =>
          const SizedBox(width: AppSpacing.xs),
      itemBuilder: (context, index) {
        final filter = FeedFilter.values[index];
        final isLive = filter == FeedFilter.live;
        return FilterPill(
          key: Key('filter-${filter.name}'),
          label: filter.label,
          selected: filter == selected,
          onTap: () => onSelected(filter),
          // Sólo "En vivo" lleva punto: es el único filtro que describe algo
          // que está pasando ahora.
          dotColor: isLive ? AppColors.secondary : null,
          count: isLive ? liveCount : null,
        );
      },
    ),
  );
}
