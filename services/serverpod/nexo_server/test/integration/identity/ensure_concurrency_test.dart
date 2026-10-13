import 'package:nexo_server/src/generated/protocol.dart';
import 'package:test/test.dart';

import '../support/fixtures.dart';
import '../test_tools/serverpod_test_tools.dart';

/// La app pide `profiles.me` dos veces al entrar con una cuenta recién
/// creada. Las dos tienen que ver el mismo perfil, y tiene que haber uno solo.
///
/// En su propio archivo porque necesita llamadas concurrentes, y la
/// herramienta de tests no las admite mientras revierte la base después de
/// cada test.
void main() {
  withServerpod(
    'Given a new account asking for its profile several times at once',
    rollbackDatabase: RollbackDatabase.disabled,
    (sessionBuilder, endpoints) {
      final fixtures = Fixtures(sessionBuilder);

      test(
        'then every call gets the same profile and only one is created',
        () async {
          final id = await fixtures.seedUser('ana.nueva', 'Ana Nueva');
          final ana = fixtures.signedIn(id);

          final views = await Future.wait([
            for (var i = 0; i < 4; i++) endpoints.profiles.me(ana),
          ]);

          expect(
            views.map((view) => view.profile.username).toSet(),
            hasLength(1),
          );
          expect(
            await AccountProfile.db.count(
              fixtures.session,
              where: (t) => t.authUserId.equals(id),
            ),
            1,
          );
        },
      );
    },
  );
}
