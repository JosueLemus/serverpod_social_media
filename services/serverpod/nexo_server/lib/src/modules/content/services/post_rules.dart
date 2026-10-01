import 'package:serverpod/serverpod.dart';

import '../../../generated/protocol.dart';

/// Límites y normalización de un post. Reglas puras: no tocan la base.
abstract final class PostRules {
  static const maxBodyLength = 2200;
  static const maxTags = 10;
  static const maxTagLength = 30;
  static const maxMedia = 4;
  static const defaultPageSize = 20;
  static const maxPageSize = 50;

  /// Recorta espacios y rechaza un texto demasiado largo. Puede quedar vacío:
  /// un post con adjuntos no necesita texto.
  static String normalizeBody(String body) {
    final trimmed = body.trim();
    if (trimmed.length > maxBodyLength) {
      throw _invalid('El texto supera los $maxBodyLength caracteres.');
    }
    return trimmed;
  }

  /// Quita el `#` inicial y los repetidos (sin distinguir mayúsculas), y
  /// conserva el orden y la grafía de la primera aparición.
  static List<String> normalizeTags(List<String> tags) {
    final seen = <String>{};
    final result = <String>[];
    for (final raw in tags) {
      final tag = raw.trim().replaceFirst(RegExp('^#+'), '');
      if (tag.isEmpty) continue;
      if (tag.length > maxTagLength || tag.contains(RegExp(r'\s'))) {
        throw _invalid('Etiqueta no válida: "$raw".');
      }
      if (seen.add(tag.toLowerCase())) result.add(tag);
    }
    if (result.length > maxTags) {
      throw _invalid('Un post admite hasta $maxTags etiquetas.');
    }
    return result;
  }

  static int pageSize(int? requested) =>
      (requested ?? defaultPageSize).clamp(1, maxPageSize);

  static NexoException _invalid(String message) =>
      NexoException(code: NexoErrorCode.invalidInput, message: message);
}

/// Qué archivos se aceptan y dónde se guardan.
///
/// La clave la arma el servidor (`posts/<autor>/<tipo>/<uuid>.<ext>`) y nunca
/// el cliente: así, al publicar, la clave misma dice de quién es el archivo y
/// de qué tipo, sin una tabla de subidas pendientes.
abstract final class MediaPolicy {
  static const maxImageBytes = 10 * 1024 * 1024;
  static const maxVideoBytes = 50 * 1024 * 1024;

  static const _extensions = {
    PostMediaKind.image: {
      'image/jpeg': 'jpg',
      'image/png': 'png',
      'image/webp': 'webp',
      'image/gif': 'gif',
    },
    PostMediaKind.video: {
      'video/mp4': 'mp4',
      'video/quicktime': 'mov',
      'video/webm': 'webm',
    },
  };

  static int maxBytes(PostMediaKind kind) => switch (kind) {
    PostMediaKind.image => maxImageBytes,
    PostMediaKind.video => maxVideoBytes,
  };

  /// La extensión para [contentType], o `null` si ese tipo no se acepta como
  /// [kind].
  static String? extensionFor(PostMediaKind kind, String contentType) =>
      _extensions[kind]![contentType.toLowerCase()];

  static String newKey(UuidValue ownerId, PostMediaKind kind, String ext) =>
      'posts/$ownerId/${kind.name}/${const Uuid().v7()}.$ext';

  /// Descompone una clave armada por [newKey], o devuelve `null` si no lo es.
  static MediaKey? parseKey(String key) {
    final parts = key.split('/');
    if (parts.length != 4 || parts[0] != 'posts') return null;

    final kind = PostMediaKind.values.where((k) => k.name == parts[2]);
    if (kind.isEmpty) return null;

    final file = parts[3].split('.');
    if (file.length != 2 || _uuidOrNull(file[0]) == null) return null;

    final contentType = _extensions[kind.single]!.entries
        .where((e) => e.value == file[1])
        .map((e) => e.key)
        .firstOrNull;
    if (contentType == null) return null;

    final ownerId = _uuidOrNull(parts[1]);
    if (ownerId == null) return null;

    return MediaKey(
      ownerId: ownerId,
      kind: kind.single,
      contentType: contentType,
    );
  }

  static UuidValue? _uuidOrNull(String value) {
    try {
      return UuidValue.withValidation(value);
    } on FormatException {
      return null;
    }
  }
}

class MediaKey {
  const MediaKey({
    required this.ownerId,
    required this.kind,
    required this.contentType,
  });

  final UuidValue ownerId;
  final PostMediaKind kind;
  final String contentType;
}
