import 'dart:async';

import 'package:nexo_server/src/generated/protocol.dart';
import 'package:nexo_server/src/modules/messages/services/messages_rules.dart';
import 'package:test/test.dart';

import '../support/fixtures.dart';
import '../test_tools/serverpod_test_tools.dart';

/// `messages.watch`. Sin revertir la base, como `live_watch_test`: el stream
/// y los endpoints corren a la vez.
void main() {
  var run = 0;

  Future<void> until(bool Function() condition, {String? reason}) async {
    for (var i = 0; i < 150 && !condition(); i++) {
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
    expect(condition(), isTrue, reason: reason);
  }

  withServerpod(
    'Given messages.watch',
    rollbackDatabase: RollbackDatabase.disabled,
    (sessionBuilder, endpoints) {
      final fixtures = Fixtures(sessionBuilder);
      final subscriptions = <StreamSubscription<Object?>>[];

      tearDown(() async {
        for (final s in subscriptions) {
          await s.cancel();
        }
        subscriptions.clear();
      });

      test('then the other member receives the message and the read', () async {
        final n = ++run;
        final elenaId = await fixtures.seedCreator('elena_dmw$n', 'Elena');
        final tomasId = await fixtures.seedAccount('tomas_dmw$n', 'Tomás');
        final elena = fixtures.signedIn(elenaId);
        final tomas = fixtures.signedIn(tomasId);
        MessagesThrottle.instance.reset();

        final elenaEvents = <DirectMessageEvent>[];
        final tomasEvents = <DirectMessageEvent>[];
        subscriptions
          ..add(endpoints.messages.watch(elena).listen(elenaEvents.add))
          ..add(endpoints.messages.watch(tomas).listen(tomasEvents.add));
        await flushEventQueue();

        final conversation = await endpoints.messages.open(tomas, elenaId);
        final sent = await endpoints.messages.send(
          tomas,
          conversation.id,
          'hola, Elena',
        );

        await until(() => elenaEvents.isNotEmpty, reason: 'message event');
        final received = elenaEvents.single;
        expect(received.kind, DirectMessageEventKind.message);
        expect(received.message?.id, sent.id);
        expect(received.message?.body, 'hola, Elena');
        expect(received.unreadConversations, 1);
        // El que escribe también lo recibe: sus otras pantallas se enteran.
        await until(() => tomasEvents.isNotEmpty, reason: 'echo');
        expect(tomasEvents.single.unreadConversations, 0);

        await endpoints.messages.markRead(elena, conversation.id);
        await until(
          () => tomasEvents.any((e) => e.kind == DirectMessageEventKind.read),
          reason: 'read event',
        );
        final read = tomasEvents.lastWhere(
          (e) => e.kind == DirectMessageEventKind.read,
        );
        expect(read.readerId, elenaId);
        expect(read.lastReadMessageId, sent.id);
      });

      test('then a guest cannot watch', () async {
        final events = <Object>[];
        final errors = <Object>[];
        subscriptions.add(
          endpoints.messages
              .watch(fixtures.guest)
              .listen(events.add, onError: errors.add),
        );
        await until(() => errors.isNotEmpty, reason: 'unauthenticated');
        expect(events, isEmpty);
      });
    },
  );
}
