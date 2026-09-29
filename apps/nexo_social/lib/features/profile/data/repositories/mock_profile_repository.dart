import '../../../../core/mock/mock_platform.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../domain/repositories/profile_repository.dart';

class MockProfileRepository implements ProfileRepository {
  MockProfileRepository(this._platform);

  final MockPlatform _platform;

  @override
  Future<AccountStatus> statusOf(String username) async =>
      _platform.statusOf(username);

  @override
  Stream<void> changes() => _platform.changes;
}
