/// Reglas puras del buscador: cómo se normaliza el texto, cuándo alcanza para
/// buscar y cómo se arma el patrón de `ILIKE`.
///
/// La búsqueda ignora tildes: quien escribe "jose" busca a José, y en un
/// teclado de teléfono la tilde es lo primero que se omite. Se pliegan los
/// dos lados —el patrón en Dart ([fold]) y la columna en SQL ([foldSql])—
/// con la misma tabla, así que no pueden separarse.
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
  ///
  /// El texto se pliega antes de escapar ([fold]): la columna se compara
  /// plegada ([foldSql]), y un patrón con tildes no coincidiría con nada.
  static String containsPattern(String normalized) =>
      '%${escapeLike(fold(normalized))}%';

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
      final text = fold(normalized);
      final value = fold(field.toLowerCase());
      if (value.startsWith(text)) return true;
      if (value.split(RegExp(r'[\s._-]+')).any((w) => w.startsWith(text))) {
        return true;
      }
    }
    return false;
  }

  /// Cada letra con diacrítico y su letra base. Las marcas combinables (una
  /// tilde escrita aparte, como la deja un texto en NFD) van a la cadena
  /// vacía: se borran. Sólo minúsculas y mayúsculas latinas: en una base con
  /// locale `C`, `lower()` de Postgres no toca lo que no es ASCII, así que
  /// las mayúsculas acentuadas se pliegan acá y no se dejan a `lower()`.
  static const _folds = {
    'á': 'a', 'à': 'a', 'ä': 'a', 'â': 'a', 'ã': 'a', 'å': 'a', //
    'é': 'e', 'è': 'e', 'ë': 'e', 'ê': 'e', //
    'í': 'i', 'ì': 'i', 'ï': 'i', 'î': 'i', //
    'ó': 'o', 'ò': 'o', 'ö': 'o', 'ô': 'o', 'õ': 'o', //
    'ú': 'u', 'ù': 'u', 'ü': 'u', 'û': 'u', //
    'ñ': 'n', 'ç': 'c', //
    'Á': 'a', 'À': 'a', 'Ä': 'a', 'Â': 'a', 'Ã': 'a', 'Å': 'a', //
    'É': 'e', 'È': 'e', 'Ë': 'e', 'Ê': 'e', //
    'Í': 'i', 'Ì': 'i', 'Ï': 'i', 'Î': 'i', //
    'Ó': 'o', 'Ò': 'o', 'Ö': 'o', 'Ô': 'o', 'Õ': 'o', //
    'Ú': 'u', 'Ù': 'u', 'Ü': 'u', 'Û': 'u', //
    'Ñ': 'n', 'Ç': 'c', //
    '\u0300': '', '\u0301': '', '\u0302': '', '\u0303': '', '\u0308': '', //
  };

  /// [text] sin diacríticos: con [normalize] antes, "José" queda "jose".
  /// Es exactamente lo que hace [foldSql] del lado de la base.
  static String fold(String text) {
    final out = StringBuffer();
    for (final rune in text.runes) {
      final char = String.fromCharCode(rune);
      out.write(_folds[char] ?? char);
    }
    return out.toString();
  }

  /// La [column] plegada en SQL, para comparar con [containsPattern]:
  /// `translate` con la misma tabla que [fold], después de `lower()`. Sin la
  /// extensión `unaccent`, que pediría una migración y permisos de
  /// superusuario en la base. Las marcas combinables van al final del
  /// origen y sin pareja en el destino, que es como `translate` las borra.
  ///
  /// [column] es una expresión escrita en el código, nunca texto del
  /// usuario: lo de afuera viaja como parámetro.
  static String foldSql(String column) =>
      "translate(lower($column), '$_sqlFrom', '$_sqlTo')";

  static final _sqlFrom = [
    ..._folds.entries.where((e) => e.value.isNotEmpty).map((e) => e.key),
    ..._folds.entries.where((e) => e.value.isEmpty).map((e) => e.key),
  ].join();

  static final _sqlTo = _folds.values.where((v) => v.isNotEmpty).join();
}
