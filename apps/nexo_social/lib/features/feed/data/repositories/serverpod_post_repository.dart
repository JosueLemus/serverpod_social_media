import 'dart:async';
import 'dart:typed_data';

import 'package:nexo_client/nexo_client.dart' as api;

import '../../../../core/errors/failures.dart';
import '../../../../core/network/serverpod_failures.dart';
import '../../../moderation/domain/entities/moderation_action.dart';
import '../../domain/entities/post.dart';
import '../../domain/entities/post_extras.dart';
import '../../domain/repositories/post_repository.dart';

/// Publicaciones contra los módulos `content`, `social` y `moderation`.
class ServerpodPostRepository implements PostRepository {
  ServerpodPostRepository(this._client);

  final api.Client _client;
  final _changes = StreamController<void>.broadcast();

  @override
  Stream<void> changes() => _changes.stream;

  @override
  Future<PostPage> feed({String? cursor}) => _guard(() async {
    final page = await _client.posts.feed(after: _decodeCursor(cursor));
    return PostPage([
      for (final view in page.items) toPost(view),
    ], nextCursor: _encodeCursor(page.nextCursor));
  });

  @override
  Future<Post> create(PostDraftInput input) => _guard(() async {
    final keys = <String>[];
    final attachment = input.attachment;
    if (attachment != null) keys.add(await _upload(attachment));

    final view = await _client.posts.create(
      api.PostDraft(
        body: input.body,
        tags: input.tags,
        visibility: api.PostVisibility.values.byName(input.visibility.name),
        allowComments: input.allowComments,
        mediaKeys: keys,
      ),
    );
    _notify();
    return toPost(view);
  });

  /// Pide permiso al servidor, sube el archivo directo al storage y devuelve
  /// la clave para publicar. El tipo y el tamaño los vuelve a exigir el
  /// storage al recibirlo: el cliente no puede mentir sobre ellos.
  Future<String> _upload(MediaAttachment attachment) async {
    final ticket = await _client.posts.requestMediaUpload(
      kind: attachment.kind == PostMedia.video
          ? api.PostMediaKind.video
          : api.PostMediaKind.image,
      contentType: attachment.contentType,
      sizeBytes: attachment.sizeBytes,
    );
    final uploaded = await api.FileUploader(
      ticket.uploadDescription,
    ).uploadByteData(ByteData.sublistView(attachment.bytes));
    if (!uploaded) throw const NetworkFailure('upload failed');
    return ticket.key;
  }

  @override
  Future<Post> update(
    String postId, {
    String? body,
    List<String>? tags,
    bool? allowComments,
  }) => _guard(() async {
    final view = await _client.posts.update(
      int.parse(postId),
      api.PostEdit(body: body, tags: tags, allowComments: allowComments),
    );
    _notify();
    return toPost(view);
  });

  @override
  Future<void> delete(String postId) => _guard(() async {
    await _client.posts.delete(int.parse(postId));
    _notify();
  });

  @override
  Future<LikeResult> setLiked(String postId, {required bool liked}) =>
      _guard(() async {
        final id = int.parse(postId);
        final state = liked
            ? await _client.likes.like(id)
            : await _client.likes.unlike(id);
        return LikeResult(isLiked: state.isLiked, likes: state.likeCount);
      });

  @override
  Future<List<PostLiker>> likers(String postId) => _guard(() async {
    final page = await _client.likes.likers(int.parse(postId));
    return [
      for (final liker in page.items)
        PostLiker(
          username: liker.username ?? '',
          name: liker.name ?? liker.username ?? '',
        ),
    ];
  });

  @override
  Future<CommentPage> comments(String postId, {String? cursor}) =>
      _guard(() async {
        final page = await _client.comments.list(
          int.parse(postId),
          after: _decodeCursor(cursor),
        );
        return CommentPage([
          for (final view in page.items) _toComment(view),
        ], nextCursor: _encodeCursor(page.nextCursor));
      });

  @override
  Future<PostComment> addComment(String postId, String body) =>
      _guard(() async {
        final view = await _client.comments.create(int.parse(postId), body);
        _notify();
        return _toComment(view);
      });

  @override
  Future<void> deleteComment(String commentId) => _guard(() async {
    await _client.comments.delete(int.parse(commentId));
    _notify();
  });

  @override
  Future<void> report(
    ReportTarget target,
    String targetId,
    ModerationReason reason,
  ) => _guard(
    () => _client.moderation.report(
      targetType: target == ReportTarget.post
          ? api.ReportTargetType.post
          : api.ReportTargetType.postComment,
      targetId: int.parse(targetId),
      reason: api.ModerationReason.values.byName(reason.name),
    ),
  );

  /// Público para los tests: es la traducción que más se puede romper.
  static Post toPost(api.PostView view) {
    final media = view.media.isEmpty ? null : view.media.first;
    return Post(
      id: '${view.id}',
      author: view.authorUsername ?? '',
      authorId: view.authorId.toString(),
      name: view.authorName ?? view.authorUsername ?? '',
      body: view.body,
      tags: view.tags,
      likes: view.likeCount,
      comments: view.commentCount,
      createdAt: view.createdAt.toLocal(),
      media: switch (media?.kind) {
        api.PostMediaKind.image => PostMedia.image,
        api.PostMediaKind.video => PostMedia.video,
        null => null,
      },
      mediaUrl: media?.url.toString(),
      isLiked: view.isLiked,
      canEdit: view.canEdit,
      canDelete: view.canDelete,
      allowComments: view.allowComments,
      visibility: PostVisibility.values.byName(view.visibility.name),
      editedAt: view.editedAt?.toLocal(),
    );
  }

  static PostComment _toComment(api.PostCommentView view) => PostComment(
    id: '${view.id}',
    postId: '${view.postId}',
    author: view.authorUsername ?? '',
    name: view.authorName ?? view.authorUsername ?? '',
    body: view.body,
    createdAt: view.createdAt.toLocal(),
    canDelete: view.canDelete,
  );

  /// El cursor del servidor viaja como texto opaco: la app no sabe ni
  /// necesita saber que es `(createdAt, id)`.
  static String? _encodeCursor(api.PageCursor? cursor) => cursor == null
      ? null
      : '${cursor.createdAt.toUtc().toIso8601String()}|${cursor.id}';

  static api.PageCursor? _decodeCursor(String? cursor) {
    if (cursor == null) return null;
    final parts = cursor.split('|');
    if (parts.length != 2) return null;
    final createdAt = DateTime.tryParse(parts[0]);
    final id = int.tryParse(parts[1]);
    if (createdAt == null || id == null) return null;
    return api.PageCursor(createdAt: createdAt, id: id);
  }

  void _notify() {
    if (!_changes.isClosed) _changes.add(null);
  }

  static Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } catch (error) {
      throw failureFromServer(error);
    }
  }
}
