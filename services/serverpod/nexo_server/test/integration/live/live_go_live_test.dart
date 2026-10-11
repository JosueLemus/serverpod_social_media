import 'package:nexo_server/src/generated/protocol.dart';
import 'package:test/test.dart';

import '../support/fixtures.dart';
import '../test_tools/serverpod_test_tools.dart';

/// "Transmitir ahora" (`live.goLive`) y la credencial de video
/// (`live.mediaToken`).
void main() {
  withServerpod('Given Live endpoint', (sessionBuilder, endpoints) {
    final fixtures = Fixtures(sessionBuilder);
    late TestSessionBuilder elena;
    late TestSessionBuilder tomas;

    setUp(() async {
      elena = fixtures.signedIn(
        await fixtures.seedCreator('elena_ux', 'Elena Vega'),
      );
      tomas = fixtures.signedIn(
        await fixtures.seedAccount('tomas', 'Tomás Ríos'),
      );
    });

    group('when a verified creator goes live now', () {
      test('then the show is created already on air', () async {
        final show = await endpoints.live.goLive(elena, '  Probando  ');

        expect(show.status, LiveShowStatus.live);
        expect(show.title, 'Probando');
        expect(show.startedAt, isNotNull);
        expect(show.hostUsername, 'elena_ux');
        expect(
          (await endpoints.live.mine(elena)).map((s) => s.id),
          contains(show.id),
        );
      });

      test('then a second live while on air is a conflict', () async {
        await endpoints.live.goLive(elena, 'Primero');

        await expectLater(
          endpoints.live.goLive(elena, 'Segundo'),
          throwsNexo(NexoErrorCode.conflict),
        );
      });

      test(
        'then starting a scheduled show while on air is a conflict too',
        () async {
          final scheduled = await endpoints.live.schedule(
            elena,
            fixtures.showDraft('Programado'),
          );
          await endpoints.live.goLive(elena, 'Al aire');

          await expectLater(
            endpoints.live.start(elena, scheduled.id),
            throwsNexo(NexoErrorCode.conflict),
          );
        },
      );

      test('then going live again after ending works', () async {
        final first = await endpoints.live.goLive(elena, 'Primero');
        await endpoints.live.end(elena, first.id);

        final second = await endpoints.live.goLive(elena, 'Segundo');

        expect(second.status, LiveShowStatus.live);
        expect(second.id, isNot(first.id));
      });
    });

    group('when someone who cannot broadcast goes live now', () {
      test('then a guest is unauthenticated', () async {
        await expectLater(
          endpoints.live.goLive(fixtures.guest, 'Hola'),
          throwsNexo(NexoErrorCode.unauthenticated),
        );
      });

      test('then a plain user gets creatorNotVerified', () async {
        await expectLater(
          endpoints.live.goLive(tomas, 'Hola'),
          throwsNexo(NexoErrorCode.creatorNotVerified),
        );
      });

      test('then a suspended creator gets accountSuspended', () async {
        final suspended = fixtures.signedIn(
          await fixtures.seedAccount(
            'suspendida',
            'Suspendida',
            isCreator: true,
            verification: VerificationStatus.verified,
            status: AccountStatus.suspended,
          ),
        );

        await expectLater(
          endpoints.live.goLive(suspended, 'Hola'),
          throwsNexo(NexoErrorCode.accountSuspended),
        );
      });

      test('then an empty title is invalid input', () async {
        await expectLater(
          endpoints.live.goLive(elena, '   '),
          throwsNexo(NexoErrorCode.invalidInput),
        );
      });
    });

    group('when asking for the video credential', () {
      test('then the host on air publishes and the rest subscribes', () async {
        final show = await endpoints.live.goLive(elena, 'En vivo');

        final host = await endpoints.live.mediaToken(elena, show.id);
        final viewer = await endpoints.live.mediaToken(tomas, show.id);
        final guest = await endpoints.live.mediaToken(fixtures.guest, show.id);

        expect(host.role, LiveMediaGrantRole.publisher);
        expect(viewer.role, LiveMediaGrantRole.subscriber);
        expect(guest.role, LiveMediaGrantRole.subscriber);
        expect(host.channel, 'nexo_live_${show.id}');
        expect(viewer.channel, host.channel);
      });

      test('then each account has its own stable uid', () async {
        final show = await endpoints.live.goLive(elena, 'En vivo');

        final host = await endpoints.live.mediaToken(elena, show.id);
        final again = await endpoints.live.mediaToken(elena, show.id);
        final viewer = await endpoints.live.mediaToken(tomas, show.id);
        final guest = await endpoints.live.mediaToken(fixtures.guest, show.id);

        expect(host.uid, again.uid);
        expect(host.uid, isNot(viewer.uid));
        expect(host.uid, greaterThan(0));
        expect(guest.uid, 0);
      });

      test('then the host of a scheduled show only subscribes', () async {
        final show = await endpoints.live.schedule(
          elena,
          fixtures.showDraft('Más tarde'),
        );

        final grant = await endpoints.live.mediaToken(elena, show.id);

        expect(grant.role, LiveMediaGrantRole.subscriber);
      });

      test('then an ended show has no video to join', () async {
        final show = await endpoints.live.goLive(elena, 'Corto');
        await endpoints.live.end(elena, show.id);

        await expectLater(
          endpoints.live.mediaToken(tomas, show.id),
          throwsNexo(NexoErrorCode.conflict),
        );
      });

      test('then without an App Certificate the token is empty', () async {
        final show = await endpoints.live.goLive(elena, 'Modo prueba');

        final grant = await endpoints.live.mediaToken(elena, show.id);

        expect(grant.token, isEmpty);
        expect(
          grant.expiresAt.isAfter(DateTime.now().toUtc()),
          isTrue,
        );
      });
    });
  });
}
