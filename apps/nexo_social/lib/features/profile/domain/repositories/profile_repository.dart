import '../../../auth/domain/entities/app_user.dart';

abstract interface class ProfileRepository {
  /// El estado público de la cuenta. Público a propósito: una sanción que no
  /// se ve desde afuera no se puede demostrar.
  Future<AccountStatus> statusOf(String username);

  Stream<void> changes();
}
