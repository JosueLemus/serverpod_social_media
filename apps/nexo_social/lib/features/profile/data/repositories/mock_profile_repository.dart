import '../../../../core/errors/failures.dart';
import '../../../../core/mock/demo_accounts.dart';
import '../../../../core/mock/mock_platform.dart';
import '../../../../core/storage/mock_social_store.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../feed/domain/entities/post_extras.dart';
import '../../domain/entities/public_profile.dart';
import '../../domain/repositories/profile_repository.dart';

class MockProfileRepository implements ProfileRepository {
  MockProfileRepository(this._platform, this._store);

  final MockPlatform _platform;
  final MockSocialStore _store;

  /// Lo que el diseño muestra de Elena y el mock no modela: bio y métricas.
  /// Sólo el mock los trae; el servidor no los tiene todavía (F8).
  static const _extras = {
    'elena_ux': (
      bio:
          'Diseñadora de Producto & Mentora de Creadores. Construyendo el '
          'futuro de la economía creativa ✨',
      followers: 48500,
      following: 320,
      likes: 1200000,
    ),
  };

  @override
  Future<PublicProfile> byUsername(String username) async {
    final extras = _extras[username];
    for (final demo in [...DemoAccounts.all, DemoAccounts.spammer]) {
      if (demo.username != username) continue;
      final user = _platform.accountById(demo.id);
      if (user == null) break;
      return PublicProfile(
        id: user.id,
        username: user.username,
        name: user.name,
        bio: extras?.bio,
        isCreator: user.isCreator,
        verification: user.verification,
        status: user.status,
        followers: extras?.followers,
        following: extras?.following,
        likes: extras?.likes,
        viewerFollows: _store.isFollowing(user.username),
      );
    }
    // Los autores del feed mock que no son cuentas sembradas: su perfil sale
    // de sus publicaciones, para que tocar su nombre no lleve a "no existe".
    for (final post in _store.readPosts()) {
      if (post.author == username) {
        return PublicProfile(
          id: username,
          username: username,
          name: post.name,
          isCreator: true,
          verification: post.authorIsVerified
              ? VerificationStatus.verified
              : VerificationStatus.none,
          viewerFollows: _store.isFollowing(username),
        );
      }
    }
    throw const NotFoundFailure('profile');
  }

  @override
  Future<PostPage> postsOf(PublicProfile profile, {String? cursor}) async =>
      PostPage(
        cursor != null
            ? const []
            : [
                for (final post in _store.readPosts())
                  if (post.author == profile.username) post,
              ],
      );

  @override
  Future<AccountStatus> statusOf(String username) async =>
      _platform.statusOf(username);

  @override
  Stream<void> changes() => _platform.changes;
}
