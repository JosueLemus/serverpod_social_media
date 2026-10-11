import 'package:flutter/material.dart';

/// La paleta de Nexo: una **plancha de stickers**.
///
/// El suelo es el liner negro sobre el que vienen pegados los stickers. Cada
/// sticker se corta como el gato del logo: relleno blanco, contorno de tinta y
/// borde troquelado. Los colores de vinilo salen del borde holográfico del
/// logo, y el holo en sí está reservado para lo que está **al aire**.
///
/// Todo color de la app sale de acá: nunca hex crudo, nunca `Colors.X`. Un
/// literal suelto es invisible a un cambio de tema, y así es como dos
/// pantallas terminan con dos negros apenas distintos.
///
/// Única excepción: el color de marca de un tercero (el azul de Google en el
/// botón de identidad). Es suyo, no nuestro, y no se re-tematiza.
abstract final class AppColors {
  // ── El liner ──────────────────────────────────────────────────────────────
  /// El negro de la plancha. Es el suelo de toda la app.
  static const liner = Color(0xFF0F0F12);

  /// Una hoja apoyada sobre el liner: paneles, hojas inferiores, tarjetas.
  static const linerRaised = Color(0xFF18181D);

  /// Un paso más arriba: campos, controles en reposo, filas presionadas.
  static const linerHigh = Color(0xFF23232B);

  // ── El sticker ────────────────────────────────────────────────────────────
  /// El relleno de un sticker. Es la acción principal: un CTA es un sticker
  /// blanco con tinta encima.
  static const sticker = Color(0xFFFFFFFF);

  /// La tinta: el contorno grueso del gato y el texto sobre un sticker.
  static const ink = Color(0xFF0F0F12);

  /// Texto secundario **sobre un sticker blanco**. El gris de [textSecondary]
  /// está pensado para el liner y sobre blanco no llega al contraste.
  static const inkSecondary = Color(0xFF57555F);

  // ── Vinilos, sacados del borde holográfico del logo ───────────────────────
  static const vinylCyan = Color(0xFF3FE0F2);
  static const vinylBlue = Color(0xFF4F7BFF);
  static const vinylViolet = Color(0xFF9B5CFF);
  static const vinylMagenta = Color(0xFFE24CF2);
  static const vinylLime = Color(0xFFC9F24A);
  static const vinylGreen = Color(0xFF3EE58C);

  /// El foil holográfico del logo, en el orden en que gira alrededor del gato.
  /// **Sólo para lo que está al aire** y para la marca: un borde holo dice
  /// "está pasando ahora", y gastarlo en decoración le quita el significado.
  static const holo = <Color>[
    vinylCyan,
    vinylBlue,
    vinylViolet,
    vinylMagenta,
    vinylLime,
    vinylGreen,
    vinylCyan,
  ];

  // ── Roles (los nombres que usa toda la app) ───────────────────────────────
  /// Acento: enlaces, selección y foco. El lila del centro del holo, que se
  /// lee sobre el liner.
  static const primary = Color(0xFF8E8BFF);

  /// Relleno de marca que lleva texto blanco encima. **No** es un color de
  /// texto sobre el liner: ahí no llega al contraste. Para texto, [primary].
  static const primaryDeep = Color(0xFF5B4BFF);
  static const primaryDark = Color(0xFF6F63FF);

  /// Superficie teñida de marca: chips en reposo, tarjetas de marca.
  static const primarySurface = Color(0xFF211F38);

  /// El extremo profundo del degradado de marca, para placeholders de media.
  static const primarySurfaceDeep = Color(0xFF2D2A55);

  /// El rojo de sticker. **No es "error"**: es la marca de en vivo y de
  /// reacción, y aparece en pantallas donde nada falló. [error] apunta al
  /// mismo valor para cuando sí se trata de un fallo.
  static const secondary = Color(0xFFF0234A);

  /// Confirmación, "online", disponibilidad. Lleva tinta encima, no blanco.
  static const tertiary = vinylGreen;

  /// Tinta para velos y superficies invertidas sobre media. Sigue oscuro: un
  /// velo encima de un video tiene que bajar la luz, no subirla.
  static const neutral = ink;

  // ── Semánticos ────────────────────────────────────────────────────────────
  static const success = tertiary;
  static const successSurface = Color(0xFF12291E);

  /// Ámbar. Distinto de [error] porque "mirá esto" y "se rompió" son dos
  /// promesas distintas.
  static const warning = Color(0xFFFFB020);

  /// Mismo valor que [secondary]. Se elige el nombre por lo que dice la
  /// pantalla: `error` cuando algo falló, `secondary` cuando es la marca de
  /// en vivo o de reacción.
  static const error = secondary;

  static const textPrimary = Color(0xFFF4F3EF);
  static const textSecondary = Color(0xFFA09EAB);

  /// Texto deshabilitado o de tercer orden. No se usa para nada que haya que
  /// leer: no llega a 4.5:1.
  static const textTertiary = Color(0xFF6C6A76);

  /// Texto sobre [primarySurface].
  static const textOnBrandSurface = Color(0xFFC7C3FF);

  static const background = liner;
  static const surface = linerRaised;
  static const border = Color(0xFF2B2A33);

  /// Video y salas en vivo, donde el contenido es la luz.
  static const stageDark = Color(0xFF070709);

  /// El velo sobre el video que deja legible el chrome encima.
  static const stageScrim = Color(0x99070709);

  /// Elevación: sobre un liner negro una sombra casi no se ve, así que la
  /// separación la hace el borde troquelado. La sombra queda para lo que se
  /// despega (un sticker levantado, una hoja).
  static const shadow = Color(0x66000000);

  /// La sombra teñida del botón de crear.
  static const brandShadow = Color(0x665B4BFF);
}

abstract final class AppSpacing {
  static const xxs = 4.0;
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 48.0;
}

abstract final class AppRadii {
  static const small = BorderRadius.all(Radius.circular(10));
  static const medium = BorderRadius.all(Radius.circular(18));
  static const large = BorderRadius.all(Radius.circular(26));

  /// Completamente redondeado. **Es la forma por defecto de todo control**:
  /// botones, chips, campos de búsqueda e insignias son stickers con forma de
  /// pastilla. El valor es deliberadamente mayor que cualquier alto.
  static const pill = BorderRadius.all(Radius.circular(999));
}

/// El corte de un sticker: cuánto mide cada capa alrededor del relleno.
abstract final class AppStroke {
  /// El contorno de tinta. Es el trazo grueso del gato.
  static const ink = 2.5;

  /// El borde troquelado blanco (o holo) alrededor del contorno.
  static const kissCut = 3.0;

  /// El filete de un panel sobre el liner.
  static const hairline = 1.0;
}

/// Altos de control, para que dos pantallas no inventen dos botones distintos.
abstract final class AppSizes {
  /// CTA principal.
  static const buttonHeight = 52.0;

  /// Botón denso: acciones dentro de una tarjeta.
  static const buttonHeightDense = 44.0;

  /// Chip de filtro.
  static const chipHeight = 38.0;

  /// Campo de búsqueda.
  static const searchHeight = 46.0;

  /// Avatar del header.
  static const avatarHeader = 34.0;

  /// Ícono de navegación y de acción.
  static const icon = 24.0;
}
