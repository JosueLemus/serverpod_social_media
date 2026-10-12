import 'dart:async';

import '../../../../core/storage/mock_social_store.dart';
import '../../../moderation/domain/entities/moderation_action.dart';
import '../../domain/entities/post.dart';
import '../../domain/entities/post_extras.dart';
import '../../domain/repositories/post_repository.dart';

/// Publicaciones sobre el [MockSocialStore]. Vive hasta M7 (SDD 0004), cuando
/// el mock sale del runtime y queda sólo para tests.
///
/// Los comentarios y los reportes viven en memoria: el mock nunca los tuvo,
/// y persistirlos ahora sería construir algo que se borra en una semana.
class MockPostRepository implements PostRepository {
  MockPostRepository(this._store);

  final MockSocialStore _store;
  final _comments = <String, List<PostComment>>{};
  final _changes = StreamController<void>.broadcast();
  var _sequence = 0;

  /// En el mock, todo lo que se publica es de la cuenta de demo.
  static const _author = 'elena_ux';

  @override
  Stream<void> changes() => _changes.stream;

  @override
  Future<PostPage> feed({String? cursor}) async =>
      PostPage(cursor == null ? _store.readPosts() : const []);

  @override
  Future<Post> create(PostDraftInput input) async {
    final post = Post(
      id: 'post-${DateTime.now().microsecondsSinceEpoch}-${_sequence++}',
      author: _author,
      name: 'Elena Vega',
      body: input.body,
      tags: input.tags,
      likes: 0,
      comments: 0,
      createdAt: DateTime.now(),
      media: input.attachment?.kind,
      canEdit: true,
      canDelete: true,
      allowComments: input.allowComments,
      visibility: input.visibility,
    );
    await _store.savePosts([post, ..._store.readPosts()]);
    _notify();
    return post;
  }

  @override
  Future<Post> update(
    String postId, {
    String? body,
    List<String>? tags,
    bool? allowComments,
  }) async {
    late Post updated;
    await _store.savePosts([
      for (final post in _store.readPosts())
        if (post.id == postId)
          updated = post.copyWith(
            body: body,
            tags: tags,
            allowComments: allowComments,
            editedAt: DateTime.now(),
          )
        else
          post,
    ]);
    _notify();
    return updated;
  }

  @override
  Future<void> delete(String postId) async {
    await _store.savePosts(
      _store.readPosts().where((post) => post.id != postId).toList(),
    );
    _notify();
  }

  @override
  Future<LikeResult> setLiked(String postId, {required bool liked}) async {
    var result = LikeResult(isLiked: liked, likes: 0);
    await _store.savePosts([
      for (final post in _store.readPosts())
        if (post.id == postId)
          () {
            final likes = post.isLiked == liked
                ? post.likes
                : post.likes + (liked ? 1 : -1);
            result = LikeResult(isLiked: liked, likes: likes);
            return post.copyWith(isLiked: liked, likes: likes);
          }()
        else
          post,
    ]);
    return result;
  }

  @override
  Future<List<PostLiker>> likers(String postId) async => const [];

  @override
  Future<CommentPage> comments(String postId, {String? cursor}) async =>
      CommentPage(List.unmodifiable(_comments[postId] ?? const []));

  @override
  Future<PostComment> addComment(String postId, String body) async {
    final comment = PostComment(
      id: 'comment-${_sequence++}',
      postId: postId,
      author: _author,
      name: 'Elena Vega',
      body: body,
      createdAt: DateTime.now(),
      canDelete: true,
    );
    _comments.putIfAbsent(postId, () => []).add(comment);
    await _bumpComments(postId, 1);
    return comment;
  }

  @override
  Future<void> deleteComment(String commentId) async {
    for (final entry in _comments.entries) {
      final before = entry.value.length;
      entry.value.removeWhere((comment) => comment.id == commentId);
      if (entry.value.length != before) await _bumpComments(entry.key, -1);
    }
  }

  @override
  Future<void> report(
    ReportTarget target,
    String targetId,
    ModerationReason reason,
  ) async {}

  Future<void> _bumpComments(String postId, int delta) async {
    await _store.savePosts([
      for (final post in _store.readPosts())
        if (post.id == postId)
          post.copyWith(comments: (post.comments + delta).clamp(0, 1 << 30))
        else
          post,
    ]);
    _notify();
  }

  void _notify() {
    if (!_changes.isClosed) _changes.add(null);
  }
}
