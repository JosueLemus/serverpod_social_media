import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_tokens.dart';

/// Las dos familias, empaquetadas en `assets/fonts` (ver pubspec).
abstract final class AppFonts {
  /// Titulares. Una gótica japonesa de trazo grueso: la voz de un sticker.
  static const display = 'DelaGothicOne';

  /// Cuerpo, etiquetas y datos. Terminaciones redondeadas, como el contorno
  /// del gato.
  static const text = 'MPlusRounded';
}

/// El único `ThemeData` de la app: la plancha de stickers.
///
/// Es oscuro por el lugar donde se usa (alguien en la cama a medianoche, con
/// el brillo bajo, saltando del feed a un vivo) y por el material: el borde
/// troquelado blanco de un sticker sólo se lee sobre un liner negro.
abstract final class AppTheme {
  static ThemeData get nexo {
    TextStyle display(double size, {double tracking = -.2}) => TextStyle(
      fontFamily: AppFonts.display,
      color: AppColors.textPrimary,
      fontSize: size,
      height: 1.12,
      letterSpacing: tracking,
    );
    TextStyle text(
      double size, {
      FontWeight weight = FontWeight.w500,
      Color color = AppColors.textPrimary,
      double height = 1.4,
    }) => TextStyle(
      fontFamily: AppFonts.text,
      color: color,
      fontSize: size,
      fontWeight: weight,
      height: height,
    );

    final textTheme = TextTheme(
      displayLarge: display(34, tracking: -.6),
      displayMedium: display(30, tracking: -.5),
      displaySmall: display(26, tracking: -.4),
      headlineLarge: display(24),
      headlineMedium: display(22),
      headlineSmall: display(20),
      titleLarge: display(18, tracking: 0),
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
      brightness: Brightness.dark,
      fontFamily: AppFonts.text,
      // Densidad estándar también en escritorio y web: la adaptativa achica
      // 8 px cada control en macOS y Chrome, y deja los botones por debajo
      // de los 44 pt de toque que pide iOS, que es donde se muestra la demo.
      visualDensity: VisualDensity.standard,
      colorScheme: const ColorScheme.dark(
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
        onError: AppColors.sticker,
        outline: AppColors.border,
        outlineVariant: AppColors.border,
        shadow: AppColors.shadow,
      ),
      scaffoldBackgroundColor: AppColors.background,
      canvasColor: AppColors.background,
      textTheme: textTheme,
      iconTheme: const IconThemeData(color: AppColors.textPrimary, size: 24),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: AppColors.primary,
        selectionColor: AppColors.primary.withValues(alpha: .35),
        selectionHandleColor: AppColors.primary,
      ),
      cardTheme: const CardThemeData(
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
        focusedBorder: const OutlineInputBorder(
          borderRadius: AppRadii.pill,
          borderSide: BorderSide(color: AppColors.primary, width: 1.6),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: AppRadii.pill,
          borderSide: BorderSide(color: AppColors.error, width: 1.6),
        ),
        focusedErrorBorder: const OutlineInputBorder(
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
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      dividerTheme: const DividerThemeData(color: AppColors.border, space: 1),
      // El CTA es un sticker blanco con tinta encima: la forma más clara que
      // hay sobre el liner, y la misma que el gato del logo.
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.sticker,
          foregroundColor: AppColors.ink,
          disabledBackgroundColor: AppColors.linerHigh,
          disabledForegroundColor: AppColors.textTertiary,
          minimumSize: const Size(0, AppSizes.buttonHeight),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          shape: pill,
          textStyle: buttonText,
          overlayColor: AppColors.ink,
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
        selectedIconTheme: const IconThemeData(color: AppColors.ink),
        unselectedIconTheme: const IconThemeData(
          color: AppColors.textSecondary,
        ),
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
        decoration: const BoxDecoration(
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
      bottomSheetTheme: const BottomSheetThemeData(
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
              ? const Icon(Icons.circle, size: 10, color: AppColors.ink)
              : null,
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.sticker
              : Colors.transparent,
        ),
        checkColor: const WidgetStatePropertyAll(AppColors.ink),
        side: const BorderSide(color: AppColors.textSecondary, width: 1.6),
        shape: const RoundedRectangleBorder(borderRadius: AppRadii.small),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.sticker
              : AppColors.textSecondary,
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
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
        indicator: const UnderlineTabIndicator(
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
