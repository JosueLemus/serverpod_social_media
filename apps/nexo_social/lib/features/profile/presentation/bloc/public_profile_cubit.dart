import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../../feed/domain/entities/post.dart';
import '../../../feed/domain/repositories/post_repository.dart';
import '../../../live/domain/entities/live_session.dart';
import '../../../live/domain/repositories/live_repository.dart';
import '../../domain/entities/public_profile.dart';
import '../../domain/repositories/profile_repository.dart';

sealed class PublicProfileState extends Equatable {
  const PublicProfileState();

  @override
  List<Object?> get props => const [];
}

class PublicProfileLoading extends PublicProfileState {
  const PublicProfileLoading();
}

/// La cuenta no existe, o ya no se puede ver.
class PublicProfileNotFound extends PublicProfileState {
  const PublicProfileNotFound();
}

class PublicProfileFailure extends PublicProfileState {
  const PublicProfileFailure({this.offline = false});

  final bool offline;

  @override
  List<Object?> get props => [offline];
}

class PublicProfileLoaded extends PublicProfileState {
  const PublicProfileLoaded({
    required this.profile,
    this.posts = const [],
    this.nextCursor,
    this.isLoadingMore = false,
    this.lives = const [],
  });

  final PublicProfile profile;
  final List<Post> posts;
  final String? nextCursor;
  final bool isLoadingMore;

  /// Los vivos de esta cuenta: al aire, programados y grabados.
  final List<LiveSession> lives;

  bool get hasMore => nextCursor != null;

  PublicProfileLoaded copyWith({
    List<Post>? posts,
    String? Function()? nextCursor,
    bool? isLoadingMore,
  }) => PublicProfileLoaded(
    profile: profile,
    posts: posts ?? this.posts,
    nextCursor: nextCursor == null ? this.nextCursor : nextCursor(),
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    lives: lives,
  );

  @override
  List<Object?> get props => [profile, posts, nextCursor, isLoadingMore, lives];
}

/// El perfil de [username]: lo que dice el servidor de la cuenta, sus
/// publicaciones y sus vivos. Antes la pantalla tenía a Elena escrita a mano
/// y mostraba lo mismo para cualquier cuenta.
class PublicProfileCubit extends Cubit<PublicProfileState> {
  PublicProfileCubit(this._profiles, this._lives, this._posts, this.username)
    : super(const PublicProfileLoading()) {
    // Publicar, editar o borrar desde otra pestaña tiene que verse en el
    // perfil propio, que el shell conserva montado.
    _changes = _posts.changes().listen((_) => unawaited(_reload()));
  }

  final ProfileRepository _profiles;
  final LiveRepository _lives;
  final PostRepository _posts;
  final String username;
  late final StreamSubscription<void> _changes;

  Future<void> load() async {
    emit(const PublicProfileLoading());
    await _reload();
  }

  Future<void> _reload() async {
    try {
      final profile = await _profiles.byUsername(username);
      final page = await _profiles.postsOf(profile);
      final lives = await _livesOf(profile);
      if (isClosed) return;
      emit(
        PublicProfileLoaded(
          profile: profile,
          posts: page.posts,
          nextCursor: page.nextCursor,
          lives: lives,
        ),
      );
    } on NotFoundFailure {
      if (!isClosed) emit(const PublicProfileNotFound());
    } on Failure catch (failure) {
      if (isClosed) return;
      // Un fallo al refrescar no borra lo que ya se estaba mostrando.
      if (state is PublicProfileLoaded) return;
      emit(PublicProfileFailure(offline: failure is NetworkFailure));
    }
  }

  Future<void> loadMore() async {
    final current = state;
    if (current is! PublicProfileLoaded ||
        !current.hasMore ||
        current.isLoadingMore) {
      return;
    }
    emit(current.copyWith(isLoadingMore: true));
    try {
      final page = await _profiles.postsOf(
        current.profile,
        cursor: current.nextCursor,
      );
      if (isClosed) return;
      // Sobre el estado de ahora y no sobre `current`: lo que cambió durante
      // el await no se pisa.
      final latest = state;
      if (latest is! PublicProfileLoaded) return;
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
      final latest = state;
      if (!isClosed && latest is PublicProfileLoaded) {
        emit(latest.copyWith(isLoadingMore: false));
      }
    }
  }

  /// Un perfil sin la lista de vivos se sigue viendo: la lista es un extra,
  /// no la razón de la pantalla.
  ///
  /// Por nombre visible porque `LiveSession` todavía no trae el usuario del
  /// host; el SDD 0006 lo suma (`hostUsername`) y esto pasa a compararlo.
  /// Por username, que es único; el nombre visible no lo es. El mock no
  /// conoce el username del host, y ahí se cae al nombre.
  static bool _hostedBy(LiveSession live, PublicProfile profile) =>
      live.hostUsername.isEmpty
      ? live.hostName == profile.name
      : live.hostUsername == profile.username;

  Future<List<LiveSession>> _livesOf(PublicProfile profile) async {
    try {
      return [
        for (final live in await _lives.list())
          if (_hostedBy(live, profile)) live,
      ];
    } on Failure {
      return const [];
    }
  }

  @override
  Future<void> close() async {
    await _changes.cancel();
    return super.close();
  }
}
