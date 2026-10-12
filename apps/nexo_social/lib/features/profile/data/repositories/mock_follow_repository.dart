import '../../../../core/errors/failures.dart';
import '../../../../core/mock/demo_accounts.dart';
import '../../../../core/mock/mock_platform.dart';
import '../../../../core/storage/mock_social_store.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../domain/entities/follow.dart';
import '../../domain/repositories/follow_repository.dart';

/// Seguir en el modo mock (`AUTH_SOURCE=mock`) y en los tests.
///
/// Guarda a quién sigue la sesión en `MockSocialStore`, por username, que es
/// lo que ya leía el botón Seguir antes de M2. No cuenta seguidores: el mock
/// no tiene un grafo, y un contador inventado es peor que ninguno.
class MockFollowRepository implements FollowRepository {
  MockFollowRepository(this._platform, this._store);

  final MockPlatform _platform;
  final MockSocialStore _store;

  @override
  Future<FollowState> follow(String userId) => _set(userId, following: true);

  @override
  Future<FollowState> unfollow(String userId) => _set(userId, following: false);

  Future<FollowState> _set(String userId, {required bool following}) async {
    final viewer = _platform.sessionAccountId;
    if (viewer == null) throw const ForbiddenFailure('follow: unauthenticated');
    if (viewer == userId) throw const ConflictFailure('follow: self');
    final username = _usernameOf(userId);
    if (_store.isFollowing(username) != following) {
      await _store.toggleFollowing(username);
    }
    return FollowState(userId: userId, viewerFollows: following);
  }

  @override
  Future<FollowPage> list(
    String userId,
    FollowListKind kind, {
    String? cursor,
  }) async {
    // El mock sólo sabe a quién sigue la sesión.
    if (kind == FollowListKind.followers ||
        userId != _platform.sessionAccountId ||
        cursor != null) {
      return const FollowPage([]);
    }
    return FollowPage([
      for (final demo in _demos)
        if (_store.isFollowing(demo.username)) ?_summaryOf(demo),
    ]);
  }

  @override
  Future<List<ProfileSummary>> suggestions({int? limit}) async {
    final viewer = _platform.sessionAccountId;
    final picks = [
      for (final demo in _demos)
        if (demo.id != viewer && !_store.isFollowing(demo.username))
          ?_summaryOf(demo, creatorsOnly: true),
    ];
    return picks.take(limit ?? 10).toList();
  }

  static const _demos = [...DemoAccounts.all, DemoAccounts.spammer];

  String _usernameOf(String userId) {
    final user = _platform.accountById(userId);
    // Los autores del feed mock que no son cuentas sembradas usan el
    // username como id (ver `MockProfileRepository`).
    return user?.username ?? userId;
  }

  ProfileSummary? _summaryOf(DemoAccount demo, {bool creatorsOnly = false}) {
    final user = _platform.accountById(demo.id);
    if (user == null) return null;
    if (creatorsOnly && !(user.isCreator && user.isVerified)) return null;
    if (user.status != AccountStatus.active) return null;
    return ProfileSummary(
      id: user.id,
      username: user.username,
      name: user.name,
      isCreator: user.isCreator,
      isVerified: user.isVerified,
      viewerFollows: _store.isFollowing(user.username),
    );
  }
}
