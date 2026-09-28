import '../../../../core/mock/mock_platform.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../live/domain/entities/live_session.dart';
import '../../../moderation/domain/entities/moderation_action.dart';
import '../../domain/entities/account_detail.dart';
import '../../domain/entities/audit_entry.dart';
import '../../domain/repositories/admin_repository.dart';

class MockAdminRepository implements AdminRepository {
  MockAdminRepository(this._platform);

  final MockPlatform _platform;

  @override
  Future<ResultPage<AppUser>> searchAccounts(
    String query, {
    String? cursor,
  }) async => _platform.searchAccounts(query, cursor: cursor);

  @override
  Future<AccountDetail> account(String accountId) async =>
      _platform.accountDetail(accountId);

  @override
  Future<void> suspend(String accountId, ModerationReason reason) async =>
      _platform.suspend(accountId, reason);

  @override
  Future<void> ban(String accountId, ModerationReason reason) async =>
      _platform.ban(accountId, reason);

  @override
  Future<void> restore(String accountId) async => _platform.restore(accountId);

  @override
  Future<void> setVerification(
    String accountId, {
    required bool verified,
    ModerationReason? reason,
  }) async =>
      _platform.setVerification(accountId, verified: verified, reason: reason);

  @override
  Future<List<AppUser>> creators() async => _platform.creators();

  @override
  Future<List<LiveSession>> activeLives() async => _platform.activeLives();

  @override
  Future<void> forceEndLive(String liveId, ModerationReason reason) async =>
      _platform.forceEndLive(liveId, reason);

  @override
  Future<ResultPage<AuditEntry>> audit(
    AuditFilter filter, {
    String? cursor,
  }) async => _platform.audit(filter, cursor: cursor);

  @override
  Stream<void> changes() => _platform.changes;
}
