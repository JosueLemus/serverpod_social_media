import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:nexo_social/core/errors/failures.dart';
import 'package:nexo_social/features/live/domain/entities/live_media_grant.dart';
import 'package:nexo_social/features/live/domain/entities/live_moderation.dart';
import 'package:nexo_social/features/live/domain/entities/live_room_event.dart';
import 'package:nexo_social/features/live/domain/entities/live_session.dart';
import 'package:nexo_social/features/live/domain/repositories/live_repository.dart';
import 'package:nexo_social/features/live/presentation/bloc/live_room_cubit.dart';
import 'package:nexo_social/features/moderation/data/repositories/mock_moderation_repository.dart';

import '../../../support/stage_stubs.dart';

import '../../../support/platform_harness.dart';

/// La sala contra un repositorio cuyo stream maneja el test: lo que con
/// Serverpod llega por `live.watch`.
class _FakeLiveRepository with StageStubs implements LiveRepository {
  final rooms = <StreamController<LiveRoomEvent>>[];
  final watched = <String>[];
  List<LiveSession> shows = const [];
  Object? postError;

  StreamController<LiveRoomEvent> get room => rooms.last;

  @override
  Stream<LiveRoomEvent> watch(String liveId) {
    watched.add(liveId);
    final controller = StreamController<LiveRoomEvent>();
    rooms.add(controller);
    return controller.stream;
  }

  @override
  Future<List<LiveSession>> mine() async => shows;

  @override
  Future<LiveComment> postComment(String liveId, String body) async {
    if (postError != null) throw postError!;
    return LiveComment(id: 'm1', author: 'Tomás', body: body, isMine: true);
  }

  @override
  Future<void> hideComment(String liveId, String commentId) async {}

  @override
  Future<LiveSession> transition(String id, LiveStatus status) async =>
      _session(id: id, status: status);

  @override
  Stream<void> changes() => const Stream.empty();

  @override
  Future<List<LiveSession>> list() async => shows;

  @override
  Future<LiveSession?> byId(String id) async => null;

  @override
  Future<List<LiveComment>> comments(String liveId) async => const [];

  @override
  Future<LiveRole> roleIn(String liveId) async => LiveRole.audience;

  @override
  Future<LiveSession> goLive(String title) async =>
      _session(id: '99', status: LiveStatus.live);

  @override
  Future<LiveMediaGrant> mediaToken(String liveId) async => LiveMediaGrant(
    channel: 'nexo_live_$liveId',
    role: LiveMediaGrantRole.subscriber,
  );
}

LiveSession _session({
  String id = '12',
  LiveStatus status = LiveStatus.live,
  int viewers = 0,
  DateTime? startedAt,
  DateTime? scheduledAt,
}) => LiveSession(
  id: id,
  title: 'Masterclass',
  hostName: 'Elena Vega',
  status: status,
  viewers: viewers,
  startedAt: startedAt,
  scheduledAt: scheduledAt,
);

const _hola = LiveComment(id: 'c1', author: 'Ana', body: 'hola');

void main() {
  late _FakeLiveRepository repository;
  late LiveRoomCubit cubit;
  final now = DateTime(2026, 10, 11, 20, 10);

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  setUp(() async {
    repository = _FakeLiveRepository();
    cubit = LiveRoomCubit(
      repository,
      MockModerationRepository(await platformAs(null)),
      now: () => now,
      reconnectDelays: const [Duration.zero],
    );
  });

  tearDown(() => cubit.close());

  /// Abre la sala y le entrega la foto inicial.
  Future<void> open({LiveSession? session, List<LiveComment>? comments}) async {
    final loading = cubit.load('12');
    await settle();
    repository.room.add(
      LiveRoomSnapshot(
        session: session ?? _session(),
        role: LiveRole.audience,
        comments: comments ?? const [_hola],
      ),
    );
    await loading;
  }

  test('loading waits for the snapshot and shows it', () async {
    final loading = cubit.load('12');
    await settle();
    expect(cubit.state.isLoading, isTrue);

    repository.room.add(
      LiveRoomSnapshot(
        session: _session(),
        role: LiveRole.moderator,
        comments: const [_hola],
      ),
    );
    await loading;

    expect(cubit.state.isLoading, isFalse);
    expect(cubit.state.session?.id, '12');
    expect(cubit.state.role, LiveRole.moderator);
    expect(cubit.state.comments, [_hola]);
  });

  test('viewers, status and chat events change only their part', () async {
    await open();

    repository.room
      ..add(const LiveViewersChanged(4))
      ..add(
        const LiveCommentAdded(
          LiveComment(id: 'c2', author: 'Tomás', body: 'x'),
        ),
      );
    await settle();
    expect(cubit.state.session?.viewers, 4);
    expect(cubit.state.comments.map((c) => c.id), ['c1', 'c2']);

    repository.room
      ..add(const LiveCommentHidden('c1'))
      ..add(LiveSessionChanged(_session(status: LiveStatus.recorded)));
    await settle();
    expect(cubit.state.comments.map((c) => c.id), ['c2']);
    expect(cubit.state.session?.status, LiveStatus.recorded);
  });

  test('my own comment shows once even when the echo arrives', () async {
    await open();

    await cubit.sendComment('hola a todos');
    repository.room.add(
      const LiveCommentAdded(
        LiveComment(id: 'm1', author: 'Tomás', body: 'hola a todos'),
      ),
    );
    await settle();

    expect(cubit.state.comments.where((c) => c.id == 'm1'), hasLength(1));
  });

  test('sending too fast is a typed reason, not a generic error', () async {
    await open();
    repository.postError = const RateLimitedFailure('slow down');

    await cubit.sendComment('otra vez');

    expect(cubit.state.issue, LiveRoomIssue.tooFast);
  });

  test('a room that does not exist ends in notFound', () async {
    final loading = cubit.load('12');
    await settle();
    repository.room.addError(const NotFoundFailure('live'));
    await loading;

    expect(cubit.state.notFound, isTrue);
    expect(cubit.state.isLoading, isFalse);
  });

  test('a kick on reconnect leaves the room instead of retrying', () async {
    await open();

    // Al reconectarse, el servidor rechaza a un expulsado con forbidden.
    repository.room.addError(const ForbiddenFailure('live: kicked'));
    await settle();
    await settle();

    expect(cubit.state.exclusion, LiveSanctionKind.kick);
    expect(cubit.state.reconnecting, isFalse);
    expect(repository.rooms, hasLength(1), reason: 'no vuelve a suscribirse');
  });

  test('a kick that reaches me as an event leaves the room', () async {
    await open();

    repository.room.add(
      const LiveSanctioned(
        userId: 'me',
        kind: LiveSanctionKind.ban,
        isMine: true,
      ),
    );
    await settle();

    expect(cubit.state.exclusion, LiveSanctionKind.ban);
  });

  test('someone else being kicked does not touch my room', () async {
    await open();

    repository.room.add(
      const LiveSanctioned(
        userId: 'other',
        kind: LiveSanctionKind.kick,
        isMine: false,
      ),
    );
    await settle();

    expect(cubit.state.exclusion, isNull);
  });

  test(
    'a dropped stream reconnects and resyncs from the new snapshot',
    () async {
      await open();

      repository.room.addError(const NetworkFailure('socket closed'));
      await settle();
      expect(cubit.state.reconnecting, isTrue);
      await settle();
      expect(repository.rooms, hasLength(2), reason: 'volvió a suscribirse');

      repository.room.add(
        LiveRoomSnapshot(
          session: _session(viewers: 9),
          role: LiveRole.audience,
          comments: const [],
        ),
      );
      await settle();

      expect(cubit.state.reconnecting, isFalse);
      expect(cubit.state.session?.viewers, 9);
    },
  );

  test('the studio clock comes from startedAt', () async {
    await open(
      session: _session(startedAt: now.subtract(const Duration(minutes: 3))),
    );

    expect(cubit.state.elapsed, const Duration(minutes: 3));
  });

  group('the studio', () {
    test('opens the host show on air before the scheduled one', () async {
      repository.shows = [
        _session(
          id: 'scheduled',
          status: LiveStatus.scheduled,
          scheduledAt: now.add(const Duration(hours: 1)),
        ),
        _session(id: 'on-air'),
      ];

      unawaited(cubit.loadStudio());
      await settle();
      await settle();

      expect(repository.watched, ['on-air']);
    });

    test('with no shows it ends in the empty state', () async {
      await cubit.loadStudio();

      expect(cubit.state.notFound, isTrue);
      expect(repository.watched, isEmpty);
    });
  });
}
