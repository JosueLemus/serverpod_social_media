import 'package:serverpod/serverpod.dart';

/// Qué se acepta como imagen de perfil (avatar o banner) y cómo se nombra en
/// el storage. Mismo esquema que los adjuntos de posts (`MediaPolicy`): la
/// clave la arma el servidor y lleva el dueño adentro, así nadie confirma
/// como propio un archivo ajeno.
final class ProfileImagePolicy {
  const ProfileImagePolicy._({
    required this.folder,
    required this.maxBytes,
    required this.label,
  });

  /// El avatar: chico, se dibuja en círculos de 24 a 120 px.
  static const avatar = ProfileImagePolicy._(
    folder: 'avatars',
    maxBytes: 5 * 1024 * 1024,
    label: 'El avatar',
  );

  /// El banner: ancho, ocupa todo el encabezado del perfil.
  static const cover = ProfileImagePolicy._(
    folder: 'covers',
    maxBytes: 8 * 1024 * 1024,
    label: 'El banner',
  );

  final String folder;
  final int maxBytes;

  /// Cómo se nombra en los mensajes de error ("El avatar supera…").
  final String label;

  static const _extensions = {
    'image/jpeg': 'jpg',
    'image/png': 'png',
    'image/webp': 'webp',
  };

  /// La extensión para [contentType], o `null` si no se acepta.
  String? extensionFor(String contentType) =>
      _extensions[contentType.toLowerCase()];

  String newKey(UuidValue ownerId, String ext) =>
      '$folder/$ownerId/${const Uuid().v7()}.$ext';

  /// El dueño de una clave armada por [newKey], o `null` si no lo es (otra
  /// carpeta, otro formato o un id inválido).
  UuidValue? ownerOf(String key) {
    final parts = key.split('/');
    if (parts.length != 3 || parts[0] != folder) return null;
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
