import '../../../moderation/domain/entities/moderation_action.dart';
import '../entities/post.dart';
import '../entities/post_extras.dart';

/// Publicaciones, likes, comentarios y reportes.
///
/// Cada error sale como un `Failure` tipado: `ForbiddenFailure` si el
/// servidor no deja, `NotFoundFailure` si el post ya no está,
/// `NetworkFailure` sin red. La View elige la copy.
abstract interface class PostRepository {
  /// El feed, del más nuevo al más viejo. Pasar el `nextCursor` de la página
  /// anterior para seguir.
  Future<PostPage> feed({String? cursor});

  /// Publica. Si hay adjunto, primero lo sube y después publica.
  Future<Post> create(PostDraftInput input);

  /// Sólo el autor. Los adjuntos no se editan.
  Future<Post> update(
    String postId, {
    String? body,
    List<String>? tags,
    bool? allowComments,
  });

  /// El autor o el staff. El servidor lo marca eliminado; no lo borra.
  Future<void> delete(String postId);

  /// Idempotente: dar like dos veces deja un like.
  Future<LikeResult> setLiked(String postId, {required bool liked});

  Future<List<PostLiker>> likers(String postId);

  Future<CommentPage> comments(String postId, {String? cursor});

  Future<PostComment> addComment(String postId, String body);

  Future<void> deleteComment(String commentId);

  Future<void> report(
    ReportTarget target,
    String targetId,
    ModerationReason reason,
  );

  /// Emite cuando algo cambió por una acción de esta app (publicar, editar,
  /// eliminar), para que el feed se refresque sin recargar.
  Stream<void> changes();
}
