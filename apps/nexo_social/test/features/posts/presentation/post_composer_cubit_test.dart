import 'dart:typed_data';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexo_social/core/errors/failures.dart';
import 'package:nexo_social/core/media/media_picker.dart';
import 'package:nexo_social/features/feed/domain/entities/media_rules.dart';
import 'package:nexo_social/features/feed/domain/entities/post_extras.dart';
import 'package:nexo_social/features/posts/presentation/bloc/post_composer_cubit.dart';

import '../../../support/fake_post_repository.dart';

/// Devuelve el archivo que el test quiere, sin abrir ninguna galería.
class _FakePicker implements MediaPicker {
  _FakePicker(this.attachment);

  final MediaAttachment? attachment;

  @override
  Future<MediaAttachment?> pick(PostMedia kind) async => attachment;
}

MediaAttachment _file({
  PostMedia kind = PostMedia.image,
  String type = 'image/jpeg',
  int bytes = 1024,
}) => MediaAttachment(
  kind: kind,
  bytes: Uint8List(bytes),
  contentType: type,
  fileName: kind == PostMedia.video ? 'clip.mp4' : 'foto.jpg',
);

void main() {
  late FakePostRepository repository;

  setUp(() => repository = FakePostRepository());

  blocTest<PostComposerCubit, PostComposerState>(
    'publishes the draft through the repository, with its hashtags',
    build: () => PostComposerCubit(repository, _FakePicker(null)),
    act: (cubit) async {
      cubit.change('Hola #Nexo y #diseño');
      await cubit.publish();
    },
    verify: (cubit) {
      expect(cubit.state, isA<PostComposerPublished>());
      expect(repository.created.single.body, 'Hola #Nexo y #diseño');
      expect(repository.created.single.tags, ['nexo', 'diseño']);
    },
  );

  blocTest<PostComposerCubit, PostComposerState>(
    'an attached photo travels with the post',
    build: () => PostComposerCubit(repository, _FakePicker(_file())),
    act: (cubit) async {
      cubit.change('Con foto');
      await cubit.attach(PostMedia.image);
      await cubit.publish();
    },
    verify: (_) =>
        expect(repository.created.single.attachment?.fileName, 'foto.jpg'),
  );

  /// Mejor enterarse al elegir el archivo que después de esperar la subida.
  blocTest<PostComposerCubit, PostComposerState>(
    'a file over the limit is rejected before uploading',
    build: () => PostComposerCubit(
      repository,
      _FakePicker(_file(bytes: MediaRules.maxImageBytes + 1)),
    ),
    act: (cubit) => cubit.attach(PostMedia.image),
    verify: (cubit) {
      final state = cubit.state as PostComposerIdle;
      expect(state.attachment, isNull);
      expect(state.issue, ComposerIssue.fileTooLarge);
    },
  );

  blocTest<PostComposerCubit, PostComposerState>(
    'an unsupported format is rejected',
    build: () =>
        PostComposerCubit(repository, _FakePicker(_file(type: 'image/heic'))),
    act: (cubit) => cubit.attach(PostMedia.image),
    verify: (cubit) => expect(
      (cubit.state as PostComposerIdle).issue,
      ComposerIssue.unsupportedFile,
    ),
  );

  /// Un fallo al publicar no pierde lo escrito.
  blocTest<PostComposerCubit, PostComposerState>(
    'a failed publish keeps the draft and says why',
    build: () => PostComposerCubit(repository, _FakePicker(null)),
    act: (cubit) async {
      cubit.change('No se pierde');
      repository.failNext = const NetworkFailure('offline');
      await cubit.publish();
    },
    verify: (cubit) {
      final state = cubit.state as PostComposerIdle;
      expect(state.text, 'No se pierde');
      expect(state.isPublishing, isFalse);
      expect(state.issue, ComposerIssue.offline);
    },
  );

  test('publishing disables the button: a double tap is one post', () async {
    final cubit = PostComposerCubit(repository, _FakePicker(null))
      ..change('Una vez');
    await Future.wait([cubit.publish(), cubit.publish()]);

    expect(repository.created, hasLength(1));
    await cubit.close();
  });

  group('MediaRules.tagsIn', () {
    test('lowercases, dedupes and caps at ten', () {
      final text = List.generate(12, (i) => '#tag$i').join(' ');
      expect(MediaRules.tagsIn('#Hola #hola'), ['hola']);
      expect(MediaRules.tagsIn(text), hasLength(10));
    });
  });
}
