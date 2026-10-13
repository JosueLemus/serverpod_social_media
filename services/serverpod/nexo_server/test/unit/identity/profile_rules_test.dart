import 'package:nexo_server/src/modules/identity/services/profile_image_policy.dart';
import 'package:nexo_server/src/modules/identity/services/website_rules.dart';
import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';

void main() {
  group('WebsiteRules', () {
    test('adds https to a link written without scheme', () {
      expect(WebsiteRules.normalize('nexo.dev'), 'https://nexo.dev');
      expect(WebsiteRules.normalize('http://nexo.dev'), 'http://nexo.dev');
      expect(WebsiteRules.normalize('   '), isNull);
    });

    test('accepts http and https links with a real host only', () {
      expect(WebsiteRules.problemWith('https://nexo.dev/elena'), isNull);
      expect(WebsiteRules.problemWith('ftp://nexo.dev'), isNotNull);
      expect(WebsiteRules.problemWith('https://localhost'), isNotNull);
      expect(WebsiteRules.problemWith('https://nexo .dev'), isNotNull);
    });
  });

  group('ProfileImagePolicy', () {
    final owner = const Uuid().v7obj();

    test('avatar and banner keys live in their own folder', () {
      final avatar = ProfileImagePolicy.avatar.newKey(owner, 'jpg');
      final cover = ProfileImagePolicy.cover.newKey(owner, 'png');
      expect(avatar, startsWith('avatars/$owner/'));
      expect(cover, startsWith('covers/$owner/'));
      expect(ProfileImagePolicy.avatar.ownerOf(avatar), owner);
      expect(ProfileImagePolicy.cover.ownerOf(cover), owner);
      // Una clave de avatar no sirve como banner, ni al revés.
      expect(ProfileImagePolicy.cover.ownerOf(avatar), isNull);
      expect(ProfileImagePolicy.avatar.ownerOf(cover), isNull);
    });

    test('the banner allows more bytes than the avatar', () {
      expect(ProfileImagePolicy.avatar.maxBytes, 5 * 1024 * 1024);
      expect(ProfileImagePolicy.cover.maxBytes, 8 * 1024 * 1024);
    });
  });
}
