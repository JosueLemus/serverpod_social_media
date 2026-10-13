import 'package:nexo_social/features/live/domain/entities/live_stage.dart';

/// El escenario vacío, para los fakes de `LiveRepository` de tests que no
/// prueban el escenario: el contrato lo exige y cada fake lo repetía.
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
}
