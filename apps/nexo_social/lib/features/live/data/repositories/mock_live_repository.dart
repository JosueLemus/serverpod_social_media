import '../../../../core/mock/mock_platform.dart';
import '../../domain/entities/live_comment.dart';
import '../../domain/entities/live_session.dart';
import '../../domain/repositories/live_repository.dart';

/// Capa fina sobre [MockPlatform]: las reglas —el gate de verificación, la
/// máquina de estados, quién puede ocultar— viven ahí, como van a vivir en
/// Serverpod.
class MockLiveRepository implements LiveRepository {
  MockLiveRepository(this._platform);

  final MockPlatform _platform;

  @override
  Future<List<LiveSession>> list() async => _platform.lives();

  @override
  Future<LiveSession?> byId(String id) async => _platform.live(id);

  @override
  Future<LiveSession> transition(String id, LiveStatus status) async =>
      _platform.transitionLive(id, status);

  @override
  Future<List<LiveComment>> comments(String liveId) async =>
      _platform.comments(liveId);

  @override
  Future<LiveComment> postComment(String liveId, String body) async =>
      _platform.postComment(liveId, body);

  @override
  Future<void> hideComment(String liveId, String commentId) async =>
      _platform.hideComment(liveId, commentId);

  @override
  Future<LiveRole> roleIn(String liveId) async => _platform.roleIn(liveId);

  @override
  Stream<void> changes() => _platform.changes;
}
