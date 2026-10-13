import 'package:nexo_server/src/generated/protocol.dart';
import 'package:nexo_server/src/modules/messages/services/messages_rules.dart';
import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';

import '../support/fixtures.dart';
import '../test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Given the messages endpoint', (sessionBuilder, endpoints) {
    final fixtures = Fixtures(sessionBuilder);
    late UuidValue elenaId;
    late UuidValue tomasId;
    late TestSessionBuilder elena;
    late TestSessionBuilder tomas;
    late TestSessionBuilder ana;

    /// Sin el límite de un mensaje por segundo: los tests mandan seguido.
    Future<DirectMessageView> send(
      TestSessionBuilder who,
      int conversationId,
      String body,
    ) {
      MessagesThrottle.instance.reset();
      return endpoints.messages.send(who, conversationId, body);
    }

    setUp(() async {
      MessagesThrottle.instance.reset();
      elenaId = await fixtures.seedCreator('elena_dm', 'Elena Vega');
      tomasId = await fixtures.seedAccount('tomas_dm', 'Tomás Ríos');
      elena = fixtures.signedIn(elenaId);
      tomas = fixtures.signedIn(tomasId);
      ana = fixtures.signedIn(await fixtures.seedAccount('ana_dm', 'Ana'));
    });

    test(
      'then opening twice, from either side, returns one conversation',
      () async {
        final first = await endpoints.messages.open(tomas, elenaId);
        final again = await endpoints.messages.open(tomas, elenaId);
        final fromElena = await endpoints.messages.open(elena, tomasId);

        expect(again.id, first.id);
        expect(fromElena.id, first.id);
        expect(first.other.username, 'elena_dm');
        expect(fromElena.other.username, 'tomas_dm');
        expect(await DmConversation.db.count(fixtures.session), 1);
      },
    );

    test('then you cannot open a conversation with yourself', () async {
      await expectLater(
        endpoints.messages.open(tomas, tomasId),
        throwsNexo(NexoErrorCode.invalidInput),
      );
    });

    test('then a guest cannot use messages', () async {
      await expectLater(
        endpoints.messages.open(fixtures.guest, elenaId),
        throwsNexo(NexoErrorCode.unauthenticated),
      );
      await expectLater(
        endpoints.messages.conversations(fixtures.guest),
        throwsNexo(NexoErrorCode.unauthenticated),
      );
    });

    test('then an unknown account is not found and a suspended one cannot '
        'receive messages', () async {
      final stranger = await fixtures.seedUser('nadie', 'Nadie');
      await expectLater(
        endpoints.messages.open(tomas, stranger),
        throwsNexo(NexoErrorCode.notFound),
      );
      final banned = await fixtures.seedAccount(
        'troll_dm',
        'Troll',
        status: AccountStatus.suspended,
      );
      await expectLater(
        endpoints.messages.open(tomas, banned),
        throwsNexo(NexoErrorCode.forbidden),
      );
    });

    test('then a suspended account cannot open or send', () async {
      final conversation = await endpoints.messages.open(tomas, elenaId);
      final account = (await AccountProfile.db.findFirstRow(
        fixtures.session,
        where: (t) => t.authUserId.equals(tomasId),
      ))!;
      await AccountProfile.db.updateRow(
        fixtures.session,
        account.copyWith(status: AccountStatus.suspended),
      );

      await expectLater(
        endpoints.messages.open(tomas, elenaId),
        throwsNexo(NexoErrorCode.accountSuspended),
      );
      await expectLater(
        send(tomas, conversation.id, 'hola'),
        throwsNexo(NexoErrorCode.accountSuspended),
      );
    });

    test('then only members read or write a conversation', () async {
      final conversation = await endpoints.messages.open(tomas, elenaId);
      await send(tomas, conversation.id, 'hola');

      await expectLater(
        endpoints.messages.history(ana, conversation.id),
        throwsNexo(NexoErrorCode.forbidden),
      );
      await expectLater(
        send(ana, conversation.id, 'me meto'),
        throwsNexo(NexoErrorCode.forbidden),
      );
      await expectLater(
        endpoints.messages.markRead(ana, conversation.id),
        throwsNexo(NexoErrorCode.forbidden),
      );
      await expectLater(
        endpoints.messages.history(tomas, 999999),
        throwsNexo(NexoErrorCode.notFound),
      );
      await expectLater(
        endpoints.messages.conversation(ana, conversation.id),
        throwsNexo(NexoErrorCode.forbidden),
      );
      final mine = await endpoints.messages.conversation(
        elena,
        conversation.id,
      );
      expect(mine.other.username, 'tomas_dm');
      expect(mine.lastMessage?.body, 'hola');
    });

    test('then empty or too long bodies are rejected', () async {
      final conversation = await endpoints.messages.open(tomas, elenaId);
      await expectLater(
        send(tomas, conversation.id, '   '),
        throwsNexo(NexoErrorCode.invalidInput),
      );
      await expectLater(
        send(tomas, conversation.id, 'a' * (MessagesRules.maxBodyLength + 1)),
        throwsNexo(NexoErrorCode.invalidInput),
      );
    });

    test('then two messages within a second are rate limited', () async {
      final conversation = await endpoints.messages.open(tomas, elenaId);
      await endpoints.messages.send(tomas, conversation.id, 'uno');
      await expectLater(
        endpoints.messages.send(tomas, conversation.id, 'dos'),
        throwsNexo(NexoErrorCode.rateLimited),
      );
    });

    test('then the inbox lists only conversations with messages, newest '
        'first', () async {
      final withElena = await endpoints.messages.open(tomas, elenaId);
      final anaId = (await AccountProfile.db.findFirstRow(
        fixtures.session,
        where: (t) => t.username.equals('ana_dm'),
      ))!.authUserId;
      final withAna = await endpoints.messages.open(tomas, anaId);
      expect((await endpoints.messages.conversations(tomas)).items, isEmpty);

      await send(tomas, withElena.id, 'primero');
      await send(tomas, withAna.id, 'después');

      final inbox = (await endpoints.messages.conversations(tomas)).items;
      expect([for (final c in inbox) c.other.username], ['ana_dm', 'elena_dm']);
      expect(inbox.first.lastMessage?.body, 'después');
    });

    test('then unread counts follow the read pointers', () async {
      final conversation = await endpoints.messages.open(tomas, elenaId);
      await send(tomas, conversation.id, 'hola');
      await send(tomas, conversation.id, '¿estás?');

      expect(await endpoints.messages.unreadCount(elena), 1);
      expect(await endpoints.messages.unreadCount(tomas), 0);
      final inbox = (await endpoints.messages.conversations(elena)).items;
      expect(inbox.single.unreadCount, 2);

      expect(await endpoints.messages.markRead(elena, conversation.id), 0);
      expect(
        (await endpoints.messages.conversations(
          elena,
        )).items.single.unreadCount,
        0,
      );

      await send(elena, conversation.id, 'sí, acá');
      expect(await endpoints.messages.unreadCount(tomas), 1);
      expect(await endpoints.messages.unreadCount(elena), 0);
    });

    test('then history pages backwards, oldest to newest', () async {
      final conversation = await endpoints.messages.open(tomas, elenaId);
      for (final body in ['1', '2', '3', '4', '5']) {
        await send(tomas, conversation.id, body);
      }

      final last = await endpoints.messages.history(
        elena,
        conversation.id,
        limit: 2,
      );
      expect([for (final m in last.items) m.body], ['4', '5']);
      expect(last.hasMore, isTrue);

      final before = await endpoints.messages.history(
        elena,
        conversation.id,
        beforeId: last.items.first.id,
        limit: 10,
      );
      expect([for (final m in before.items) m.body], ['1', '2', '3']);
      expect(before.hasMore, isFalse);
    });
  });
}
