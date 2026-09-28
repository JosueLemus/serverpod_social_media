import '../../../../core/mock/mock_platform.dart';
import '../../domain/entities/moderation_action.dart';
import '../../domain/repositories/moderation_repository.dart';

class MockModerationRepository implements ModerationRepository {
  MockModerationRepository(this._platform);

  final MockPlatform _platform;

  @override
  Future<List<ModerationReport>> reports() async => _platform.openReports();

  @override
  Future<List<ModerationAction>> list() async => _platform.moderationActions();

  @override
  Future<void> reportComment({
    required String liveId,
    required String commentId,
    required ModerationReason reason,
  }) async => _platform.reportComment(
    liveId: liveId,
    commentId: commentId,
    reason: reason,
  );

  @override
  Future<ModerationAction> resolve(
    String reportId,
    ModerationDecision decision,
  ) async => _platform.resolveReport(reportId, decision);

  @override
  Future<void> dismiss(String reportId) async =>
      _platform.dismissReport(reportId);

  @override
  Stream<void> changes() => _platform.changes;
}
