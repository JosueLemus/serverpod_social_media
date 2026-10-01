import 'package:nexo_server/src/generated/protocol.dart';
import 'package:nexo_server/src/shared/auth/auth_context.dart';
import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';

import '../support/fixtures.dart';
import '../test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Given Moderation endpoint', (sessionBuilder, endpoints) {
    final fixtures = Fixtures(sessionBuilder);
    late UuidValue elenaId;
    late UuidValue moderatorId;
    late TestSessionBuilder elena;
    late TestSessionBuilder tomas;
    late TestSessionBuilder ana;
    late TestSessionBuilder moderator;
    late int postId;

    setUp(() async {
      elenaId = await fixtures.seedUser('elena_ux', 'Elena Vega');
      elena = fixtures.signedIn(elenaId);
      tomas = fixtures.signedIn(await fixtures.seedUser('tomas', 'Tomás'));
      ana = fixtures.signedIn(await fixtures.seedUser('ana', 'Ana'));
      moderatorId = await fixtures.seedUser('mod_lucia', 'Lucía');
      moderator = fixtures.signedIn(moderatorId, {NexoScopes.moderator});
      postId = (await endpoints.posts.create(
        elena,
        fixtures.draft('contenido dudoso'),
      )).id;
    });

    Future<void> reportPost(
      TestSessionBuilder as,
      ModerationReason reason, {
      int? id,
    }) => endpoints.moderation.report(
      as,
      targetType: ReportTargetType.post,
      targetId: id ?? postId,
      reason: reason,
    );

    group('when users report a post', () {
      test('then the queue shows it once, with the highest severity', () async {
        await reportPost(tomas, ModerationReason.spam);
        await reportPost(ana, ModerationReason.harassment);

        final queue = await endpoints.moderation.queue(moderator);

        expect(queue, hasLength(1));
        expect(queue.single.targetId, postId);
        expect(queue.single.severity, ReportSeverity.high);
        expect(queue.single.reason, ModerationReason.harassment);
        expect(queue.single.reportCount, 2);
        expect(queue.single.excerpt, 'contenido dudoso');
        expect(queue.single.targetAuthorUsername, 'elena_ux');
      });

      test('then reporting the same post twice keeps one report', () async {
        await reportPost(tomas, ModerationReason.spam);
        await reportPost(tomas, ModerationReason.spam);

        final queue = await endpoints.moderation.queue(moderator);

        expect(queue.single.reportCount, 1);
      });

      test('then the author cannot report their own post', () async {
        await expectLater(
          reportPost(elena, ModerationReason.spam),
          throwsNexo(NexoErrorCode.invalidInput),
        );
      });

      test('then a guest is rejected as unauthenticated', () async {
        await expectLater(
          reportPost(fixtures.guest, ModerationReason.spam),
          throwsNexo(NexoErrorCode.unauthenticated),
        );
      });
    });

    group('when ordering the queue', () {
      test('then more severe content comes first', () async {
        final other = await endpoints.posts.create(
          elena,
          fixtures.draft('otro'),
        );
        await reportPost(tomas, ModerationReason.other);
        await reportPost(tomas, ModerationReason.violence, id: other.id);

        final queue = await endpoints.moderation.queue(moderator);

        expect(queue.map((i) => i.targetId), [other.id, postId]);
      });
    });

    group('when a non-moderator uses the queue', () {
      test('then it is forbidden', () async {
        await expectLater(
          endpoints.moderation.queue(tomas),
          throwsNexo(NexoErrorCode.forbidden),
        );
      });
    });

    group('when a moderator hides a reported post', () {
      test('then it leaves the feed, all its reports close and it is audited '
          'once', () async {
        await reportPost(tomas, ModerationReason.spam);
        await reportPost(ana, ModerationReason.spam);
        final item = (await endpoints.moderation.queue(moderator)).single;

        await endpoints.moderation.resolve(
          moderator,
          item.reportId,
          ReportDecision.hideContent,
        );

        expect((await endpoints.posts.feed(fixtures.guest)).items, isEmpty);
        expect(await endpoints.moderation.queue(moderator), isEmpty);

        final audit = await AuditLog.db.find(
          fixtures.session,
          where: (t) => t.action.like('moderation.%'),
        );
        expect(audit.single.action, 'moderation.hideContent');
        expect(audit.single.actorId, moderatorId);
        expect(audit.single.entityId, '$postId');
      });

      test('then resolving the same report again is a conflict', () async {
        await reportPost(tomas, ModerationReason.spam);
        final item = (await endpoints.moderation.queue(moderator)).single;
        await endpoints.moderation.resolve(
          moderator,
          item.reportId,
          ReportDecision.dismiss,
        );

        await expectLater(
          endpoints.moderation.resolve(
            moderator,
            item.reportId,
            ReportDecision.dismiss,
          ),
          throwsNexo(NexoErrorCode.conflict),
        );
      });
    });

    group('when a moderator dismisses a report', () {
      test('then the post stays and the queue empties', () async {
        await reportPost(tomas, ModerationReason.other);
        final item = (await endpoints.moderation.queue(moderator)).single;

        await endpoints.moderation.resolve(
          moderator,
          item.reportId,
          ReportDecision.dismiss,
        );

        expect(
          (await endpoints.posts.feed(fixtures.guest)).items,
          hasLength(1),
        );
        expect(await endpoints.moderation.queue(moderator), isEmpty);
      });
    });

    group('when a comment is reported and hidden', () {
      test('then it disappears and the post count goes down', () async {
        final comment = await endpoints.comments.create(
          tomas,
          postId,
          'insulto',
        );
        await endpoints.moderation.report(
          ana,
          targetType: ReportTargetType.postComment,
          targetId: comment.id,
          reason: ModerationReason.harassment,
        );
        final item = (await endpoints.moderation.queue(moderator)).single;

        expect(item.postId, postId);
        expect(item.excerpt, 'insulto');

        await endpoints.moderation.resolve(
          moderator,
          item.reportId,
          ReportDecision.hideContent,
        );

        expect((await endpoints.comments.list(ana, postId)).items, isEmpty);
        expect((await endpoints.posts.get(ana, postId)).commentCount, 0);
      });
    });

    group('when the author deleted the post before review', () {
      test('then the queue flags it as removed', () async {
        await reportPost(tomas, ModerationReason.spam);
        await endpoints.posts.delete(elena, postId);

        final item = (await endpoints.moderation.queue(moderator)).single;

        expect(item.targetRemoved, isTrue);
      });
    });
  });
}
