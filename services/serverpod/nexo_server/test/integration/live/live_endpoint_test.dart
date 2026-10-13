import 'package:nexo_server/src/generated/protocol.dart';
import 'package:nexo_server/src/shared/auth/auth_context.dart';
import 'package:nexo_server/src/modules/live/services/live_rules.dart';
import 'package:test/test.dart';

import '../support/fixtures.dart';
import '../test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Given Live endpoint', (sessionBuilder, endpoints) {
    final fixtures = Fixtures(sessionBuilder);
    late TestSessionBuilder elena;
    late TestSessionBuilder tomas;
    late TestSessionBuilder operator;
    late int showId;

    setUp(() async {
      elena = fixtures.signedIn(
        await fixtures.seedCreator('elena_ux', 'Elena Vega'),
      );
      tomas = fixtures.signedIn(
        await fixtures.seedAccount('tomas', 'Tomás Ríos'),
      );
      operator = fixtures.signedIn(
        await fixtures.seedAccount('nexo_ops', 'Operaciones'),
        {NexoScopes.admin},
      );
      showId = (await endpoints.live.schedule(
        elena,
        fixtures.showDraft('Masterclass'),
      )).id;
    });

    group('when a verified creator schedules a show', () {
      test('then it comes back scheduled with the host data', () async {
        final show = await endpoints.live.get(fixtures.guest, showId);

        expect(show.status, LiveShowStatus.scheduled);
        expect(show.hostUsername, 'elena_ux');
        expect(show.hostName, 'Elena Vega');
        expect(show.viewerCount, 0);
      });

      test('then a guest is stored by username', () async {
        final show = await endpoints.live.schedule(
          elena,
          fixtures.showDraft('Con invitado', guests: ['@Tomas']),
        );

        expect(show.guestIds, hasLength(1));
      });

      test(
        'then a past date or more guests than the stage are rejected',
        () async {
          await expectLater(
            endpoints.live.schedule(
              elena,
              fixtures.showDraft(
                'Ayer',
                startsAt: DateTime.now().toUtc().subtract(
                  const Duration(hours: 1),
                ),
              ),
            ),
            throwsNexo(NexoErrorCode.invalidInput),
          );
          await expectLater(
            endpoints.live.schedule(
              elena,
              fixtures.showDraft(
                'Muchos',
                guests: [
                  for (var i = 0; i <= LiveRules.maxGuests; i++) 'guest$i',
                ],
              ),
            ),
            throwsNexo(NexoErrorCode.invalidInput),
          );
        },
      );

      test('then an unknown guest is notFound', () async {
        await expectLater(
          endpoints.live.schedule(
            elena,
            fixtures.showDraft('Fantasma', guests: ['nadie']),
          ),
          throwsNexo(NexoErrorCode.notFound),
        );
      });
    });

    group('when someone who is not a verified creator schedules', () {
      test('then a plain user gets creatorNotVerified', () async {
        await expectLater(
          endpoints.live.schedule(tomas, fixtures.showDraft('Mío')),
          throwsNexo(NexoErrorCode.creatorNotVerified),
        );
      });

      test('then a guest gets unauthenticated', () async {
        await expectLater(
          endpoints.live.schedule(fixtures.guest, fixtures.showDraft('x')),
          throwsNexo(NexoErrorCode.unauthenticated),
        );
      });
    });

    group('when the host starts the show', () {
      test('then it goes live with a start time', () async {
        final show = await endpoints.live.start(elena, showId);

        expect(show.status, LiveShowStatus.live);
        expect(show.startedAt, isNotNull);
      });

      test('then a second show on air is a conflict', () async {
        final other = await endpoints.live.schedule(
          elena,
          fixtures.showDraft('Otro'),
        );
        await endpoints.live.start(elena, showId);

        await expectLater(
          endpoints.live.start(elena, other.id),
          throwsNexo(NexoErrorCode.conflict),
        );
      });

      test('then starting twice is a conflict', () async {
        await endpoints.live.start(elena, showId);

        await expectLater(
          endpoints.live.start(elena, showId),
          throwsNexo(NexoErrorCode.conflict),
        );
      });
    });

    group('when someone else tries to start it', () {
      test('then a viewer and the operator are forbidden', () async {
        await expectLater(
          endpoints.live.start(tomas, showId),
          throwsNexo(NexoErrorCode.forbidden),
        );
        await expectLater(
          endpoints.live.start(operator, showId),
          throwsNexo(NexoErrorCode.forbidden),
        );
      });

      test('then a guest is unauthenticated', () async {
        await expectLater(
          endpoints.live.start(fixtures.guest, showId),
          throwsNexo(NexoErrorCode.unauthenticated),
        );
      });
    });

    group('when the host lost the conditions to go live', () {
      test('then an unverified creator gets creatorNotVerified', () async {
        await _setAccount(
          fixtures,
          'elena_ux',
          (a) => a.copyWith(verification: VerificationStatus.revoked),
        );

        await expectLater(
          endpoints.live.start(elena, showId),
          throwsNexo(NexoErrorCode.creatorNotVerified),
        );
      });

      test('then a suspended host gets accountSuspended', () async {
        await _setAccount(
          fixtures,
          'elena_ux',
          (a) => a.copyWith(status: AccountStatus.suspended),
        );

        await expectLater(
          endpoints.live.start(elena, showId),
          throwsNexo(NexoErrorCode.accountSuspended),
        );
      });
    });

    group('when the show ends', () {
      test('then the host ends it and it becomes a replay', () async {
        await endpoints.live.start(elena, showId);
        final ended = await endpoints.live.end(elena, showId);

        expect(ended.status, LiveShowStatus.recorded);
        expect(ended.endedAt, isNotNull);
        expect(ended.endedByModeration, isFalse);

        final published = await endpoints.live.publish(elena, showId);
        expect(published.status, LiveShowStatus.published);
      });

      test('then the operator ending it marks it as moderation', () async {
        await endpoints.live.start(elena, showId);
        final ended = await endpoints.live.end(operator, showId);

        expect(ended.endedByModeration, isTrue);
      });

      test('then a viewer cannot end it', () async {
        await endpoints.live.start(elena, showId);

        await expectLater(
          endpoints.live.end(tomas, showId),
          throwsNexo(NexoErrorCode.forbidden),
        );
      });

      test('then ending a show that never started is a conflict', () async {
        await expectLater(
          endpoints.live.end(elena, showId),
          throwsNexo(NexoErrorCode.conflict),
        );
      });

      test('then a show without replay cannot be published', () async {
        final noReplay = await endpoints.live.schedule(
          elena,
          fixtures.showDraft('Sin replay', recordReplay: false),
        );
        await endpoints.live.start(elena, noReplay.id);
        await endpoints.live.end(elena, noReplay.id);

        await expectLater(
          endpoints.live.publish(elena, noReplay.id),
          throwsNexo(NexoErrorCode.conflict),
        );
      });
    });

    group('when reading', () {
      test('then the transitions are audited', () async {
        await endpoints.live.start(elena, showId);
        await endpoints.live.end(elena, showId);

        final actions = (await AuditLog.db.find(
          fixtures.session,
          where: (t) => t.entityType.equals('liveShow'),
          orderBy: (t) => t.id,
        )).map((a) => a.action);
        expect(
          actions,
          containsAllInOrder([
            'live.schedule',
            'live.start',
            'live.end',
          ]),
        );
      });

      test('then list puts the show on air first', () async {
        final other = await endpoints.live.schedule(
          elena,
          fixtures.showDraft('Después'),
        );
        await endpoints.live.start(elena, other.id);

        final list = await endpoints.live.list(fixtures.guest);
        expect(list.first.id, other.id);
        expect(list.map((s) => s.id), contains(showId));
      });

      test('then mine returns only own shows', () async {
        expect(
          (await endpoints.live.mine(elena)).map((s) => s.id),
          contains(showId),
        );
        expect(await endpoints.live.mine(tomas), isEmpty);
      });

      test('then roleIn tells host, moderator and audience apart', () async {
        expect(await endpoints.live.roleIn(elena, showId), LiveShowRole.host);
        expect(
          await endpoints.live.roleIn(operator, showId),
          LiveShowRole.moderator,
        );
        expect(
          await endpoints.live.roleIn(tomas, showId),
          LiveShowRole.audience,
        );
        expect(
          await endpoints.live.roleIn(fixtures.guest, showId),
          LiveShowRole.audience,
        );
      });

      test('then an unknown show is notFound', () async {
        await expectLater(
          endpoints.live.get(fixtures.guest, 999999),
          throwsNexo(NexoErrorCode.notFound),
        );
      });
    });
  });
}

/// Cambia el perfil de Nexo de [username] directo en la base, como lo haría
/// el operador desde la consola (M6).
Future<void> _setAccount(
  Fixtures fixtures,
  String username,
  AccountProfile Function(AccountProfile) change,
) async {
  final account = (await AccountProfile.db.findFirstRow(
    fixtures.session,
    where: (t) => t.username.equals(username),
  ))!;
  await AccountProfile.db.updateRow(fixtures.session, change(account));
}
