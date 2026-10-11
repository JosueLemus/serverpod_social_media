import 'package:nexo_client/nexo_client.dart' as api;

import '../../../../core/errors/failures.dart';
import '../../../../core/mock/mock_platform.dart';
import '../../../../core/network/serverpod_failures.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../feed/data/repositories/serverpod_post_repository.dart';
import '../../../feed/domain/entities/post_extras.dart';
import '../../domain/entities/public_profile.dart';
import '../../domain/repositories/profile_repository.dart';

/// Perfiles sobre `client.profiles` y sus publicaciones sobre
/// `client.posts.byAuthor`.
///
/// [_consoleSanctions] es la única pieza mock: las suspensiones de la
/// consola del operador todavía viven en `MockPlatform` (M6). Sin ella, una
/// cuenta real suspendida desde la consola salía de la app pero su perfil
/// no mostraba la sanción. Se va con M6, igual que el puente de auth.
class ServerpodProfileRepository implements ProfileRepository {
  ServerpodProfileRepository(this._client, [this._consoleSanctions]);

  final api.Client _client;
  final MockPlatform? _consoleSanctions;

  @override
  Future<PublicProfile> byUsername(String username) => _guard(
    () async => toProfile(await _client.profiles.byUsername(username)),
  );

  @override
  Future<PostPage> postsOf(PublicProfile profile, {String? cursor}) =>
      _guard(() async {
        final page = await _client.posts.byAuthor(
          api.UuidValue.fromString(profile.id),
          after: ServerpodPostRepository.decodeCursor(cursor),
        );
        return PostPage([
          for (final view in page.items) ServerpodPostRepository.toPost(view),
        ], nextCursor: ServerpodPostRepository.encodeCursor(page.nextCursor));
      });

  @override
  Future<AccountStatus> statusOf(String username) async {
    final status = (await byUsername(username)).status;
    if (status != AccountStatus.active) return status;
    return _consoleSanctions?.statusOf(username) ?? status;
  }

  @override
  Stream<void> changes() =>
      _consoleSanctions?.changes ?? const Stream<void>.empty();

  /// Público para los tests: es la traducción que más se puede romper.
  static PublicProfile toProfile(api.ProfileView view) => PublicProfile(
    id: view.userId.toString(),
    username: view.username,
    name: view.displayName,
    bio: (view.bio?.trim().isEmpty ?? true) ? null : view.bio!.trim(),
    isCreator: view.isCreator,
    verification: VerificationStatus.values.byName(view.verification.name),
    status: AccountStatus.values.byName(view.status.name),
    joinedAt: view.createdAt.toLocal(),
    followers: view.followerCount,
    following: view.followingCount,
    viewerFollows: view.viewerFollows,
    avatarUrl: view.avatarUrl,
  );

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
