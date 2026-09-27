import '../entities/moderation_action.dart';

abstract interface class ModerationRepository {
  Future<List<ModerationAction>> list();
  Future<ModerationAction> create(
    ModerationType type,
    String target,
    String reason,
  );
}
