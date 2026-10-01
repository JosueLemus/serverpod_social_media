import 'dart:typed_data';

import 'package:nexo_server/src/generated/protocol.dart';
import 'package:nexo_server/src/shared/auth/auth_context.dart';
import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';

import '../support/fixtures.dart';
import '../test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Given Posts endpoint', (sessionBuilder, endpoints) {
    final fixtures = Fixtures(sessionBuilder);
    final session = fixtures.session;
    final guest = fixtures.guest;
    final draft = fixtures.draft;
    late UuidValue elenaId;
    late UuidValue tomasId;
    late TestSessionBuilder elena;
    late TestSessionBuilder tomas;
    late TestSessionBuilder moderator;

    /// Pide el permiso de subida y deja el archivo en el storage, como haría
    /// `FileUploader` desde la app.
    Future<String> upload(
      TestSessionBuilder as, {
      PostMediaKind kind = PostMediaKind.image,
      String contentType = 'image/jpeg',
    }) async {
      final ticket = await endpoints.posts.requestMediaUpload(
        as,
        kind: kind,
        contentType: contentType,
        sizeBytes: 8,
      );
      await session.storage.storeFile(
        storageId: 'public',
        path: ticket.key,
        byteData: ByteData(8),
      );
      return ticket.key;
    }

    setUp(() async {
      elenaId = await fixtures.seedUser('elena_ux', 'Elena Vega');
      tomasId = await fixtures.seedUser('tomas', 'Tomás');
      elena = fixtures.signedIn(elenaId);
      tomas = fixtures.signedIn(tomasId);
      moderator = fixtures.signedIn(
        await fixtures.seedUser('mod_lucia', 'Lucía'),
        {NexoScopes.moderator},
      );
    });

    group('when a guest publishes', () {
      test('then it is rejected as unauthenticated', () async {
        await expectLater(
          endpoints.posts.create(guest, draft('hola')),
          throwsNexo(NexoErrorCode.unauthenticated),
        );
      });
    });

    group('when a user publishes text', () {
      test('then the post comes back with its author and actions', () async {
        final post = await endpoints.posts.create(
          elena,
          draft('  Primer post  ', tags: ['#Nuevo', 'nuevo']),
        );

        expect(post.body, 'Primer post');
        expect(post.tags, ['Nuevo']);
        expect(post.authorId, elenaId);
        expect(post.authorUsername, 'elena_ux');
        expect(post.authorName, 'Elena Vega');
        expect(post.canEdit, isTrue);
        expect(post.canDelete, isTrue);
      });

      test('then another user sees it but cannot edit or delete it', () async {
        final created = await endpoints.posts.create(elena, draft('hola'));
        final seen = await endpoints.posts.get(tomas, created.id);

        expect(seen.canEdit, isFalse);
        expect(seen.canDelete, isFalse);
      });

      test('then an empty post is rejected', () async {
        await expectLater(
          endpoints.posts.create(elena, draft('   ')),
          throwsNexo(NexoErrorCode.invalidInput),
        );
      });
    });

    group('when a user publishes with media', () {
      test('then photos and videos come back in order with a URL', () async {
        final photo = await upload(elena);
        final video = await upload(
          elena,
          kind: PostMediaKind.video,
          contentType: 'video/mp4',
        );

        final post = await endpoints.posts.create(
          elena,
          draft('', mediaKeys: [photo, video]),
        );

        expect(post.media.map((m) => m.kind), [
          PostMediaKind.image,
          PostMediaKind.video,
        ]);
        expect(post.media.last.contentType, 'video/mp4');
        expect(post.media.every((m) => m.url.hasScheme), isTrue);
      });

      test('then a file that was never uploaded is rejected', () async {
        final ticket = await endpoints.posts.requestMediaUpload(
          elena,
          kind: PostMediaKind.image,
          contentType: 'image/png',
          sizeBytes: 8,
        );

        await expectLater(
          endpoints.posts.create(elena, draft('', mediaKeys: [ticket.key])),
          throwsNexo(NexoErrorCode.invalidInput),
        );
      });

      test('then someone else\'s file is forbidden', () async {
        final key = await upload(tomas);

        await expectLater(
          endpoints.posts.create(elena, draft('robado', mediaKeys: [key])),
          throwsNexo(NexoErrorCode.forbidden),
        );
      });

      test('then a file already used in another post is a conflict', () async {
        final key = await upload(elena);
        await endpoints.posts.create(elena, draft('uno', mediaKeys: [key]));

        await expectLater(
          endpoints.posts.create(elena, draft('dos', mediaKeys: [key])),
          throwsNexo(NexoErrorCode.conflict),
        );
      });
    });

    group('when requesting an upload', () {
      test('then a type that does not match the kind is rejected', () async {
        await expectLater(
          endpoints.posts.requestMediaUpload(
            elena,
            kind: PostMediaKind.image,
            contentType: 'video/mp4',
            sizeBytes: 8,
          ),
          throwsNexo(NexoErrorCode.invalidInput),
        );
      });

      test('then a file over the limit is rejected', () async {
        await expectLater(
          endpoints.posts.requestMediaUpload(
            elena,
            kind: PostMediaKind.image,
            contentType: 'image/png',
            sizeBytes: 11 * 1024 * 1024,
          ),
          throwsNexo(NexoErrorCode.invalidInput),
        );
      });
    });

    group('when reading the feed', () {
      test('then pages go newest first without repeating posts', () async {
        for (var i = 1; i <= 5; i++) {
          await endpoints.posts.create(elena, draft('post $i'));
        }

        final first = await endpoints.posts.feed(guest, limit: 2);
        final second = await endpoints.posts.feed(
          guest,
          after: first.nextCursor,
          limit: 2,
        );
        final last = await endpoints.posts.feed(
          guest,
          after: second.nextCursor,
          limit: 2,
        );

        expect(
          [...first.items, ...second.items, ...last.items].map((p) => p.body),
          ['post 5', 'post 4', 'post 3', 'post 2', 'post 1'],
        );
        expect(last.nextCursor, isNull);
      });

      test(
        'then followers-only posts are visible only to their author',
        () async {
          await endpoints.posts.create(elena, draft('para todos'));
          await endpoints.posts.create(
            elena,
            draft('solo seguidores', visibility: PostVisibility.followers),
          );

          final asGuest = await endpoints.posts.feed(guest);
          final asTomas = await endpoints.posts.feed(tomas);
          final asElena = await endpoints.posts.byAuthor(elena, elenaId);

          expect(asGuest.items.map((p) => p.body), ['para todos']);
          expect(asTomas.items.map((p) => p.body), ['para todos']);
          expect(asElena.items, hasLength(2));
        },
      );
    });

    group('when editing a post', () {
      test('then the author changes text and it is marked as edited', () async {
        final created = await endpoints.posts.create(elena, draft('antes'));

        final edited = await endpoints.posts.update(
          elena,
          created.id,
          PostEdit(body: 'después', allowComments: false),
        );

        expect(edited.body, 'después');
        expect(edited.allowComments, isFalse);
        expect(edited.editedAt, isNotNull);
      });

      test('then another user is forbidden', () async {
        final created = await endpoints.posts.create(elena, draft('mío'));

        await expectLater(
          endpoints.posts.update(tomas, created.id, PostEdit(body: 'tuyo')),
          throwsNexo(NexoErrorCode.forbidden),
        );
      });

      test('then a private post of someone else is not found', () async {
        final created = await endpoints.posts.create(
          elena,
          draft('privado', visibility: PostVisibility.members),
        );

        await expectLater(
          endpoints.posts.update(tomas, created.id, PostEdit(body: 'x')),
          throwsNexo(NexoErrorCode.notFound),
        );
      });
    });

    group('when deleting a post', () {
      test('then it leaves the feed and the action is audited', () async {
        final created = await endpoints.posts.create(elena, draft('adiós'));

        await endpoints.posts.delete(elena, created.id);

        expect((await endpoints.posts.feed(guest)).items, isEmpty);
        await expectLater(
          endpoints.posts.get(elena, created.id),
          throwsNexo(NexoErrorCode.notFound),
        );
        final audit = await AuditLog.db.find(
          session,
          where: (t) => t.entityType.equals('post'),
        );
        expect(audit.single.action, 'post.delete');
        expect(audit.single.actorId, elenaId);
      });

      test('then another user is forbidden', () async {
        final created = await endpoints.posts.create(elena, draft('mío'));

        await expectLater(
          endpoints.posts.delete(tomas, created.id),
          throwsNexo(NexoErrorCode.forbidden),
        );
      });

      test('then a moderator can delete someone else\'s post', () async {
        final created = await endpoints.posts.create(elena, draft('spam'));

        await endpoints.posts.delete(moderator, created.id);

        expect((await endpoints.posts.feed(guest)).items, isEmpty);
      });
    });
  });
}
