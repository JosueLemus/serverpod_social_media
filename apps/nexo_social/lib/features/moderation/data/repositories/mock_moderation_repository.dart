import '../../domain/entities/moderation_action.dart';
import '../../domain/repositories/moderation_repository.dart';

class MockModerationRepository implements ModerationRepository {
  final _actions = <ModerationAction>[];
  @override
  Future<ModerationAction> create(
    ModerationType type,
    String target,
    String reason,
  ) async {
    final action = ModerationAction(
      id: 'audit-${_actions.length + 1}',
      type: type,
      target: target,
      reason: reason,
      actor: 'moderador_demo',
      createdAt: DateTime.now(),
    );
    _actions.insert(0, action);
    return action;
  }

  @override
  Future<List<ModerationAction>> list() async => List.of(_actions);
}
