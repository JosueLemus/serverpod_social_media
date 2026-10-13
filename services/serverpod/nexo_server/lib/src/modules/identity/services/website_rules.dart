/// El enlace propio de un perfil: una URL http o https, de hasta
/// [maxLength] caracteres.
///
/// Se acepta sin esquema (`nexo.dev/elena`) y se guarda con `https://`
/// adelante: es como lo escribe la gente, y un enlace sin esquema no se
/// puede abrir.
abstract final class WebsiteRules {
  static const maxLength = 200;

  /// [value] listo para guardar, o `null` si queda vacío (quita el enlace).
  static String? normalize(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    final hasScheme = RegExp(
      r'^[a-zA-Z][a-zA-Z0-9+.-]*://',
    ).hasMatch(trimmed);
    return hasScheme ? trimmed : 'https://$trimmed';
  }

  /// Por qué [url] (ya normalizada) no sirve, o `null` si sirve.
  static String? problemWith(String url) {
    if (url.length > maxLength) {
      return 'El enlace supera los $maxLength caracteres.';
    }
    if (url.contains(RegExp(r'\s'))) {
      return 'El enlace no puede tener espacios.';
    }
    final uri = Uri.tryParse(url);
    if (uri == null ||
        !(uri.scheme == 'http' || uri.scheme == 'https') ||
        uri.host.isEmpty ||
        !uri.host.contains('.')) {
      return 'Ese enlace no es válido.';
    }
    return null;
  }
}
