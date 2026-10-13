import 'package:nexo_server/src/generated/protocol.dart';
import 'package:test/test.dart';

import '../support/fixtures.dart';
import '../test_tools/serverpod_test_tools.dart';

/// Dos toques simultáneos en "Enviar mensaje" no crean dos conversaciones
/// (SDD 0010, M3). En su propio archivo: las llamadas concurrentes no se
/// admiten mientras la herramienta revierte la base.
void main() {
  withServerpod(
    'Given simultaneous opens',
    rollbackDatabase: RollbackDatabase.disabled,
    (sessionBuilder, endpoints) {
      final fixtures = Fixtures(sessionBuilder);
      final suffix = DateTime.now().microsecondsSinceEpoch;

      test('then both sides opening at once share one conversation', () async {
        final a = await fixtures.seedAccount('dm_a_$suffix', 'A');
        final b = await fixtures.seedAccount('dm_b_$suffix', 'B');

        final opened = await Future.wait([
          endpoints.messages.open(fixtures.signedIn(a), b),
          endpoints.messages.open(fixtures.signedIn(b), a),
          endpoints.messages.open(fixtures.signedIn(a), b),
        ]);

        expect({for (final c in opened) c.id}, hasLength(1));
        expect(
          await DmConversation.db.count(
            fixtures.session,
            where: (t) =>
                (t.userA.equals(a) & t.userB.equals(b)) |
                (t.userA.equals(b) & t.userB.equals(a)),
          ),
          1,
        );
      });
    },
  );
}
