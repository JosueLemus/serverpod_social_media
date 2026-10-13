import 'package:nexo_social/features/live/domain/entities/live_moderation.dart';
import 'package:nexo_social/features/live/domain/entities/live_reaction.dart';
import 'package:nexo_social/features/live/domain/entities/live_stage.dart';

/// El escenario vacío y la moderación de la sala sin efecto, para los fakes
/// de `LiveRepository` de tests que no prueban eso: el contrato lo exige y
/// cada fake lo repetía.
mixin StageStubs {
  Future<LiveStage> stage(String liveId) async => LiveStage.empty;
  Future<void> raiseHand(String liveId) async {}
  Future<void> lowerHand(String liveId) async {}
  Future<void> approveRequest(String liveId, String userId) async {}
  Future<void> denyRequest(String liveId, String userId) async {}
  Future<void> inviteToStage(String liveId, String userId) async {}
  Future<void> removeFromStage(String liveId, String userId) async {}
  Future<void> leaveStage(String liveId) async {}
  Future<void> setMicMuted(
    String liveId,
    String userId, {
    required bool muted,
  }) async {}
  Future<void> setCamera(String liveId, {required bool on}) async {}
  Future<void> assignModerator(String liveId, String? userId) async {}
  Future<void> muteChat(
    String liveId,
    String userId,
    LiveMuteDuration duration,
  ) async {}
  Future<void> unmuteChat(String liveId, String userId) async {}
  Future<void> kick(String liveId, String userId) async {}
  Future<void> ban(String liveId, String userId) async {}
  Future<void> unban(String userId) async {}
  Future<void> unhideComment(String liveId, String commentId) async {}
  Future<void> deleteComment(String liveId, String commentId) async {}
  Future<void> pinComment(String liveId, String? commentId) async {}
  Future<void> highlightQuestion(String liveId, String? commentId) async {}
  Future<void> react(String liveId, LiveReactionKind kind) async {}
}
