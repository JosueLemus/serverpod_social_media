import 'package:flutter/material.dart';

import 'app_tokens.dart';

/// Un tema de Nexo: una paleta, sus dos tipografías y cómo se dibuja el CTA.
///
/// El usuario elige uno en Perfil → Temas y la app entera cambia en caliente
/// (ver `NexoApp`). El catálogo es [NexoThemes.all].
@immutable
class NexoThemeSpec {
  const NexoThemeSpec({
    required this.id,
    required this.name,
    required this.description,
    required this.palette,
    required this.displayFont,
    required this.textFont,
    this.displayWeight = FontWeight.w700,
    this.displayTracking = -.4,
    this.brandButtons = true,
    this.stickerCut = false,
  });

  /// Lo que se persiste. **No se renombra**: un id viejo guardado en un
  /// teléfono que ya no matchea cae al tema por defecto, sin aviso.
  final String id;
  final String name;
  final String description;
  final NexoPalette palette;

  /// Titulares, secciones y números grandes.
  final String displayFont;

  /// Todo lo demás.
  final String textFont;
  final FontWeight displayWeight;
  final double displayTracking;

  /// Si el botón principal se pinta con el color de marca ([NexoPalette.primaryDeep])
  /// o con el [NexoPalette.sticker] neutro. Nexo Pro, Monocromo y las dos
  /// planchas usan el neutro: su marca es un acento, no un relleno.
  final bool brandButtons;

  /// Si lo que se publica lleva el troquel blanco de la plancha de stickers
  /// (avatares, media, insignias, tarjetas). Sólo las dos planchas: en el resto
  /// el mismo borde es un filete fino, y la superficie hace la separación.
  final bool stickerCut;

  bool get isDark => palette.isDark;
}

/// El catálogo de temas.
///
/// Las paletas se arman con [_dark] / [_light], que derivan los roles
/// secundarios (superficie de marca, vinilos, texto terciario) de los seis
/// colores que definen un tema. Escribir los treinta campos a mano por tema es
/// cómo dos temas terminan con un texto terciario que no se lee en uno solo.
abstract final class NexoThemes {
  static const defaultId = 'aurora';

  /// El tema en uso. Lo escribe [activate].
  static NexoThemeSpec get active => _active;
  static NexoThemeSpec _active = byId(defaultId);

  /// Activa un tema: su paleta pasa a ser la de [AppColors] y sus fuentes las
  /// de [AppFonts]. No redibuja nada por sí mismo — eso es de la raíz.
  static void activate(NexoThemeSpec spec) {
    _active = spec;
    AppColors.activate(spec.palette);
  }

  /// El tema con ese id, o el de por defecto si no existe (un id guardado por
  /// una versión que tenía un tema que ésta ya no tiene).
  static NexoThemeSpec byId(String? id) =>
      all.firstWhere((t) => t.id == id, orElse: () => all.first);

  static final List<NexoThemeSpec> all = [
    NexoThemeSpec(
      id: 'aurora',
      name: 'Aurora',
      description: 'Índigo con violeta y cian',
      displayFont: 'Lexend',
      textFont: 'Lexend',
      palette: _aurora,
    ),
    NexoThemeSpec(
      id: 'nexo_pro',
      name: 'Nexo Pro',
      description: 'Oscuro neutro, acento violeta',
      displayFont: 'Inter',
      textFont: 'Inter',
      displayWeight: FontWeight.w800,
      brandButtons: false,
      palette: _dark(
        bg: const Color(0xFF0B0B0F),
        s1: const Color(0xFF15151B),
        s2: const Color(0xFF1E1E26),
        border: const Color(0xFF26262F),
        text: const Color(0xFFF5F5F7),
        text2: const Color(0xFF9A9AA6),
        brand: const Color(0xFF7C5CFF),
        brandText: const Color(0xFFA594FF),
        live: const Color(0xFFFF2D55),
      ),
    ),
    NexoThemeSpec(
      id: 'neon',
      name: 'Neón en vivo',
      description: 'Lima eléctrico, pensado para los vivos',
      displayFont: 'SpaceGrotesk',
      textFont: 'SpaceGrotesk',
      displayTracking: -.8,
      palette: _dark(
        bg: const Color(0xFF07080C),
        s1: const Color(0xFF10121A),
        s2: const Color(0xFF181B27),
        border: const Color(0xFF1C2030),
        text: const Color(0xFFEEF1FF),
        text2: const Color(0xFF8A90A8),
        brand: const Color(0xFFC6FF3D),
        live: const Color(0xFFFF3B5C),
      ),
    ),
    NexoThemeSpec(
      id: 'medianoche',
      name: 'Medianoche azul',
      description: 'Navy profundo, azul eléctrico',
      displayFont: 'DMSans',
      textFont: 'DMSans',
      palette: _dark(
        bg: const Color(0xFF0A0F1C),
        s1: const Color(0xFF111829),
        s2: const Color(0xFF1A2336),
        border: const Color(0xFF1F2A40),
        text: const Color(0xFFEAF0FF),
        text2: const Color(0xFF8794B0),
        brand: const Color(0xFF3D8BFF),
        brandText: const Color(0xFF6FA8FF),
        live: const Color(0xFFFF4D6D),
      ),
    ),
    NexoThemeSpec(
      id: 'calido',
      name: 'Cálido creador',
      description: 'Oscuro cálido con naranja',
      displayFont: 'BricolageGrotesque',
      textFont: 'Manrope',
      displayWeight: FontWeight.w800,
      palette: _dark(
        bg: const Color(0xFF14110F),
        s1: const Color(0xFF1E1A17),
        s2: const Color(0xFF29231F),
        border: const Color(0xFF2E2824),
        text: const Color(0xFFF7F1EA),
        text2: const Color(0xFFA89C90),
        brand: const Color(0xFFFF7A1A),
        brandText: const Color(0xFFFF9A4D),
        live: const Color(0xFFFF3D3D),
      ),
    ),
    NexoThemeSpec(
      id: 'grafito',
      name: 'Grafito magenta',
      description: 'Grafito con magenta intenso',
      displayFont: 'Sora',
      textFont: 'Sora',
      palette: _dark(
        bg: const Color(0xFF111113),
        s1: const Color(0xFF1A1A1D),
        s2: const Color(0xFF242428),
        border: const Color(0xFF2A2A30),
        text: const Color(0xFFF4F4F6),
        text2: const Color(0xFF9C9CA6),
        brand: const Color(0xFFFF2E93),
        brandText: const Color(0xFFFF5CAB),
        live: const Color(0xFFFF2E93),
      ),
    ),
    NexoThemeSpec(
      id: 'oceano',
      name: 'Océano',
      description: 'Teal profundo con aqua',
      displayFont: 'Outfit',
      textFont: 'Outfit',
      palette: _dark(
        bg: const Color(0xFF06141A),
        s1: const Color(0xFF0C1F27),
        s2: const Color(0xFF122B35),
        border: const Color(0xFF183540),
        text: const Color(0xFFE8FBFF),
        text2: const Color(0xFF7FA3AD),
        brand: const Color(0xFF2DD4BF),
        live: const Color(0xFFFF5470),
      ),
    ),
    NexoThemeSpec(
      id: 'monocromo',
      name: 'Monocromo',
      description: 'Negro puro y blanco',
      displayFont: 'Geist',
      textFont: 'Geist',
      brandButtons: false,
      palette: _dark(
        bg: const Color(0xFF000000),
        s1: const Color(0xFF0E0E0E),
        s2: const Color(0xFF1A1A1A),
        border: const Color(0xFF222222),
        text: const Color(0xFFFFFFFF),
        text2: const Color(0xFF8A8A8A),
        brand: const Color(0xFFFFFFFF),
        live: const Color(0xFFFF3B30),
      ),
    ),
    NexoThemeSpec(
      id: 'cyber',
      name: 'Cyber amarillo',
      description: 'Negro con amarillo señal',
      displayFont: 'Archivo',
      textFont: 'Archivo',
      displayWeight: FontWeight.w800,
      palette: _dark(
        bg: const Color(0xFF0D0D0D),
        s1: const Color(0xFF161616),
        s2: const Color(0xFF202020),
        border: const Color(0xFF2B2B2B),
        text: const Color(0xFFF5F5F5),
        text2: const Color(0xFF9A9A9A),
        brand: const Color(0xFFFFD60A),
        live: const Color(0xFFFF3B30),
      ),
    ),
    NexoThemeSpec(
      id: 'bosque',
      name: 'Bosque',
      description: 'Verde oscuro con salvia',
      displayFont: 'Manrope',
      textFont: 'Manrope',
      displayWeight: FontWeight.w800,
      palette: _dark(
        bg: const Color(0xFF0E1411),
        s1: const Color(0xFF151D19),
        s2: const Color(0xFF1D2822),
        border: const Color(0xFF24302A),
        text: const Color(0xFFEEF5F0),
        text2: const Color(0xFF8FA197),
        brand: const Color(0xFF7BD389),
        live: const Color(0xFFFF5A5F),
      ),
    ),
    NexoThemeSpec(
      id: 'atardecer',
      name: 'Atardecer',
      description: 'Ciruela con durazno',
      displayFont: 'Poppins',
      textFont: 'Poppins',
      displayTracking: -.6,
      palette: _dark(
        bg: const Color(0xFF160F1A),
        s1: const Color(0xFF201725),
        s2: const Color(0xFF2B2031),
        border: const Color(0xFF33263A),
        text: const Color(0xFFFFF1EC),
        text2: const Color(0xFFB49FAE),
        brand: const Color(0xFFFF8A5B),
        live: const Color(0xFFFF3D6E),
      ),
    ),
    NexoThemeSpec(
      id: 'carbon',
      name: 'Carbón rojo',
      description: 'Carbón con rojo de en vivo',
      displayFont: 'Rubik',
      textFont: 'Rubik',
      palette: _dark(
        bg: const Color(0xFF121212),
        s1: const Color(0xFF1B1B1B),
        s2: const Color(0xFF262626),
        border: const Color(0xFF2C2C2C),
        text: const Color(0xFFF2F2F2),
        text2: const Color(0xFF999999),
        brand: const Color(0xFFFF3040),
        brandText: const Color(0xFFFF6370),
        live: const Color(0xFFFF3040),
      ),
    ),
    NexoThemeSpec(
      id: 'holo',
      name: 'Holo refinado',
      description: 'La plancha de stickers, depurada',
      displayFont: 'DelaGothicOne',
      textFont: 'Inter',
      displayWeight: FontWeight.w400,
      displayTracking: -.2,
      brandButtons: false,
      stickerCut: true,
      palette: _dark(
        bg: const Color(0xFF0F0F12),
        s1: const Color(0xFF18181D),
        s2: const Color(0xFF23232B),
        border: const Color(0xFF2B2A33),
        text: const Color(0xFFF4F3EF),
        text2: const Color(0xFFA09EAB),
        brand: const Color(0xFF5B4BFF),
        brandText: const Color(0xFF8E8BFF),
        live: const Color(0xFFF0234A),
        foil: true,
      ),
    ),
    NexoThemeSpec(
      id: 'plancha',
      name: 'Plancha clásica',
      description: 'El diseño original, con troquel y foil',
      displayFont: 'DelaGothicOne',
      textFont: 'MPlusRounded',
      displayWeight: FontWeight.w400,
      displayTracking: -.2,
      brandButtons: false,
      stickerCut: true,
      palette: _plancha,
    ),
    // ── Claros ────────────────────────────────────────────────────────────
    NexoThemeSpec(
      id: 'editorial',
      name: 'Editorial claro',
      description: 'Blanco, tinta y coral, con titulares serif',
      displayFont: 'InstrumentSerif',
      textFont: 'Inter',
      displayWeight: FontWeight.w400,
      displayTracking: -.2,
      palette: _light(
        bg: const Color(0xFFFFFFFF),
        s1: const Color(0xFFF5F4F1),
        s2: const Color(0xFFECEAE5),
        border: const Color(0xFFE7E5E0),
        text: const Color(0xFF111111),
        text2: const Color(0xFF6B6966),
        brand: const Color(0xFF111111),
        brandText: const Color(0xFFD9401F),
        live: const Color(0xFFFF4F2E),
      ),
    ),
    NexoThemeSpec(
      id: 'menta',
      name: 'Menta fresca',
      description: 'Claro con verde menta',
      displayFont: 'PlusJakartaSans',
      textFont: 'PlusJakartaSans',
      displayWeight: FontWeight.w800,
      palette: _light(
        bg: const Color(0xFFF7FAF8),
        s1: const Color(0xFFFFFFFF),
        s2: const Color(0xFFE9F2EE),
        border: const Color(0xFFE1EBE6),
        text: const Color(0xFF0F1F18),
        text2: const Color(0xFF5E7168),
        brand: const Color(0xFF00A877),
        brandText: const Color(0xFF00805A),
        live: const Color(0xFFFF3B30),
      ),
    ),
    NexoThemeSpec(
      id: 'arena',
      name: 'Arena terracota',
      description: 'Claro cálido, titulares Fraunces',
      displayFont: 'Fraunces',
      textFont: 'Inter',
      palette: _light(
        bg: const Color(0xFFFAF6F0),
        s1: const Color(0xFFFFFFFF),
        s2: const Color(0xFFF0E8DC),
        border: const Color(0xFFE8DDCD),
        text: const Color(0xFF2A1F17),
        text2: const Color(0xFF7A6A5C),
        brand: const Color(0xFFC2410C),
        live: const Color(0xFFE11D48),
      ),
    ),
    NexoThemeSpec(
      id: 'lavanda',
      name: 'Lavanda',
      description: 'Claro con violeta suave',
      displayFont: 'Figtree',
      textFont: 'Figtree',
      displayWeight: FontWeight.w800,
      palette: _light(
        bg: const Color(0xFFF8F7FF),
        s1: const Color(0xFFFFFFFF),
        s2: const Color(0xFFEEEBFF),
        border: const Color(0xFFE6E2FA),
        text: const Color(0xFF16132B),
        text2: const Color(0xFF6B6787),
        brand: const Color(0xFF6D4AFF),
        live: const Color(0xFFFF3D71),
      ),
    ),
    NexoThemeSpec(
      id: 'azul',
      name: 'Azul clásico',
      description: 'Claro con azul cielo',
      displayFont: 'Inter',
      textFont: 'Inter',
      displayWeight: FontWeight.w800,
      palette: _light(
        bg: const Color(0xFFFFFFFF),
        s1: const Color(0xFFF7F9FA),
        s2: const Color(0xFFEFF3F4),
        border: const Color(0xFFE6ECEF),
        text: const Color(0xFF0F1419),
        text2: const Color(0xFF536471),
        brand: const Color(0xFF1D9BF0),
        brandText: const Color(0xFF0C7ABF),
        live: const Color(0xFFF91880),
      ),
    ),
    NexoThemeSpec(
      id: 'chicle',
      name: 'Chicle',
      description: 'Claro con rosa chicle',
      displayFont: 'Urbanist',
      textFont: 'Urbanist',
      displayWeight: FontWeight.w800,
      palette: _light(
        bg: const Color(0xFFFFF7FA),
        s1: const Color(0xFFFFFFFF),
        s2: const Color(0xFFFFE8F1),
        border: const Color(0xFFFBDCE8),
        text: const Color(0xFF2A0F1C),
        text2: const Color(0xFF8A6577),
        brand: const Color(0xFFFF3E8A),
        brandText: const Color(0xFFD81B66),
        live: const Color(0xFFFF3E8A),
      ),
    ),
    NexoThemeSpec(
      id: 'brutalista',
      name: 'Brutalista',
      description: 'Papel, bordes de tinta y naranja',
      displayFont: 'SpaceGrotesk',
      textFont: 'SpaceGrotesk',
      displayTracking: -.8,
      palette: _light(
        bg: const Color(0xFFF2F0E9),
        s1: const Color(0xFFFFFFFF),
        s2: const Color(0xFFE4E1D6),
        border: const Color(0xFF111111),
        text: const Color(0xFF111111),
        text2: const Color(0xFF555046),
        brand: const Color(0xFFFF5A1F),
        brandText: const Color(0xFFD13F0A),
        live: const Color(0xFFFF5A1F),
      ),
    ),
  ];

  static const _aurora = NexoPalette(
    brightness: Brightness.dark,
    liner: Color(0xFF090B14),
    linerRaised: Color(0xFF111421),
    linerHigh: Color(0xFF191D2E),
    sticker: Color(0xFFEDEFFF),
    ink: Color(0xFF090B14),
    inkSecondary: Color(0xFF4A4E6A),
    vinylCyan: Color(0xFF67E8F9),
    vinylBlue: Color(0xFF93C5FD),
    vinylViolet: Color(0xFFC4B5FD),
    vinylMagenta: Color(0xFFF0ABFC),
    vinylLime: Color(0xFFBEF264),
    vinylGreen: Color(0xFF6EE7B7),
    holo: [Color(0xFF8B5CF6), Color(0xFF22D3EE), Color(0xFF8B5CF6)],
    primary: Color(0xFFA78BFA),
    primaryDeep: Color(0xFF8B5CF6),
    primarySurface: Color(0xFF1F1A3D),
    secondary: Color(0xFF22D3EE),
    tertiary: Color(0xFF6EE7B7),
    successSurface: Color(0xFF0F2A24),
    warning: Color(0xFFFBBF24),
    error: Color(0xFFFF5C7A),
    textPrimary: Color(0xFFEDEFFF),
    textSecondary: Color(0xFF8C91B5),
    textTertiary: Color(0xFF5A5F80),
    textOnBrandSurface: Color(0xFFD6CCFF),
    border: Color(0xFF222740),
  );

  /// El diseño original, valor por valor.
  static const _plancha = NexoPalette(
    brightness: Brightness.dark,
    liner: Color(0xFF0F0F12),
    linerRaised: Color(0xFF18181D),
    linerHigh: Color(0xFF23232B),
    sticker: Color(0xFFFFFFFF),
    ink: Color(0xFF0F0F12),
    inkSecondary: Color(0xFF57555F),
    vinylCyan: _foilCyan,
    vinylBlue: _foilBlue,
    vinylViolet: _foilViolet,
    vinylMagenta: _foilMagenta,
    vinylLime: _foilLime,
    vinylGreen: _foilGreen,
    holo: _foil,
    primary: Color(0xFF8E8BFF),
    primaryDeep: Color(0xFF5B4BFF),
    primarySurface: Color(0xFF211F38),
    secondary: Color(0xFFF0234A),
    tertiary: _foilGreen,
    successSurface: Color(0xFF12291E),
    warning: Color(0xFFFFB020),
    error: Color(0xFFF0234A),
    textPrimary: Color(0xFFF4F3EF),
    textSecondary: Color(0xFFA09EAB),
    textTertiary: Color(0xFF6C6A76),
    textOnBrandSurface: Color(0xFFC7C3FF),
    border: Color(0xFF2B2A33),
  );

  // El borde holográfico del logo.
  static const _foilCyan = Color(0xFF3FE0F2);
  static const _foilBlue = Color(0xFF4F7BFF);
  static const _foilViolet = Color(0xFF9B5CFF);
  static const _foilMagenta = Color(0xFFE24CF2);
  static const _foilLime = Color(0xFFC9F24A);
  static const _foilGreen = Color(0xFF3EE58C);
  static const _foil = [
    _foilCyan,
    _foilBlue,
    _foilViolet,
    _foilMagenta,
    _foilLime,
    _foilGreen,
    _foilCyan,
  ];

  /// Vinilos de un tema oscuro: vivos, llevan tinta oscura encima.
  static const _darkVinyls = [
    _foilCyan,
    Color(0xFF7FA2FF),
    Color(0xFFB58CFF),
    Color(0xFFEE7CF7),
    _foilLime,
    _foilGreen,
  ];

  /// Vinilos de un tema claro: profundos, llevan texto blanco encima.
  static const _lightVinyls = [
    Color(0xFF0E7490),
    Color(0xFF1D4ED8),
    Color(0xFF6D28D9),
    Color(0xFFBE185D),
    Color(0xFF4D7C0F),
    Color(0xFF047857),
  ];

  static NexoPalette _dark({
    required Color bg,
    required Color s1,
    required Color s2,
    required Color border,
    required Color text,
    required Color text2,
    required Color brand,
    required Color live,
    Color? brandText,
    bool foil = false,
  }) {
    const ink = Color(0xFF0B0B0F);
    const tertiary = Color(0xFF3EE58C);
    return NexoPalette(
      brightness: Brightness.dark,
      liner: bg,
      linerRaised: s1,
      linerHigh: s2,
      sticker: text,
      ink: ink,
      inkSecondary: Color.lerp(ink, text, .38)!,
      vinylCyan: foil ? _foilCyan : _darkVinyls[0],
      vinylBlue: foil ? _foilBlue : _darkVinyls[1],
      vinylViolet: foil ? _foilViolet : _darkVinyls[2],
      vinylMagenta: foil ? _foilMagenta : _darkVinyls[3],
      vinylLime: foil ? _foilLime : _darkVinyls[4],
      vinylGreen: foil ? _foilGreen : _darkVinyls[5],
      holo: foil ? _foil : [live, live],
      primary: brandText ?? brand,
      primaryDeep: brand,
      primarySurface: Color.lerp(s1, brand, .16)!,
      secondary: live,
      tertiary: tertiary,
      successSurface: Color.lerp(bg, tertiary, .14)!,
      warning: const Color(0xFFFFB020),
      error: _isRed(live) ? live : const Color(0xFFFF4D6A),
      textPrimary: text,
      textSecondary: text2,
      textTertiary: Color.lerp(text2, bg, .38)!,
      textOnBrandSurface: Color.lerp(brandText ?? brand, text, .45)!,
      border: border,
    );
  }

  static NexoPalette _light({
    required Color bg,
    required Color s1,
    required Color s2,
    required Color border,
    required Color text,
    required Color text2,
    required Color brand,
    required Color live,
    Color? brandText,
  }) {
    const ink = Color(0xFFFFFFFF);
    const tertiary = Color(0xFF047857);
    return NexoPalette(
      brightness: Brightness.light,
      liner: bg,
      linerRaised: s1,
      linerHigh: s2,
      sticker: text,
      ink: ink,
      inkSecondary: Color.lerp(ink, text, .32)!,
      vinylCyan: _lightVinyls[0],
      vinylBlue: _lightVinyls[1],
      vinylViolet: _lightVinyls[2],
      vinylMagenta: _lightVinyls[3],
      vinylLime: _lightVinyls[4],
      vinylGreen: _lightVinyls[5],
      holo: [live, live],
      primary: brandText ?? brand,
      primaryDeep: brand,
      primarySurface: Color.lerp(s1, brand, .1)!,
      secondary: live,
      tertiary: tertiary,
      successSurface: Color.lerp(s1, tertiary, .1)!,
      warning: const Color(0xFFB45309),
      error: const Color(0xFFDC2626),
      textPrimary: text,
      textSecondary: text2,
      textTertiary: Color.lerp(text2, bg, .35)!,
      textOnBrandSurface: Color.lerp(brandText ?? brand, text, .25)!,
      border: border,
    );
  }

  /// ¿El color de en vivo es un rojo? Si no lo es, el error necesita su propio
  /// rojo: un fallo pintado en cian no se lee como un fallo.
  static bool _isRed(Color c) {
    final hue = HSVColor.fromColor(c).hue;
    return hue >= 330 || hue <= 15;
  }
}
