/// Reglas puras del buscador: cómo se normaliza el texto, cuándo alcanza para
/// buscar y cómo se arma el patrón de `ILIKE`.
abstract final class SearchRules {
  /// Con menos letras, "a" coincide con media base y la respuesta no ayuda.
  static const minLength = 2;
  static const defaultLimit = 10;
  static const maxLimit = 20;

  /// El texto que se busca: sin espacios de más, en minúsculas y sin el `@`
  /// o `#` inicial, que la persona escribe por costumbre.
  static String normalize(String text) {
    var value = text.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
    while (value.startsWith('@') || value.startsWith('#')) {
      value = value.substring(1).trimLeft();
    }
    return value;
  }

  static bool isSearchable(String normalized) => normalized.length >= minLength;

  static int limit(int? requested) =>
      (requested ?? defaultLimit).clamp(1, maxLimit);

  /// `%texto%` con los comodines de `LIKE` escapados: si no, buscar `%` o `_`
  /// coincidiría con todo. El escape es la barra invertida, el de Postgres
  /// por defecto.
  static String containsPattern(String normalized) =>
      '%${escapeLike(normalized)}%';

  static String escapeLike(String value) => value
      .replaceAll(r'\', r'\\')
      .replaceAll('%', r'\%')
      .replaceAll('_', r'\_');

  /// Primero lo que empieza con el texto (o alguna de sus palabras), después
  /// lo que sólo lo contiene: quien escribe "ele" busca a Elena antes que a
  /// "Ariel Ele".
  static bool isPrefixMatch(String normalized, Iterable<String?> fields) {
    for (final field in fields) {
      if (field == null) continue;
      final value = field.toLowerCase();
      if (value.startsWith(normalized)) return true;
      if (value
          .split(RegExp(r'[\s._-]+'))
          .any((w) => w.startsWith(normalized))) {
        return true;
      }
    }
    return false;
  }
}
