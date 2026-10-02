import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../../moderation/domain/entities/moderation_action.dart';
import '../../domain/entities/feed_filter.dart';
import '../../domain/entities/post.dart';
import '../../domain/entities/post_extras.dart';
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
}

class FeedLoaded extends FeedState {
  const FeedLoaded(
    this.posts, {
    this.filter = FeedFilter.forYou,
    this.nextCursor,
    this.isLoadingMore = false,
    this.notice,
    this.noticeSerial = 0,
  });

  /// Everything the feed holds, unfiltered. The filter is applied on read so
  /// switching tabs never drops a post from memory and never needs a refetch.
  final List<Post> posts;
  final FeedFilter filter;

  /// Null cuando no hay más páginas.
  final String? nextCursor;
  final bool isLoadingMore;

  /// El resultado de la última acción. [noticeSerial] crece con cada una,
  /// así que la misma dos veces seguidas también se avisa.
  final FeedNotice? notice;
  final int noticeSerial;

  bool get hasMore => nextCursor != null;

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
  }) => FeedLoaded(
    posts ?? this.posts,
    filter: filter ?? this.filter,
    nextCursor: nextCursor == null ? this.nextCursor : nextCursor(),
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    notice: notice ?? this.notice,
    noticeSerial: noticeSerial ?? this.noticeSerial,
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
  FeedCubit(this._posts) : super(const FeedInitial()) {
    // The feed is not rebuilt when the user returns from the composer: the
    // shell keeps one navigator per tab, so this cubit and its list survive.
    // Without this subscription a published post only showed up after a
    // restart.
    _changes = _posts.changes().listen((_) => unawaited(_reload()));
  }

  final PostRepository _posts;
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
      final page = await _posts.feed();
      if (isClosed) return;
      final current = state;
      emit(
        FeedLoaded(
          page.posts,
          filter: filter,
          nextCursor: page.nextCursor,
          notice: current is FeedLoaded ? current.notice : null,
          noticeSerial: current is FeedLoaded ? current.noticeSerial : 0,
        ),
      );
    } on Failure catch (failure) {
      if (isClosed) return;
      // Un fallo al refrescar no borra lo que ya se estaba mostrando.
      if (state is FeedLoaded) return;
      emit(FeedFailure(offline: failure is NetworkFailure));
    }
  }

  Future<void> loadMore() async {
    final current = state;
    if (current is! FeedLoaded || !current.hasMore || current.isLoadingMore) {
      return;
    }
    emit(current.copyWith(isLoadingMore: true));
    try {
      final page = await _posts.feed(cursor: current.nextCursor);
      if (isClosed) return;
      final known = {for (final post in current.posts) post.id};
      emit(
        current.copyWith(
          posts: [
            ...current.posts,
            ...page.posts.where((post) => !known.contains(post.id)),
          ],
          nextCursor: () => page.nextCursor,
          isLoadingMore: false,
        ),
      );
    } on Failure {
      if (!isClosed) emit(current.copyWith(isLoadingMore: false));
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
