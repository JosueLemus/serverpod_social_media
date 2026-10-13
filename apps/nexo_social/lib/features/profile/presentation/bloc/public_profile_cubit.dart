import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../../feed/domain/entities/post.dart';
import '../../../feed/domain/entities/post_extras.dart';
import '../../../feed/domain/repositories/post_repository.dart';
import '../../../live/domain/entities/live_session.dart';
import '../../../live/domain/repositories/live_repository.dart';
import '../../../subscriptions/domain/repositories/subscription_repository.dart';
import '../../domain/entities/public_profile.dart';
import '../../domain/repositories/follow_repository.dart';
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

/// Por qué no se pudo seguir. La View elige la copy.
enum ProfileNotice { followFailed, signInToFollow, suspended }

class PublicProfileLoaded extends PublicProfileState {
  const PublicProfileLoaded({
    required this.profile,
    this.posts = const [],
    this.nextCursor,
    this.isLoadingMore = false,
    this.lives = const [],
    this.notice,
    this.noticeSerial = 0,
    this.isMember = false,
  });

  final PublicProfile profile;
  final List<Post> posts;
  final String? nextCursor;
  final bool isLoadingMore;

  /// Los vivos de esta cuenta: al aire, programados y grabados.
  final List<LiveSession> lives;

  /// El último rechazo al seguir. [noticeSerial] crece con cada uno, así que
  /// el mismo dos veces seguidas también se avisa.
  final ProfileNotice? notice;
  final int noticeSerial;

  /// Si quien mira tiene la membresía de esta cuenta: la pestaña Premium se
  /// muestra abierta en vez de con el candado.
  final bool isMember;

  bool get hasMore => nextCursor != null;

  PublicProfileLoaded copyWith({
    PublicProfile? profile,
    List<Post>? posts,
    String? Function()? nextCursor,
    bool? isLoadingMore,
    ProfileNotice? notice,
    int? noticeSerial,
    bool? isMember,
  }) => PublicProfileLoaded(
    profile: profile ?? this.profile,
    posts: posts ?? this.posts,
    nextCursor: nextCursor == null ? this.nextCursor : nextCursor(),
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    lives: lives,
    notice: notice ?? this.notice,
    noticeSerial: noticeSerial ?? this.noticeSerial,
    isMember: isMember ?? this.isMember,
  );

  @override
  List<Object?> get props => [
    profile,
    posts,
    nextCursor,
    isLoadingMore,
    lives,
    notice,
    noticeSerial,
    isMember,
  ];
}

/// El perfil de [username]: lo que dice el servidor de la cuenta, sus
/// publicaciones y sus vivos. Antes la pantalla tenía a Elena escrita a mano
/// y mostraba lo mismo para cualquier cuenta.
class PublicProfileCubit extends Cubit<PublicProfileState> {
  PublicProfileCubit(
    this._profiles,
    this._lives,
    this._posts,
    this.username, [
    this._follows,
    this._subscriptions,
  ]) : super(const PublicProfileLoading()) {
    // Publicar, editar, borrar o dar like desde otra pestaña tiene que verse
    // en el perfil propio, que el shell conserva montado.
    _changes = _posts.changes().listen((_) => unawaited(_reload()));
    // Seguir desde el feed, Explorar o un vivo cambia el botón y el contador
    // de este perfil. Sólo se relee la cuenta: las publicaciones no cambian.
    _followChanges = _follows?.changes().listen(
      (_) => unawaited(_refreshProfile()),
    );
    // Suscribirse desde el muro abre la pestaña Premium al volver.
    _membershipChanges = _subscriptions?.changes().listen(
      (_) => unawaited(_refreshMembership()),
    );
  }

  final ProfileRepository _profiles;
  final LiveRepository _lives;
  final PostRepository _posts;
  final FollowRepository? _follows;
  final SubscriptionRepository? _subscriptions;
  final String username;
  late final StreamSubscription<void> _changes;
  StreamSubscription<void>? _followChanges;
  StreamSubscription<void>? _membershipChanges;

  Future<void> load() async {
    emit(const PublicProfileLoading());
    await _reload();
  }

  Future<void> _reload() async {
    try {
      final profile = await _profiles.byUsername(username);
      final page = await _profiles.postsOf(profile);
      final lives = await _livesOf(profile);
      final isMember = await _isMember();
      if (isClosed) return;
      final current = state;
      final merged = current is PublicProfileLoaded
          ? mergeFirstPage(current, page)
          : (posts: page.posts, nextCursor: page.nextCursor);
      emit(
        PublicProfileLoaded(
          profile: profile,
          posts: merged.posts,
          nextCursor: merged.nextCursor,
          lives: lives,
          isMember: isMember,
          // Un aviso pendiente no se pierde por una relectura.
          notice: current is PublicProfileLoaded ? current.notice : null,
          noticeSerial: current is PublicProfileLoaded
              ? current.noticeSerial
              : 0,
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

  /// La primera página recién leída, más lo ya paginado que queda después.
  ///
  /// Un like desde la publicación relee el perfil que quedó debajo: si la
  /// relectura **reemplazara** la lista, quien había bajado tres páginas
  /// volvería a la primera. Lo guardado es local, así que se copia por id.
  @visibleForTesting
  static ({List<Post> posts, String? nextCursor}) mergeFirstPage(
    PublicProfileLoaded current,
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
    if (page.nextCursor == null || fresh.isEmpty) {
      return (posts: fresh, nextCursor: page.nextCursor);
    }
    final ids = {for (final post in fresh) post.id};
    final boundary = fresh.last.createdAt;
    final older = [
      for (final post in current.posts)
        if (!ids.contains(post.id) && !post.createdAt.isAfter(boundary)) post,
    ];
    return (
      posts: [...fresh, ...older],
      nextCursor: older.isEmpty ? page.nextCursor : current.nextCursor,
    );
  }

  /// Sólo la cuenta: seguir cambió el botón y el contador, no las
  /// publicaciones.
  Future<void> _refreshProfile() async {
    try {
      final profile = await _profiles.byUsername(username);
      final latest = state;
      if (isClosed || latest is! PublicProfileLoaded) return;
      emit(latest.copyWith(profile: profile));
    } on Failure {
      // Lo que ya se ve sigue valiendo.
    }
  }

  Future<void> _refreshMembership() async {
    final isMember = await _isMember();
    final latest = state;
    if (isClosed || latest is! PublicProfileLoaded) return;
    emit(latest.copyWith(isMember: isMember));
  }

  /// Sin repositorio de membresías, o si no se pudo leer, queda cerrado: el
  /// candado es lo seguro, el servidor decide igual al abrir el contenido.
  Future<bool> _isMember() async {
    final subscriptions = _subscriptions;
    if (subscriptions == null) return false;
    try {
      return (await subscriptions.entitlement(username)).active;
    } on Failure {
      return false;
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

  /// Optimista: el botón y el contador cambian en el turno del tap. La
  /// respuesta del servidor deja el número real; si falla, todo vuelve como
  /// estaba y se dice por qué.
  Future<void> toggleFollow() async {
    final follows = _follows;
    final current = state;
    if (follows == null || current is! PublicProfileLoaded) return;
    final before = current.profile;
    final following = !before.viewerFollows;
    emit(
      current.copyWith(
        profile: before.copyWith(
          viewerFollows: following,
          followers: () => switch (before.followers) {
            final count? => count + (following ? 1 : -1),
            null => null,
          },
        ),
      ),
    );
    try {
      final result = following
          ? await follows.follow(before.id)
          : await follows.unfollow(before.id);
      final latest = state;
      if (isClosed || latest is! PublicProfileLoaded) return;
      emit(
        latest.copyWith(
          profile: latest.profile.copyWith(
            viewerFollows: result.viewerFollows,
            followers: result.followerCount == null
                ? null
                : () => result.followerCount,
          ),
        ),
      );
    } on Failure catch (failure) {
      final latest = state;
      if (isClosed || latest is! PublicProfileLoaded) return;
      emit(
        latest.copyWith(
          profile: before,
          notice: switch (failure) {
            AccountSuspendedFailure() => ProfileNotice.suspended,
            ForbiddenFailure() => ProfileNotice.signInToFollow,
            _ => ProfileNotice.followFailed,
          },
          noticeSerial: latest.noticeSerial + 1,
        ),
      );
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
    await _followChanges?.cancel();
    await _membershipChanges?.cancel();
    return super.close();
  }
}
