import 'package:serverpod/serverpod.dart';

/// Qué se acepta como avatar y cómo se nombra en el storage. Mismo esquema
/// que los adjuntos de posts (`MediaPolicy`): la clave la arma el servidor y
/// lleva el dueño adentro, así nadie confirma como propio un archivo ajeno.
abstract final class AvatarPolicy {
  static const maxBytes = 5 * 1024 * 1024;

  static const _extensions = {
    'image/jpeg': 'jpg',
    'image/png': 'png',
    'image/webp': 'webp',
  };

  /// La extensión para [contentType], o `null` si no se acepta.
  static String? extensionFor(String contentType) =>
      _extensions[contentType.toLowerCase()];

  static String newKey(UuidValue ownerId, String ext) =>
      'avatars/$ownerId/${const Uuid().v7()}.$ext';

  /// El dueño de una clave armada por [newKey], o `null` si no lo es.
  static UuidValue? ownerOf(String key) {
    final parts = key.split('/');
    if (parts.length != 3 || parts[0] != 'avatars') return null;
    final file = parts[2].split('.');
    if (file.length != 2 || !_extensions.containsValue(file[1])) return null;
    if (_uuidOrNull(file[0]) == null) return null;
    return _uuidOrNull(parts[1]);
  }

  static UuidValue? _uuidOrNull(String value) {
    try {
      return UuidValue.withValidation(value);
    } on FormatException {
      return null;
    }
  }
}
