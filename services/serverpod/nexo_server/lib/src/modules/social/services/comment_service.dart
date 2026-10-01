import 'package:serverpod/serverpod.dart';

import '../../../generated/protocol.dart';
import '../../../shared/audit/audit_service.dart';
import '../../../shared/auth/auth_context.dart';
import '../../../shared/profiles/profile_lookup.dart';
import '../../content/services/post_rules.dart';
import '../../content/services/post_service.dart';

/// Comentarios de posts: leer, comentar y eliminar.
class CommentService {
  const CommentService({
    this._posts = const PostService(),
    this._audit = const AuditService(),
  });

  static const maxBodyLength = 1000;

  final PostService _posts;
  final AuditService _audit;

  /// Del más viejo al más nuevo. Lo ve quien ve el post.
  Future<PostCommentPage> list(
    Session session,
    int postId, {
    PageCursor? after,
    int? limit,
  }) async {
    final post = await _posts.loadVisible(session, postId);

    final size = PostRules.pageSize(limit);
    final rows = await PostComment.db.find(
      session,
      where: (t) {
        var where = t.postId.equals(postId) & t.deletedAt.equals(null);
        if (after != null) {
          where =
              where &
              ((t.createdAt > after.createdAt) |
                  (t.createdAt.equals(after.createdAt) & (t.id > after.id)));
        }
        return where;
      },
      orderByList: (t) => [t.createdAt.asc(), t.id.asc()],
      limit: size + 1,
    );

    final hasMore = rows.length > size;
    final items = hasMore ? rows.sublist(0, size) : rows;
    return PostCommentPage(
      items: await _toViews(session, post, items),
      nextCursor: hasMore
          ? PageCursor(createdAt: items.last.createdAt, id: items.last.id!)
          : null,
    );
  }

  Future<PostCommentView> create(
    Session session,
    int postId,
    String body,
  ) async {
    final authorId = session.requireUserId;
    final text = body.trim();
    if (text.isEmpty) {
      throw _error(NexoErrorCode.invalidInput, 'El comentario está vacío.');
    }
    if (text.length > maxBodyLength) {
      throw _error(
        NexoErrorCode.invalidInput,
        'El comentario supera los $maxBodyLength caracteres.',
      );
    }

    final (post, comment) = await session.db.transaction((tx) async {
      final post = await _posts.loadVisible(session, postId, transaction: tx);
      if (!post.allowComments) {
        throw _error(
          NexoErrorCode.forbidden,
          'Esta publicación no acepta comentarios.',
        );
      }
      final comment = await PostComment.db.insertRow(
        session,
        PostComment(postId: postId, authorId: authorId, body: text),
        transaction: tx,
      );
      await _posts.adjustCounts(session, post, comments: 1, transaction: tx);
      return (post, comment);
    });

    return (await _toViews(session, post, [comment])).single;
  }

  /// El autor del comentario, el autor del post o el staff de moderación.
  Future<void> delete(Session session, int commentId) async {
    final userId = session.requireUserId;

    await session.db.transaction((tx) async {
      final (post, comment) = await loadVisible(
        session,
        commentId,
        transaction: tx,
      );
      final isAuthor = comment.authorId == userId;
      if (!isAuthor && post.authorId != userId && !session.isStaff) {
        throw _error(
          NexoErrorCode.forbidden,
          'Solo el autor del comentario, el del post o un moderador '
          'puede eliminarlo.',
        );
      }

      await markRemoved(session, post, comment, by: userId, transaction: tx);
      await _audit.record(
        session,
        actorId: userId,
        action: 'comment.delete',
        entityType: 'postComment',
        entityId: '$commentId',
        metadata: {'postId': post.id, 'byAuthor': isAuthor},
        transaction: tx,
      );
    });
  }

  // --- Para otros módulos --------------------------------------------------

  /// Un comentario vivo de un post que [session] puede ver, o `notFound`.
  /// Con [transaction], el post queda bloqueado para ajustar su contador.
  Future<(Post, PostComment)> loadVisible(
    Session session,
    int commentId, {
    Transaction? transaction,
  }) async {
    final comment = await PostComment.db.findById(
      session,
      commentId,
      transaction: transaction,
    );
    if (comment == null || comment.deletedAt != null) {
      throw _error(NexoErrorCode.notFound, 'El comentario no existe.');
    }
    final post = await _posts.loadVisible(
      session,
      comment.postId,
      transaction: transaction,
    );
    return (post, comment);
  }

  /// Saca [comment] de toda lectura y descuenta el contador de [post]. No
  /// audita: lo hace quien decide.
  Future<void> markRemoved(
    Session session,
    Post post,
    PostComment comment, {
    required UuidValue by,
    required Transaction transaction,
  }) async {
    await PostComment.db.updateRow(
      session,
      comment.copyWith(deletedAt: DateTime.now().toUtc(), deletedBy: by),
      columns: (t) => [t.deletedAt, t.deletedBy],
      transaction: transaction,
    );
    await _posts.adjustCounts(
      session,
      post,
      comments: -1,
      transaction: transaction,
    );
  }

  // --- Internos ------------------------------------------------------------

  Future<List<PostCommentView>> _toViews(
    Session session,
    Post post,
    List<PostComment> comments,
  ) async {
    final profiles = await profilesOf(session, comments.map((c) => c.authorId));
    final viewer = session.userIdOrNull;
    final canModerate =
        viewer != null && (post.authorId == viewer || session.isStaff);

    return [
      for (final c in comments)
        PostCommentView(
          id: c.id!,
          postId: c.postId,
          authorId: c.authorId,
          authorUsername: profiles[c.authorId]?.userName,
          authorName: profiles[c.authorId]?.fullName,
          body: c.body,
          createdAt: c.createdAt,
          canDelete: canModerate || c.authorId == viewer,
        ),
    ];
  }

  static NexoException _error(NexoErrorCode code, String message) =>
      NexoException(code: code, message: message);
}
