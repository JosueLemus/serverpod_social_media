import 'dart:async';

import 'package:nexo_client/nexo_client.dart' as api;
import 'package:serverpod_auth_core_client/serverpod_auth_core_client.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/network/serverpod_failures.dart';
import '../../domain/entities/live_comment.dart';
import '../../domain/entities/live_media_grant.dart';
import '../../domain/entities/live_room_event.dart';
import '../../domain/entities/live_session.dart';
import '../../domain/repositories/live_repository.dart';

/// Vivos contra el módulo `live` de Serverpod (SDD 0006).
///
/// El servidor decide todo: permisos, estados y quién cuenta como
/// espectador. Este repositorio sólo traduce ids (`int` del servidor a
/// `String` del dominio) y errores (`failureFromServer`).
class ServerpodLiveRepository implements LiveRepository {
  ServerpodLiveRepository(this._client, this._auth);

  final api.Client _client;
  final ClientAuthSessionManager _auth;

  /// Cuánto esperar antes de reabrir `watchIndex` si se corta.
  static const indexRetryDelay = Duration(seconds: 2);

  late final _changes = StreamController<void>.broadcast(
    onListen: _openIndex,
    onCancel: _closeIndex,
  );
  StreamSubscription<api.LiveShowView>? _index;
  Timer? _indexRetry;

  @override
  Future<List<LiveSession>> list() => _guard(() async {
    final shows = await _client.live.list();
    return [for (final show in shows) toSession(show)];
  });

  @override
  Future<List<LiveSession>> mine() => _guard(() async {
    if (!_auth.isAuthenticated) return const [];
    final shows = await _client.live.mine();
    return [for (final show in shows) toSession(show)];
  });

  @override
  Future<LiveSession?> byId(String id) async {
    final showId = int.tryParse(id);
    if (showId == null) return null;
    try {
      return toSession(await _client.live.get(showId));
    } catch (error) {
      final failure = failureFromServer(error);
      if (failure is NotFoundFailure) return null;
      throw failure;
    }
  }

  @override
  Future<LiveSession> transition(String id, LiveStatus status) =>
      _guard(() async {
        final showId = _showId(id);
        final show = switch (status) {
          LiveStatus.live => await _client.live.start(showId),
          LiveStatus.recorded => await _client.live.end(showId),
          LiveStatus.published => await _client.live.publish(showId),
          LiveStatus.cancelled => await _client.live.cancel(showId),
          // El servidor no expone el resto: pedirlo sería una transición que
          // se rechaza después de que el usuario ya se comprometió.
          _ => throw ConflictFailure('live.transition: ${status.name}'),
        };
        _notify();
        return toSession(show);
      });

  @override
  Future<LiveSession> goLive(String title) => _guard(() async {
    final show = await _client.live.goLive(title);
    _notify();
    return toSession(show);
  });

  @override
  Future<LiveMediaGrant> mediaToken(String liveId) => _guard(
    () async => toGrant(await _client.live.mediaToken(_showId(liveId))),
  );

  static LiveMediaGrant toGrant(api.LiveMediaGrant grant) => LiveMediaGrant(
    appId: grant.appId,
    channel: grant.channel,
    uid: grant.uid,
    token: grant.token,
    role: switch (grant.role) {
      api.LiveMediaGrantRole.publisher => LiveMediaGrantRole.publisher,
      api.LiveMediaGrantRole.subscriber => LiveMediaGrantRole.subscriber,
    },
    expiresAt: grant.expiresAt,
  );

  @override
  Future<List<LiveComment>> comments(String liveId) => _guard(() async {
    final messages = await _client.live.chatHistory(_showId(liveId));
    return [for (final m in messages) toComment(m, me: _me)];
  });

  @override
  Future<LiveComment> postComment(String liveId, String body) =>
      _guard(() async {
        final message = await _client.live.sendChat(_showId(liveId), body);
        return toComment(message, me: _me);
      });

  @override
  Future<void> hideComment(String liveId, String commentId) => _guard(() async {
    final messageId = int.tryParse(commentId);
    if (messageId == null) throw const NotFoundFailure('comment');
    await _client.live.hideChat(messageId);
  });

  @override
  Future<LiveRole> roleIn(String liveId) => _guard(() async {
    final showId = int.tryParse(liveId);
    if (showId == null) return LiveRole.audience;
    return toRole(await _client.live.roleIn(showId));
  });

  @override
  Stream<LiveRoomEvent> watch(String liveId) {
    final showId = int.tryParse(liveId);
    if (showId == null) return Stream.error(const NotFoundFailure('live'));
    final me = _me;
    return _client.live
        .watch(showId)
        .map((event) => toEvent(event, me: me))
        .where((event) => event != null)
        .cast<LiveRoomEvent>()
        .handleError((Object error) => throw failureFromServer(error));
  }

  @override
  Stream<void> changes() => _changes.stream;

  // --- Traducción ----------------------------------------------------------

  static LiveSession toSession(api.LiveShowView view) => LiveSession(
    id: '${view.id}',
    title: view.title,
    hostId: view.hostId.toString(),
    hostName: view.hostName ?? view.hostUsername ?? '',
    hostUsername: view.hostUsername ?? '',
    status: LiveStatus.values.byName(view.status.name),
    viewers: view.viewerCount,
    isPremium: view.access == api.LiveShowAccess.members,
    endedByModeration: view.endedByModeration,
    description: view.description,
    scheduledAt: view.startsAt.toLocal(),
    durationMinutes: view.durationMinutes,
    cohostIds: [for (final id in view.guestIds) id.toString()],
    allowQuestions: view.allowQuestions,
    recordReplay: view.recordReplay,
    startedAt: view.startedAt?.toLocal(),
    endedAt: view.endedAt?.toLocal(),
    hostAvatarUrl: view.hostAvatarUrl,
  );

  static LiveComment toComment(
    api.LiveChatMessageView message, {
    required String? me,
  }) => LiveComment(
    id: '${message.id}',
    author: message.authorName ?? message.authorUsername ?? '',
    authorId: message.authorId.toString(),
    body: message.body,
    isMine: me != null && message.authorId.toString() == me,
    authorAvatarUrl: message.authorAvatarUrl,
  );

  static LiveRole toRole(api.LiveShowRole role) =>
      LiveRole.values.byName(role.name);

  /// Null para un `kind` que este cliente no conoce: se ignora en vez de
  /// romper la sala.
  static LiveRoomEvent? toEvent(
    api.LiveEvent event, {
    required String? me,
  }) => switch (event.kind) {
    api.LiveEventKind.snapshot when event.liveShow != null => LiveRoomSnapshot(
      session: toSession(event.liveShow!),
      role: toRole(event.role ?? api.LiveShowRole.audience),
      comments: [
        for (final m in event.history ?? const <api.LiveChatMessageView>[])
          toComment(m, me: me),
      ],
    ),
    api.LiveEventKind.status when event.liveShow != null => LiveSessionChanged(
      toSession(event.liveShow!),
    ),
    api.LiveEventKind.viewers when event.viewerCount != null =>
      LiveViewersChanged(event.viewerCount!),
    api.LiveEventKind.chat when event.message != null => LiveCommentAdded(
      toComment(event.message!, me: me),
    ),
    api.LiveEventKind.chatHidden when event.hiddenMessageId != null =>
      LiveCommentHidden('${event.hiddenMessageId}'),
    _ => null,
  };

  // --- Internos ------------------------------------------------------------

  String? get _me => _auth.authInfo?.authUserId.toString();

  static int _showId(String id) {
    final showId = int.tryParse(id);
    if (showId == null) throw const NotFoundFailure('live');
    return showId;
  }

  /// `watchIndex` vive mientras alguien escucha [changes]. Si se corta (red,
  /// servidor reiniciado), se reabre solo y avisa un cambio para que las
  /// listas se resincronicen con lo que pasó mientras tanto.
  void _openIndex() {
    _indexRetry?.cancel();
    unawaited(_index?.cancel());
    _index = _client.live.watchIndex().listen(
      (_) => _notify(),
      onError: (Object _) => _retryIndex(),
      onDone: _retryIndex,
      cancelOnError: true,
    );
  }

  void _retryIndex() {
    _index = null;
    if (!_changes.hasListener) return;
    _indexRetry?.cancel();
    _indexRetry = Timer(indexRetryDelay, () {
      if (!_changes.hasListener) return;
      _openIndex();
      _notify();
    });
  }

  void _closeIndex() {
    _indexRetry?.cancel();
    unawaited(_index?.cancel());
    _index = null;
  }

  void _notify() {
    if (!_changes.isClosed) _changes.add(null);
  }

  static Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } catch (error) {
      throw failureFromServer(error);
    }
  }
}
