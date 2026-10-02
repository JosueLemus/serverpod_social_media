/// Qué es un nombre de usuario válido y cómo se propone uno.
///
/// Minúsculas, números y guion bajo; de 3 a 24 caracteres. Sin puntos ni
/// guiones: `elena.ux` y `elena-ux` se leen igual que `elena_ux` y abren la
/// puerta a suplantar a alguien con un carácter que nadie mira.
abstract final class UsernameRules {
  static const minLength = 3;
  static const maxLength = 24;
  static const maxDisplayNameLength = 50;
  static const maxBioLength = 160;

  static final _valid = RegExp(r'^[a-z0-9_]+$');

  /// Nombres que no se le dan a nadie: confundirían a quien lee un perfil o
  /// una entrada de auditoría.
  static const reserved = {
    'admin',
    'administrador',
    'moderador',
    'moderator',
    'nexo',
    'operador',
    'soporte',
    'support',
    'sistema',
    'system',
  };

  static String normalize(String value) => value.trim().toLowerCase();

  /// Null si [username] (ya normalizado) es válido; si no, el motivo.
  static String? problemWith(String username) {
    if (username.length < minLength || username.length > maxLength) {
      return 'El nombre de usuario debe tener entre $minLength y $maxLength '
          'caracteres.';
    }
    if (!_valid.hasMatch(username)) {
      return 'Solo se permiten minúsculas, números y guion bajo.';
    }
    if (reserved.contains(username)) {
      return 'Ese nombre de usuario está reservado.';
    }
    return null;
  }

  /// Una base válida a partir de lo que se sabe de la cuenta (su nombre o la
  /// parte local del correo). Puede chocar con otra: quien la usa le agrega
  /// un sufijo hasta que quede libre.
  static String suggestFrom(String? source) {
    final raw = (source ?? '').split('@').first.toLowerCase();
    var base = raw
        .replaceAll(RegExp(r'[áàä]'), 'a')
        .replaceAll(RegExp(r'[éèë]'), 'e')
        .replaceAll(RegExp(r'[íìï]'), 'i')
        .replaceAll(RegExp(r'[óòö]'), 'o')
        .replaceAll(RegExp(r'[úùü]'), 'u')
        .replaceAll('ñ', 'n')
        .replaceAll(RegExp(r'[^a-z0-9_]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    // Deja lugar para un sufijo numérico sin pasarse del máximo.
    if (base.length > maxLength - 4) base = base.substring(0, maxLength - 4);
    if (base.length < minLength || reserved.contains(base)) {
      base = 'usuario${base.isEmpty ? '' : '_$base'}';
      if (base.length > maxLength - 4) base = base.substring(0, maxLength - 4);
    }
    return base;
  }
}
