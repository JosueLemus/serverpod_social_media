import 'package:nexo_server/src/generated/protocol.dart';
import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_idp_server/core.dart';
import 'package:test/test.dart';

import '../test_tools/serverpod_test_tools.dart';

/// Falla salvo que el Future lance [NexoException] con [code].
Matcher throwsNexo(NexoErrorCode code) =>
    throwsA(isA<NexoException>().having((e) => e.code, 'code', code));

/// Cuentas de prueba con perfil y las sesiones para actuar como ellas.
class Fixtures {
  Fixtures(this._sessionBuilder) : session = _sessionBuilder.build();

  final TestSessionBuilder _sessionBuilder;

  /// Para sembrar y leer la base directamente.
  final Session session;

  TestSessionBuilder get guest => _sessionBuilder.copyWith(
    authentication: AuthenticationOverride.unauthenticated(),
  );

  TestSessionBuilder signedIn(UuidValue id, [Set<Scope> scopes = const {}]) =>
      _sessionBuilder.copyWith(
        authentication: AuthenticationOverride.authenticationInfo(
          '$id',
          scopes,
        ),
      );

  Future<UuidValue> seedUser(String userName, String fullName) async {
    final user = await AuthUser.db.insertRow(session, AuthUser(scopeNames: {}));
    await UserProfile.db.insertRow(
      session,
      UserProfile(authUserId: user.id!, userName: userName, fullName: fullName),
    );
    return user.id!;
  }

  PostDraft draft(
    String body, {
    PostVisibility visibility = PostVisibility.public,
    bool allowComments = true,
    List<String> mediaKeys = const [],
    List<String> tags = const [],
  }) => PostDraft(
    body: body,
    tags: tags,
    visibility: visibility,
    allowComments: allowComments,
    mediaKeys: mediaKeys,
  );
}
