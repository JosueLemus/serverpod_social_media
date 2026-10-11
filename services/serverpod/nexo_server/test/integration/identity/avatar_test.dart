import 'dart:typed_data';

import 'package:nexo_server/src/generated/protocol.dart';
import 'package:test/test.dart';

import '../support/fixtures.dart';
import '../test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Given an avatar', (sessionBuilder, endpoints) {
    final fixtures = Fixtures(sessionBuilder);

    Future<String> upload(
      TestSessionBuilder as, {
      String contentType = 'image/png',
    }) async {
      final ticket = await endpoints.profiles.requestAvatarUpload(
        as,
        contentType: contentType,
        sizeBytes: 8,
      );
      await fixtures.session.storage.storeFile(
        storageId: 'public',
        path: ticket.key,
        byteData: ByteData(8),
      );
      return ticket.key;
    }

    test('then an accepted image gets a ticket under avatars/<id>', () async {
      final elena = await fixtures.seedCreator('elena_ux', 'Elena Vega');
      final ticket = await endpoints.profiles.requestAvatarUpload(
        fixtures.signedIn(elena),
        contentType: 'image/jpeg',
        sizeBytes: 1024,
      );
      expect(ticket.key, startsWith('avatars/$elena/'));
      expect(ticket.key, endsWith('.jpg'));
    });

    test('then a video or an oversized file is invalidInput', () async {
      final elena = fixtures.signedIn(
        await fixtures.seedCreator('elena_ux', 'Elena Vega'),
      );
      await expectLater(
        endpoints.profiles.requestAvatarUpload(
          elena,
          contentType: 'video/mp4',
          sizeBytes: 1024,
        ),
        throwsNexo(NexoErrorCode.invalidInput),
      );
      await expectLater(
        endpoints.profiles.requestAvatarUpload(
          elena,
          contentType: 'image/png',
          sizeBytes: 6 * 1024 * 1024,
        ),
        throwsNexo(NexoErrorCode.invalidInput),
      );
    });

    test('then setting it shows up in the profile, posts, comments and '
        'shows, and null removes it', () async {
      final elenaId = await fixtures.seedCreator('elena_ux', 'Elena Vega');
      final elena = fixtures.signedIn(elenaId);
      final key = await upload(elena);

      final me = await endpoints.profiles.setAvatar(elena, key);
      expect(me.profile.avatarUrl, isNotNull);
      expect(
        (await endpoints.profiles.byUsername(
          fixtures.guest,
          'elena_ux',
        )).avatarUrl,
        me.profile.avatarUrl,
      );

      final post = await endpoints.posts.create(elena, fixtures.draft('hola'));
      expect(post.authorAvatarUrl, me.profile.avatarUrl);
      final comment = await endpoints.comments.create(elena, post.id, 'yo');
      expect(comment.authorAvatarUrl, me.profile.avatarUrl);
      final show = await endpoints.live.goLive(elena, 'Al aire');
      expect(show.hostAvatarUrl, me.profile.avatarUrl);

      final removed = await endpoints.profiles.setAvatar(elena, null);
      expect(removed.profile.avatarUrl, isNull);
    });

    test('then someone else\'s key is forbidden', () async {
      final elena = fixtures.signedIn(
        await fixtures.seedCreator('elena_ux', 'Elena Vega'),
      );
      final tomas = fixtures.signedIn(
        await fixtures.seedAccount('tomas', 'Tomás Ríos'),
      );
      final key = await upload(elena);
      await expectLater(
        endpoints.profiles.setAvatar(tomas, key),
        throwsNexo(NexoErrorCode.forbidden),
      );
    });

    test('then a malformed or not uploaded key is invalidInput', () async {
      final elenaId = await fixtures.seedCreator('elena_ux', 'Elena Vega');
      final elena = fixtures.signedIn(elenaId);
      await expectLater(
        endpoints.profiles.setAvatar(elena, 'posts/x/y.png'),
        throwsNexo(NexoErrorCode.invalidInput),
      );
      final ticket = await endpoints.profiles.requestAvatarUpload(
        elena,
        contentType: 'image/png',
        sizeBytes: 8,
      );
      await expectLater(
        endpoints.profiles.setAvatar(elena, ticket.key),
        throwsNexo(NexoErrorCode.invalidInput),
      );
    });

    test('then a guest cannot ask for an upload', () async {
      await expectLater(
        endpoints.profiles.requestAvatarUpload(
          fixtures.guest,
          contentType: 'image/png',
          sizeBytes: 8,
        ),
        throwsNexo(NexoErrorCode.unauthenticated),
      );
    });
  });
}
