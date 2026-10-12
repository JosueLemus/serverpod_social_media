import 'package:nexo_server/src/generated/protocol.dart';
import 'package:test/test.dart';

import '../support/fixtures.dart';
import '../test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Given the home feed', (sessionBuilder, endpoints) {
    final fixtures = Fixtures(sessionBuilder);

    List<FeedSectionKind> kinds(HomeFeedPage page) => [
      for (final section in page.sections) section.kind,
    ];

    FeedSection section(HomeFeedPage page, FeedSectionKind kind) =>
        page.sections.singleWhere((s) => s.kind == kind);

    List<String> bodies(FeedSection section) => [
      for (final item in section.items) item.post!.body,
    ];

    test(
      'then the first page has every section with content, in order',
      () async {
        final elena = await fixtures.seedCreator('elena_ux', 'Elena Vega');
        final carlos = await fixtures.seedCreator('carlos_mendez', 'Carlos');
        final tomas = await fixtures.seedAccount('tomas', 'Tomás Ríos');
        await endpoints.follows.follow(fixtures.signedIn(tomas), elena);
        await endpoints.posts.create(
          fixtures.signedIn(elena),
          fixtures.draft('de elena'),
        );
        await endpoints.posts.create(
          fixtures.signedIn(carlos),
          fixtures.draft('de carlos'),
        );
        await endpoints.live.goLive(fixtures.signedIn(carlos), 'Al aire');

        final page = await endpoints.feed.home(fixtures.signedIn(tomas));

        expect(kinds(page), [
          FeedSectionKind.liveNow,
          FeedSectionKind.following,
          FeedSectionKind.suggestedAccounts,
          FeedSectionKind.discover,
        ]);
        expect(
          section(page, FeedSectionKind.liveNow).items.single.kind,
          FeedItemKind.liveShow,
        );
        expect(bodies(section(page, FeedSectionKind.following)), ['de elena']);
        expect(bodies(section(page, FeedSectionKind.discover)), ['de carlos']);
        expect(
          section(page, FeedSectionKind.suggestedAccounts).accounts.map(
            (p) => p.username,
          ),
          ['carlos_mendez'],
        );
        expect(
          section(page, FeedSectionKind.following).items.single.kind,
          FeedItemKind.textPost,
        );
      },
    );

    test('then a guest gets no following section', () async {
      final elena = await fixtures.seedCreator('elena_ux', 'Elena Vega');
      await endpoints.posts.create(
        fixtures.signedIn(elena),
        fixtures.draft('hola'),
      );

      final page = await endpoints.feed.home(fixtures.guest);

      expect(kinds(page), isNot(contains(FeedSectionKind.following)));
      expect(bodies(section(page, FeedSectionKind.discover)), ['hola']);
    });

    test('then the cursor walks following first and discover after, '
        'without repeating', () async {
      final elena = await fixtures.seedCreator('elena_ux', 'Elena Vega');
      final carlos = await fixtures.seedCreator('carlos_mendez', 'Carlos');
      final tomas = await fixtures.seedAccount('tomas', 'Tomás Ríos');
      await endpoints.follows.follow(fixtures.signedIn(tomas), elena);
      for (var i = 0; i < 25; i++) {
        await endpoints.posts.create(
          fixtures.signedIn(elena),
          fixtures.draft('e$i'),
        );
        await endpoints.posts.create(
          fixtures.signedIn(carlos),
          fixtures.draft('c$i'),
        );
      }

      final seen = <String>[];
      var page = await endpoints.feed.home(fixtures.signedIn(tomas));
      final order = <FeedSectionKind>[];
      while (true) {
        for (final s in page.sections) {
          if (s.kind == FeedSectionKind.following ||
              s.kind == FeedSectionKind.discover) {
            order.add(s.kind);
            seen.addAll(bodies(s));
          }
        }
        final next = page.nextCursor;
        if (next == null) break;
        page = await endpoints.feed.home(
          fixtures.signedIn(tomas),
          cursor: next,
        );
      }

      expect(seen.toSet().length, seen.length);
      expect(seen.where((b) => b.startsWith('e')).length, 25);
      expect(seen.where((b) => b.startsWith('c')).length, 25);
      // Primera página: following y discover; después following hasta
      // agotarse y recién ahí discover.
      expect(order, [
        FeedSectionKind.following,
        FeedSectionKind.discover,
        FeedSectionKind.following,
        FeedSectionKind.discover,
      ]);
    });

    test('then discover prefers posts that share tags you liked', () async {
      final elena = await fixtures.seedCreator('elena_ux', 'Elena Vega');
      final carlos = await fixtures.seedCreator('carlos_mendez', 'Carlos');
      final tomas = await fixtures.seedAccount('tomas', 'Tomás Ríos');
      final liked = await endpoints.posts.create(
        fixtures.signedIn(tomas),
        fixtures.draft('propio', tags: ['flutter']),
      );
      await endpoints.likes.like(fixtures.signedIn(tomas), liked.id);
      await endpoints.posts.create(
        fixtures.signedIn(elena),
        fixtures.draft('con flutter', tags: ['flutter']),
      );
      await endpoints.posts.create(
        fixtures.signedIn(carlos),
        fixtures.draft('sin nada en común', tags: ['cocina']),
      );

      final page = await endpoints.feed.home(fixtures.signedIn(tomas));

      expect(bodies(section(page, FeedSectionKind.discover)), ['con flutter']);
    });
  });

  withServerpod('Given a followers-only post', (sessionBuilder, endpoints) {
    final fixtures = Fixtures(sessionBuilder);

    test('then followers see it and everyone else gets notFound', () async {
      final elena = await fixtures.seedCreator('elena_ux', 'Elena Vega');
      final tomas = await fixtures.seedAccount('tomas', 'Tomás Ríos');
      final carlos = await fixtures.seedAccount('carlos', 'Carlos');
      await endpoints.follows.follow(fixtures.signedIn(tomas), elena);
      final post = await endpoints.posts.create(
        fixtures.signedIn(elena),
        fixtures.draft('sólo seguidores', visibility: PostVisibility.followers),
      );

      final seen = await endpoints.posts.get(fixtures.signedIn(tomas), post.id);
      expect(seen.body, 'sólo seguidores');
      expect(
        (await endpoints.posts.feed(
          fixtures.signedIn(tomas),
        )).items.map((p) => p.id),
        contains(post.id),
      );

      await expectLater(
        endpoints.posts.get(fixtures.signedIn(carlos), post.id),
        throwsNexo(NexoErrorCode.notFound),
      );
      await expectLater(
        endpoints.posts.get(fixtures.guest, post.id),
        throwsNexo(NexoErrorCode.notFound),
      );
      expect(
        (await endpoints.posts.feed(
          fixtures.signedIn(carlos),
        )).items.map((p) => p.id),
        isNot(contains(post.id)),
      );
    });
  });
}
