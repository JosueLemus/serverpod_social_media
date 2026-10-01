import 'package:nexo_server/src/generated/protocol.dart';
import 'package:nexo_server/src/shared/auth/auth_context.dart';
import 'package:test/test.dart';

import '../support/fixtures.dart';
import '../test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Given Comments endpoint', (sessionBuilder, endpoints) {
    final fixtures = Fixtures(sessionBuilder);
    late TestSessionBuilder elena;
    late TestSessionBuilder tomas;
    late TestSessionBuilder ana;
    late TestSessionBuilder moderator;
    late int postId;

    setUp(() async {
      elena = fixtures.signedIn(
        await fixtures.seedUser('elena_ux', 'Elena Vega'),
      );
      tomas = fixtures.signedIn(await fixtures.seedUser('tomas', 'Tomás'));
      ana = fixtures.signedIn(await fixtures.seedUser('ana', 'Ana'));
      moderator = fixtures.signedIn(
        await fixtures.seedUser('mod_lucia', 'Lucía'),
        {NexoScopes.moderator},
      );
      postId = (await endpoints.posts.create(elena, fixtures.draft('hola'))).id;
    });

    group('when a user comments', () {
      test('then the comment comes back and the post counts it', () async {
        final comment = await endpoints.comments.create(
          tomas,
          postId,
          '  ¡Qué bueno!  ',
        );
        final post = await endpoints.posts.get(tomas, postId);

        expect(comment.body, '¡Qué bueno!');
        expect(comment.authorUsername, 'tomas');
        expect(comment.canDelete, isTrue);
        expect(post.commentCount, 1);
      });

      test('then an empty comment is rejected', () async {
        await expectLater(
          endpoints.comments.create(tomas, postId, '   '),
          throwsNexo(NexoErrorCode.invalidInput),
        );
      });

      test('then a post with comments off rejects it', () async {
        final closed = await endpoints.posts.create(
          elena,
          fixtures.draft('sin comentarios', allowComments: false),
        );

        await expectLater(
          endpoints.comments.create(tomas, closed.id, 'hola'),
          throwsNexo(NexoErrorCode.forbidden),
        );
      });

      test('then a guest is rejected as unauthenticated', () async {
        await expectLater(
          endpoints.comments.create(fixtures.guest, postId, 'hola'),
          throwsNexo(NexoErrorCode.unauthenticated),
        );
      });
    });

    group('when listing comments', () {
      test('then they come oldest first, paginated', () async {
        await endpoints.comments.create(tomas, postId, 'primero');
        await endpoints.comments.create(ana, postId, 'segundo');
        await endpoints.comments.create(tomas, postId, 'tercero');

        final first = await endpoints.comments.list(
          fixtures.guest,
          postId,
          limit: 2,
        );
        final second = await endpoints.comments.list(
          fixtures.guest,
          postId,
          after: first.nextCursor,
          limit: 2,
        );

        expect(
          [...first.items, ...second.items].map((c) => c.body),
          ['primero', 'segundo', 'tercero'],
        );
        expect(second.nextCursor, isNull);
      });

      test('then the post author can delete any comment', () async {
        await endpoints.comments.create(tomas, postId, 'de tomás');

        final asAuthor = await endpoints.comments.list(elena, postId);
        final asOther = await endpoints.comments.list(ana, postId);

        expect(asAuthor.items.single.canDelete, isTrue);
        expect(asOther.items.single.canDelete, isFalse);
      });
    });

    group('when deleting a comment', () {
      test('then its author removes it and the count goes down', () async {
        final comment = await endpoints.comments.create(tomas, postId, 'ups');

        await endpoints.comments.delete(tomas, comment.id);

        expect((await endpoints.comments.list(tomas, postId)).items, isEmpty);
        expect((await endpoints.posts.get(tomas, postId)).commentCount, 0);
      });

      test('then the post author can remove someone else\'s comment', () async {
        final comment = await endpoints.comments.create(tomas, postId, 'spam');

        await endpoints.comments.delete(elena, comment.id);

        expect((await endpoints.comments.list(elena, postId)).items, isEmpty);
      });

      test('then a moderator can remove it', () async {
        final comment = await endpoints.comments.create(tomas, postId, 'spam');

        await endpoints.comments.delete(moderator, comment.id);

        expect((await endpoints.comments.list(elena, postId)).items, isEmpty);
      });

      test('then another user is forbidden', () async {
        final comment = await endpoints.comments.create(tomas, postId, 'mío');

        await expectLater(
          endpoints.comments.delete(ana, comment.id),
          throwsNexo(NexoErrorCode.forbidden),
        );
      });

      test('then deleting it twice is not found', () async {
        final comment = await endpoints.comments.create(tomas, postId, 'x');
        await endpoints.comments.delete(tomas, comment.id);

        await expectLater(
          endpoints.comments.delete(tomas, comment.id),
          throwsNexo(NexoErrorCode.notFound),
        );
        expect((await endpoints.posts.get(tomas, postId)).commentCount, 0);
      });
    });
  });
}
