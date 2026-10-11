import '../../../auth/domain/entities/app_user.dart';
import '../../../feed/domain/entities/post_extras.dart';
import '../entities/public_profile.dart';

abstract interface class ProfileRepository {
  /// El perfil público. Lanza `NotFoundFailure` si la cuenta no existe.
  Future<PublicProfile> byUsername(String username);

  /// Las publicaciones de [profile], de la más nueva a la más vieja. Pasar el
  /// `nextCursor` de la página anterior para seguir.
  Future<PostPage> postsOf(PublicProfile profile, {String? cursor});

  /// El estado público de la cuenta. Público a propósito: una sanción que no
  /// se ve desde afuera no se puede demostrar.
  Future<AccountStatus> statusOf(String username);

  Stream<void> changes();
}
