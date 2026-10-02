import 'post.dart';

/// Qué archivos se pueden publicar. Espeja `MediaPolicy` del servidor, que
/// es quien decide de verdad: esto sólo evita esperar la subida de un video
/// de 80 MB para enterarse de que no entra.
abstract final class MediaRules {
  static const imageTypes = {
    'image/jpeg',
    'image/png',
    'image/webp',
    'image/gif',
  };
  static const videoTypes = {'video/mp4', 'video/quicktime', 'video/webm'};

  static const maxImageBytes = 10 * 1024 * 1024;
  static const maxVideoBytes = 50 * 1024 * 1024;

  static int maxBytes(PostMedia kind) =>
      kind == PostMedia.video ? maxVideoBytes : maxImageBytes;

  static bool accepts(PostMedia kind, String contentType) =>
      (kind == PostMedia.video ? videoTypes : imageTypes).contains(
        contentType.toLowerCase(),
      );

  /// Las etiquetas del texto: `#Diseño` → `diseño`. Hasta 10, de hasta 30
  /// caracteres, sin repetir: los mismos límites que el servidor.
  static List<String> tagsIn(String text) {
    final tags = <String>{};
    for (final match in RegExp(
      r'#([\p{L}\p{N}_]+)',
      unicode: true,
    ).allMatches(text)) {
      final tag = match.group(1)!.toLowerCase();
      if (tag.length <= 30) tags.add(tag);
      if (tags.length == 10) break;
    }
    return tags.toList();
  }
}
