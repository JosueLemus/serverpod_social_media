import 'package:serverpod/serverpod.dart';

import '../../../generated/protocol.dart';
import '../../../shared/auth/auth_context.dart';
import '../../../shared/profiles/profile_lookup.dart';
import '../../content/services/post_rules.dart';
import '../../content/services/post_service.dart';

/// Likes de posts. Dar y quitar son idempotentes: repetir la llamada deja el
/// mismo estado, así que un doble toque o un reintento de red no descuadra el
/// contador.
class LikeService {
  const LikeService({this._posts = const PostService()});

  final PostService _posts;

  Future<LikeState> like(Session session, int postId) =>
      _set(session, postId, liked: true);

  Future<LikeState> unlike(Session session, int postId) =>
      _set(session, postId, liked: false);

  /// Quién dio like, del más reciente al más viejo. Lo ve quien ve el post.
  Future<PostLikerPage> likers(
    Session session,
    int postId, {
    PageCursor? after,
    int? limit,
  }) async {
    await _posts.loadVisible(session, postId);

    final size = PostRules.pageSize(limit);
    final rows = await PostLike.db.find(
      session,
      where: (t) {
        var where = t.postId.equals(postId);
        if (after != null) {
          where =
              where &
              ((t.createdAt < after.createdAt) |
                  (t.createdAt.equals(after.createdAt) & (t.id < after.id)));
        }
        return where;
      },
      orderByList: (t) => [t.createdAt.desc(), t.id.desc()],
      limit: size + 1,
    );

    final hasMore = rows.length > size;
    final items = hasMore ? rows.sublist(0, size) : rows;
    final profiles = await profilesOf(session, items.map((l) => l.userId));
    return PostLikerPage(
      items: [
        for (final like in items)
          PostLiker(
            userId: like.userId,
            username: profiles[like.userId]?.userName,
            name: profiles[like.userId]?.fullName,
            likedAt: like.createdAt,
          ),
      ],
      nextCursor: hasMore
          ? PageCursor(createdAt: items.last.createdAt, id: items.last.id!)
          : null,
    );
  }

  /// El post queda bloqueado mientras dura la transacción, así que dos likes
  /// simultáneos del mismo usuario no insertan dos filas ni suman dos.
  Future<LikeState> _set(
    Session session,
    int postId, {
    required bool liked,
  }) async {
    final userId = session.requireUserId;

    return session.db.transaction((tx) async {
      final post = await _posts.loadVisible(session, postId, transaction: tx);
      final existing = await PostLike.db.findFirstRow(
        session,
        where: (t) => t.postId.equals(postId) & t.userId.equals(userId),
        transaction: tx,
      );

      var delta = 0;
      if (liked && existing == null) {
        await PostLike.db.insertRow(
          session,
          PostLike(postId: postId, userId: userId),
          transaction: tx,
        );
        delta = 1;
      } else if (!liked && existing != null) {
        await PostLike.db.deleteRow(session, existing, transaction: tx);
        delta = -1;
      }
      if (delta != 0) {
        await _posts.adjustCounts(session, post, likes: delta, transaction: tx);
      }

      return LikeState(
        postId: postId,
        isLiked: liked,
        likeCount: post.likeCount + delta,
      );
    });
  }
}
