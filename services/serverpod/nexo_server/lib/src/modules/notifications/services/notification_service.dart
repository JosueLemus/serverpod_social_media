import 'package:serverpod/serverpod.dart';

import '../../../generated/protocol.dart';
import '../../../shared/auth/auth_context.dart';
import '../../../shared/profiles/avatar_lookup.dart';
import '../../../shared/profiles/profile_lookup.dart';
import '../../content/services/post_rules.dart';

/// Los canales de los avisos en tiempo real. `user:<id>` queda para las
/// sanciones de M6: un canal tipa sus mensajes con una sola clase.
abstract final class NotificationChannels {
  static String user(UuidValue userId) => 'notifications:$userId';
}

/// Avisos dentro de la app (D10 del SDD 0004): crearlos junto con la acción
/// que los origina, leerlos, marcarlos y publicarlos en el momento.
class NotificationService {
  const NotificationService();

  static const excerptLength = 80;

  // --- Para otros módulos --------------------------------------------------

  /// Crea un aviso de [kind] para cada cuenta de [recipients], dentro de
  /// [transaction]: si la acción se revierte, el aviso tampoco existe.
  ///
  /// [actorId] nunca se avisa a sí mismo. Un `postLiked` sin leer del mismo
  /// actor y el mismo post no se repite (S13): dar y quitar like en un loop
  /// no llena la bandeja de nadie. Devuelve lo creado, para [publish].
  Future<List<UserNotification>> create(
    Session session, {
    required Iterable<UuidValue> recipients,
    required NotificationKind kind,
    UuidValue? actorId,
    int? postId,
    int? showId,
    required Transaction transaction,
  }) async {
    var targets = {...recipients}..remove(actorId);
    if (targets.isEmpty) return const [];

    if (kind == NotificationKind.postLiked &&
        actorId != null &&
        postId != null) {
      final pending = await UserNotification.db.find(
        session,
        where: (t) =>
            t.userId.inSet(targets) &
            t.kind.equals(NotificationKind.postLiked) &
            t.actorId.equals(actorId) &
            t.postId.equals(postId) &
            t.readAt.equals(null),
        transaction: transaction,
      );
      targets = targets.difference({for (final n in pending) n.userId});
      if (targets.isEmpty) return const [];
    }

    return UserNotification.db.insert(session, [
      for (final userId in targets)
        UserNotification(
          userId: userId,
          kind: kind,
          actorId: actorId,
          postId: postId,
          showId: showId,
        ),
    ], transaction: transaction);
  }

  /// Manda cada aviso a su destinatario. Se llama **después** del commit.
  Future<void> publish(Session session, List<UserNotification> rows) async {
    if (rows.isEmpty) return;
    final views = await _views(session, rows);
    for (final (i, row) in rows.indexed) {
      await session.messages.postMessage(
        NotificationChannels.user(row.userId),
        views[i],
      );
    }
  }

  // --- Lectura y marcas ----------------------------------------------------

  /// De la más nueva a la más vieja, de la cuenta de la sesión.
  Future<NotificationPage> list(
    Session session, {
    PageCursor? after,
    int? limit,
  }) async {
    final userId = session.requireUserId;
    final size = PostRules.pageSize(limit);
    final rows = await UserNotification.db.find(
      session,
      where: (t) {
        var where = t.userId.equals(userId);
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
    return NotificationPage(
      items: await _views(session, items),
      nextCursor: hasMore
          ? PageCursor(createdAt: items.last.createdAt, id: items.last.id!)
          : null,
    );
  }

  Future<int> unreadCount(Session session) {
    final userId = session.requireUserId;
    return UserNotification.db.count(
      session,
      where: (t) => t.userId.equals(userId) & t.readAt.equals(null),
    );
  }

  /// Marca [ids] como leídos. Sólo los propios: un id ajeno se ignora en vez
  /// de confirmar que existe. Devuelve los que quedan sin leer.
  Future<int> markRead(Session session, List<int> ids) async {
    final userId = session.requireUserId;
    if (ids.isNotEmpty) {
      await _markRead(
        session,
        (t) =>
            t.userId.equals(userId) &
            t.id.inSet(ids.toSet()) &
            t.readAt.equals(null),
      );
    }
    return unreadCount(session);
  }

  /// Marca todos, también los que la app todavía no cargó.
  Future<int> markAllRead(Session session) async {
    final userId = session.requireUserId;
    await _markRead(
      session,
      (t) => t.userId.equals(userId) & t.readAt.equals(null),
    );
    return 0;
  }

  // --- Internos ------------------------------------------------------------

  Future<void> _markRead(
    Session session,
    Expression Function(UserNotificationTable t) where,
  ) async {
    final now = DateTime.now().toUtc();
    final rows = await UserNotification.db.find(session, where: where);
    if (rows.isEmpty) return;
    await UserNotification.db.update(
      session,
      [for (final row in rows) row.copyWith(readAt: now)],
      columns: (t) => [t.readAt],
    );
  }

  /// Una consulta por tabla para toda la página: actores, posts y shows.
  Future<List<NotificationView>> _views(
    Session session,
    List<UserNotification> rows,
  ) async {
    if (rows.isEmpty) return const [];
    final actorIds = {for (final r in rows) ?r.actorId};
    final postIds = <int>{for (final r in rows) ?r.postId};
    final showIds = <int>{for (final r in rows) ?r.showId};

    final profiles = await profilesOf(session, actorIds);
    final avatars = await avatarsOf(session, actorIds);
    final posts = postIds.isEmpty
        ? const <int, Post>{}
        : {
            for (final post in await Post.db.find(
              session,
              where: (t) => t.id.inSet(postIds),
            ))
              post.id!: post,
          };
    final shows = showIds.isEmpty
        ? const <int, LiveShow>{}
        : {
            for (final show in await LiveShow.db.find(
              session,
              where: (t) => t.id.inSet(showIds),
            ))
              show.id!: show,
          };

    return [
      for (final row in rows)
        NotificationView(
          id: row.id!,
          kind: row.kind,
          actorId: row.actorId,
          actorUsername: profiles[row.actorId]?.userName,
          actorName: profiles[row.actorId]?.fullName,
          actorAvatarUrl: avatars[row.actorId],
          postId: row.postId,
          postExcerpt: _excerpt(posts[row.postId]),
          showId: row.showId,
          showTitle: shows[row.showId]?.title,
          isRead: row.readAt != null,
          createdAt: row.createdAt,
        ),
    ];
  }

  /// El principio del post, para dibujar el aviso. Uno borrado no se cita.
  static String? _excerpt(Post? post) {
    if (post == null || post.deletedAt != null) return null;
    final body = post.body.trim();
    if (body.isEmpty) return null;
    return body.length <= excerptLength
        ? body
        : '${body.substring(0, excerptLength).trimRight()}…';
  }
}
