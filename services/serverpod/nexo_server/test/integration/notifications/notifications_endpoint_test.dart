import 'package:nexo_server/src/generated/protocol.dart';
import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';

import '../support/fixtures.dart';
import '../test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Given notifications', (sessionBuilder, endpoints) {
    final fixtures = Fixtures(sessionBuilder);
    late UuidValue elenaId;
    late UuidValue tomasId;
    late TestSessionBuilder elena;
    late TestSessionBuilder tomas;

    setUp(() async {
      elenaId = await fixtures.seedCreator('elena_ux', 'Elena Vega');
      tomasId = await fixtures.seedAccount('tomas', 'Tomás Ríos');
      elena = fixtures.signedIn(elenaId);
      tomas = fixtures.signedIn(tomasId);
    });

    Future<List<NotificationView>> inbox(TestSessionBuilder who) async =>
        (await endpoints.notifications.list(who)).items;

    test('then following someone notifies them with who it was', () async {
      await endpoints.follows.follow(tomas, elenaId);

      final items = await inbox(elena);
      expect(items.single.kind, NotificationKind.newFollower);
      expect(items.single.actorUsername, 'tomas');
      expect(items.single.isRead, isFalse);
      expect(await inbox(tomas), isEmpty);
    });

    test(
      'then a like and a comment notify the author with an excerpt',
      () async {
        final post = await endpoints.posts.create(
          elena,
          fixtures.draft('Mi nuevo diseño'),
        );
        await endpoints.likes.like(tomas, post.id);
        await endpoints.comments.create(tomas, post.id, '¡Genial!');

        final items = await inbox(elena);
        expect(items.map((n) => n.kind), [
          NotificationKind.postCommented,
          NotificationKind.postLiked,
        ]);
        expect(items.every((n) => n.postExcerpt == 'Mi nuevo diseño'), isTrue);
      },
    );

    test('then liking, unliking and liking again does not repeat an '
        'unread notification', () async {
      final post = await endpoints.posts.create(elena, fixtures.draft('hola'));
      await endpoints.likes.like(tomas, post.id);
      await endpoints.likes.unlike(tomas, post.id);
      await endpoints.likes.like(tomas, post.id);

      expect(await inbox(elena), hasLength(1));
    });

    test('then nobody is notified about their own actions', () async {
      final post = await endpoints.posts.create(elena, fixtures.draft('hola'));
      await endpoints.likes.like(elena, post.id);
      await endpoints.comments.create(elena, post.id, 'yo misma');

      expect(await inbox(elena), isEmpty);
    });

    test('then going live notifies every follower, not the host', () async {
      final ana = await fixtures.seedAccount('ana', 'Ana');
      await endpoints.follows.follow(tomas, elenaId);
      await endpoints.follows.follow(fixtures.signedIn(ana), elenaId);
      await endpoints.notifications.markAllRead(elena);

      final show = await endpoints.live.goLive(elena, 'Ahora mismo');

      for (final who in [tomas, fixtures.signedIn(ana)]) {
        final item = (await inbox(who)).single;
        expect(item.kind, NotificationKind.liveStarted);
        expect(item.showId, show.id);
        expect(item.showTitle, 'Ahora mismo');
      }
      expect(await endpoints.notifications.unreadCount(elena), 0);
    });

    test('then starting a scheduled show also notifies followers', () async {
      await endpoints.follows.follow(tomas, elenaId);
      final show = await endpoints.live.schedule(
        elena,
        fixtures.showDraft('Programado'),
      );
      await endpoints.live.start(elena, show.id);

      expect(
        (await inbox(tomas)).map((n) => n.kind),
        contains(NotificationKind.liveStarted),
      );
    });

    test(
      'then markRead only touches your own and unreadCount follows',
      () async {
        await endpoints.follows.follow(tomas, elenaId);
        final post = await endpoints.posts.create(
          elena,
          fixtures.draft('hola'),
        );
        await endpoints.likes.like(tomas, post.id);
        await endpoints.follows.follow(elena, tomasId);

        final mine = await inbox(elena);
        final theirs = await inbox(tomas);
        expect(await endpoints.notifications.unreadCount(elena), 2);

        final left = await endpoints.notifications.markRead(elena, [
          mine.first.id,
          theirs.single.id,
        ]);
        expect(left, 1);
        expect(await endpoints.notifications.unreadCount(tomas), 1);

        expect(await endpoints.notifications.markAllRead(elena), 0);
        expect(await endpoints.notifications.unreadCount(elena), 0);
        expect((await inbox(elena)).every((n) => n.isRead), isTrue);
      },
    );

    test('then a guest cannot read notifications', () async {
      await expectLater(
        endpoints.notifications.list(fixtures.guest),
        throwsNexo(NexoErrorCode.unauthenticated),
      );
    });
  });
}
