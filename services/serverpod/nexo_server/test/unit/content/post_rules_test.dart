import 'package:nexo_server/src/generated/protocol.dart';
import 'package:nexo_server/src/modules/content/services/post_rules.dart';
import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';

void main() {
  final owner = UuidValue.fromString('0199a0b2-1c3d-7e4f-8a5b-6c7d8e9f0a1b');

  group('Given PostRules.normalizeTags', () {
    test('when tags have #, spaces and repeats then returns them clean', () {
      expect(
        PostRules.normalizeTags([' #Diseño', 'diseño', '##ux', '', 'UX']),
        ['Diseño', 'ux'],
      );
    });

    test('when a tag contains a space then throws invalidInput', () {
      expect(
        () => PostRules.normalizeTags(['dos palabras']),
        throwsA(
          isA<NexoException>().having(
            (e) => e.code,
            'code',
            NexoErrorCode.invalidInput,
          ),
        ),
      );
    });

    test('when there are too many tags then throws invalidInput', () {
      expect(
        () => PostRules.normalizeTags([
          for (var i = 0; i <= PostRules.maxTags; i++) 'tag$i',
        ]),
        throwsA(isA<NexoException>()),
      );
    });
  });

  group('Given PostRules.normalizeBody', () {
    test('when body has surrounding spaces then trims it', () {
      expect(PostRules.normalizeBody('  hola  '), 'hola');
    });

    test('when body is too long then throws invalidInput', () {
      expect(
        () => PostRules.normalizeBody('a' * (PostRules.maxBodyLength + 1)),
        throwsA(isA<NexoException>()),
      );
    });
  });

  group('Given PostRules.pageSize', () {
    test('when no size is requested then uses the default', () {
      expect(PostRules.pageSize(null), PostRules.defaultPageSize);
    });

    test('when size is out of range then clamps it', () {
      expect(PostRules.pageSize(0), 1);
      expect(PostRules.pageSize(500), PostRules.maxPageSize);
    });
  });

  group('Given MediaPolicy', () {
    test('when content type does not match the kind then has no extension', () {
      expect(
        MediaPolicy.extensionFor(PostMediaKind.image, 'video/mp4'),
        isNull,
      );
      expect(MediaPolicy.extensionFor(PostMediaKind.video, 'VIDEO/MP4'), 'mp4');
    });

    test('when parsing a key built by newKey then recovers owner and type', () {
      final key = MediaPolicy.newKey(owner, PostMediaKind.video, 'mov');
      final parsed = MediaPolicy.parseKey(key)!;

      expect(parsed.ownerId, owner);
      expect(parsed.kind, PostMediaKind.video);
      expect(parsed.contentType, 'video/quicktime');
    });

    test('when the key was not built by the server then returns null', () {
      for (final key in [
        'avatar.png',
        'posts/$owner/image/not-a-uuid.png',
        'posts/not-a-uuid/image/0199a0b2-1c3d-7e4f-8a5b-6c7d8e9f0a1b.png',
        'posts/$owner/audio/0199a0b2-1c3d-7e4f-8a5b-6c7d8e9f0a1b.mp3',
        'posts/$owner/image/0199a0b2-1c3d-7e4f-8a5b-6c7d8e9f0a1b.mp4',
        '../posts/$owner/image/0199a0b2-1c3d-7e4f-8a5b-6c7d8e9f0a1b.png',
      ]) {
        expect(MediaPolicy.parseKey(key), isNull, reason: key);
      }
    });
  });
}
