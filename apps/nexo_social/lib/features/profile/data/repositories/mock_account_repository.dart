import '../../../../core/errors/failures.dart';
import '../../../feed/domain/entities/post_extras.dart';
import '../../domain/entities/profile_changes.dart';
import '../../domain/repositories/account_repository.dart';

/// Editar el perfil necesita el servidor: el mock no modela perfiles
/// editables. Responde que no se pudo, en vez de fingir que guardó.
class MockAccountRepository implements AccountRepository {
  const MockAccountRepository();

  static const _unavailable = ServerFailure('mock: sin servidor');

  @override
  Future<void> update(ProfileChanges changes) async => throw _unavailable;

  @override
  Future<void> setAvatar(MediaAttachment? image) async => throw _unavailable;

  @override
  Future<void> setCover(MediaAttachment? image) async => throw _unavailable;

  @override
  Future<void> becomeCreator() async => throw _unavailable;
}
