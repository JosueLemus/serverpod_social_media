import 'package:nexo_server/src/generated/protocol.dart';
import 'package:nexo_server/src/modules/live/services/live_rules.dart';
import 'package:nexo_server/src/shared/auth/auth_context.dart';
import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';

import '../support/fixtures.dart';
import '../test_tools/serverpod_test_tools.dart';

/// El escenario de una sala (SDD 0011, Etapa 2).
void main() {
  withServerpod('Given the stage of a live room', (sessionBuilder, endpoints) {
    final fixtures = Fixtures(sessionBuilder);
    late TestSessionBuilder elena;
    late TestSessionBuilder carlos;
    late TestSessionBuilder tomas;
    late TestSessionBuilder ana;
    late TestSessionBuilder moderator;
    late UuidValue carlosId;
    late UuidValue tomasId;
    late UuidValue anaId;
    late UuidValue elenaId;
    late int showId;

    setUp(() async {
      elenaId = await fixtures.seedCreator('elena_ux', 'Elena Vega');
      elena = fixtures.signedIn(elenaId);
      carlosId = await fixtures.seedAccount('carlos', 'Carlos');
      carlos = fixtures.signedIn(carlosId);
      tomasId = await fixtures.seedAccount('tomas', 'Tomás');
      tomas = fixtures.signedIn(tomasId);
      anaId = await fixtures.seedAccount('ana', 'Ana');
      ana = fixtures.signedIn(anaId);
      moderator = fixtures.signedIn(
        await fixtures.seedAccount('mod_lucia', 'Lucía'),
        {NexoScopes.moderator},
      );
      showId = (await endpoints.live.schedule(
        elena,
        fixtures.showDraft('Masterclass', guests: ['carlos']),
      )).id;
    });

    test(
      'when the show is not on air then raising a hand is a conflict',
      () async {
        await expectLater(
          endpoints.live.raiseHand(tomas, showId),
          throwsNexo(NexoErrorCode.conflict),
        );
      },
    );

    group('when the show goes on air', () {
      setUp(() => endpoints.live.start(elena, showId));

      test('then the host and the agenda guests are on stage', () async {
        final stage = await endpoints.live.stage(fixtures.guest, showId);

        expect(stage.speakers.map((s) => s.userId), [elenaId, carlosId]);
        expect(stage.speakers.first.role, LiveShowRole.host);
        expect(stage.speakers.last.role, LiveShowRole.cohost);
        expect(stage.hands, isEmpty);
        expect(
          await endpoints.live.roleIn(carlos, showId),
          LiveShowRole.cohost,
        );
      });

      test(
        'then a guest on stage publishes and the audience does not',
        () async {
          expect(
            (await endpoints.live.mediaToken(carlos, showId)).role,
            LiveMediaGrantRole.publisher,
          );
          expect(
            (await endpoints.live.mediaToken(tomas, showId)).role,
            LiveMediaGrantRole.subscriber,
          );
        },
      );

      test('then a raised hand goes up when the host approves it', () async {
        await endpoints.live.raiseHand(tomas, showId);
        await endpoints.live.raiseHand(ana, showId);

        var stage = await endpoints.live.stage(fixtures.guest, showId);
        expect(stage.hands.map((h) => h.userId), [tomasId, anaId]);

        await endpoints.live.approveRequest(elena, showId, tomasId);

        stage = await endpoints.live.stage(fixtures.guest, showId);
        expect(stage.speakers.map((s) => s.userId), contains(tomasId));
        expect(stage.hands.map((h) => h.userId), [anaId]);
        expect(await endpoints.live.roleIn(tomas, showId), LiveShowRole.cohost);
        expect(
          (await endpoints.live.mediaToken(tomas, showId)).role,
          LiveMediaGrantRole.publisher,
        );
      });

      test('then raising a hand twice keeps the place in the queue', () async {
        await endpoints.live.raiseHand(tomas, showId);
        final first = (await endpoints.live.stage(
          fixtures.guest,
          showId,
        )).hands.single.raisedAt;
        await endpoints.live.raiseHand(tomas, showId);

        expect(
          (await endpoints.live.stage(
            fixtures.guest,
            showId,
          )).hands.single.raisedAt,
          first,
        );
      });

      test('then approving someone who did not ask is a conflict', () async {
        await expectLater(
          endpoints.live.approveRequest(elena, showId, tomasId),
          throwsNexo(NexoErrorCode.conflict),
        );
      });

      test('then the moderator approves but cannot invite directly', () async {
        await endpoints.live.raiseHand(tomas, showId);
        await endpoints.live.approveRequest(moderator, showId, tomasId);
        expect(await endpoints.live.roleIn(tomas, showId), LiveShowRole.cohost);

        await expectLater(
          endpoints.live.inviteToStage(moderator, showId, anaId),
          throwsNexo(NexoErrorCode.forbidden),
        );
      });

      test('then a guest does not moderate the stage', () async {
        await endpoints.live.raiseHand(tomas, showId);
        await expectLater(
          endpoints.live.approveRequest(carlos, showId, tomasId),
          throwsNexo(NexoErrorCode.forbidden),
        );
        await expectLater(
          endpoints.live.setMicMuted(carlos, showId, elenaId, true),
          throwsNexo(NexoErrorCode.forbidden),
        );
      });

      test('then a denied request leaves the person in the room', () async {
        await endpoints.live.raiseHand(tomas, showId);
        await endpoints.live.denyRequest(elena, showId, tomasId);

        final stage = await endpoints.live.stage(fixtures.guest, showId);
        expect(stage.hands, isEmpty);
        expect(stage.speakers.map((s) => s.userId), isNot(contains(tomasId)));
      });

      test('then the host invites directly and takes people down', () async {
        await endpoints.live.inviteToStage(elena, showId, tomasId);
        expect(await endpoints.live.roleIn(tomas, showId), LiveShowRole.cohost);

        await endpoints.live.removeFromStage(elena, showId, tomasId);
        expect(
          await endpoints.live.roleIn(tomas, showId),
          LiveShowRole.audience,
        );
        expect(
          (await endpoints.live.mediaToken(tomas, showId)).role,
          LiveMediaGrantRole.subscriber,
        );
      });

      test(
        'then an agenda guest who leaves goes back to the audience',
        () async {
          await endpoints.live.leaveStage(carlos, showId);

          expect(
            await endpoints.live.roleIn(carlos, showId),
            LiveShowRole.audience,
          );
          expect(
            (await endpoints.live.stage(fixtures.guest, showId)).speakers.map(
              (s) => s.userId,
            ),
            [elenaId],
          );
        },
      );

      test('then muting someone else is soft and only goes one way', () async {
        await endpoints.live.setMicMuted(moderator, showId, carlosId, true);
        var carlosOnStage = (await endpoints.live.stage(
          fixtures.guest,
          showId,
        )).speakers.last;
        expect(carlosOnStage.micMuted, isTrue);

        await expectLater(
          endpoints.live.setMicMuted(moderator, showId, carlosId, false),
          throwsNexo(NexoErrorCode.forbidden),
        );

        // El propio invitado lo vuelve a activar (S11).
        await endpoints.live.setMicMuted(carlos, showId, carlosId, false);
        carlosOnStage = (await endpoints.live.stage(
          fixtures.guest,
          showId,
        )).speakers.last;
        expect(carlosOnStage.micMuted, isFalse);
      });

      test('then nobody silences the host', () async {
        await expectLater(
          endpoints.live.setMicMuted(moderator, showId, elenaId, true),
          throwsNexo(NexoErrorCode.forbidden),
        );
      });

      test('then the camera is only for those on stage', () async {
        await endpoints.live.setCamera(carlos, showId, true);
        expect(
          (await endpoints.live.stage(
            fixtures.guest,
            showId,
          )).speakers.last.cameraOn,
          isTrue,
        );
        await expectLater(
          endpoints.live.setCamera(tomas, showId, true),
          throwsNexo(NexoErrorCode.forbidden),
        );
      });

      test(
        'then the stage holds the host and ${LiveRules.maxGuests} guests',
        () async {
          // Carlos ya ocupa un lugar desde la agenda.
          for (var i = 1; i < LiveRules.maxGuests; i++) {
            final id = await fixtures.seedAccount('extra$i', 'Extra $i');
            await endpoints.live.inviteToStage(elena, showId, id);
          }
          expect(
            (await endpoints.live.stage(fixtures.guest, showId)).speakers,
            hasLength(LiveRules.maxGuests + 1),
          );

          await expectLater(
            endpoints.live.inviteToStage(elena, showId, tomasId),
            throwsNexo(NexoErrorCode.conflict),
          );
        },
      );

      test('then every action on someone else is audited', () async {
        await endpoints.live.raiseHand(tomas, showId);
        await endpoints.live.approveRequest(elena, showId, tomasId);
        await endpoints.live.setMicMuted(elena, showId, tomasId, true);
        await endpoints.live.removeFromStage(elena, showId, tomasId);

        final actions = (await AuditLog.db.find(
          fixtures.session,
          where: (t) => t.entityId.equals('$showId'),
        )).map((a) => a.action);
        expect(
          actions,
          containsAll([
            'live.stage.approve',
            'live.stage.muteMic',
            'live.stage.remove',
          ]),
        );
      });
    });
  });
}
