import 'package:nexo_server/src/generated/protocol.dart';
import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';

import '../support/fixtures.dart';
import '../test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Given Likes endpoint', (sessionBuilder, endpoints) {
    final fixtures = Fixtures(sessionBuilder);
    late UuidValue tomasId;
    late TestSessionBuilder elena;
    late TestSessionBuilder tomas;
    late TestSessionBuilder ana;
    late int postId;

    setUp(() async {
      elena = fixtures.signedIn(
        await fixtures.seedUser('elena_ux', 'Elena Vega'),
      );
      tomasId = await fixtures.seedUser('tomas', 'Tomás');
      tomas = fixtures.signedIn(tomasId);
      ana = fixtures.signedIn(await fixtures.seedUser('ana', 'Ana'));
      postId = (await endpoints.posts.create(elena, fixtures.draft('hola'))).id;
    });

    group('when a user likes a post', () {
      test('then the count goes up and the post shows it as liked', () async {
        final state = await endpoints.likes.like(tomas, postId);
        final post = await endpoints.posts.get(tomas, postId);

        expect(state.isLiked, isTrue);
        expect(state.likeCount, 1);
        expect(post.likeCount, 1);
        expect(post.isLiked, isTrue);
      });

      test('then liking twice still counts one', () async {
        await endpoints.likes.like(tomas, postId);
        final state = await endpoints.likes.like(tomas, postId);

        expect(state.likeCount, 1);
      });

      test('then other viewers do not see it as their own like', () async {
        await endpoints.likes.like(tomas, postId);
        final post = await endpoints.posts.get(ana, postId);

        expect(post.likeCount, 1);
        expect(post.isLiked, isFalse);
      });
    });

    group('when a user unlikes', () {
      test('then the count goes back down', () async {
        await endpoints.likes.like(tomas, postId);
        final state = await endpoints.likes.unlike(tomas, postId);

        expect(state.isLiked, isFalse);
        expect(state.likeCount, 0);
      });

      test('then unliking without a like changes nothing', () async {
        await endpoints.likes.like(ana, postId);
        final state = await endpoints.likes.unlike(tomas, postId);

        expect(state.likeCount, 1);
      });
    });

    group('when a guest likes', () {
      test('then it is rejected as unauthenticated', () async {
        await expectLater(
          endpoints.likes.like(fixtures.guest, postId),
          throwsNexo(NexoErrorCode.unauthenticated),
        );
      });
    });

    group('when liking a post the user cannot see', () {
      test('then it is not found', () async {
        final private = await endpoints.posts.create(
          elena,
          fixtures.draft('privado', visibility: PostVisibility.followers),
        );

        await expectLater(
          endpoints.likes.like(tomas, private.id),
          throwsNexo(NexoErrorCode.notFound),
        );
      });
    });

    group('when listing who liked', () {
      test('then shows the newest first with names, paginated', () async {
        await endpoints.likes.like(tomas, postId);
        await endpoints.likes.like(ana, postId);

        final first = await endpoints.likes.likers(
          fixtures.guest,
          postId,
          limit: 1,
        );
        final second = await endpoints.likes.likers(
          fixtures.guest,
          postId,
          after: first.nextCursor,
          limit: 1,
        );

        expect(first.items.single.username, 'ana');
        expect(second.items.single.userId, tomasId);
        expect(second.items.single.name, 'Tomás');
        expect(second.nextCursor, isNull);
      });
    });
  });
}
