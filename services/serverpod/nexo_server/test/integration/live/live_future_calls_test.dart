import 'package:nexo_server/src/generated/protocol.dart';
import 'package:nexo_server/src/modules/live/services/live_service.dart';
import 'package:nexo_server/src/modules/live/services/show_scheduler.dart';
import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';

import '../support/fixtures.dart';
import '../test_tools/serverpod_test_tools.dart';

/// Registra lo que se programa en vez de esperar al reloj (S16 del SDD 0008).
class _RecordingScheduler implements ShowScheduler {
  final calls = <String>[];

  @override
  Future<void> scheduled(Session session, LiveShow show) async =>
      calls.add('scheduled:${show.id}');

  @override
  Future<void> started(Session session, int showId) async =>
      calls.add('started:$showId');

  @override
  Future<void> cancelled(Session session, int showId) async =>
      calls.add('cancelled:$showId');

  @override
  Future<void> ended(Session session, LiveShow show) async =>
      calls.add('ended:${show.id}');

  @override
  Future<void> published(Session session, int showId) async =>
      calls.add('published:$showId');
}

void main() {
  withServerpod('Given the show future calls', (sessionBuilder, endpoints) {
    final fixtures = Fixtures(sessionBuilder);
    late _RecordingScheduler scheduler;
    late LiveService live;
    late UuidValue elenaId;
    late Session elena;

    Future<LiveShow> stored(int id) async =>
        (await LiveShow.db.findById(fixtures.session, id))!;

    setUp(() async {
      scheduler = _RecordingScheduler();
      live = LiveService(scheduler: scheduler);
      elenaId = await fixtures.seedCreator('elena_ux', 'Elena Vega');
      elena = fixtures.signedIn(elenaId).build();
    });

    test('then scheduling, starting and ending program and cancel the '
        'right tasks', () async {
      final show = await live.schedule(elena, fixtures.showDraft('Show'));
      await live.start(elena, show.id);
      await live.end(elena, show.id);
      await live.publish(elena, show.id);

      expect(scheduler.calls, [
        'scheduled:${show.id}',
        'started:${show.id}',
        'ended:${show.id}',
        'published:${show.id}',
      ]);
    });

    test('then cancelling a scheduled show cancels its tasks', () async {
      final show = await live.schedule(elena, fixtures.showDraft('Show'));
      await live.cancel(elena, show.id);
      expect(scheduler.calls.last, 'cancelled:${show.id}');
    });

    test(
      'then expire cancels a show that never started, and only that',
      () async {
        final idle = await live.schedule(elena, fixtures.showDraft('Nadie'));
        await live.expire(fixtures.session, idle.id);
        expect((await stored(idle.id)).status, LiveShowStatus.cancelled);

        final started = await live.schedule(
          elena,
          fixtures.showDraft('Arrancó'),
        );
        await live.start(elena, started.id);
        await live.expire(fixtures.session, started.id);
        expect((await stored(started.id)).status, LiveShowStatus.live);
      },
    );

    test('then the replay publishes itself only if it is still recorded and '
        'keeps a replay', () async {
      final kept = await live.schedule(elena, fixtures.showDraft('Con replay'));
      await live.start(elena, kept.id);
      await live.end(elena, kept.id);
      await live.autoPublish(fixtures.session, kept.id);
      expect((await stored(kept.id)).status, LiveShowStatus.published);

      final dropped = await live.schedule(
        elena,
        fixtures.showDraft('Sin replay', recordReplay: false),
      );
      await live.start(elena, dropped.id);
      await live.end(elena, dropped.id);
      await live.autoPublish(fixtures.session, dropped.id);
      expect((await stored(dropped.id)).status, LiveShowStatus.recorded);
    });

    test('then remind notifies followers and invited guests while the show '
        'is still scheduled', () async {
      final tomasId = await fixtures.seedAccount('tomas', 'Tomás');
      final anaId = await fixtures.seedAccount('ana', 'Ana');
      await endpoints.follows.follow(fixtures.signedIn(tomasId), elenaId);
      final show = await live.schedule(
        elena,
        fixtures.showDraft('Pronto', guests: ['ana']),
      );

      await live.remind(fixtures.session, show.id);

      for (final id in [tomasId, anaId]) {
        final items = await endpoints.notifications.list(fixtures.signedIn(id));
        expect(
          items.items.map((n) => n.kind),
          contains(NotificationKind.showStartingSoon),
        );
      }

      await live.start(elena, show.id);
      await live.remind(fixtures.session, show.id);
      final tomasInbox = await endpoints.notifications.list(
        fixtures.signedIn(tomasId),
      );
      expect(
        tomasInbox.items
            .where((n) => n.kind == NotificationKind.showStartingSoon)
            .length,
        1,
      );
    });

    test('then the real scheduler does not break the action that triggers '
        'it', () async {
      // El endpoint usa las Future Calls de verdad. Programar nunca tumba la
      // acción: el show queda programado aunque la tarea falle.
      final show = await endpoints.live.schedule(
        fixtures.signedIn(elenaId),
        fixtures.showDraft('Real'),
      );
      expect(show.status, LiveShowStatus.scheduled);
    });
  });
}
