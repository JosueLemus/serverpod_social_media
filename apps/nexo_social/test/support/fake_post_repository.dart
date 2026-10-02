import 'dart:async';

import 'package:nexo_social/core/errors/failures.dart';
import 'package:nexo_social/features/feed/domain/entities/post.dart';
import 'package:nexo_social/features/feed/domain/entities/post_extras.dart';
import 'package:nexo_social/features/feed/domain/repositories/post_repository.dart';
import 'package:nexo_social/features/moderation/domain/entities/moderation_action.dart';

Post fakePost(
  String id, {
  int likes = 0,
  bool liked = false,
  bool live = false,
  bool followed = false,
  bool canEdit = false,
  List<String> tags = const ['t'],
}) => Post(
  id: id,
  author: 'a',
  name: 'A',
  body: 'post $id',
  tags: tags,
  likes: likes,
  comments: 0,
  createdAt: DateTime(2026),
  isLiked: liked,
  isLive: live,
  isFollowed: followed,
  canEdit: canEdit,
  canDelete: canEdit,
);

/// Un servidor de posts en memoria, con fallos a pedido.
class FakePostRepository implements PostRepository {
  FakePostRepository([List<Post>? posts]) : posts = posts ?? [fakePost('1')];

  List<Post> posts;

  /// Páginas de a [pageSize]; el cursor es el índice siguiente.
  int pageSize = 20;

  /// El próximo llamado a cualquier método lanza esto.
  Failure? failNext;

  final created = <PostDraftInput>[];
  final reports = <(ReportTarget, String, ModerationReason)>[];
  final threads = <String, List<PostComment>>{};
  final _changes = StreamController<void>.broadcast();

  void _maybeFail() {
    final failure = failNext;
    if (failure != null) {
      failNext = null;
      throw failure;
    }
  }

  void emitChange() => _changes.add(null);

  @override
  Stream<void> changes() => _changes.stream;

  @override
  Future<PostPage> feed({String? cursor}) async {
    _maybeFail();
    final start = int.tryParse(cursor ?? '') ?? 0;
    final end = (start + pageSize).clamp(0, posts.length);
    return PostPage(
      posts.sublist(start, end),
      nextCursor: end < posts.length ? '$end' : null,
    );
  }

  @override
  Future<Post> create(PostDraftInput input) async {
    _maybeFail();
    created.add(input);
    final post = fakePost('new-${created.length}', canEdit: true);
    posts = [post, ...posts];
    return post;
  }

  @override
  Future<Post> update(
    String postId, {
    String? body,
    List<String>? tags,
    bool? allowComments,
  }) async {
    _maybeFail();
    final post = posts.firstWhere((p) => p.id == postId).copyWith(body: body);
    posts = [for (final p in posts) p.id == postId ? post : p];
    return post;
  }

  @override
  Future<void> delete(String postId) async {
    _maybeFail();
    posts = posts.where((p) => p.id != postId).toList();
  }

  @override
  Future<LikeResult> setLiked(String postId, {required bool liked}) async {
    _maybeFail();
    final post = posts.firstWhere((p) => p.id == postId);
    // El servidor cuenta: idempotente, como el endpoint real.
    final likes = post.isLiked == liked
        ? post.likes
        : post.likes + (liked ? 1 : -1);
    posts = [
      for (final p in posts)
        p.id == postId ? p.copyWith(isLiked: liked, likes: likes) : p,
    ];
    return LikeResult(isLiked: liked, likes: likes);
  }

  @override
  Future<List<PostLiker>> likers(String postId) async => const [
    PostLiker(username: 'tomas', name: 'Tomás'),
  ];

  @override
  Future<CommentPage> comments(String postId, {String? cursor}) async {
    _maybeFail();
    return CommentPage(List.of(threads[postId] ?? const []));
  }

  @override
  Future<PostComment> addComment(String postId, String body) async {
    _maybeFail();
    final comment = PostComment(
      id: 'c${(threads[postId]?.length ?? 0) + 1}',
      postId: postId,
      author: 'tomas',
      name: 'Tomás',
      body: body,
      createdAt: DateTime(2026),
      canDelete: true,
    );
    threads.putIfAbsent(postId, () => []).add(comment);
    return comment;
  }

  @override
  Future<void> deleteComment(String commentId) async {
    _maybeFail();
    for (final list in threads.values) {
      list.removeWhere((c) => c.id == commentId);
    }
  }

  @override
  Future<void> report(
    ReportTarget target,
    String targetId,
    ModerationReason reason,
  ) async {
    _maybeFail();
    reports.add((target, targetId, reason));
  }
}
