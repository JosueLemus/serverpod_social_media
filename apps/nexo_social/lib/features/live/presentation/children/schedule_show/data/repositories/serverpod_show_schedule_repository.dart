import 'package:nexo_client/nexo_client.dart' as api;
import 'package:serverpod_auth_core_client/serverpod_auth_core_client.dart';

import '../../../../../../../core/errors/failures.dart';
import '../../../../../../../core/network/serverpod_failures.dart';
import '../../../../../data/repositories/serverpod_live_repository.dart';
import '../../../../../domain/entities/live_session.dart';
import '../../domain/entities/show_draft.dart';
import '../../domain/repositories/show_schedule_repository.dart';
import '../datasources/show_draft_local_data_source.dart';

/// Programar un show contra `live.schedule` (SDD 0006).
///
/// El borrador sigue en el dispositivo, por cuenta: es lo que se está
/// escribiendo, no un show. Programar lo valida el servidor (creador
/// verificado, fecha futura, tope de invitados).
class ServerpodShowScheduleRepository implements ShowScheduleRepository {
  ServerpodShowScheduleRepository(this._client, this._auth, this._local);

  final api.Client _client;
  final ClientAuthSessionManager _auth;
  final ShowDraftLocalDataSource _local;

  String get _accountId {
    final id = _auth.authInfo?.authUserId.toString();
    if (id == null) throw const ForbiddenFailure('unauthenticated');
    return id;
  }

  @override
  Future<ShowDraft?> loadDraft() async => _local.read(_accountId);

  @override
  Future<void> saveDraft(ShowDraft draft) => _local.write(_accountId, draft);

  @override
  Future<void> clearDraft() => _local.clear(_accountId);

  /// Los mismos rechazos que el mock: no existe, sos vos, o no puede
  /// participar.
  @override
  Future<ShowGuest> findGuest(String username) async {
    final handle = username.trim().replaceFirst(RegExp('^@+'), '');
    final api.ProfileView profile;
    try {
      profile = await _client.profiles.byUsername(handle);
    } catch (error) {
      throw failureFromServer(error);
    }
    if (profile.userId.toString() == _accountId) {
      throw const ConflictFailure('cohost: host as cohost');
    }
    if (profile.status != api.AccountStatus.active) {
      throw const ForbiddenFailure('cohost: inactive');
    }
    return ShowGuest(
      id: profile.userId.toString(),
      username: profile.username,
      name: profile.displayName,
    );
  }

  @override
  Future<LiveSession> schedule(ShowDraft draft) async {
    try {
      final show = await _client.live.schedule(
        api.LiveShowDraft(
          title: draft.title,
          description: draft.description,
          startsAt: draft.startsAt.toUtc(),
          durationMinutes: draft.durationMinutes,
          access: draft.access == ShowAccess.members
              ? api.LiveShowAccess.members
              : api.LiveShowAccess.public,
          allowQuestions: draft.allowQuestions,
          recordReplay: draft.recordReplay,
          guestUsernames: [for (final guest in draft.guests) guest.username],
        ),
      );
      return ServerpodLiveRepository.toSession(show);
    } catch (error) {
      throw failureFromServer(error);
    }
  }
}
