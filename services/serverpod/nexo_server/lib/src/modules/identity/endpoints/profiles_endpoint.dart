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

  /// Cambia nombre de usuario, nombre visible, bio o enlace. Exige sesión.
  /// `conflict` si el nombre de usuario ya está en uso.
  Future<AccountView> update(Session session, ProfileEdit edit) =>
      _identity.update(session, edit);

  /// El permiso para subir un avatar: JPEG, PNG o WebP de hasta 5 MB. Se
  /// sube con `FileUploader(ticket.uploadDescription)` y se confirma con
  /// [setAvatar]. Exige sesión.
  Future<MediaUploadTicket> requestAvatarUpload(
    Session session, {
    required String contentType,
    required int sizeBytes,
  }) => _identity.requestAvatarUpload(
    session,
    contentType: contentType,
    sizeBytes: sizeBytes,
  );

  /// Confirma el avatar subido con [key], o lo quita con `null`. La clave
  /// tiene que ser de esta cuenta. Exige sesión.
  Future<AccountView> setAvatar(Session session, String? key) =>
      _identity.setAvatar(session, key);

  /// El permiso para subir el banner del perfil: JPEG, PNG o WebP de hasta
  /// 8 MB. Se sube con `FileUploader(ticket.uploadDescription)` y se confirma
  /// con [setCover]. Exige sesión.
  Future<MediaUploadTicket> requestCoverUpload(
    Session session, {
    required String contentType,
    required int sizeBytes,
  }) => _identity.requestCoverUpload(
    session,
    contentType: contentType,
    sizeBytes: sizeBytes,
  );

  /// Confirma el banner subido con [key], o lo quita con `null`. La clave
  /// tiene que ser de esta cuenta. Exige sesión.
  Future<AccountView> setCover(Session session, String? key) =>
      _identity.setCover(session, key);

  /// Declara la cuenta como creadora. La verificación la da un operador.
  Future<AccountView> becomeCreator(Session session) =>
      _identity.becomeCreator(session);

  /// El perfil público de [username]. Público: lo ve un invitado.
  Future<ProfileView> byUsername(Session session, String username) =>
      _identity.byUsername(session, username);
}
