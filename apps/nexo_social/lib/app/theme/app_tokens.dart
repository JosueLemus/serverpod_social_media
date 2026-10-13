import 'package:flutter/material.dart';

import 'nexo_themes.dart';

/// Una paleta completa: todos los roles de color que usa la app.
///
/// Cada tema del catálogo (`nexo_themes.dart`) es una de éstas. Los nombres de
/// los roles vienen de la Plancha clásica —el liner, el sticker, la tinta—, y
/// se conservan porque describen una **relación** que vale en cualquier tema:
///
/// - [liner] es el suelo; [linerRaised] y [linerHigh] suben un escalón cada uno.
/// - [sticker] es el relleno de máximo contraste contra el suelo: el CTA, el
///   chip seleccionado, la snackbar. Blanco en un tema oscuro, casi negro en
///   uno claro.
/// - [ink] es lo que va **encima** del sticker y de cualquier relleno de color
///   (vinilos, [tertiary], [warning]). Por eso, en un tema claro, esos rellenos
///   son tonos profundos que llevan texto blanco, y en uno oscuro son vivos que
///   llevan texto oscuro.
///
/// Lo que NO es parte de una paleta, porque no cambia con el tema, vive como
/// constante en [AppColors]: el blanco y el velo sobre video ([AppColors.onMedia],
/// [AppColors.stageDark], [AppColors.stageScrim], [AppColors.neutral]). Un
/// video es la misma luz en un tema claro que en uno oscuro.
@immutable
class NexoPalette {
  const NexoPalette({
    required this.brightness,
    required this.liner,
    required this.linerRaised,
    required this.linerHigh,
    required this.sticker,
    required this.ink,
    required this.inkSecondary,
    required this.vinylCyan,
    required this.vinylBlue,
    required this.vinylViolet,
    required this.vinylMagenta,
    required this.vinylLime,
    required this.vinylGreen,
    required this.holo,
    required this.primary,
    required this.primaryDeep,
    required this.primarySurface,
    required this.secondary,
    required this.tertiary,
    required this.successSurface,
    required this.warning,
    required this.error,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.textOnBrandSurface,
    required this.border,
  });

  final Brightness brightness;
  final Color liner;
  final Color linerRaised;
  final Color linerHigh;
  final Color sticker;
  final Color ink;

  /// Texto secundario sobre un [sticker].
  final Color inkSecondary;

  final Color vinylCyan;
  final Color vinylBlue;
  final Color vinylViolet;
  final Color vinylMagenta;
  final Color vinylLime;
  final Color vinylGreen;

  /// El borde de lo que está **al aire**. En la Plancha es el foil del logo;
  /// en la mayoría de los temas es el color de en vivo repetido, o sea un
  /// anillo sólido. Sólo para lo que está pasando ahora.
  final List<Color> holo;

  /// Acento legible sobre el suelo: enlaces, selección, foco.
  final Color primary;

  /// Relleno de marca. Lleva [onPrimaryDeep] encima.
  final Color primaryDeep;

  /// Superficie teñida de marca: chips en reposo, tarjetas de marca.
  final Color primarySurface;

  /// En vivo y reacción. En la mayoría de los temas es rojo y coincide con
  /// [error]; en Aurora es cian, y por eso son dos campos.
  final Color secondary;

  /// Confirmación, online. Lleva [ink] encima.
  final Color tertiary;
  final Color successSurface;

  /// "Mirá esto". Lleva [ink] encima.
  final Color warning;

  /// Fallo. Siempre un rojo, aunque el en vivo del tema no lo sea.
  final Color error;

  final Color textPrimary;
  final Color textSecondary;

  /// Deshabilitado o de tercer orden. No llega a 4.5:1.
  final Color textTertiary;

  /// Texto sobre [primarySurface].
  final Color textOnBrandSurface;

  final Color border;

  bool get isDark => brightness == Brightness.dark;

  /// Texto sobre [primaryDeep]. Se elige por luminancia, no se declara: así
  /// un tema con marca clara (lima, amarillo, menta) no termina con blanco
  /// ilegible encima de su propio botón.
  Color get onPrimaryDeep => _onFill(primaryDeep);

  /// Texto sobre el color de en vivo.
  Color get onSecondary => _onFill(secondary);

  /// El de los dos (casi negro o blanco) que más contraste da sobre [fill].
  /// Un umbral fijo de luminancia se equivoca justo en los naranjas y los
  /// duraznos, que tienen luminancia media: los dejaba con blanco a 2.6:1.
  static Color _onFill(Color fill) {
    const dark = Color(0xFF0B0B0F), light = Color(0xFFFFFFFF);
    final l = fill.computeLuminance();
    final onDark = (l + .05) / (dark.computeLuminance() + .05);
    final onLight = (light.computeLuminance() + .05) / (l + .05);
    return onDark >= onLight ? dark : light;
  }
}

/// El color de la app. Todo color sale de acá: nunca hex crudo, nunca
/// `Colors.X`. Un literal suelto es invisible a un cambio de tema, y así es
/// como dos pantallas terminan con dos negros apenas distintos.
///
/// **Los valores dependen del tema activo**: son getters sobre [palette], que
/// cambia cuando el usuario elige otro tema en Perfil → Temas. Por eso:
///
/// - **Nunca dentro de un `const`.** `const Icon(color: AppColors.ink)` no
///   compila, y está bien que no compile: un color congelado en compilación
///   no sigue al tema.
/// - **Nunca guardado en un `static final` ni en un top-level `final`.** Ésos
///   se evalúan una sola vez y quedan con el color del tema que había al
///   primer acceso. Va un getter.
///
/// Única excepción a "todo sale de acá": el color de marca de un tercero (el
/// azul de Google en el botón de identidad). Es suyo, no nuestro.
abstract final class AppColors {
  /// La paleta en uso. La escribe [activate]; lo único que la llama es la raíz
  /// de la app cuando cambia el tema elegido.
  static NexoPalette get palette => _palette;
  static NexoPalette _palette = NexoThemes.byId(NexoThemes.defaultId).palette;

  /// Cambia la paleta de toda la app. No redibuja nada por sí mismo: quien la
  /// llama es responsable de reconstruir el árbol (ver `NexoApp`).
  static void activate(NexoPalette palette) => _palette = palette;

  // ── El liner ──────────────────────────────────────────────────────────────
  static Color get liner => _palette.liner;
  static Color get linerRaised => _palette.linerRaised;
  static Color get linerHigh => _palette.linerHigh;

  // ── El sticker ────────────────────────────────────────────────────────────
  static Color get sticker => _palette.sticker;
  static Color get ink => _palette.ink;
  static Color get inkSecondary => _palette.inkSecondary;

  // ── Vinilos ───────────────────────────────────────────────────────────────
  static Color get vinylCyan => _palette.vinylCyan;
  static Color get vinylBlue => _palette.vinylBlue;
  static Color get vinylViolet => _palette.vinylViolet;
  static Color get vinylMagenta => _palette.vinylMagenta;
  static Color get vinylLime => _palette.vinylLime;
  static Color get vinylGreen => _palette.vinylGreen;

  /// El borde de lo que está **al aire**. Ver [NexoPalette.holo].
  static List<Color> get holo => _palette.holo;

  /// El troquel alrededor de un sticker: el blanco de la plancha en los temas
  /// que lo tienen (`NexoThemeSpec.stickerCut`), transparente en el resto. Es
  /// transparente y no ausente para que el blanco táctil no cambie de tamaño
  /// de un tema a otro.
  static Color get cut =>
      NexoThemes.active.stickerCut ? _palette.sticker : const Color(0x00000000);

  // ── Roles ─────────────────────────────────────────────────────────────────
  static Color get primary => _palette.primary;
  static Color get primaryDeep => _palette.primaryDeep;
  static Color get onPrimaryDeep => _palette.onPrimaryDeep;
  static Color get primaryDark => _palette.primaryDeep;
  static Color get primarySurface => _palette.primarySurface;

  /// El relleno de la acción principal (CTA, crear): la marca, o el sticker
  /// neutro en los temas cuya marca es un acento (`NexoThemeSpec.brandButtons`).
  static Color get cta =>
      NexoThemes.active.brandButtons ? _palette.primaryDeep : _palette.sticker;

  /// Lo que va encima de [cta].
  static Color get onCta =>
      NexoThemes.active.brandButtons ? _palette.onPrimaryDeep : _palette.ink;
  static Color get primarySurfaceDeep =>
      Color.lerp(_palette.primarySurface, _palette.primaryDeep, .25)!;

  /// En vivo y reacción. **No es "error"**: en casi todos los temas tienen el
  /// mismo valor, pero en Aurora el en vivo es cian. Se elige el nombre por lo
  /// que dice la pantalla.
  static Color get secondary => _palette.secondary;
  static Color get onSecondary => _palette.onSecondary;
  static Color get tertiary => _palette.tertiary;

  // ── Semánticos ────────────────────────────────────────────────────────────
  static Color get success => _palette.tertiary;
  static Color get successSurface => _palette.successSurface;
  static Color get warning => _palette.warning;
  static Color get error => _palette.error;
  static Color get onError => NexoPalette._onFill(_palette.error);

  /// Texto legible sobre un relleno cualquiera: casi negro sobre uno claro,
  /// blanco sobre uno oscuro. Para un relleno que no es un rol de la paleta
  /// (el vinilo de una categoría, el color de un estado).
  static Color on(Color fill) => NexoPalette._onFill(fill);

  static Color get textPrimary => _palette.textPrimary;
  static Color get textSecondary => _palette.textSecondary;
  static Color get textTertiary => _palette.textTertiary;
  static Color get textOnBrandSurface => _palette.textOnBrandSurface;

  static Color get background => _palette.liner;
  static Color get surface => _palette.linerRaised;
  static Color get border => _palette.border;

  /// Elevación: sobre un suelo oscuro una sombra casi no se ve, así que la
  /// separación la hace el borde. La sombra queda para lo que se despega.
  static Color get shadow =>
      _palette.isDark ? const Color(0x66000000) : const Color(0x1F101828);

  /// La sombra teñida del botón de crear.
  static Color get brandShadow => _palette.primaryDeep.withValues(alpha: .4);

  // ── Lo que no cambia con el tema ──────────────────────────────────────────
  /// Texto e íconos **sobre video o media**. Siempre blanco: lo que hay debajo
  /// es la imagen, no el suelo del tema.
  static const onMedia = Color(0xFFFFFFFF);

  /// Texto secundario sobre video.
  static const onMediaSecondary = Color(0xB8FFFFFF);

  /// Video y salas en vivo, donde el contenido es la luz.
  static const stageDark = Color(0xFF070709);

  /// El velo sobre el video que deja legible el chrome encima.
  static const stageScrim = Color(0x99070709);

  /// Tinta para velos sobre media. Sigue oscuro en un tema claro: un velo
  /// encima de un video tiene que bajar la luz, no subirla.
  static const neutral = Color(0xFF0F0F12);
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
