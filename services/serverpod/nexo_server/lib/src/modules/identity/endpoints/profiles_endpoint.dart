import 'package:serverpod/serverpod.dart';

import '../../../generated/protocol.dart';
import '../services/identity_service.dart';

/// Perfiles de Nexo. Desde Flutter: `client.profiles`.
///
/// La primera llamada a [me] de una cuenta nueva le crea su perfil con un
/// nombre de usuario libre, así que la app siempre tiene algo que mostrar.
class ProfilesEndpoint extends Endpoint {
  static const _identity = IdentityService();

  /// La cuenta de la sesión, con sus roles. Exige sesión.
  Future<AccountView> me(Session session) => _identity.me(session);

  /// Cambia nombre de usuario, nombre visible o bio. Exige sesión.
  /// `conflict` si el nombre de usuario ya está en uso.
  Future<AccountView> update(Session session, ProfileEdit edit) =>
      _identity.update(session, edit);

  /// Declara la cuenta como creadora. La verificación la da un operador.
  Future<AccountView> becomeCreator(Session session) =>
      _identity.becomeCreator(session);

  /// El perfil público de [username]. Público: lo ve un invitado.
  Future<ProfileView> byUsername(Session session, String username) =>
      _identity.byUsername(session, username);
}
