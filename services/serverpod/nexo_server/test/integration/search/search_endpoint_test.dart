import 'package:nexo_server/src/generated/protocol.dart';
import 'package:test/test.dart';

import '../support/fixtures.dart';
import '../test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Given the search endpoint', (sessionBuilder, endpoints) {
    final fixtures = Fixtures(sessionBuilder);

    List<String> usernames(SearchResults r) => [
      for (final a in r.accounts) a.username,
    ];
    List<String> bodies(SearchResults r) => [for (final p in r.posts) p.body];

    test('then less than two letters returns nothing', () async {
      await fixtures.seedAccount('ana', 'Ana');
      for (final text in ['a', ' a ', '@', '#a', '   ']) {
        final r = await endpoints.search.query(fixtures.guest, text);
        expect(r.accounts, isEmpty, reason: text);
        expect(r.posts, isEmpty, reason: text);
        expect(r.lives, isEmpty, reason: text);
        expect(r.tags, isEmpty, reason: text);
      }
    });

    test(
      'then accounts that start with the text come first, by followers',
      () async {
        final contains = await fixtures.seedAccount('adele_r', 'Adele Ríos');
        await fixtures.seedAccount('elena_ux', 'Elena Vega');
        final popular = await fixtures.seedAccount('elenita', 'Elenita');
        final fan = await fixtures.seedAccount('tomas', 'Tomás');
        await endpoints.follows.follow(fixtures.signedIn(fan), popular);
        await endpoints.follows.follow(fixtures.signedIn(fan), contains);

        final r = await endpoints.search.query(fixtures.guest, '  @ELE ');

        expect(r.query, 'ele');
        expect(usernames(r), ['elenita', 'elena_ux', 'adele_r']);
      },
    );

    test(
      'then it finds accounts by display name and skips suspended',
      () async {
        await fixtures.seedAccount('lu_design', 'Lucía Torres');
        await fixtures.seedAccount(
          'troll_99',
          'Lucía Falsa',
          status: AccountStatus.suspended,
        );

        final r = await endpoints.search.query(fixtures.guest, 'lucía');

        expect(usernames(r), ['lu_design']);
      },
    );

    test(
      'then posts respect visibility: followers only for followers',
      () async {
        final elena = await fixtures.seedCreator('elena_ux', 'Elena Vega');
        final fan = await fixtures.seedAccount('tomas', 'Tomás');
        final other = await fixtures.seedAccount('otro', 'Otro');
        await endpoints.follows.follow(fixtures.signedIn(fan), elena);
        await endpoints.posts.create(
          fixtures.signedIn(elena),
          fixtures.draft('Masterclass pública'),
        );
        await endpoints.posts.create(
          fixtures.signedIn(elena),
          fixtures.draft(
            'Masterclass para seguidores',
            visibility: PostVisibility.followers,
          ),
        );
        final gone = await endpoints.posts.create(
          fixtures.signedIn(elena),
          fixtures.draft('Masterclass borrada'),
        );
        await endpoints.posts.delete(fixtures.signedIn(elena), gone.id);

        final asFan = await endpoints.search.query(
          fixtures.signedIn(fan),
          'masterclass',
        );
        final asOther = await endpoints.search.query(
          fixtures.signedIn(other),
          'masterclass',
        );
        final asGuest = await endpoints.search.query(
          fixtures.guest,
          'masterclass',
        );

        expect(bodies(asFan), [
          'Masterclass para seguidores',
          'Masterclass pública',
        ]);
        expect(bodies(asOther), ['Masterclass pública']);
        expect(bodies(asGuest), ['Masterclass pública']);
      },
    );

    test('then posts match by tag, and tags come by use', () async {
      final elena = await fixtures.seedCreator('elena_ux', 'Elena Vega');
      await endpoints.posts.create(
        fixtures.signedIn(elena),
        fixtures.draft('uno', tags: ['flutterdev', 'uiux']),
      );
      await endpoints.posts.create(
        fixtures.signedIn(elena),
        fixtures.draft('dos', tags: ['flutterdev']),
      );
      await endpoints.posts.create(
        fixtures.signedIn(elena),
        fixtures.draft('tres', tags: ['flutterweb']),
      );
      await endpoints.posts.create(
        fixtures.signedIn(elena),
        fixtures.draft(
          'oculto',
          tags: ['fluttersecreto'],
          visibility: PostVisibility.followers,
        ),
      );

      final r = await endpoints.search.query(fixtures.guest, '#flutter');

      expect(bodies(r), ['tres', 'dos', 'uno']);
      expect(r.tags, ['flutterdev', 'flutterweb']);
    });

    test('then % and _ are literal, not wildcards', () async {
      final elena = await fixtures.seedCreator('elena_ux', 'Elena Vega');
      await fixtures.seedAccount('ana_b', 'Ana B');
      await fixtures.seedAccount('anaxb', 'Ana X');
      await endpoints.posts.create(
        fixtures.signedIn(elena),
        fixtures.draft('Descuento del 50% hoy'),
      );
      await endpoints.posts.create(
        fixtures.signedIn(elena),
        fixtures.draft('Cincuenta y punto'),
      );

      final underscore = await endpoints.search.query(fixtures.guest, 'a_b');
      final percent = await endpoints.search.query(fixtures.guest, '0%');
      final both = await endpoints.search.query(fixtures.guest, '%%');

      expect(usernames(underscore), ['ana_b']);
      expect(bodies(percent), ['Descuento del 50% hoy']);
      expect(both.accounts, isEmpty);
      expect(both.posts, isEmpty);
    });

    test('then lives on air come first and cancelled ones never', () async {
      final elena = await fixtures.seedCreator('elena_ux', 'Elena Vega');
      final carlos = await fixtures.seedCreator('carlos_mendez', 'Carlos');
      await endpoints.live.schedule(
        fixtures.signedIn(elena),
        fixtures.showDraft('Diseño programado'),
      );
      final cancelled = await endpoints.live.schedule(
        fixtures.signedIn(elena),
        fixtures.showDraft('Diseño cancelado'),
      );
      await endpoints.live.cancel(fixtures.signedIn(elena), cancelled.id);
      await endpoints.live.goLive(fixtures.signedIn(carlos), 'Diseño al aire');

      final r = await endpoints.search.query(fixtures.guest, 'diseño');

      expect(
        [for (final l in r.lives) l.title],
        [
          'Diseño al aire',
          'Diseño programado',
        ],
      );
    });

    test('then the limit is per section and capped at 20', () async {
      for (var i = 0; i < 25; i++) {
        await fixtures.seedAccount('nexo_$i', 'Nexo $i');
      }

      final two = await endpoints.search.query(
        fixtures.guest,
        'nexo',
        limit: 2,
      );
      final many = await endpoints.search.query(
        fixtures.guest,
        'nexo',
        limit: 100,
      );
      final byDefault = await endpoints.search.query(fixtures.guest, 'nexo');

      expect(two.accounts, hasLength(2));
      expect(many.accounts, hasLength(20));
      expect(byDefault.accounts, hasLength(10));
    });

    test('then accents are optional on either side', () async {
      final jose = await fixtures.seedCreator('jose_p', 'José Pérez');
      await endpoints.posts.create(
        fixtures.signedIn(jose),
        fixtures.draft('Mi nueva Canción', tags: ['música']),
      );
      await endpoints.live.goLive(fixtures.signedIn(jose), 'Diseño en vivo');

      final plain = await endpoints.search.query(fixtures.guest, 'perez');
      final song = await endpoints.search.query(fixtures.guest, 'cancion');
      final tag = await endpoints.search.query(fixtures.guest, '#musica');
      final live = await endpoints.search.query(fixtures.guest, 'diseno');
      final accented = await endpoints.search.query(fixtures.guest, 'jósé');

      expect(usernames(plain), ['jose_p']);
      expect(bodies(song), ['Mi nueva Canción']);
      expect(tag.tags, ['música']);
      expect([for (final l in live.lives) l.title], ['Diseño en vivo']);
      expect(usernames(accented), ['jose_p']);
      // Lo que vuelve es lo que se escribió, no la versión plegada.
      expect(accented.query, 'jósé');
    });
  });
}
