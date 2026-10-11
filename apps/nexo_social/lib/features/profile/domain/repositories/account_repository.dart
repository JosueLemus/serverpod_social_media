import '../../../feed/domain/entities/post_extras.dart';
import '../entities/profile_changes.dart';

/// La cuenta de la sesión: editar el perfil, la foto y volverse creador.
///
/// Errores: `ConflictFailure` si el nombre de usuario ya está tomado,
/// `ServerFailure` si el servidor rechaza los datos, `NetworkFailure` sin
/// red, `AccountSuspendedFailure` si la cuenta está sancionada.
abstract interface class AccountRepository {
  Future<void> update(ProfileChanges changes);

  /// Sube [image] y la deja como foto de perfil. Null la quita.
  Future<void> setAvatar(MediaAttachment? image);

  /// Ser creador es autoservicio (D14); verificar es del operador.
  Future<void> becomeCreator();
}
