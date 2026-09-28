import '../entities/moderation_action.dart';

abstract interface class ModerationRepository {
  /// Pending reports, highest severity first.
  Future<List<ModerationReport>> reports();

  /// The audit trail, newest first.
  Future<List<ModerationAction>> list();

  Future<ModerationAction> create(
    ModerationType type,
    String target,
    String reason,
  );

  /// Resolving a report removes it from the queue but never from the trail —
  /// the action that resolved it is what stays.
  Future<void> resolve(String reportId);
}
