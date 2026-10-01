import 'package:serverpod/serverpod.dart';

import '../../../generated/protocol.dart';
import '../services/like_service.dart';

/// Likes de posts. Desde Flutter: `client.likes`.
///
/// Dar y quitar devuelven el estado final con el contador ya actualizado, y
/// se pueden repetir sin efecto: dos `like` seguidos dejan un solo like.
class LikesEndpoint extends Endpoint {
  static const _likes = LikeService();

  /// Da like. Requiere sesión.
  Future<LikeState> like(Session session, int postId) =>
      _likes.like(session, postId);

  /// Quita el like. Requiere sesión.
  Future<LikeState> unlike(Session session, int postId) =>
      _likes.unlike(session, postId);

  /// Quién dio like, del más reciente al más viejo. Público si el post lo es.
  /// Misma paginación que `posts.feed`.
  Future<PostLikerPage> likers(
    Session session,
    int postId, {
    PageCursor? after,
    int? limit,
  }) => _likes.likers(session, postId, after: after, limit: limit);
}
