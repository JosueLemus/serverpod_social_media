import '../../../../core/errors/failures.dart';
import '../../../../core/mock/demo_accounts.dart';
import '../../../../core/mock/mock_platform.dart';
import '../../../moderation/domain/entities/moderation_action.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_data_source.dart';

class MockAuthRepository implements AuthRepository {
  MockAuthRepository(this._local, this._platform);

  final AuthLocalDataSource _local;
  final MockPlatform _platform;

  static const _guest = AppUser(
    id: 'guest',
    username: 'invitado',
    name: 'Invitado',
    role: UserRole.visitor,
  );

  @override
  Future<AppUser?> currentUser() async {
    final id = _local.readAccountId();
    final user = id == null ? null : _platform.accountById(id);
    if (user == null) return null;
    _platform.bindSession(user.id);
    if (!user.isActive) throw const AccountSuspendedFailure('restore');
    return user;
  }

  @override
  Future<AppUser> exploreAsGuest() async {
    // Guest access is intentionally ephemeral. It exists only in the active
    // AuthCubit session and must not restore after the app is reopened.
    await _local.clear();
    _platform.bindSession(null);
    return _guest;
  }

  /// El correo elige la cuenta sembrada; la contraseña no se valida en el
  /// mock. Un correo desconocido entra como Elena, la cuenta de demo: todo el
  /// contenido mock es de ella, y una sesión con otro nombre dejaba la barra
  /// diciendo `@creador` mientras el perfil decía `@elena_ux`.
  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    final account =
        _platform.accountByEmail(email) ??
        _platform.accountById(DemoAccounts.elena.id)!;
    try {
      final user = _platform.signIn(account.id);
      await _local.save(user.id);
      return user;
    } on AccountSuspendedFailure {
      _platform.bindSession(null);
      await _local.clear();
      rethrow;
    }
  }

  /// Los datos del formulario se ignoran en el mock: ver [signIn].
  @override
  Future<AppUser> signUp({
    required String name,
    required String username,
    required String email,
    required String password,
  }) => signIn(email: DemoAccounts.elena.email, password: password);

  @override
  Future<void> signOut() async {
    _platform.bindSession(null);
    await _local.clear();
  }

  @override
  Stream<AppUser?> watchSession() => _platform.changes.map((_) {
    final id = _platform.sessionAccountId;
    return id == null ? null : _platform.accountById(id);
  });

  @override
  Future<ModerationReason?> sanctionReason(String accountId) async =>
      _platform.statusReason(accountId);
}
