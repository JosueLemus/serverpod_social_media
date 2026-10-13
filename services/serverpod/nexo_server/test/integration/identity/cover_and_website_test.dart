import 'dart:typed_data';

import 'package:nexo_server/src/generated/protocol.dart';
import 'package:test/test.dart';

import '../support/fixtures.dart';
import '../test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Given a profile banner, link and post count', (
    sessionBuilder,
    endpoints,
  ) {
    final fixtures = Fixtures(sessionBuilder);

    Future<String> uploadCover(TestSessionBuilder as) async {
      final ticket = await endpoints.profiles.requestCoverUpload(
        as,
        contentType: 'image/jpeg',
        sizeBytes: 8,
      );
      await fixtures.session.storage.storeFile(
        storageId: 'public',
        path: ticket.key,
        byteData: ByteData(8),
      );
      return ticket.key;
    }

    test(
      'then a banner gets a ticket under covers/<id> and up to 8 MB',
      () async {
        final elena = await fixtures.seedCreator('elena_ux', 'Elena Vega');
        final ticket = await endpoints.profiles.requestCoverUpload(
          fixtures.signedIn(elena),
          contentType: 'image/png',
          sizeBytes: 7 * 1024 * 1024,
        );
        expect(ticket.key, startsWith('covers/$elena/'));
        expect(ticket.key, endsWith('.png'));
        expect(ticket.maxBytes, 8 * 1024 * 1024);
      },
    );

    test('then a video or a banner over 8 MB is invalidInput', () async {
      final elena = fixtures.signedIn(
        await fixtures.seedCreator('elena_ux', 'Elena Vega'),
      );
      await expectLater(
        endpoints.profiles.requestCoverUpload(
          elena,
          contentType: 'video/mp4',
          sizeBytes: 1024,
        ),
        throwsNexo(NexoErrorCode.invalidInput),
      );
      await expectLater(
        endpoints.profiles.requestCoverUpload(
          elena,
          contentType: 'image/jpeg',
          sizeBytes: 9 * 1024 * 1024,
        ),
        throwsNexo(NexoErrorCode.invalidInput),
      );
    });

    test('then setting it shows in the public profile and null removes it, '
        'without touching the avatar', () async {
      final elenaId = await fixtures.seedCreator('elena_ux', 'Elena Vega');
      final elena = fixtures.signedIn(elenaId);
      final key = await uploadCover(elena);

      final me = await endpoints.profiles.setCover(elena, key);
      expect(me.profile.coverUrl, isNotNull);
      expect(me.profile.avatarUrl, isNull);
      expect(
        (await endpoints.profiles.byUsername(
          fixtures.guest,
          'elena_ux',
        )).coverUrl,
        me.profile.coverUrl,
      );

      final cleared = await endpoints.profiles.setCover(elena, null);
      expect(cleared.profile.coverUrl, isNull);
    });

    test('then a banner key of another account is forbidden, an avatar key '
        'is not a banner, and an unfinished upload is invalidInput', () async {
      final elena = fixtures.signedIn(
        await fixtures.seedCreator('elena_ux', 'Elena Vega'),
      );
      final tomas = fixtures.signedIn(
        await fixtures.seedAccount('tomas', 'Tomás Ríos'),
      );
      final elenasCover = await uploadCover(elena);
      await expectLater(
        endpoints.profiles.setCover(tomas, elenasCover),
        throwsNexo(NexoErrorCode.forbidden),
      );

      final avatar = await endpoints.profiles.requestAvatarUpload(
        elena,
        contentType: 'image/png',
        sizeBytes: 8,
      );
      await expectLater(
        endpoints.profiles.setCover(elena, avatar.key),
        throwsNexo(NexoErrorCode.invalidInput),
      );

      final pending = await endpoints.profiles.requestCoverUpload(
        elena,
        contentType: 'image/jpeg',
        sizeBytes: 8,
      );
      await expectLater(
        endpoints.profiles.setCover(elena, pending.key),
        throwsNexo(NexoErrorCode.invalidInput),
      );
    });

    test('then a link without scheme is saved with https, an empty one '
        'removes it, and a broken one is invalidInput', () async {
      final elena = fixtures.signedIn(
        await fixtures.seedCreator('elena_ux', 'Elena Vega'),
      );
      final saved = await endpoints.profiles.update(
        elena,
        ProfileEdit(website: '  nexo.dev/elena '),
      );
      expect(saved.profile.website, 'https://nexo.dev/elena');

      // Cambiar otro campo no toca el enlace.
      final renamed = await endpoints.profiles.update(
        elena,
        ProfileEdit(bio: 'Diseño de producto'),
      );
      expect(renamed.profile.website, 'https://nexo.dev/elena');

      for (final bad in [
        'javascript:alert(1)',
        'no es un link',
        'https://local',
      ]) {
        await expectLater(
          endpoints.profiles.update(elena, ProfileEdit(website: bad)),
          throwsNexo(NexoErrorCode.invalidInput),
          reason: bad,
        );
      }
      await expectLater(
        endpoints.profiles.update(
          elena,
          ProfileEdit(website: 'https://nexo.dev/${'a' * 200}'),
        ),
        throwsNexo(NexoErrorCode.invalidInput),
      );

      final cleared = await endpoints.profiles.update(
        elena,
        ProfileEdit(website: ''),
      );
      expect(cleared.profile.website, isNull);
    });

    test('then postCount counts the posts that are not deleted', () async {
      final elena = fixtures.signedIn(
        await fixtures.seedCreator('elena_ux', 'Elena Vega'),
      );
      final first = await endpoints.posts.create(elena, fixtures.draft('uno'));
      await endpoints.posts.create(elena, fixtures.draft('dos'));
      await endpoints.posts.create(elena, fixtures.draft('tres'));
      await endpoints.posts.delete(elena, first.id);

      final profile = await endpoints.profiles.byUsername(
        fixtures.guest,
        'elena_ux',
      );
      expect(profile.postCount, 2);
      expect((await endpoints.profiles.me(elena)).profile.postCount, 2);
    });
  });
}
