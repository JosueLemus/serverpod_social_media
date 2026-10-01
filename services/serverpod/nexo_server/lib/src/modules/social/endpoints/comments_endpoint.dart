import 'package:serverpod/serverpod.dart';

import '../../../generated/protocol.dart';
import '../services/comment_service.dart';

/// Comentarios de posts. Desde Flutter: `client.comments`.
class CommentsEndpoint extends Endpoint {
  static const _comments = CommentService();

  /// Comentarios de un post, del más viejo al más nuevo. Público si el post
  /// lo es. Misma paginación que `posts.feed`.
  Future<PostCommentPage> list(
    Session session,
    int postId, {
    PageCursor? after,
    int? limit,
  }) => _comments.list(session, postId, after: after, limit: limit);

  /// Comenta, hasta 1000 caracteres. Requiere sesión. `forbidden` si el
  /// autor del post desactivó los comentarios.
  Future<PostCommentView> create(Session session, int postId, String body) =>
      _comments.create(session, postId, body);

  /// Elimina un comentario: su autor, el autor del post o un moderador.
  /// Queda auditado.
  Future<void> delete(Session session, int commentId) =>
      _comments.delete(session, commentId);
}
