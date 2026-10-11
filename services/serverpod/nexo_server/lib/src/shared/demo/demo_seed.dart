import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_idp_server/core.dart';

import '../../generated/protocol.dart';
import '../auth/auth_context.dart';

/// Crea la contraseña de una cuenta. En el servidor es el admin del
/// proveedor de email de Serverpod; en los tests, un registro.
///
/// Recibe la transacción que está creando al usuario: la cuenta de email
/// apunta a `AuthUser` por foreign key, y fuera de esa transacción el usuario
/// todavía no existe.
typedef CreateCredentials =
    Future<void> Function(
      Session session,
      UuidValue authUserId,
      String email,
      String password,
      Transaction transaction,
    );

class DemoAccount {
  const DemoAccount({
    required this.email,
    required this.username,
    required this.name,
    this.scopes = const {},
    this.isCreator = false,
  });

  final String email;
  final String username;
  final String name;
  final Set<Scope> scopes;
  final bool isCreator;
}

/// Las cuentas y el contenido con los que arranca la demo local.
///
/// **Idempotente**: correrlo dos veces no duplica nada. Lo dispara
/// `tool/demo.sh` con `NEXO_DEMO_SEED=1` y **sólo en desarrollo** (lo
/// comprueba `server.dart`): en producción nadie recibe el scope `admin`
/// por una variable de entorno.
///
/// Los correos son los mismos del selector de cuentas demo de la app, así
/// el atajo de login sirve también contra el servidor real.
class DemoSeed {
  const DemoSeed(this._createCredentials);

  final CreateCredentials _createCredentials;

  /// La contraseña de todas las cuentas demo. Está en el README: es una
  /// demo local, no un secreto.
  static const password = 'nexo-demo-2026';

  static final accounts = [
    const DemoAccount(
      email: 'elena@nexo.demo',
      username: 'elena_ux',
      name: 'Elena Vega',
      isCreator: true,
    ),
    const DemoAccount(
      email: 'carlos@nexo.demo',
      username: 'carlos_mendez',
      name: 'Carlos Méndez',
      isCreator: true,
    ),
    DemoAccount(
      email: 'operador@nexo.demo',
      username: 'nexo_ops',
      name: 'Operaciones Nexo',
      scopes: {NexoScopes.admin},
    ),
    DemoAccount(
      email: 'moderador@nexo.demo',
      username: 'mod_lucia',
      name: 'Lucía Moderadora',
      scopes: {NexoScopes.moderator},
    ),
    const DemoAccount(
      email: 'tomas@nexo.demo',
      username: 'tomas',
      name: 'Tomás Ríos',
    ),
    const DemoAccount(
      email: 'troll@nexo.demo',
      username: 'troll_99',
      name: 'Troll 99',
    ),
  ];

  /// Devuelve cuántas cuentas creó (0 si ya estaban todas).
  Future<int> run(Session session) async {
    var created = 0;
    final ids = <String, UuidValue>{};
    for (final account in accounts) {
      final existing = await AccountProfile.db.findFirstRow(
        session,
        where: (t) => t.username.equals(account.username),
      );
      if (existing != null) {
        ids[account.username] = existing.authUserId;
        continue;
      }
      ids[account.username] = await _createAccount(session, account);
      created++;
    }
    await _seedContent(session, ids);
    await _seedLive(session, ids);
    await _seedFollows(session, ids);
    return created;
  }

  Future<UuidValue> _createAccount(Session session, DemoAccount account) =>
      session.db.transaction((tx) async {
        final user = await AuthUser.db.insertRow(
          session,
          AuthUser(scopeNames: {for (final s in account.scopes) s.name!}),
          transaction: tx,
        );
        final id = user.id!;
        await UserProfile.db.insertRow(
          session,
          UserProfile(
            authUserId: id,
            userName: account.username,
            fullName: account.name,
            email: account.email,
          ),
          transaction: tx,
        );
        await AccountProfile.db.insertRow(
          session,
          AccountProfile(
            authUserId: id,
            username: account.username,
            isCreator: account.isCreator,
            // Los creadores de la demo llegan verificados: es lo que les
            // permite iniciar un vivo. Revocarlo es parte del guion.
            verification: account.isCreator
                ? VerificationStatus.verified
                : VerificationStatus.none,
          ),
          transaction: tx,
        );
        await _createCredentials(session, id, account.email, password, tx);
        return id;
      });

  /// Publicaciones de texto para que el feed no arranque vacío. Sólo si el
  /// autor todavía no publicó nada: no se repiten en cada arranque.
  Future<void> _seedContent(
    Session session,
    Map<String, UuidValue> ids,
  ) async {
    final elena = ids['elena_ux']!;
    final carlos = ids['carlos_mendez']!;
    final troll = ids['troll_99']!;

    final elenaPosts = await Post.db.count(
      session,
      where: (t) => t.authorId.equals(elena),
    );
    if (elenaPosts > 0) return;

    await session.db.transaction((tx) async {
      final first = await Post.db.insertRow(
        session,
        Post(
          authorId: elena,
          body:
              'Rediseñando la experiencia de micro-comunidades. ¿Qué parte de '
              'tu comunidad quieres hacer más humana?',
          tags: ['uiux', 'comunidades'],
          visibility: PostVisibility.public,
          commentCount: 1,
        ),
        transaction: tx,
      );
      await Post.db.insertRow(
        session,
        Post(
          authorId: elena,
          body: 'Esta noche: masterclass de diseño mobile en vivo. ¿Vienen?',
          tags: ['designsystems', 'envivo'],
          visibility: PostVisibility.public,
        ),
        transaction: tx,
      );
      await Post.db.insertRow(
        session,
        Post(
          authorId: carlos,
          body:
              'Tokens de diseño en Flutter: del Figma al ThemeData sin '
              'copiar a mano.',
          tags: ['flutterdev', 'designsystems'],
          visibility: PostVisibility.public,
        ),
        transaction: tx,
      );
      // Un comentario para reportar en el guion de la demo.
      await PostComment.db.insertRow(
        session,
        PostComment(
          postId: first.id!,
          authorId: troll,
          body: 'Esto no aporta nada a la conversación, ándate de aquí',
        ),
        transaction: tx,
      );
    });
  }

  /// Dos shows programados y un replay. Nada "al aire": un vivo al aire sin
  /// nadie transmitiendo es justo el mock que esto reemplaza. Guarda propia:
  /// la de los posts hace `return` y lo saltearía en el segundo arranque.
  Future<void> _seedLive(Session session, Map<String, UuidValue> ids) async {
    final elena = ids['elena_ux']!;
    final carlos = ids['carlos_mendez']!;
    final tomas = ids['tomas']!;
    final troll = ids['troll_99']!;

    final elenaShows = await LiveShow.db.count(
      session,
      where: (t) => t.hostId.equals(elena),
    );
    if (elenaShows > 0) return;

    final now = DateTime.now().toUtc();
    await session.db.transaction((tx) async {
      await LiveShow.db.insert(session, [
        LiveShow(
          hostId: elena,
          title: 'Masterclass de Diseño Mobile',
          description:
              'Cómo pasar de un mockup a un design system que el equipo '
              'pueda mantener.',
          startsAt: now.add(const Duration(hours: 1)),
          durationMinutes: 60,
          access: LiveShowAccess.public,
          status: LiveShowStatus.scheduled,
        ),
        LiveShow(
          hostId: carlos,
          title: 'Flutter en vivo: tokens de diseño',
          description: 'Del Figma al ThemeData sin copiar a mano.',
          startsAt: now.add(const Duration(days: 1)),
          durationMinutes: 45,
          access: LiveShowAccess.public,
          status: LiveShowStatus.scheduled,
        ),
      ], transaction: tx);

      final startedAt = now.subtract(const Duration(days: 2));
      final replay = await LiveShow.db.insertRow(
        session,
        LiveShow(
          hostId: elena,
          title: 'Q&A: portfolio de producto',
          description:
              'Preguntas de la comunidad sobre cómo armar un '
              'portfolio de diseño de producto.',
          startsAt: startedAt,
          durationMinutes: 45,
          access: LiveShowAccess.public,
          status: LiveShowStatus.published,
          startedAt: startedAt,
          endedAt: startedAt.add(const Duration(minutes: 47)),
          endedBy: elena,
          viewerPeak: 312,
        ),
        transaction: tx,
      );
      await LiveChatMessage.db.insert(session, [
        LiveChatMessage(
          showId: replay.id!,
          authorId: tomas,
          body: '¿Cuántos proyectos recomiendas mostrar?',
          createdAt: startedAt.add(const Duration(minutes: 5)),
        ),
        LiveChatMessage(
          showId: replay.id!,
          authorId: carlos,
          body: 'Gran sesión, gracias Elena 🙌',
          createdAt: startedAt.add(const Duration(minutes: 30)),
        ),
        LiveChatMessage(
          showId: replay.id!,
          authorId: troll,
          body: 'Aburrido, nadie mira esto',
          createdAt: startedAt.add(const Duration(minutes: 31)),
        ),
      ], transaction: tx);
    });
  }

  /// El grafo de la demo: Tomás y Troll siguen a Elena, y Elena y Carlos se
  /// siguen entre sí. Guarda propia, como [_seedLive]: si Tomás ya sigue a
  /// Elena, no hace nada.
  Future<void> _seedFollows(Session session, Map<String, UuidValue> ids) async {
    final elena = ids['elena_ux']!;
    final carlos = ids['carlos_mendez']!;
    final tomas = ids['tomas']!;
    final troll = ids['troll_99']!;

    final seeded = await Follow.db.count(
      session,
      where: (t) => t.followerId.equals(tomas) & t.followeeId.equals(elena),
    );
    if (seeded > 0) return;

    const pairs = <(String, String)>[
      ('tomas', 'elena_ux'),
      ('troll_99', 'elena_ux'),
      ('elena_ux', 'carlos_mendez'),
      ('carlos_mendez', 'elena_ux'),
    ];
    await session.db.transaction((tx) async {
      await Follow.db.insert(session, [
        for (final (follower, followee) in pairs)
          Follow(followerId: ids[follower]!, followeeId: ids[followee]!),
      ], transaction: tx);
      // Los contadores se recalculan desde las filas: la semilla no tiene
      // que saber cuántos había antes.
      for (final id in {elena, carlos, tomas, troll}) {
        final account = (await AccountProfile.db.findFirstRow(
          session,
          where: (t) => t.authUserId.equals(id),
          transaction: tx,
        ))!;
        await AccountProfile.db.updateRow(
          session,
          account.copyWith(
            followerCount: await Follow.db.count(
              session,
              where: (t) => t.followeeId.equals(id),
              transaction: tx,
            ),
            followingCount: await Follow.db.count(
              session,
              where: (t) => t.followerId.equals(id),
              transaction: tx,
            ),
          ),
          columns: (t) => [t.followerCount, t.followingCount],
          transaction: tx,
        );
      }

      // La bandeja de Elena no arranca vacía: sus dos seguidores nuevos y un
      // like real (con su fila y su contador) a su último post.
      final notices = [
        UserNotification(
          userId: elena,
          kind: NotificationKind.newFollower,
          actorId: tomas,
        ),
        UserNotification(
          userId: elena,
          kind: NotificationKind.newFollower,
          actorId: troll,
        ),
      ];
      final latest = await Post.db.findFirstRow(
        session,
        where: (t) => t.authorId.equals(elena) & t.deletedAt.equals(null),
        orderByList: (t) => [t.createdAt.desc()],
        transaction: tx,
      );
      if (latest != null) {
        final liked = await PostLike.db.count(
          session,
          where: (t) => t.postId.equals(latest.id!) & t.userId.equals(tomas),
          transaction: tx,
        );
        if (liked == 0) {
          await PostLike.db.insertRow(
            session,
            PostLike(postId: latest.id!, userId: tomas),
            transaction: tx,
          );
          await Post.db.updateRow(
            session,
            latest.copyWith(likeCount: latest.likeCount + 1),
            columns: (t) => [t.likeCount],
            transaction: tx,
          );
        }
        notices.add(
          UserNotification(
            userId: elena,
            kind: NotificationKind.postLiked,
            actorId: tomas,
            postId: latest.id,
          ),
        );
      }
      await UserNotification.db.insert(session, notices, transaction: tx);
    });
  }
}
