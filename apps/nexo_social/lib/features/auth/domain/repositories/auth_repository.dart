import '../../../moderation/domain/entities/moderation_action.dart';
import '../entities/app_user.dart';

/// A request identifier is not a credential. It may live in memory while the
/// person enters the email code, but passwords, codes and verification tokens
/// are never stored by the app.
class EmailVerificationRequest {
  const EmailVerificationRequest(this.id);

  final String id;
}

abstract interface class AuthRepository {
  /// Lanza `AccountSuspendedFailure` si la sesión guardada es de una cuenta
  /// que fue sancionada mientras tanto.
  Future<AppUser?> currentUser();

  /// Lanza `AccountSuspendedFailure` sobre una cuenta sancionada.
  Future<AppUser> signIn({required String email, required String password});
  Future<EmailVerificationRequest> startRegistration({required String email});
  Future<AppUser> finishRegistration({
    required EmailVerificationRequest request,
    required String verificationCode,
    required String password,
  });

  Future<EmailVerificationRequest> startPasswordReset({required String email});
  Future<void> finishPasswordReset({
    required EmailVerificationRequest request,
    required String verificationCode,
    required String newPassword,
  });
  Future<AppUser> exploreAsGuest();
  Future<void> signOut();

  /// La cuenta de la sesión, cada vez que cambia del lado del servidor: un
  /// rol, una verificación o una suspensión. Null si la sesión se revocó.
  Stream<AppUser?> watchSession();

  /// Por qué se sancionó la cuenta, para decírselo a quien la usa.
  Future<ModerationReason?> sanctionReason(String accountId);
}
