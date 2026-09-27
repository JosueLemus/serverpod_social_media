import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/storage/mock_social_store.dart';
import '../../../feed/domain/entities/post.dart';

sealed class PostComposerState {
  const PostComposerState();
}

class PostComposerIdle extends PostComposerState {
  const PostComposerIdle({this.text = ''});
  final String text;
}

class PostComposerPublished extends PostComposerState {
  const PostComposerPublished();
}

class PostComposerCubit extends Cubit<PostComposerState> {
  PostComposerCubit(this._store) : super(const PostComposerIdle());
  final MockSocialStore _store;
  void change(String text) => emit(PostComposerIdle(text: text));
  Future<void> publish() async {
    final current = state;
    if (current is! PostComposerIdle || current.text.trim().isEmpty) return;
    final posts = _store.readPosts();
    posts.insert(
      0,
      Post(
        id: 'draft-${posts.length + 1}',
        author: 'nexo',
        name: 'Tu comunidad',
        body: current.text.trim(),
        tags: const ['Nuevo'],
        likes: 0,
        comments: 0,
      ),
    );
    await _store.savePosts(posts);
    emit(const PostComposerPublished());
  }
}
