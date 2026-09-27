import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexo_social/core/storage/mock_social_store.dart';
import 'package:nexo_social/features/posts/presentation/bloc/post_composer_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late MockSocialStore store;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    store = MockSocialStore(await SharedPreferences.getInstance());
  });
  blocTest<PostComposerCubit, PostComposerState>(
    'publishes a valid draft into persistent mock storage',
    build: () => PostComposerCubit(store),
    act: (cubit) async {
      cubit.change('Hola Nexo');
      await cubit.publish();
    },
    expect: () => [isA<PostComposerIdle>(), isA<PostComposerPublished>()],
    verify: (_) => expect(store.readPosts().first.body, 'Hola Nexo'),
  );
}
