import 'package:nexo_client/nexo_client.dart' as api;

import '../../../../core/errors/failures.dart';
import '../../../../core/network/serverpod_failures.dart';
import '../../../feed/data/repositories/serverpod_post_repository.dart';
import '../../domain/entities/follow.dart';
import '../../domain/repositories/follow_repository.dart';

/// Seguir sobre `client.follows`. El servidor es la autoridad: los
/// contadores que devuelve reemplazan a los optimistas de la pantalla.
class ServerpodFollowRepository implements FollowRepository {
  ServerpodFollowRepository(this._client);

  final api.Client _client;

  @override
  Future<FollowState> follow(String userId) =>
      _guard(() async => toState(await _client.follows.follow(_uuid(userId))));

  @override
  Future<FollowState> unfollow(String userId) => _guard(
    () async => toState(await _client.follows.unfollow(_uuid(userId))),
  );

  @override
  Future<FollowPage> list(
    String userId,
    FollowListKind kind, {
    String? cursor,
  }) => _guard(() async {
    final after = ServerpodPostRepository.decodeCursor(cursor);
    final page = switch (kind) {
      FollowListKind.followers => await _client.follows.followers(
        _uuid(userId),
        after: after,
      ),
      FollowListKind.following => await _client.follows.following(
        _uuid(userId),
        after: after,
      ),
    };
    return FollowPage([
      for (final view in page.items) toSummary(view),
    ], nextCursor: ServerpodPostRepository.encodeCursor(page.nextCursor));
  });

  @override
  Future<List<ProfileSummary>> suggestions({int? limit}) => _guard(
    () async => [
      for (final view in await _client.follows.suggestions(limit: limit))
        toSummary(view),
    ],
  );

  /// Públicos para los tests y para quien arma listas con perfiles del
  /// servidor (el feed por secciones, Explorar).
  static ProfileSummary toSummary(api.ProfileView view) => ProfileSummary(
    id: view.userId.toString(),
    username: view.username,
    name: view.displayName,
    bio: (view.bio?.trim().isEmpty ?? true) ? null : view.bio!.trim(),
    avatarUrl: view.avatarUrl,
    isCreator: view.isCreator,
    isVerified: view.verification == api.VerificationStatus.verified,
    followerCount: view.followerCount,
    viewerFollows: view.viewerFollows,
  );

  static FollowState toState(api.FollowState state) => FollowState(
    userId: state.userId.toString(),
    viewerFollows: state.viewerFollows,
    followerCount: state.followerCount,
  );

  /// Un id que no es UUID no existe en el servidor: es un `NotFound`, no una
  /// excepción de formato que se cuela hasta la pantalla.
  static api.UuidValue _uuid(String id) {
    try {
      return api.UuidValue.fromString(id);
    } on FormatException {
      throw const NotFoundFailure('account');
    }
  }

  static Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on Failure {
      rethrow;
    } catch (error) {
      throw failureFromServer(error);
    }
  }
}
