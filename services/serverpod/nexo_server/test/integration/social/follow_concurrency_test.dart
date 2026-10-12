import 'package:nexo_server/src/generated/protocol.dart';
import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';

import '../support/fixtures.dart';
import '../test_tools/serverpod_test_tools.dart';

/// Dos cuentas que se siguen al mismo tiempo no se bloquean entre sí, y un
/// doble toque no suma dos.
///
/// En su propio archivo porque necesita llamadas concurrentes, que la
/// herramienta de tests no admite mientras revierte la base.
void main() {
  withServerpod(
    'Given simultaneous follows',
    rollbackDatabase: RollbackDatabase.disabled,
    (sessionBuilder, endpoints) {
      final fixtures = Fixtures(sessionBuilder);
      final suffix = DateTime.now().microsecondsSinceEpoch;

      Future<AccountProfile> account(UuidValue id) async =>
          (await AccountProfile.db.findFirstRow(
            fixtures.session,
            where: (t) => t.authUserId.equals(id),
          ))!;

      test('then A following B while B follows A finishes with both '
          'counters at one', () async {
        final a = await fixtures.seedAccount('a_$suffix', 'A');
        final b = await fixtures.seedAccount('b_$suffix', 'B');

        await Future.wait([
          endpoints.follows.follow(fixtures.signedIn(a), b),
          endpoints.follows.follow(fixtures.signedIn(b), a),
        ]);

        for (final id in [a, b]) {
          final profile = await account(id);
          expect(profile.followerCount, 1);
          expect(profile.followingCount, 1);
        }
      });

      test('then three taps on follow at once leave one follower', () async {
        final elena = await fixtures.seedCreator('e_$suffix', 'Elena');
        final tomas = await fixtures.seedAccount('t_$suffix', 'Tomás');

        Future<void> follow() =>
            endpoints.follows.follow(fixtures.signedIn(tomas), elena);
        await Future.wait([follow(), follow(), follow()]);

        expect((await account(elena)).followerCount, 1);
        expect(
          await Follow.db.count(
            fixtures.session,
            where: (t) => t.followeeId.equals(elena),
          ),
          1,
        );
      });
    },
  );
}
