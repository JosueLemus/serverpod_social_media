import 'package:nexo_server/src/generated/protocol.dart';
import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';

import '../support/fixtures.dart';
import '../test_tools/serverpod_test_tools.dart';

/// Lo que la cola de moderación necesita para no mentir: un reporte por
/// persona y contenido, y cada reporte en la auditoría.
void main() {
  withServerpod('Given a reported post', (sessionBuilder, endpoints) {
    final fixtures = Fixtures(sessionBuilder);
    late UuidValue tomasId;
    late TestSessionBuilder tomas;
    late int postId;

    setUp(() async {
      final elena = fixtures.signedIn(
        await fixtures.seedUser('elena_ux', 'Elena Vega'),
      );
      tomasId = await fixtures.seedUser('tomas', 'Tomás');
      tomas = fixtures.signedIn(tomasId);
      postId = (await endpoints.posts.create(
        elena,
        fixtures.draft('contenido dudoso'),
      )).id;
    });

    Future<void> report() => endpoints.moderation.report(
      tomas,
      targetType: ReportTargetType.post,
      targetId: postId,
      reason: ModerationReason.spam,
    );

    test('then the report is in the audit log, with who and why', () async {
      await report();

      final audit = await AuditLog.db.find(
        fixtures.session,
        where: (t) => t.action.equals('moderation.report'),
      );
      expect(audit, hasLength(1));
      expect(audit.single.actorId, tomasId);
      expect(audit.single.entityId, '$postId');
      expect(audit.single.metadataJson, contains('spam'));
    });

    test('then a repeated report is not audited twice', () async {
      await report();
      await report();

      expect(
        await AuditLog.db.count(
          fixtures.session,
          where: (t) => t.action.equals('moderation.report'),
        ),
        1,
      );
    });
  });
}
