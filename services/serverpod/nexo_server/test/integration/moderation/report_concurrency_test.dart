import 'package:nexo_server/src/generated/protocol.dart';
import 'package:test/test.dart';

import '../support/fixtures.dart';
import '../test_tools/serverpod_test_tools.dart';

/// Dos toques seguidos en "Reportar" no pueden dejar dos reportes iguales.
///
/// En su propio archivo porque necesita llamadas concurrentes, y la herramienta
/// de tests no las admite mientras revierte la base después de cada test. Cada
/// grupo de `withServerpod` tiene su propia base, así que no revertir acá no
/// contamina a los otros archivos.
void main() {
  withServerpod(
    'Given simultaneous reports',
    rollbackDatabase: RollbackDatabase.disabled,
    (sessionBuilder, endpoints) {
      final fixtures = Fixtures(sessionBuilder);

      test('then the same person reporting the same post three times at '
          'once leaves one open report and one audit entry', () async {
        final elena = fixtures.signedIn(
          await fixtures.seedUser('elena_ux', 'Elena Vega'),
        );
        final tomas = fixtures.signedIn(
          await fixtures.seedUser('tomas', 'Tomás'),
        );
        final postId = (await endpoints.posts.create(
          elena,
          fixtures.draft('contenido dudoso'),
        )).id;

        Future<void> report() => endpoints.moderation.report(
          tomas,
          targetType: ReportTargetType.post,
          targetId: postId,
          reason: ModerationReason.spam,
        );
        await Future.wait([report(), report(), report()]);

        expect(
          await ContentReport.db.count(
            fixtures.session,
            where: (t) => t.targetId.equals(postId) & t.resolvedAt.equals(null),
          ),
          1,
        );
        expect(
          await AuditLog.db.count(
            fixtures.session,
            where: (t) =>
                t.action.equals('moderation.report') &
                t.entityId.equals('$postId'),
          ),
          1,
        );
      });
    },
  );
}
