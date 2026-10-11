import 'package:nexo_server/src/generated/protocol.dart';
import 'package:nexo_server/src/shared/auth/auth_context.dart';
import 'package:test/test.dart';

import '../support/fixtures.dart';
import '../test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Given the live chat', (sessionBuilder, endpoints) {
    final fixtures = Fixtures(sessionBuilder);
    late TestSessionBuilder elena;
    late TestSessionBuilder tomas;
    late TestSessionBuilder troll;
    late TestSessionBuilder moderator;
    late int showId;

    setUp(() async {
      elena = fixtures.signedIn(
        await fixtures.seedCreator('elena_ux', 'Elena Vega'),
      );
      tomas = fixtures.signedIn(await fixtures.seedAccount('tomas', 'Tomás'));
      troll = fixtures.signedIn(await fixtures.seedAccount('troll', 'Troll'));
      moderator = fixtures.signedIn(
        await fixtures.seedAccount('mod_lucia', 'Lucía'),
        {NexoScopes.moderator},
      );
      showId = (await endpoints.live.schedule(
        elena,
        fixtures.showDraft('Masterclass'),
      )).id;
    });

    test('when the show is not on air then sending is a conflict', () async {
      await expectLater(
        endpoints.live.sendChat(tomas, showId, 'hola'),
        throwsNexo(NexoErrorCode.conflict),
      );
    });

    group('when the show is on air', () {
      setUp(() => endpoints.live.start(elena, showId));

      test('then a message comes back with its author', () async {
        final message = await endpoints.live.sendChat(
          tomas,
          showId,
          '  ¡Hola!  ',
        );

        expect(message.body, '¡Hola!');
        expect(message.authorUsername, 'tomas');
        expect(
          (await endpoints.live.chatHistory(fixtures.guest, showId)).map(
            (m) => m.id,
          ),
          [message.id],
        );
      });

      test('then two messages in the same second are rateLimited', () async {
        await endpoints.live.sendChat(tomas, showId, 'uno');

        await expectLater(
          endpoints.live.sendChat(tomas, showId, 'dos'),
          throwsNexo(NexoErrorCode.rateLimited),
        );
      });

      test('then a guest cannot send', () async {
        await expectLater(
          endpoints.live.sendChat(fixtures.guest, showId, 'hola'),
          throwsNexo(NexoErrorCode.unauthenticated),
        );
      });

      test('then a suspended account cannot send', () async {
        final suspended = fixtures.signedIn(
          await fixtures.seedAccount(
            'baneado',
            'Baneado',
            status: AccountStatus.suspended,
          ),
        );

        await expectLater(
          endpoints.live.sendChat(suspended, showId, 'hola'),
          throwsNexo(NexoErrorCode.accountSuspended),
        );
      });

      test('then the host and a moderator hide, and it is audited', () async {
        final first = await endpoints.live.sendChat(troll, showId, 'basura');
        final second = await endpoints.live.sendChat(tomas, showId, 'spam');

        await endpoints.live.hideChat(elena, first.id);
        await endpoints.live.hideChat(moderator, second.id);

        expect(await endpoints.live.chatHistory(fixtures.guest, showId), []);
        final hidden = await LiveChatMessage.db.findById(
          fixtures.session,
          first.id,
        );
        expect(hidden!.hiddenAt, isNotNull);
        expect(
          await AuditLog.db.count(
            fixtures.session,
            where: (t) => t.action.equals('live.hideChat'),
          ),
          2,
        );
      });

      test('then a viewer cannot hide someone else\'s message', () async {
        final message = await endpoints.live.sendChat(troll, showId, 'hola');

        await expectLater(
          endpoints.live.hideChat(tomas, message.id),
          throwsNexo(NexoErrorCode.forbidden),
        );
      });
    });
  });
}
