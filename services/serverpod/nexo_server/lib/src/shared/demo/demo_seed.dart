import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_idp_server/core.dart';

import '../../generated/protocol.dart';
import '../auth/auth_context.dart';

/// Crea la contraseña de una cuenta. En el servidor es el admin del
/// proveedor de email de Serverpod; en los tests, un registro.
typedef CreateCredentials =
    Future<void> Function(
      Session session,
      UuidValue authUserId,
      String email,
      String password,
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
        await _createCredentials(session, id, account.email, password);
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
}
