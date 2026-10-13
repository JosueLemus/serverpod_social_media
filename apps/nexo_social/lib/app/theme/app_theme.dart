import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_tokens.dart';
import 'nexo_themes.dart';

/// Las dos familias del tema activo, empaquetadas en `assets/fonts`.
///
/// Son getters por lo mismo que [AppColors]: cambian con el tema, así que
/// nunca van dentro de un `const`.
abstract final class AppFonts {
  /// Titulares, secciones y números grandes.
  static String get display => NexoThemes.active.displayFont;

  /// Cuerpo, etiquetas y datos.
  static String get text => NexoThemes.active.textFont;
}

/// El `ThemeData` de la app, armado a partir de un [NexoThemeSpec].
///
/// Hay uno por tema del catálogo. La raíz (`NexoApp`) lo reconstruye cuando el
/// usuario elige otro tema en Perfil → Temas.
abstract final class AppTheme {
  /// El del tema activo.
  static ThemeData get nexo => of(NexoThemes.active);

  /// Asume que [spec] ya está activado (`NexoThemes.activate`): los colores
  /// los lee de [AppColors], igual que el resto de la app, para que el tema de
  /// Material y los widgets nunca pinten dos paletas distintas.
  static ThemeData of(NexoThemeSpec spec) {
    final dark = spec.isDark;
    TextStyle display(double size, {double tracking = 0}) => TextStyle(
      fontFamily: spec.displayFont,
      fontWeight: spec.displayWeight,
      color: AppColors.textPrimary,
      fontSize: size,
      height: 1.12,
      letterSpacing: spec.displayTracking + tracking,
    );
    TextStyle text(
      double size, {
      FontWeight weight = FontWeight.w500,
      Color? color,
      double height = 1.4,
    }) => TextStyle(
      fontFamily: spec.textFont,
      color: color ?? AppColors.textPrimary,
      fontSize: size,
      fontWeight: weight,
      height: height,
    );

    // El CTA: con el color de marca, o con el sticker neutro en los temas cuya
    // marca es un acento (ver [NexoThemeSpec.brandButtons]).
    final ctaFill = AppColors.cta;
    final ctaOn = AppColors.onCta;

    final textTheme = TextTheme(
      displayLarge: display(34, tracking: -.2),
      displayMedium: display(30, tracking: -.1),
      displaySmall: display(26),
      headlineLarge: display(24),
      headlineMedium: display(22),
      headlineSmall: display(20),
      titleLarge: display(18, tracking: .2),
      titleMedium: text(15.5, weight: FontWeight.w800, height: 1.3),
      titleSmall: text(14, weight: FontWeight.w800, height: 1.3),
      bodyLarge: text(16),
      bodyMedium: text(14.5),
      bodySmall: text(12.5, color: AppColors.textSecondary),
      labelLarge: text(15, weight: FontWeight.w800, height: 1.2),
      labelMedium: text(13, weight: FontWeight.w700, height: 1.2),
      labelSmall: text(11, weight: FontWeight.w700, height: 1.2),
    );

    const pill = RoundedRectangleBorder(borderRadius: AppRadii.pill);
    final buttonText = textTheme.labelLarge;

    return ThemeData(
      useMaterial3: true,
      brightness: spec.palette.brightness,
      fontFamily: spec.textFont,
      // Densidad estándar también en escritorio y web: la adaptativa achica
      // 8 px cada control en macOS y Chrome, y deja los botones por debajo
      // de los 44 pt de toque que pide iOS, que es donde se muestra la demo.
      visualDensity: VisualDensity.standard,
      colorScheme: ColorScheme(
        brightness: spec.palette.brightness,
        primary: AppColors.primary,
        onPrimary: AppColors.ink,
        primaryContainer: AppColors.primarySurface,
        onPrimaryContainer: AppColors.textOnBrandSurface,
        // Material saca el tinte de "seleccionado" del contenedor secundario.
        // Seleccionar es despegar un sticker: blanco con tinta.
        secondary: AppColors.sticker,
        onSecondary: AppColors.ink,
        secondaryContainer: AppColors.sticker,
        onSecondaryContainer: AppColors.ink,
        tertiary: AppColors.tertiary,
        onTertiary: AppColors.ink,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        onSurfaceVariant: AppColors.textSecondary,
        surfaceContainerHighest: AppColors.linerHigh,
        error: AppColors.error,
        onError: AppColors.onError,
        outline: AppColors.border,
        outlineVariant: AppColors.border,
        shadow: AppColors.shadow,
      ),
      scaffoldBackgroundColor: AppColors.background,
      canvasColor: AppColors.background,
      textTheme: textTheme,
      iconTheme: IconThemeData(color: AppColors.textPrimary, size: 24),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: AppColors.primary,
        selectionColor: AppColors.primary.withValues(alpha: .35),
        selectionHandleColor: AppColors.primary,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        // Las tarjetas no traen margen propio: el default de Material agrega 4
        // por lado y ensancha en silencio cada gap que una pantalla define con
        // AppSpacing, así que el ritmo deja de ser razonable.
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadii.medium,
          side: BorderSide(color: AppColors.border),
        ),
      ),
      // Campo con forma de pastilla. El borde aparece sólo en foco: en una
      // pantalla llena de stickers, un campo con marco compite con ellos.
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.linerHigh,
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: AppColors.textSecondary,
        ),
        labelStyle: textTheme.bodyMedium?.copyWith(
          color: AppColors.textSecondary,
        ),
        floatingLabelStyle: textTheme.labelMedium?.copyWith(
          color: AppColors.primary,
        ),
        prefixIconColor: AppColors.textSecondary,
        suffixIconColor: AppColors.textSecondary,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        border: const OutlineInputBorder(
          borderRadius: AppRadii.pill,
          borderSide: BorderSide.none,
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: AppRadii.pill,
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadii.pill,
          borderSide: BorderSide(color: AppColors.primary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadii.pill,
          borderSide: BorderSide(color: AppColors.error, width: 1.6),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadii.pill,
          borderSide: BorderSide(color: AppColors.error, width: 1.6),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        titleTextStyle: textTheme.titleLarge,
        systemOverlayStyle: dark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
      ),
      dividerTheme: DividerThemeData(color: AppColors.border, space: 1),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: ctaFill,
          foregroundColor: ctaOn,
          disabledBackgroundColor: AppColors.linerHigh,
          disabledForegroundColor: AppColors.textTertiary,
          minimumSize: const Size(0, AppSizes.buttonHeight),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          shape: pill,
          textStyle: buttonText,
          overlayColor: ctaOn,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          backgroundColor: Colors.transparent,
          disabledForegroundColor: AppColors.textTertiary,
          minimumSize: const Size(0, AppSizes.buttonHeight),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          side: BorderSide(
            color: AppColors.textPrimary.withValues(alpha: .38),
            width: 1.6,
          ),
          shape: pill,
          textStyle: buttonText,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          shape: pill,
          textStyle: textTheme.labelLarge,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          disabledForegroundColor: AppColors.textTertiary,
          minimumSize: const Size(44, 44),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.linerHigh,
        selectedColor: AppColors.sticker,
        side: BorderSide.none,
        shape: pill,
        labelStyle: textTheme.labelMedium,
        secondaryLabelStyle: textTheme.labelMedium?.copyWith(
          color: AppColors.ink,
        ),
        checkmarkColor: AppColors.ink,
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: AppColors.background,
        indicatorColor: AppColors.sticker,
        indicatorShape: pill,
        selectedIconTheme: IconThemeData(color: AppColors.ink),
        unselectedIconTheme: IconThemeData(color: AppColors.textSecondary),
        selectedLabelTextStyle: textTheme.labelLarge?.copyWith(
          color: AppColors.textPrimary,
        ),
        unselectedLabelTextStyle: textTheme.labelLarge?.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w600,
        ),
      ),
      // La snackbar es un sticker que se pega abajo: blanco, tinta, pastilla.
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.sticker,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: AppColors.ink,
          fontWeight: FontWeight.w700,
        ),
        actionTextColor: AppColors.primaryDeep,
        shape: pill,
        elevation: 0,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppColors.sticker,
          borderRadius: AppRadii.pill,
        ),
        textStyle: textTheme.labelMedium?.copyWith(color: AppColors.ink),
      ),
      listTileTheme: ListTileThemeData(
        shape: const RoundedRectangleBorder(borderRadius: AppRadii.medium),
        iconColor: AppColors.textSecondary,
        textColor: AppColors.textPrimary,
        titleTextStyle: textTheme.titleSmall,
        subtitleTextStyle: textTheme.bodySmall,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        dragHandleColor: AppColors.border,
        showDragHandle: false,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(borderRadius: AppRadii.large),
        titleTextStyle: textTheme.headlineSmall,
        contentTextStyle: textTheme.bodyMedium,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: AppColors.linerHigh,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(borderRadius: AppRadii.medium),
        textStyle: textTheme.bodyMedium,
      ),
      // El toggle es un sticker redondo que se corre sobre una pista de
      // vinilo: lima encendido, liner apagado. No el verde de stock.
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.sticker
              : AppColors.textSecondary,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.vinylLime
              : AppColors.linerHigh,
        ),
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.ink
              : Colors.transparent,
        ),
        trackOutlineWidth: const WidgetStatePropertyAll(AppStroke.ink),
        thumbIcon: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? Icon(Icons.circle, size: 10, color: AppColors.ink)
              : null,
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.sticker
              : Colors.transparent,
        ),
        checkColor: WidgetStatePropertyAll(AppColors.ink),
        side: BorderSide(color: AppColors.textSecondary, width: 1.6),
        shape: const RoundedRectangleBorder(borderRadius: AppRadii.small),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.sticker
              : AppColors.textSecondary,
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: AppColors.linerHigh,
        circularTrackColor: Colors.transparent,
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStatePropertyAll(
          AppColors.textSecondary.withValues(alpha: .4),
        ),
        radius: const Radius.circular(999),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          backgroundColor: AppColors.linerHigh,
          foregroundColor: AppColors.textSecondary,
          selectedBackgroundColor: AppColors.sticker,
          selectedForegroundColor: AppColors.ink,
          side: BorderSide.none,
          shape: pill,
          textStyle: textTheme.labelMedium,
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.textPrimary,
        unselectedLabelColor: AppColors.textSecondary,
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(color: AppColors.sticker, width: 3),
          borderRadius: BorderRadius.all(Radius.circular(3)),
        ),
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: AppColors.border,
        labelStyle: textTheme.labelLarge,
        unselectedLabelStyle: textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
