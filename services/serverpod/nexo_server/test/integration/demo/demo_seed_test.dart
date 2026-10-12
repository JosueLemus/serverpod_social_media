import 'package:nexo_server/src/generated/protocol.dart';
import 'package:nexo_server/src/shared/demo/demo_seed.dart';
import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_idp_server/core.dart';
import 'package:test/test.dart';

import '../support/fixtures.dart';
import '../test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Given the demo seed', (sessionBuilder, endpoints) {
    final fixtures = Fixtures(sessionBuilder);
    late List<String> credentials;
    late DemoSeed seed;

    setUp(() {
      credentials = [];
      seed = DemoSeed((session, id, email, password) async {
        credentials.add('$email:$password');
      });
    });

    Future<UuidValue> idOf(String username) async =>
        (await AccountProfile.db.findFirstRow(
          fixtures.session,
          where: (t) => t.username.equals(username),
        ))!.authUserId;

    test('then every demo account exists with its password', () async {
      final created = await seed.run(fixtures.session);

      expect(created, DemoSeed.accounts.length);
      expect(credentials, contains('operador@nexo.demo:${DemoSeed.password}'));
    });

    test(
      'then roles come as server scopes and creators are verified',
      () async {
        await seed.run(fixtures.session);

        final ops = await AuthUser.db.findById(
          fixtures.session,
          await idOf('nexo_ops'),
        );
        expect(ops!.scopeNames, {'admin'});

        final elena = await endpoints.profiles.me(
          fixtures.signedIn(await idOf('elena_ux')),
        );
        expect(elena.profile.isCreator, isTrue);
        expect(elena.profile.verification, VerificationStatus.verified);
        expect(elena.profile.displayName, 'Elena Vega');
      },
    );

    test('then running it again duplicates nothing', () async {
      await seed.run(fixtures.session);
      credentials.clear();

      final created = await seed.run(fixtures.session);

      expect(created, 0);
      expect(credentials, isEmpty);
      expect(
        await AccountProfile.db.count(fixtures.session),
        DemoSeed.accounts.length,
      );
      expect(await Post.db.count(fixtures.session), 3);
    });

    test('then the feed has content and a comment to report', () async {
      await seed.run(fixtures.session);

      final feed = await endpoints.posts.feed(fixtures.guest);
      expect(feed.items, hasLength(3));
      expect(feed.items.map((p) => p.authorUsername), contains('elena_ux'));

      final withComment = feed.items.firstWhere((p) => p.commentCount == 1);
      final comments = await endpoints.comments.list(
        fixtures.guest,
        withComment.id,
      );
      expect(comments.items.single.body, contains('ándate de aquí'));
    });
  });
}
