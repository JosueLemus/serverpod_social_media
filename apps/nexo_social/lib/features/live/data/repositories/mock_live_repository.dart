import 'dart:async';

import '../../../../core/errors/failures.dart';
import '../../../../core/mock/mock_platform.dart';
import '../../domain/entities/live_comment.dart';
import '../../domain/entities/live_media_grant.dart';
import '../../domain/entities/live_room_event.dart';
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
  Future<List<LiveSession>> mine() async {
    final host = _platform.sessionAccountId;
    if (host == null) return const [];
    return [
      for (final live in _platform.lives())
        if (live.hostId == host) live,
    ];
  }

  @override
  Future<LiveSession?> byId(String id) async => _platform.live(id);

  @override
  Future<LiveSession> transition(String id, LiveStatus status) async =>
      _platform.transitionLive(id, status);

  /// Con las reglas que ya tiene la plataforma: se programa para dentro de
  /// un minuto (no acepta el pasado) y se inicia. El chequeo de "otro vivo al
  /// aire" va antes, para no dejar un show programado huérfano.
  @override
  Future<LiveSession> goLive(String title) async {
    final host = _platform.sessionAccountId;
    if (host != null &&
        _platform.lives().any((live) => live.hostId == host && _onAir(live))) {
      throw const ConflictFailure('live.goLive: already on air');
    }
    final show = _platform.scheduleShow(
      title: title,
      description: '',
      startsAt: DateTime.now().add(const Duration(minutes: 1)),
      durationMinutes: 60,
      isPremium: false,
      cohostIds: const [],
      allowQuestions: true,
      recordReplay: true,
    );
    return _platform.transitionLive(show.id, LiveStatus.live);
  }

  /// Modo de prueba: token vacío y uid 0. El rol sigue la regla del
  /// servidor: publica sólo el host con el vivo al aire.
  @override
  Future<LiveMediaGrant> mediaToken(String liveId) async {
    final live = _platform.live(liveId);
    if (live == null) throw const NotFoundFailure('live');
    if (!_onAir(live) && live.status != LiveStatus.scheduled) {
      throw const ConflictFailure('live.mediaToken: not on air');
    }
    final isHost = live.hostId == _platform.sessionAccountId;
    return LiveMediaGrant(
      channel: 'nexo_live_${liveId.replaceAll(RegExp('[^A-Za-z0-9_]'), '_')}',
      role: isHost && _onAir(live)
          ? LiveMediaGrantRole.publisher
          : LiveMediaGrantRole.subscriber,
    );
  }

  static bool _onAir(LiveSession live) =>
      live.status == LiveStatus.live || live.status == LiveStatus.ending;

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

  /// El mock no sabe decir qué cambió: emite la sala entera al suscribirse y
  /// de nuevo con cada cambio de la plataforma.
  ///
  /// Con un controller y no con `async*`: cancelar un `async*` parado en un
  /// `await for` espera al próximo evento, así que cerrar la sala colgaba
  /// hasta que otra cosa cambiara.
  @override
  Stream<LiveRoomEvent> watch(String liveId) {
    late final StreamController<LiveRoomEvent> controller;
    StreamSubscription<void>? changes;
    void push() {
      try {
        controller.add(_snapshot(liveId));
      } on Failure catch (failure) {
        controller.addError(failure);
      }
    }

    controller = StreamController<LiveRoomEvent>(
      onListen: () {
        push();
        changes = _platform.changes.listen((_) => push());
      },
      onCancel: () => changes?.cancel(),
    );
    return controller.stream;
  }

  LiveRoomSnapshot _snapshot(String liveId) {
    final session = _platform.live(liveId);
    if (session == null) throw const NotFoundFailure('live');
    return LiveRoomSnapshot(
      session: session,
      role: _platform.roleIn(liveId),
      comments: _platform.comments(liveId),
    );
  }

  @override
  Stream<void> changes() => _platform.changes;
}
