import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/router/app_routes.dart';
import '../../../../app/theme/app_tokens.dart';
import '../../../../core/animations/app_motion.dart';
import '../../../../core/layout/nexo_page.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../../core/widgets/nexo_icon.dart';
import '../../../../core/widgets/nexo_mascot.dart';
import '../../../../core/widgets/pills.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../live/domain/entities/live_session.dart';
import '../../../live/presentation/bloc/live_list_cubit.dart';
import '../../../live/presentation/utils/live_status_ui.dart';
import '../../../live/presentation/widgets/featured_live_card.dart';
import '../../../live/presentation/widgets/live_card.dart';
import '../../../live/presentation/widgets/live_stories_row.dart';
import '../../../moderation/presentation/widgets/staff_shortcut_card.dart';
import '../../domain/entities/feed_filter.dart';
import '../../domain/entities/post.dart';
import '../bloc/feed_cubit.dart';
import '../widgets/empty_feed_view.dart';
import '../widgets/comments_sheet.dart';
import '../widgets/post_actions.dart';
import '../widgets/post_card.dart';
import '../widgets/suggested_accounts_row.dart';
import '../../../live/presentation/utils/live_navigation.dart';

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
  Widget build(BuildContext context) => BlocListener<FeedCubit, FeedState>(
    listenWhen: (previous, current) =>
        current is FeedLoaded &&
        current.notice != null &&
        (previous is! FeedLoaded ||
            previous.noticeSerial != current.noticeSerial),
    listener: (context, state) => ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text((state as FeedLoaded).notice!.message)),
    ),
    child: BlocBuilder<FeedCubit, FeedState>(
      builder: (context, state) {
        final cubit = context.read<FeedCubit>();
        final loaded = state is FeedLoaded ? state : null;

        return NexoPage(
          section: 'Feed',
          actions: [
            // La búsqueda de verdad vive en Explorar. El campo que había acá
            // no buscaba nada y empujaba las historias fuera del primer
            // vistazo; un ícono en la barra lleva al mismo lugar.
            IconButton(
              key: const Key('feed-search'),
              tooltip: 'Buscar',
              onPressed: () => context.go(AppRoutes.explore),
              icon: const NexoIcon(NexoGlyph.search, size: 22),
            ),
            // Mensajes no va acá: es una pestaña de la barra, con su badge.
            // Un ícono en la barra del feed además repetía la misma entrada.
          ],
          // Los dos cubits se resuelven antes del await: después de él este
          // context puede estar desmontado, y leer un provider desde un Element
          // muerto revienta sin mensaje legible.
          onRefresh: () {
            final live = context.read<LiveListCubit>();
            return Future.wait([cubit.refresh(), live.load()]);
          },
          children: [
            const StaffShortcutCard(),
            // El primer vistazo: la plancha de avatares, los filtros y el vivo
            // destacado, en ese orden.
            const _LiveStories(),
            const SizedBox(height: AppSpacing.md),
            // La fila de filtros queda montada en todos los estados: perder el
            // control que acabás de tocar mientras refresca se lee como que el
            // tap rompió algo.
            _FilterRow(
              selected: loaded?.filter ?? FeedFilter.forYou,
              onSelected: cubit.selectFilter,
              // Los vivos al aire, no los posts marcados: con Serverpod un post
              // nunca dice que está en vivo, y el contador quedaba en 0 con un
              // vivo al aire.
              liveCount: context.select<LiveListCubit, int?>(
                (live) => switch (live.state) {
                  LiveListLoaded(:final sessions) =>
                    sessions.where((session) => session.status.isOnAir).length,
                  _ => null,
                },
              ),
            ),
            // Con el chip "En vivo" la lista de abajo ya son los vivos: la
            // tarjeta destacada repetiría la misma transmisión dos veces
            // seguidas. Las historias quedan: están arriba de los filtros, y
            // esconderlas haría saltar la fila que se acaba de tocar.
            if (loaded?.filter != FeedFilter.live) const _FeaturedLive(),
            ..._body(context, state),
          ],
        );
      },
    ),
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
    // Los vivos no son posts: con Serverpod ningún post dice que está en
    // vivo, y filtrar por eso dejaba la lista vacía con vivos al aire.
    if (loaded.filter == FeedFilter.live) {
      return [
        _LiveNowList(onShowAll: () => cubit.selectFilter(FeedFilter.forYou)),
      ];
    }
    if (loaded.filter == FeedFilter.forYou) {
      return _sections(context, loaded);
    }
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
      ..._cards(context, posts),
      ..._loadMore(cubit, loaded),
    ];
  }

  /// "Para ti" por secciones, en el orden que arma el servidor: de quienes
  /// sigues, a quién seguir y para descubrir. Los vivos van arriba, en el
  /// rail, que se actualiza solo.
  List<Widget> _sections(BuildContext context, FeedLoaded loaded) {
    final cubit = context.read<FeedCubit>();
    final following = loaded.followingPosts;
    final discover = loaded.discoverPosts;
    final suggestions = loaded.suggestions;
    if (following.isEmpty && discover.isEmpty && suggestions.isEmpty) {
      return [
        EmptyFeedView(
          filter: loaded.filter,
          onShowAll: () => cubit.selectFilter(FeedFilter.forYou),
        ),
      ];
    }
    // Con una sola sección de posts y nada más, el título sobra: un feed
    // que dice "Descubrir" arriba de todo se lee como una pantalla distinta.
    final titled = following.isNotEmpty || suggestions.isNotEmpty;
    // Los títulos de sección van solos, en la gótica: un ícono de Material
    // al lado era otra mano junto a la tipografía de la marca.
    return [
      // El encabezado de sección ya trae su aire arriba; sin encabezado, el
      // primer post necesita el suyo para despegarse del vivo destacado.
      SizedBox(height: titled ? AppSpacing.xs : AppSpacing.lg),
      if (following.isNotEmpty) ...[
        const SectionHeader(
          key: Key('feed-section-following'),
          title: 'De quienes sigues',
        ),
        ..._cards(context, following),
      ],
      if (suggestions.isNotEmpty) ...[
        const SectionHeader(
          key: Key('feed-section-suggested'),
          title: 'A quién seguir',
        ),
        SuggestedAccountsRow(
          accounts: suggestions,
          onToggleFollow: (account) => unawaited(cubit.toggleFollow(account)),
        ),
      ],
      if (discover.isNotEmpty) ...[
        if (titled)
          const SectionHeader(
            key: Key('feed-section-discover'),
            title: 'Descubrir',
          ),
        ..._cards(context, discover, from: following.length),
      ],
      ..._loadMore(cubit, loaded),
    ];
  }

  List<Widget> _cards(BuildContext context, List<Post> posts, {int from = 0}) {
    final cubit = context.read<FeedCubit>();
    return [
      for (final (index, post) in posts.indexed) ...[
        // Los posts van sobre el liner, sin tarjeta: entre uno y otro, aire y
        // un filete. Nada después del último, para que no quede una línea
        // suelta arriba del siguiente encabezado.
        if (index > 0)
          const Padding(
            padding: EdgeInsets.only(top: AppSpacing.xs, bottom: AppSpacing.md),
            child: Divider(height: 1),
          ),
        Enter(
          // Keyed por post para que un like no reinicie la entrada de toda
          // la columna: animate_do vuelve a correr cuando su subárbol se
          // reconstruye desde cero, y una key por índice hace que cada
          // tarjeta sea un subárbol nuevo apenas se filtra la lista.
          key: ValueKey(post.id),
          index: from + index,
          child: PostCard(
            post: post,
            onLike: () => unawaited(cubit.toggleLike(post.id)),
            onSave: () => cubit.toggleSave(post.id),
            onComment: () => unawaited(showCommentsSheet(context, post)),
            onShowLikers: () =>
                unawaited(showLikersSheet(context, cubit.likersOf(post.id))),
            onMore: () => unawaited(_runAction(context, cubit, post)),
            onOpen: () => unawaited(context.push(AppRoutes.post(post.id))),
          ),
        ),
      ],
    ];
  }

  List<Widget> _loadMore(FeedCubit cubit, FeedLoaded loaded) => [
    if (loaded.hasMore)
      Center(
        child: loaded.isLoadingMore
            ? const Padding(
                padding: EdgeInsets.all(AppSpacing.md),
                child: CircularProgressIndicator(),
              )
            : TextButton(
                key: const Key('feed-load-more'),
                onPressed: () => unawaited(cubit.loadMore()),
                child: const Text('Ver más publicaciones'),
              ),
      ),
  ];
}

/// Los vivos al aire, para el chip "En vivo". Los lee del mismo cubit que el
/// contador del chip, así que el número y la lista no pueden discrepar.
class _LiveNowList extends StatelessWidget {
  const _LiveNowList({required this.onShowAll});

  final VoidCallback onShowAll;

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<LiveListCubit, LiveListState>(
        builder: (context, state) => switch (state) {
          LiveListLoaded(:final sessions) => _list(
            context,
            sessions.where((session) => session.status.isOnAir).toList(),
          ),
          LiveListFailure() => AppErrorView(
            onRetry: () => context.read<LiveListCubit>().load(),
          ),
          _ => const Padding(
            padding: EdgeInsets.only(top: AppSpacing.md),
            child: FeedSkeleton(count: 1),
          ),
        },
      );

  Widget _list(BuildContext context, List<LiveSession> onAir) {
    if (onAir.isEmpty) {
      return AppEmptyView(
        key: const Key('feed-live-empty'),
        mascot: NexoMascot.mic,
        title: 'Nadie está en vivo ahora',
        message:
            'Cuando alguien empiece a transmitir aparece acá, sin que '
            'tengas que recargar.',
        actionLabel: 'Ver todo',
        onAction: onShowAll,
      );
    }
    return Column(
      children: [
        for (final (index, session) in onAir.indexed)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.md),
            child: EnterStatic(
              key: ValueKey(session.id),
              index: index,
              child: LiveCard(
                session: session,
                onTap: () => openLive(context, session),
              ),
            ),
          ),
      ],
    );
  }
}

/// La fila de avatares troquelados que abre el feed. Lee su propio cubit, así
/// que un fallo al listar vivos no deja al feed sin posts.
///
/// Queda montada mientras carga o si falla, con sólo "Tu historia": es la
/// primera fila de la pantalla, y si apareciera recién al llegar los vivos
/// empujaría hacia abajo los filtros que el usuario ya está por tocar.
class _LiveStories extends StatelessWidget {
  const _LiveStories();

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<LiveListCubit, LiveListState>(
        builder: (context, state) {
          final stories = state is LiveListLoaded
              ? state.sessions
                    .where((session) => session.status != LiveStatus.cancelled)
                    .toList()
              : const <LiveSession>[];
          return LiveStoriesRow(
            sessions: stories,
            onCreate: () => context.push(AppRoutes.create),
            onTap: (session) => openLive(context, session),
          );
        },
      );
}

/// La transmisión destacada, debajo de los filtros. Sólo si hay alguien al
/// aire: un hueco reservado para un vivo que no existe se lee como un error.
class _FeaturedLive extends StatelessWidget {
  const _FeaturedLive();

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<LiveListCubit, LiveListState>(
        builder: (context, state) {
          if (state is! LiveListLoaded) return const SizedBox.shrink();

          final featured = state.sessions
              .where((session) => session.status == LiveStatus.live)
              .firstOrNull;
          if (featured == null) return const SizedBox.shrink();

          return Padding(
            padding: const EdgeInsets.only(top: AppSpacing.md),
            // Sólo aparece: la tarjeta lleva el botón para entrar, y una
            // traslación dejaría el hit test corrido mientras dura.
            child: EnterStatic(
              child: FeaturedLiveCard(
                session: featured,
                hostUsername: featured.hostUsername,
                onJoin: () => openLive(context, featured),
                isOwn: isOwnLive(context, featured),
              ),
            ),
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

/// Aplica lo que se eligió en el menú "…". El menú sólo decide; el cubit
/// aplica y avisa el resultado.
Future<void> _runAction(
  BuildContext context,
  FeedCubit cubit,
  Post post,
) async {
  final action = await showPostActions(context, post);
  switch (action) {
    case EditPost(:final body):
      await cubit.edit(post, body);
    case DeletePost():
      await cubit.delete(post);
    case ReportPost(:final reason):
      await cubit.report(post, reason);
    case null:
      break;
  }
}

extension on FeedNotice {
  String get message => switch (this) {
    FeedNotice.edited => 'Publicación actualizada.',
    FeedNotice.deleted => 'Publicación eliminada.',
    FeedNotice.reported => 'Gracias. El reporte llegó a moderación.',
    FeedNotice.likeFailed =>
      'No pudimos guardar tu me gusta. Inténtalo de nuevo.',
    FeedNotice.actionFailed =>
      'No pudimos completar la acción. Inténtalo de nuevo.',
    FeedNotice.forbidden => 'Tu cuenta no puede hacer esto.',
    FeedNotice.followFailed =>
      'No pudimos actualizar a quién sigues. Inténtalo de nuevo.',
    FeedNotice.signInToFollow => 'Inicia sesión para seguir cuentas.',
  };
}
