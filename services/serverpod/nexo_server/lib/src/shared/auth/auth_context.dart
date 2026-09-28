import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_idp_server/core.dart';

import '../../generated/protocol.dart';

/// Scopes globales guardados en el usuario de Serverpod.
/// `creator` no es un scope: vive en el perfil.
abstract final class NexoScopes {
  static const moderator = Scope('moderator');
  static const admin = Scope('admin');
}

extension AuthContext on Session {
  /// Id del usuario autenticado, o `null` si es un invitado.
  UuidValue? get userIdOrNull => authenticated?.authUserId;

  /// Id del usuario autenticado; lanza [NexoException] si es un invitado.
  UuidValue get requireUserId {
    final id = userIdOrNull;
    if (id == null) {
      throw NexoException(
        code: NexoErrorCode.unauthenticated,
        message: 'Debes iniciar sesión.',
      );
    }
    return id;
  }

  bool hasScope(Scope scope) => authenticated?.scopes.contains(scope) ?? false;
}
