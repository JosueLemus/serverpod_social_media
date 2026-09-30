import '../../../../../../../core/errors/failures.dart';
import '../../../../../../../core/mock/mock_platform.dart';
import '../../../../../domain/entities/live_session.dart';
import '../../domain/entities/show_draft.dart';
import '../../domain/repositories/show_schedule_repository.dart';
import '../datasources/show_draft_local_data_source.dart';

class MockShowScheduleRepository implements ShowScheduleRepository {
  MockShowScheduleRepository(this._platform, this._local);

  final MockPlatform _platform;
  final ShowDraftLocalDataSource _local;

  String get _accountId {
    final id = _platform.sessionAccountId;
    if (id == null) throw const ForbiddenFailure('unauthenticated');
    return id;
  }

  @override
  Future<ShowDraft?> loadDraft() async => _local.read(_accountId);

  @override
  Future<void> saveDraft(ShowDraft draft) => _local.write(_accountId, draft);

  @override
  Future<void> clearDraft() => _local.clear(_accountId);

  @override
  Future<ShowGuest> findGuest(String username) async {
    final user = _platform.invitableAccount(username);
    return ShowGuest(id: user.id, username: user.username, name: user.name);
  }

  @override
  Future<LiveSession> schedule(ShowDraft draft) async => _platform.scheduleShow(
    title: draft.title,
    description: draft.description,
    startsAt: draft.startsAt,
    durationMinutes: draft.durationMinutes,
    isPremium: draft.access == ShowAccess.members,
    cohostIds: [for (final guest in draft.guests) guest.id],
    allowQuestions: draft.allowQuestions,
    recordReplay: draft.recordReplay,
  );
}
