/// Las reacciones efímeras del vivo (D7 del SDD 0011).
///
/// Son **cinco fijas**, no un emoji libre: el repertorio chico es lo que las
/// hace legibles sobre video a 24 px, y lo que deja al servidor contar
/// categorías tipadas en vez de todo el repertorio Unicode. El contrato las
/// publica como enum también.
///
/// No se persisten: nadie puede volver a leer una reacción pasada. Lo único
/// que se registra es la cuenta agregada en la métrica del vivo (pendiente,
/// no bloquea).
enum LiveReactionKind {
  heart,
  fire,
  laugh,
  clap,
  hundred;

  /// El glifo Unicode que la hoja y el overlay pintan. No es un asset: cinco
  /// imágenes propias para cinco emoticonos duplican lo que la fuente del
  /// sistema ya trae con buen contraste sobre video.
  String get emoji => switch (this) {
    LiveReactionKind.heart => '❤️',
    LiveReactionKind.fire => '🔥',
    LiveReactionKind.laugh => '😂',
    LiveReactionKind.clap => '👏',
    LiveReactionKind.hundred => '💯',
  };

  /// Etiqueta para accesibilidad. "Corazón" / "Fuego" / "Risa" / "Aplausos" /
  /// "Cien". El emoji por su cuenta lo lee el screen reader como "corazón
  /// rojo pesado", que no es la convención del idioma.
  String get semanticLabel => switch (this) {
    LiveReactionKind.heart => 'Corazón',
    LiveReactionKind.fire => 'Fuego',
    LiveReactionKind.laugh => 'Risa',
    LiveReactionKind.clap => 'Aplausos',
    LiveReactionKind.hundred => 'Cien',
  };
}
