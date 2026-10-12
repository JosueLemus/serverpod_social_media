import 'dart:async';

import 'package:nexo_server/src/generated/protocol.dart';
import 'package:test/test.dart';

import '../support/fixtures.dart';
import '../test_tools/serverpod_test_tools.dart';

/// `notifications.watch`. En su propio archivo y sin revertir la base, como
/// `live_watch_test`: el aviso se publica mientras el stream está abierto.
void main() {
  var run = 0;

  Future<void> until(bool Function() condition, {String? reason}) async {
    for (var i = 0; i < 150 && !condition(); i++) {
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
    expect(condition(), isTrue, reason: reason);
  }

  withServerpod(
    'Given notifications.watch',
    rollbackDatabase: RollbackDatabase.disabled,
    (sessionBuilder, endpoints) {
      final fixtures = Fixtures(sessionBuilder);

      test(
        'then a new follower arrives at once, only for its recipient',
        () async {
          final n = ++run;
          final elenaId = await fixtures.seedCreator('elena_n$n', 'Elena');
          final tomasId = await fixtures.seedAccount('tomas_n$n', 'Tomás');
          final elena = fixtures.signedIn(elenaId);
          final tomas = fixtures.signedIn(tomasId);

          final forElena = <NotificationView>[];
          final forTomas = <NotificationView>[];
          final subs = [
            endpoints.notifications.watch(elena).listen(forElena.add),
            endpoints.notifications.watch(tomas).listen(forTomas.add),
          ];
          await flushEventQueue();

          await endpoints.follows.follow(tomas, elenaId);
          await until(() => forElena.isNotEmpty, reason: 'aviso en vivo');

          expect(forElena.single.kind, NotificationKind.newFollower);
          expect(forElena.single.actorUsername, 'tomas_n$n');
          expect(forTomas, isEmpty);
          for (final s in subs) {
            await s.cancel();
          }
        },
      );

      test('then a guest cannot watch', () async {
        final errors = <Object>[];
        final sub = endpoints.notifications
            .watch(fixtures.guest)
            .listen((_) {}, onError: errors.add);
        await until(() => errors.isNotEmpty, reason: 'rechazo');
        // Después del rechazo llega el cierre de la conexión: lo que importa es
        // que el primero sea el motivo.
        expect(errors.first, isA<NexoException>());
        await sub.cancel();
      });
    },
  );
}
