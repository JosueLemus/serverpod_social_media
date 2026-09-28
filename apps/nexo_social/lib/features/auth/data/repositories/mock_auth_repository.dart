import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_data_source.dart';

class MockAuthRepository implements AuthRepository {
  MockAuthRepository(this._local);

  final AuthLocalDataSource _local;

  /// La cuenta de demo.
  ///
  /// Iniciar sesión y registrarse devuelven **la misma** identidad a
  /// propósito: todo el contenido mock de la app —el feed, el perfil, los
  /// vivos— es el de Elena, y una sesión con otro nombre deja la barra
  /// diciendo `@creador` mientras el perfil debajo dice `@elena_ux`. Cuando
  /// Serverpod exista, cada método devolverá la cuenta real.
  static const _demoCreator = AppUser(
    id: 'creator-1',
    username: 'elena_ux',
    name: 'Elena Vega',
    role: UserRole.creator,
  );
  @override
  Future<AppUser?> currentUser() async => _local.read();
  @override
  Future<AppUser> exploreAsGuest() async {
    const user = AppUser(
      id: 'guest',
      username: 'invitado',
      name: 'Invitado',
      role: UserRole.visitor,
    );
    // Guest access is intentionally ephemeral. It exists only in the active
    // AuthCubit session and must not restore after the app is reopened.
    await _local.clear();
    return user;
  }

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    await _local.save(_demoCreator);
    return _demoCreator;
  }

  @override
  Future<AppUser> signUp({
    required String name,
    required String username,
    required String email,
    required String password,
  }) async {
    // Los datos del formulario se ignoran en el mock: ver [_demoCreator].
    await _local.save(_demoCreator);
    return _demoCreator;
  }

  @override
  Future<void> signOut() => _local.clear();
}
