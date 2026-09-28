import 'package:flutter/material.dart';

/// La paleta, transcrita del design system de Stitch.
///
/// Todo color de la app sale de acá — nunca hex crudo, nunca `Colors.X`. Un
/// literal suelto es invisible a un cambio de tema y es cómo dos pantallas
/// terminan con dos azules apenas distintos.
///
/// Única excepción: el color de marca de un tercero (el azul de Google en el
/// botón de identidad). Es suyo, no nuestro, y no se re-tematiza.
abstract final class AppColors {
  // ── Los cuatro del design system ──────────────────────────────────────────
  /// `Primary #3B82F6`. Acentos, selección, enlaces.
  static const primary = Color(0xFF3B82F6);

  /// `Secondary #EF4444`. En el design system el rojo es **secundario**, no un
  /// color de error: es la marca de "en vivo" y de reacción, y aparece en
  /// pantallas donde nada falló. [error] apunta al mismo valor para cuando sí
  /// se trata de un fallo, y los dos nombres se usan según lo que la pantalla
  /// quiera decir.
  static const secondary = Color(0xFFEF4444);

  /// `Tertiary #16A34A`. Confirmación, "online", disponibilidad.
  static const tertiary = Color(0xFF16A34A);

  /// `Neutral #172033`. Texto principal y la superficie del botón invertido.
  static const neutral = Color(0xFF172033);

  // ── Rampa del primario ────────────────────────────────────────────────────
  /// El azul de los CTA rellenos. Un paso más profundo que [primary]: en el
  /// design system el swatch es el acento y el botón usa este.
  static const primaryDeep = Color(0xFF1D4ED8);
  static const primaryDark = Color(0xFF2563EB);

  /// Superficie del botón secundario, de los chips y de las tarjetas de marca.
  static const primarySurface = Color(0xFFEAF3FF);

  /// El extremo profundo del degradado de marca, para placeholders de media.
  static const primarySurfaceDeep = Color(0xFFDCE8FB);

  // ── Semánticos ────────────────────────────────────────────────────────────
  static const success = tertiary;
  static const successSurface = Color(0xFFEAF8EF);

  /// Ámbar. Distinto de [error] porque "mirá esto" y "se rompió" son dos
  /// promesas distintas.
  static const warning = Color(0xFFD97706);

  /// Mismo valor que [secondary]. Se elige el nombre por lo que dice la
  /// pantalla: `error` cuando algo falló, `secondary` cuando es la marca de
  /// en vivo o de reacción.
  static const error = secondary;

  static const textPrimary = neutral;
  static const textSecondary = Color(0xFF667085);

  /// Texto sobre una superficie de marca clara.
  static const textOnBrandSurface = primaryDeep;

  static const background = Color(0xFFF8FAFC);
  static const surface = Color(0xFFFFFFFF);
  static const border = Color(0xFFE5E7EB);

  /// Video y salas en vivo, donde el contenido es la luz.
  static const stageDark = Color(0xFF0B1220);

  /// El velo sobre el video que deja legible el chrome encima.
  static const stageScrim = Color(0x99101828);

  /// Elevación suave. Derivada de [neutral] y no de negro puro, para que una
  /// superficie elevada se lea de la misma familia que el texto que lleva.
  static const shadow = Color(0x1A172033);

  /// La sombra del botón de componer: teñida de marca, no gris. Una sombra
  /// neutra bajo un disco azul se lee como suciedad, no como elevación.
  static const brandShadow = Color(0x4D1D4ED8);
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
  static const medium = BorderRadius.all(Radius.circular(16));
  static const large = BorderRadius.all(Radius.circular(24));

  /// Completamente redondeado. **Es la forma por defecto de todo control** en
  /// este design system: botones, chips, campos de búsqueda y pills. Un radio
  /// fijo grande sobre un control bajo deja los cantos planos visibles, así
  /// que el valor es deliberadamente mayor que cualquier alto.
  static const pill = BorderRadius.all(Radius.circular(999));
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
}
