import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_data_source.dart';

class MockAuthRepository implements AuthRepository {
  MockAuthRepository(this._local);
  final AuthLocalDataSource _local;
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
    await _local.save(user);
    return user;
  }

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    const user = AppUser(
      id: 'creator-1',
      username: 'elena_ux',
      name: 'Elena Vega',
      role: UserRole.creator,
    );
    await _local.save(user);
    return user;
  }

  @override
  Future<AppUser> signUp({
    required String name,
    required String username,
    required String email,
    required String password,
  }) async {
    final user = AppUser(
      id: 'user-$username',
      username: username,
      name: name,
      role: UserRole.creator,
    );
    await _local.save(user);
    return user;
  }

  @override
  Future<void> signOut() => _local.clear();
}
