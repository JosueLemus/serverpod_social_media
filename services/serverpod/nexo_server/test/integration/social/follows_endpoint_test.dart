import 'package:nexo_server/src/generated/protocol.dart';
import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';

import '../support/fixtures.dart';
import '../test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Given the follows endpoint', (sessionBuilder, endpoints) {
    final fixtures = Fixtures(sessionBuilder);

    Future<AccountProfile> account(UuidValue id) async =>
        (await AccountProfile.db.findFirstRow(
          fixtures.session,
          where: (t) => t.authUserId.equals(id),
        ))!;

    test('then following twice leaves one row and one follower', () async {
      final elena = await fixtures.seedCreator('elena_ux', 'Elena Vega');
      final tomas = await fixtures.seedAccount('tomas', 'Tomás Ríos');

      await endpoints.follows.follow(fixtures.signedIn(tomas), elena);
      final state = await endpoints.follows.follow(
        fixtures.signedIn(tomas),
        elena,
      );

      expect(state.viewerFollows, isTrue);
      expect(state.followerCount, 1);
      expect(await Follow.db.count(fixtures.session), 1);
      expect((await account(elena)).followerCount, 1);
      expect((await account(tomas)).followingCount, 1);
    });

    test(
      'then unfollowing someone you do not follow changes nothing',
      () async {
        final elena = await fixtures.seedCreator('elena_ux', 'Elena Vega');
        final tomas = await fixtures.seedAccount('tomas', 'Tomás Ríos');

        final state = await endpoints.follows.unfollow(
          fixtures.signedIn(tomas),
          elena,
        );

        expect(state.viewerFollows, isFalse);
        expect(state.followerCount, 0);
        expect((await account(tomas)).followingCount, 0);
      },
    );

    test('then unfollow undoes follow and both counters go back', () async {
      final elena = await fixtures.seedCreator('elena_ux', 'Elena Vega');
      final tomas = await fixtures.seedAccount('tomas', 'Tomás Ríos');
      await endpoints.follows.follow(fixtures.signedIn(tomas), elena);

      final state = await endpoints.follows.unfollow(
        fixtures.signedIn(tomas),
        elena,
      );

      expect(state.followerCount, 0);
      expect(await Follow.db.count(fixtures.session), 0);
      expect((await account(elena)).followerCount, 0);
      expect((await account(tomas)).followingCount, 0);
    });

    test('then following yourself is invalidInput', () async {
      final tomas = await fixtures.seedAccount('tomas', 'Tomás Ríos');
      await expectLater(
        endpoints.follows.follow(fixtures.signedIn(tomas), tomas),
        throwsNexo(NexoErrorCode.invalidInput),
      );
    });

    test('then a suspended account cannot follow', () async {
      final elena = await fixtures.seedCreator('elena_ux', 'Elena Vega');
      final troll = await fixtures.seedAccount(
        'troll_99',
        'Troll 99',
        status: AccountStatus.suspended,
      );
      await expectLater(
        endpoints.follows.follow(fixtures.signedIn(troll), elena),
        throwsNexo(NexoErrorCode.accountSuspended),
      );
    });

    test(
      'then a guest cannot follow and an unknown account is notFound',
      () async {
        final elena = await fixtures.seedCreator('elena_ux', 'Elena Vega');
        final tomas = await fixtures.seedAccount('tomas', 'Tomás Ríos');
        await expectLater(
          endpoints.follows.follow(fixtures.guest, elena),
          throwsNexo(NexoErrorCode.unauthenticated),
        );
        await expectLater(
          endpoints.follows.follow(
            fixtures.signedIn(tomas),
            UuidValue.fromString('00000000-0000-7000-8000-000000000000'),
          ),
          throwsNexo(NexoErrorCode.notFound),
        );
      },
    );

    test('then followers and following page from newest to oldest', () async {
      final elena = await fixtures.seedCreator('elena_ux', 'Elena Vega');
      final fans = [
        for (var i = 0; i < 3; i++)
          await fixtures.seedAccount('fan_$i', 'Fan $i'),
      ];
      for (final fan in fans) {
        await endpoints.follows.follow(fixtures.signedIn(fan), elena);
      }

      final first = await endpoints.follows.followers(
        fixtures.guest,
        elena,
        limit: 2,
      );
      final rest = await endpoints.follows.followers(
        fixtures.guest,
        elena,
        after: first.nextCursor,
        limit: 2,
      );

      expect(first.items.map((p) => p.username), ['fan_2', 'fan_1']);
      expect(first.nextCursor, isNotNull);
      expect(rest.items.map((p) => p.username), ['fan_0']);
      expect(rest.nextCursor, isNull);

      final following = await endpoints.follows.following(
        fixtures.guest,
        fans.first,
      );
      expect(following.items.single.username, 'elena_ux');
    });

    test('then suggestions are verified creators you do not follow yet, '
        'most followed first', () async {
      final elena = await fixtures.seedCreator('elena_ux', 'Elena Vega');
      final carlos = await fixtures.seedCreator('carlos_mendez', 'Carlos');
      await fixtures.seedAccount(
        'unverified',
        'Sin verificar',
        isCreator: true,
      );
      final tomas = await fixtures.seedAccount('tomas', 'Tomás Ríos');
      final fan = await fixtures.seedAccount('fan', 'Fan');
      await endpoints.follows.follow(fixtures.signedIn(fan), carlos);

      final asGuest = await endpoints.follows.suggestions(fixtures.guest);
      expect(asGuest.map((p) => p.username), [
        'carlos_mendez',
        'elena_ux',
      ]);

      await endpoints.follows.follow(fixtures.signedIn(tomas), carlos);
      final forTomas = await endpoints.follows.suggestions(
        fixtures.signedIn(tomas),
      );
      expect(forTomas.map((p) => p.userId), [elena]);

      final forElena = await endpoints.follows.suggestions(
        fixtures.signedIn(elena),
      );
      expect(forElena.map((p) => p.userId), isNot(contains(elena)));
    });

    test('then a profile says whether the viewer follows it', () async {
      final elena = await fixtures.seedCreator('elena_ux', 'Elena Vega');
      final tomas = await fixtures.seedAccount('tomas', 'Tomás Ríos');
      await endpoints.follows.follow(fixtures.signedIn(tomas), elena);

      final seenByTomas = await endpoints.profiles.byUsername(
        fixtures.signedIn(tomas),
        'elena_ux',
      );
      final seenByGuest = await endpoints.profiles.byUsername(
        fixtures.guest,
        'elena_ux',
      );

      expect(seenByTomas.viewerFollows, isTrue);
      expect(seenByTomas.followerCount, 1);
      expect(seenByGuest.viewerFollows, isFalse);
      expect(seenByGuest.followerCount, 1);
      final me = await endpoints.profiles.me(fixtures.signedIn(tomas));
      expect(me.profile.followingCount, 1);
    });
  });
}
