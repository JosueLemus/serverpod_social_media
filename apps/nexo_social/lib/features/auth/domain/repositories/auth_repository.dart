import '../../../moderation/domain/entities/moderation_action.dart';
import '../entities/app_user.dart';

abstract interface class AuthRepository {
  /// Lanza `AccountSuspendedFailure` si la sesión guardada es de una cuenta
  /// que fue sancionada mientras tanto.
  Future<AppUser?> currentUser();

  /// Lanza `AccountSuspendedFailure` sobre una cuenta sancionada.
  Future<AppUser> signIn({required String email, required String password});
  Future<AppUser> signUp({
    required String name,
    required String username,
    required String email,
    required String password,
  });
  Future<AppUser> exploreAsGuest();
  Future<void> signOut();

  /// La cuenta de la sesión, cada vez que cambia del lado del servidor: un
  /// rol, una verificación o una suspensión. Null si la sesión se revocó.
  Stream<AppUser?> watchSession();

  /// Por qué se sancionó la cuenta, para decírselo a quien la usa.
  Future<ModerationReason?> sanctionReason(String accountId);
}
