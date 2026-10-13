import 'package:nexo_server/src/generated/protocol.dart';
import 'package:nexo_server/src/shared/auth/auth_context.dart';
import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';

import '../support/fixtures.dart';
import '../test_tools/serverpod_test_tools.dart';

/// La moderación dentro de una sala (SDD 0011, Etapa 3).
void main() {
  withServerpod('Given the moderation of a live room', (
    sessionBuilder,
    endpoints,
  ) {
    final fixtures = Fixtures(sessionBuilder);
    late TestSessionBuilder elena;
    late TestSessionBuilder carlos;
    late TestSessionBuilder tomas;
    late TestSessionBuilder troll;
    late UuidValue elenaId;
    late UuidValue carlosId;
    late UuidValue tomasId;
    late UuidValue trollId;
    late int showId;

    setUp(() async {
      elenaId = await fixtures.seedCreator('elena_ux', 'Elena Vega');
      elena = fixtures.signedIn(elenaId);
      carlosId = await fixtures.seedAccount('carlos', 'Carlos');
      carlos = fixtures.signedIn(carlosId);
      tomasId = await fixtures.seedAccount('tomas', 'Tomás');
      tomas = fixtures.signedIn(tomasId);
      trollId = await fixtures.seedAccount('troll', 'Troll');
      troll = fixtures.signedIn(trollId);
      showId = (await endpoints.live.schedule(
        elena,
        fixtures.showDraft('Masterclass'),
      )).id;
    });

    group('when the host names a moderator', () {
      test('then it can be done before going on air', () async {
        await endpoints.live.assignModerator(elena, showId, carlosId);
        expect(
          await endpoints.live.roleIn(carlos, showId),
          LiveShowRole.moderator,
        );
      });

      test('then naming another one demotes the first', () async {
        await endpoints.live.assignModerator(elena, showId, carlosId);
        await endpoints.live.assignModerator(elena, showId, tomasId);

        expect(
          await endpoints.live.roleIn(carlos, showId),
          LiveShowRole.audience,
        );
        expect(
          await endpoints.live.roleIn(tomas, showId),
          LiveShowRole.moderator,
        );
      });

      test('then null removes the moderator', () async {
        await endpoints.live.assignModerator(elena, showId, carlosId);
        await endpoints.live.assignModerator(elena, showId, null);
        expect(
          await endpoints.live.roleIn(carlos, showId),
          LiveShowRole.audience,
        );
      });

      test('then nobody else names one', () async {
        await expectLater(
          endpoints.live.assignModerator(tomas, showId, trollId),
          throwsNexo(NexoErrorCode.forbidden),
        );
      });
    });

    group('when the show is on air', () {
      setUp(() async {
        await endpoints.live.assignModerator(elena, showId, carlosId);
        await endpoints.live.start(elena, showId);
      });

      test('then a muted account cannot chat until it is lifted', () async {
        await endpoints.live.muteChat(carlos, showId, trollId, 5);

        await expectLater(
          endpoints.live.sendChat(troll, showId, 'spam'),
          throwsNexo(NexoErrorCode.muted),
        );

        await endpoints.live.unmuteChat(carlos, showId, trollId);
        expect(
          (await endpoints.live.sendChat(troll, showId, 'perdón')).body,
          'perdón',
        );
      });

      test('then a mute without minutes lasts the rest of the live', () async {
        await endpoints.live.muteChat(elena, showId, trollId, null);
        await expectLater(
          endpoints.live.sendChat(troll, showId, 'spam'),
          throwsNexo(NexoErrorCode.muted),
        );
      });

      test('then a mute of any other length is invalid', () async {
        await expectLater(
          endpoints.live.muteChat(elena, showId, trollId, 7),
          throwsNexo(NexoErrorCode.invalidInput),
        );
      });

      test('then the moderator does not touch the host', () async {
        await expectLater(
          endpoints.live.muteChat(carlos, showId, elenaId, 5),
          throwsNexo(NexoErrorCode.forbidden),
        );
        await expectLater(
          endpoints.live.kick(carlos, showId, elenaId),
          throwsNexo(NexoErrorCode.forbidden),
        );
      });

      test('then a kicked account cannot come back to this live', () async {
        await endpoints.live.raiseHand(troll, showId);
        await endpoints.live.kick(carlos, showId, trollId);

        await expectLater(
          endpoints.live.mediaToken(troll, showId),
          throwsNexo(NexoErrorCode.forbidden),
        );
        await expectLater(
          endpoints.live.sendChat(troll, showId, 'volví'),
          throwsNexo(NexoErrorCode.forbidden),
        );
        await expectLater(
          endpoints.live.raiseHand(troll, showId),
          throwsNexo(NexoErrorCode.forbidden),
        );
        // El pedido de palabra se fue con él.
        expect((await endpoints.live.stage(fixtures.guest, showId)).hands, []);
      });

      test('then a kick takes the person off the stage', () async {
        await endpoints.live.inviteToStage(elena, showId, tomasId);
        await endpoints.live.kick(elena, showId, tomasId);

        expect(
          (await endpoints.live.stage(fixtures.guest, showId)).speakers.map(
            (s) => s.userId,
          ),
          isNot(contains(tomasId)),
        );
      });

      test(
        'then only the host bans, and the ban follows to the next live',
        () async {
          await expectLater(
            endpoints.live.ban(carlos, showId, trollId),
            throwsNexo(NexoErrorCode.forbidden),
          );
          await endpoints.live.ban(elena, showId, trollId);
          await endpoints.live.end(elena, showId);

          final next = await endpoints.live.goLive(elena, 'Otra vez');
          await expectLater(
            endpoints.live.mediaToken(troll, next.id),
            throwsNexo(NexoErrorCode.forbidden),
          );

          await endpoints.live.unban(elena, trollId);
          expect(
            (await endpoints.live.mediaToken(troll, next.id)).role,
            LiveMediaGrantRole.subscriber,
          );
        },
      );

      test('then hiding is reversible and deleting is not', () async {
        final hidden = await endpoints.live.sendChat(troll, showId, 'uh');
        final deleted = await endpoints.live.sendChat(tomas, showId, 'basura');

        await endpoints.live.hideChat(carlos, hidden.id);
        await endpoints.live.deleteChat(carlos, deleted.id);
        expect(await endpoints.live.chatHistory(fixtures.guest, showId), []);

        await endpoints.live.unhideChat(elena, hidden.id);
        await endpoints.live.unhideChat(elena, deleted.id);
        expect(
          (await endpoints.live.chatHistory(fixtures.guest, showId)).map(
            (m) => m.id,
          ),
          [hidden.id],
        );

        // La fila borrada sigue ahí, para la auditoría.
        final row = await LiveChatMessage.db.findById(
          fixtures.session,
          deleted.id,
        );
        expect(row!.deletedAt, isNotNull);
        expect(row.deletedBy, carlosId);
      });

      test('then nobody deletes the host\'s messages', () async {
        final message = await endpoints.live.sendChat(elena, showId, 'hola');
        await expectLater(
          endpoints.live.deleteChat(carlos, message.id),
          throwsNexo(NexoErrorCode.forbidden),
        );
      });

      test('then a guest highlights a question but does not pin', () async {
        await endpoints.live.inviteToStage(elena, showId, tomasId);
        final question = await endpoints.live.sendChat(
          troll,
          showId,
          '¿Qué plugin usás?',
        );

        await endpoints.live.highlightQuestion(tomas, showId, question.id);
        await expectLater(
          endpoints.live.pinChat(tomas, showId, question.id),
          throwsNexo(NexoErrorCode.forbidden),
        );
        await expectLater(
          endpoints.live.highlightQuestion(troll, showId, question.id),
          throwsNexo(NexoErrorCode.forbidden),
        );

        final show = await LiveShow.db.findById(fixtures.session, showId);
        expect(show!.highlightedMessageId, question.id);
      });

      test('then deleting a pinned message unpins it', () async {
        final message = await endpoints.live.sendChat(tomas, showId, 'link');
        await endpoints.live.pinChat(elena, showId, message.id);
        await endpoints.live.deleteChat(elena, message.id);

        final show = await LiveShow.db.findById(fixtures.session, showId);
        expect(show!.pinnedMessageId, isNull);
      });

      test('then every action is audited', () async {
        final message = await endpoints.live.sendChat(troll, showId, 'spam');
        await endpoints.live.muteChat(carlos, showId, trollId, 15);
        await endpoints.live.deleteChat(carlos, message.id);
        await endpoints.live.kick(carlos, showId, trollId);

        final actions = (await AuditLog.db.find(fixtures.session)).map(
          (a) => a.action,
        );
        expect(
          actions,
          containsAll([
            'live.assignModerator',
            'live.muteChat',
            'live.deleteChat',
            'live.kick',
          ]),
        );
      });
    });

    test('when a Nexo moderator is in any live then it moderates', () async {
      final staff = fixtures.signedIn(
        await fixtures.seedAccount('mod_lucia', 'Lucía'),
        {NexoScopes.moderator},
      );
      await endpoints.live.start(elena, showId);
      await endpoints.live.kick(staff, showId, trollId);
      await expectLater(
        endpoints.live.mediaToken(troll, showId),
        throwsNexo(NexoErrorCode.forbidden),
      );
    });
  });
}
