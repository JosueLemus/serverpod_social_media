import 'dart:async';

import 'package:nexo_server/src/generated/protocol.dart';
import 'package:nexo_server/src/shared/auth/auth_context.dart';
import 'package:test/test.dart';

import '../support/fixtures.dart';
import '../test_tools/serverpod_test_tools.dart';

/// `live.watch` y `live.watchIndex`.
///
/// En su propio archivo y sin revertir la base: el stream consulta la base
/// mientras el test llama a otros endpoints, y la herramienta no admite
/// llamadas concurrentes con rollback. Por eso cada test siembra cuentas con
/// nombres propios.
void main() {
  var run = 0;

  /// Espera a que [condition] se cumpla: el stream hace viajes reales a la
  /// base, así que un solo `flushEventQueue` no alcanza.
  Future<void> until(bool Function() condition, {String? reason}) async {
    for (var i = 0; i < 150 && !condition(); i++) {
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
    expect(condition(), isTrue, reason: reason);
  }

  withServerpod(
    'Given live.watch',
    rollbackDatabase: RollbackDatabase.disabled,
    (sessionBuilder, endpoints) {
      final fixtures = Fixtures(sessionBuilder);
      late TestSessionBuilder elena;
      late TestSessionBuilder tomas;
      late TestSessionBuilder ana;
      late TestSessionBuilder moderator;
      late int showId;
      final subscriptions = <StreamSubscription<Object?>>[];

      /// Se suscribe y espera la foto inicial.
      Future<List<LiveEvent>> watch(TestSessionBuilder who) async {
        final events = <LiveEvent>[];
        subscriptions.add(endpoints.live.watch(who, showId).listen(events.add));
        await until(() => events.isNotEmpty, reason: 'snapshot');
        return events;
      }

      setUp(() async {
        final n = ++run;
        elena = fixtures.signedIn(
          await fixtures.seedCreator('elena_w$n', 'Elena Vega'),
        );
        tomas = fixtures.signedIn(
          await fixtures.seedAccount('tomas_w$n', 'Tomás'),
        );
        ana = fixtures.signedIn(await fixtures.seedAccount('ana_w$n', 'Ana'));
        moderator = fixtures.signedIn(
          await fixtures.seedAccount('mod_w$n', 'Lucía'),
          {NexoScopes.moderator},
        );
        showId = (await endpoints.live.schedule(
          elena,
          fixtures.showDraft('Masterclass'),
        )).id;
        await endpoints.live.start(elena, showId);
      });

      tearDown(() async {
        for (final s in subscriptions) {
          await s.cancel();
        }
        subscriptions.clear();
      });

      test(
        'then the first event is a snapshot with role and history',
        () async {
          await endpoints.live.sendChat(ana, showId, 'primero');

          final snapshot = (await watch(tomas)).first;

          expect(snapshot.kind, LiveEventKind.snapshot);
          expect(snapshot.liveShow?.status, LiveShowStatus.live);
          expect(snapshot.role, LiveShowRole.audience);
          expect(snapshot.history?.map((m) => m.body), ['primero']);
        },
      );

      test('then each watcher gets its own role in the snapshot', () async {
        final host = await watch(elena);
        final mod = await watch(moderator);

        expect(host.first.role, LiveShowRole.host);
        expect(mod.first.role, LiveShowRole.moderator);
      });

      test('then a message sent by someone else arrives as chat', () async {
        final events = await watch(tomas);

        final sent = await endpoints.live.sendChat(ana, showId, 'hola');
        await until(() => events.any((e) => e.kind == LiveEventKind.chat));

        final chat = events.where((e) => e.kind == LiveEventKind.chat);
        expect(chat.map((e) => e.message?.id), [sent.id]);
      });

      test('then the snapshot carries the stage, host first', () async {
        final snapshot = (await watch(tomas)).first;

        expect(snapshot.stage?.speakers.map((s) => s.role), [
          LiveShowRole.host,
        ]);
      });

      test(
        'then approving a hand arrives as stage and as roleChanged',
        () async {
          final events = await watch(tomas);
          await endpoints.live.raiseHand(tomas, showId);
          final tomasId = (await endpoints.live.stage(
            fixtures.guest,
            showId,
          )).hands.single.userId;

          await endpoints.live.approveRequest(elena, showId, tomasId);
          await until(
            () => events.any((e) => e.kind == LiveEventKind.roleChanged),
          );

          final changed = events.firstWhere(
            (e) => e.kind == LiveEventKind.roleChanged,
          );
          expect(changed.targetId, tomasId);
          expect(changed.role, LiveShowRole.cohost);
          final lastStage = events.lastWhere(
            (e) => e.kind == LiveEventKind.stage,
          );
          expect(
            lastStage.stage?.speakers.map((s) => s.userId),
            contains(tomasId),
          );
        },
      );

      test('then hiding a message arrives as chatHidden', () async {
        final sent = await endpoints.live.sendChat(ana, showId, 'basura');
        final events = await watch(tomas);

        await endpoints.live.hideChat(moderator, sent.id);
        await until(
          () => events.any((e) => e.kind == LiveEventKind.chatHidden),
        );

        expect(
          events
              .where((e) => e.kind == LiveEventKind.chatHidden)
              .map((e) => e.hiddenMessageId),
          [sent.id],
        );
      });

      test('then viewers go up on join and down on leave', () async {
        final host = await watch(elena);
        await watch(tomas);
        await watch(ana);

        Future<int> viewers() async =>
            (await endpoints.live.get(fixtures.guest, showId)).viewerCount;
        expect(await viewers(), 2, reason: 'el host no cuenta');

        await subscriptions.removeLast().cancel();
        await until(
          () => host.where((e) => e.kind == LiveEventKind.viewers).length == 3,
          reason: 'la baja se publica',
        );

        expect(await viewers(), 1);
        expect(
          host
              .where((e) => e.kind == LiveEventKind.viewers)
              .map((e) => e.viewerCount),
          [1, 2, 1],
        );
      });

      test('then ending the show reaches every watcher as status', () async {
        final events = await watch(tomas);

        await endpoints.live.end(elena, showId);
        await until(() => events.any((e) => e.kind == LiveEventKind.status));

        final status = events.where((e) => e.kind == LiveEventKind.status);
        expect(status.single.liveShow?.status, LiveShowStatus.recorded);
        expect(
          events
              .where((e) => e.kind != LiveEventKind.snapshot)
              .map((e) => e.role),
          everyElement(isNull),
          reason: 'el rol sólo viaja en la foto de cada espectador',
        );
      });

      test('then an unknown show closes the stream with notFound', () async {
        final error = Completer<Object>();
        subscriptions.add(
          endpoints.live
              .watch(tomas, 999999)
              .listen(
                (_) {},
                onError: (Object e) {
                  // Después llega el cierre de la conexión: sólo importa el
                  // primero.
                  if (!error.isCompleted) error.complete(e);
                },
              ),
        );

        expect(
          await error.future.timeout(const Duration(seconds: 5)),
          isA<NexoException>().having(
            (e) => e.code,
            'code',
            NexoErrorCode.notFound,
          ),
        );
      });
    },
  );

  withServerpod(
    'Given live.watchIndex',
    rollbackDatabase: RollbackDatabase.disabled,
    (sessionBuilder, endpoints) {
      final fixtures = Fixtures(sessionBuilder);

      test('then starting a show reaches every index listener', () async {
        final elena = fixtures.signedIn(
          await fixtures.seedCreator('elena_index', 'Elena Vega'),
        );
        final show = await endpoints.live.schedule(
          elena,
          fixtures.showDraft('Masterclass'),
        );
        final seen = <LiveShowView>[];
        final sub = endpoints.live.watchIndex(fixtures.guest).listen(seen.add);
        await flushEventQueue();

        await endpoints.live.start(elena, show.id);
        await until(() => seen.isNotEmpty);
        await sub.cancel();

        expect(seen.map((s) => (s.id, s.status)), [
          (show.id, LiveShowStatus.live),
        ]);
      });

      test('then going live now reaches every index listener', () async {
        final carlos = fixtures.signedIn(
          await fixtures.seedCreator('carlos_index', 'Carlos Méndez'),
        );
        final seen = <LiveShowView>[];
        final sub = endpoints.live.watchIndex(fixtures.guest).listen(seen.add);
        await flushEventQueue();

        final show = await endpoints.live.goLive(carlos, 'Ahora mismo');
        await until(() => seen.isNotEmpty);
        await sub.cancel();

        expect(seen.map((s) => (s.id, s.status)), [
          (show.id, LiveShowStatus.live),
        ]);
      });
    },
  );
}
