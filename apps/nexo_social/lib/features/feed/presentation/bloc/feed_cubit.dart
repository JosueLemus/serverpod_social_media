import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../../moderation/domain/entities/moderation_action.dart';
import '../../../profile/domain/entities/follow.dart';
import '../../../profile/domain/repositories/follow_repository.dart';
import '../../domain/entities/feed_filter.dart';
import '../../domain/entities/home_feed.dart';
import '../../domain/entities/post.dart';
import '../../domain/entities/post_extras.dart';
import '../../domain/repositories/home_feed_repository.dart';
import '../../domain/repositories/post_repository.dart';

sealed class FeedState extends Equatable {
  const FeedState();

  @override
  List<Object?> get props => const [];
}

class FeedInitial extends FeedState {
  const FeedInitial();
}

class FeedLoading extends FeedState {
  const FeedLoading();
}

/// Qué pasó con la última acción sobre un post. La View lo traduce.
enum FeedNotice {
  edited,
  deleted,
  reported,
  likeFailed,
  actionFailed,
  forbidden,
  followFailed,
  signInToFollow,
}

class FeedLoaded extends FeedState {
  const FeedLoaded(
    this.posts, {
    this.filter = FeedFilter.forYou,
    this.nextCursor,
    this.isLoadingMore = false,
    this.notice,
    this.noticeSerial = 0,
    this.suggestions = const [],
  });

  /// Everything the feed holds, unfiltered. The filter is applied on read so
  /// switching tabs never drops a post from memory and never needs a refetch.
  ///
  /// Con el inicio por secciones, los de cuentas que seguís llevan
  /// `isFollowed`: así una sola lista alimenta la sección "seguidos", la de
  /// "descubrir" y el chip "Siguiendo", sin tres copias del mismo post.
  final List<Post> posts;
  final FeedFilter filter;

  /// "A quién seguir", de la primera página del inicio.
  final List<ProfileSummary> suggestions;

  /// Null cuando no hay más páginas.
  final String? nextCursor;
  final bool isLoadingMore;

  /// El resultado de la última acción. [noticeSerial] crece con cada una,
  /// así que la misma dos veces seguidas también se avisa.
  final FeedNotice? notice;
  final int noticeSerial;

  bool get hasMore => nextCursor != null;

  List<Post> get followingPosts =>
      posts.where((post) => post.isFollowed).toList();

  List<Post> get discoverPosts =>
      posts.where((post) => !post.isFollowed).toList();

  List<Post> get visible => switch (filter) {
    FeedFilter.forYou => posts,
    FeedFilter.following => posts.where((post) => post.isFollowed).toList(),
    FeedFilter.live => posts.where((post) => post.isLive).toList(),
    FeedFilter.communities =>
      posts.where((post) => post.tags.isNotEmpty).toList(),
  };

  FeedLoaded copyWith({
    List<Post>? posts,
    FeedFilter? filter,
    String? Function()? nextCursor,
    bool? isLoadingMore,
    FeedNotice? notice,
    int? noticeSerial,
    List<ProfileSummary>? suggestions,
  }) => FeedLoaded(
    posts ?? this.posts,
    filter: filter ?? this.filter,
    nextCursor: nextCursor == null ? this.nextCursor : nextCursor(),
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    notice: notice ?? this.notice,
    noticeSerial: noticeSerial ?? this.noticeSerial,
    suggestions: suggestions ?? this.suggestions,
  );

  // Equatable on every field. A missing entry here is a silent no-rebuild:
  // the cubit emits, the state compares equal and the UI never redraws.
  @override
  List<Object?> get props => [
    posts,
    filter,
    nextCursor,
    isLoadingMore,
    notice,
    noticeSerial,
    suggestions,
  ];
}

/// Un feed que no se pudo leer. [offline] distingue la red caída del
/// servidor caído: son dos promesas distintas al usuario.
class FeedFailure extends FeedState {
  const FeedFailure({this.offline = false});

  final bool offline;

  @override
  List<Object?> get props => [offline];
}

class FeedCubit extends Cubit<FeedState> {
  /// [_posts] escribe (likes, editar, borrar, reportar) y avisa cambios;
  /// [_home] lee el inicio por secciones; [_follows] sigue desde la fila de
  /// sugeridos.
  FeedCubit(this._posts, this._home, [this._follows])
    : super(const FeedInitial()) {
    // The feed is not rebuilt when the user returns from the composer: the
    // shell keeps one navigator per tab, so this cubit and its list survive.
    // Without this subscription a published post only showed up after a
    // restart.
    _changes = _posts.changes().listen((_) => unawaited(_reload()));
  }

  final PostRepository _posts;
  final HomeFeedRepository _home;
  final FollowRepository? _follows;
  late final StreamSubscription<void> _changes;

  @override
  Future<void> close() async {
    await _changes.cancel();
    return super.close();
  }

  Future<void> load() async {
    emit(const FeedLoading());
    await _reload();
  }

  Future<void> refresh() => _reload();

  /// Relee la primera página conservando el filtro.
  Future<void> _reload() async {
    final filter = switch (state) {
      FeedLoaded(:final filter) => filter,
      _ => FeedFilter.forYou,
    };
    try {
      final home = await _home.home();
      if (isClosed) return;
      final page = PostPage(_postsOf(home), nextCursor: home.nextCursor);
      final current = state;
      final merged = current is FeedLoaded
          ? mergeFirstPage(current, page)
          : (posts: page.posts, nextCursor: page.nextCursor);
      emit(
        FeedLoaded(
          merged.posts,
          filter: filter,
          nextCursor: merged.nextCursor,
          notice: current is FeedLoaded ? current.notice : null,
          noticeSerial: current is FeedLoaded ? current.noticeSerial : 0,
          suggestions:
              home.section(FeedSectionKind.suggestedAccounts)?.accounts ??
              const [],
        ),
      );
    } on Failure catch (failure) {
      if (isClosed) return;
      // Un fallo al refrescar no borra lo que ya se estaba mostrando, pero
      // se avisa: un pull-to-refresh que no hace nada parece que anduvo.
      if (state is FeedLoaded) {
        _notify(FeedNotice.actionFailed);
        return;
      }
      emit(FeedFailure(offline: failure is NetworkFailure));
    }
  }

  /// La primera página recién leída, más lo ya paginado que queda después.
  ///
  /// Publicar, editar o comentar disparan una relectura de la primera página,
  /// que antes **reemplazaba** la lista: quien había bajado tres páginas
  /// volvía a la primera y perdía los guardados. Los guardados son locales
  /// (no hay backend), así que se copian por id.
  ///
  /// Con el inicio por secciones, "seguidos" y "descubrir" paginan cada una
  /// por su lado, así que lo ya bajado se conserva sección por sección: cada
  /// una contra el último post de la suya en la página nueva.
  @visibleForTesting
  static ({List<Post> posts, String? nextCursor}) mergeFirstPage(
    FeedLoaded current,
    PostPage page,
  ) {
    final saved = {
      for (final post in current.posts)
        if (post.isSaved) post.id,
    };
    final fresh = [
      for (final post in page.posts)
        saved.contains(post.id) ? post.copyWith(isSaved: true) : post,
    ];
    // Todo el feed entra en una página: no hay nada más que conservar.
    if (page.nextCursor == null || fresh.isEmpty) {
      return (posts: fresh, nextCursor: page.nextCursor);
    }
    final ids = {for (final post in fresh) post.id};
    List<Post> section(List<Post> source, {required bool followed}) => [
      for (final post in source)
        if (post.isFollowed == followed) post,
    ];
    List<Post> olderOf({required bool followed}) {
      final freshSection = section(fresh, followed: followed);
      if (freshSection.isEmpty) return const [];
      final boundary = freshSection.last.createdAt;
      return [
        for (final post in section(current.posts, followed: followed))
          if (!ids.contains(post.id) && !post.createdAt.isAfter(boundary)) post,
      ];
    }

    final olderFollowing = olderOf(followed: true);
    final olderDiscover = olderOf(followed: false);
    final kept = olderFollowing.isNotEmpty || olderDiscover.isNotEmpty;
    return (
      posts: [
        ...section(fresh, followed: true),
        ...olderFollowing,
        ...section(fresh, followed: false),
        ...olderDiscover,
      ],
      // Si se conservaron páginas, el cursor sigue siendo el de la última.
      nextCursor: kept ? current.nextCursor : page.nextCursor,
    );
  }

  /// Las publicaciones de una página del inicio, en el orden de sus
  /// secciones. Los vivos no entran: el rail de vivos los lee en tiempo real
  /// de su propio cubit.
  static List<Post> _postsOf(HomeFeedPage page) => [
    for (final section in page.sections)
      if (section.kind == FeedSectionKind.following ||
          section.kind == FeedSectionKind.discover)
        ...section.posts,
  ];

  Future<void> loadMore() async {
    final current = state;
    if (current is! FeedLoaded || !current.hasMore || current.isLoadingMore) {
      return;
    }
    emit(current.copyWith(isLoadingMore: true));
    try {
      final home = await _home.home(cursor: current.nextCursor);
      if (isClosed) return;
      final page = PostPage(_postsOf(home), nextCursor: home.nextCursor);
      // Sobre el estado de ahora, no sobre `current`: emitir el de antes del
      // await revertía un like hecho mientras cargaba la página.
      final latest = state;
      if (latest is! FeedLoaded) return;
      final known = {for (final post in latest.posts) post.id};
      emit(
        latest.copyWith(
          posts: [
            ...latest.posts,
            ...page.posts.where((post) => !known.contains(post.id)),
          ],
          nextCursor: () => page.nextCursor,
          isLoadingMore: false,
        ),
      );
    } on Failure {
      if (isClosed) return;
      final latest = state;
      if (latest is FeedLoaded) {
        emit(latest.copyWith(isLoadingMore: false));
        _notify(FeedNotice.actionFailed);
      }
    }
  }

  void selectFilter(FeedFilter filter) {
    final current = state;
    if (current is FeedLoaded) emit(current.copyWith(filter: filter));
  }

  /// Optimista: el corazón cambia al toque y el número se mueve en uno. La
  /// respuesta del servidor reemplaza ambos; si falla, vuelve como estaba.
  Future<void> toggleLike(String id) async {
    final post = _find(id);
    if (post == null) return;
    final liked = !post.isLiked;
    _replace(
      post.copyWith(isLiked: liked, likes: post.likes + (liked ? 1 : -1)),
    );
    try {
      final result = await _posts.setLiked(id, liked: liked);
      final latest = _find(id);
      if (latest != null) {
        _replace(latest.copyWith(isLiked: result.isLiked, likes: result.likes));
      }
    } on Failure {
      _replace(post);
      _notify(FeedNotice.likeFailed);
    }
  }

  /// Seguir desde "A quién seguir". Optimista, con vuelta atrás si el
  /// servidor lo rechaza.
  Future<void> toggleFollow(ProfileSummary account) async {
    final follows = _follows;
    if (follows == null) return;
    final following = !account.viewerFollows;
    _replaceSuggestion(account.copyWith(viewerFollows: following));
    try {
      final result = following
          ? await follows.follow(account.id)
          : await follows.unfollow(account.id);
      _replaceSuggestion(
        account.copyWith(
          viewerFollows: result.viewerFollows,
          followerCount: result.followerCount == null
              ? null
              : () => result.followerCount,
        ),
      );
    } on Failure catch (failure) {
      _replaceSuggestion(account);
      _notify(
        failure is ForbiddenFailure
            ? FeedNotice.signInToFollow
            : FeedNotice.followFailed,
      );
    }
  }

  void _replaceSuggestion(ProfileSummary account) {
    final current = state;
    if (isClosed || current is! FeedLoaded) return;
    emit(
      current.copyWith(
        suggestions: [
          for (final item in current.suggestions)
            item.id == account.id ? account : item,
        ],
      ),
    );
  }

  /// Guardar todavía no tiene backend: es local.
  void toggleSave(String id) {
    final post = _find(id);
    if (post != null) _replace(post.copyWith(isSaved: !post.isSaved));
  }

  Future<void> edit(Post post, String body) async {
    try {
      final updated = await _posts.update(post.id, body: body);
      _replace(updated);
      _notify(FeedNotice.edited);
    } on Failure catch (failure) {
      _notify(_noticeFor(failure));
    }
  }

  /// Quién dio like. Lo pide la hoja; el cubit sólo pasa la consulta para
  /// que la vista no toque el repositorio.
  Future<List<PostLiker>> likersOf(String postId) => _posts.likers(postId);

  Future<void> delete(Post post) async {
    try {
      await _posts.delete(post.id);
      final current = state;
      if (current is FeedLoaded) {
        emit(
          current.copyWith(
            posts: current.posts.where((item) => item.id != post.id).toList(),
          ),
        );
      }
      _notify(FeedNotice.deleted);
    } on Failure catch (failure) {
      _notify(_noticeFor(failure));
    }
  }

  Future<void> report(Post post, ModerationReason reason) async {
    try {
      await _posts.report(ReportTarget.post, post.id, reason);
      _notify(FeedNotice.reported);
    } on Failure catch (failure) {
      _notify(_noticeFor(failure));
    }
  }

  Post? _find(String id) {
    final current = state;
    if (current is! FeedLoaded) return null;
    for (final post in current.posts) {
      if (post.id == id) return post;
    }
    return null;
  }

  void _replace(Post post) {
    final current = state;
    if (current is! FeedLoaded) return;
    emit(
      current.copyWith(
        posts: [
          for (final item in current.posts) item.id == post.id ? post : item,
        ],
      ),
    );
  }

  void _notify(FeedNotice notice) {
    final current = state;
    if (current is FeedLoaded) {
      emit(
        current.copyWith(
          notice: notice,
          noticeSerial: current.noticeSerial + 1,
        ),
      );
    }
  }

  static FeedNotice _noticeFor(Failure failure) => failure is ForbiddenFailure
      ? FeedNotice.forbidden
      : FeedNotice.actionFailed;
}
