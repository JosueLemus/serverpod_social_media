import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_tokens.dart';

/// El único `ThemeData` de la app.
///
/// Las dos tipografías salen del design system: **Bricolage Grotesque** para
/// titulares y **Hanken Grotesk** para cuerpo y etiquetas.
abstract final class AppTheme {
  static ThemeData get light {
    final body = GoogleFonts.hankenGroteskTextTheme();
    TextStyle headline(double size, {FontWeight weight = FontWeight.w700}) =>
        GoogleFonts.bricolageGrotesque(
          color: AppColors.textPrimary,
          fontWeight: weight,
          fontSize: size,
          height: 1.15,
        );

    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: Colors.white,
        primaryContainer: AppColors.primarySurface,
        onPrimaryContainer: AppColors.primaryDeep,
        // Material saca el tinte de "seleccionado" del contenedor secundario.
        // Con el verde ahí, el indicador del rail salía verde y la selección
        // se leía como confirmación en vez de como marca.
        secondary: AppColors.primaryDeep,
        onSecondary: Colors.white,
        secondaryContainer: AppColors.primarySurface,
        onSecondaryContainer: AppColors.primaryDeep,
        tertiary: AppColors.tertiary,
        onTertiary: Colors.white,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        error: AppColors.error,
        onError: Colors.white,
        outline: AppColors.border,
      ),
      scaffoldBackgroundColor: AppColors.background,
      textTheme: body.copyWith(
        displayLarge: headline(34),
        displayMedium: headline(30),
        displaySmall: headline(27),
        headlineMedium: headline(24),
        headlineSmall: headline(21),
        titleLarge: headline(19),
        titleMedium: body.titleMedium?.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
          fontSize: 15,
        ),
        bodyLarge: body.bodyLarge?.copyWith(color: AppColors.textPrimary),
        bodyMedium: body.bodyMedium?.copyWith(color: AppColors.textPrimary),
        bodySmall: body.bodySmall?.copyWith(color: AppColors.textSecondary),
        labelLarge: body.labelLarge?.copyWith(fontWeight: FontWeight.w700),
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
      // Campo con forma de pill, como el buscador del design system. El borde
      // desaparece en reposo y aparece en foco: en una pantalla llena de
      // tarjetas, un campo con marco compite con ellas.
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.primarySurface,
        hintStyle: body.bodyMedium?.copyWith(color: AppColors.textSecondary),
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
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        titleTextStyle: headline(18),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.border, space: 1),
      // Pill en los cuatro botones. Es la forma por defecto del design system,
      // no una variante: un rectángulo redondeado aquí se lee como otra app.
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primaryDeep,
          foregroundColor: Colors.white,
          minimumSize: const Size(0, AppSizes.buttonHeight),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          shape: const RoundedRectangleBorder(borderRadius: AppRadii.pill),
          textStyle: body.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryDeep,
          backgroundColor: AppColors.surface,
          minimumSize: const Size(0, AppSizes.buttonHeight),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          side: const BorderSide(color: AppColors.border),
          shape: const RoundedRectangleBorder(borderRadius: AppRadii.pill),
          textStyle: body.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryDeep,
          shape: const RoundedRectangleBorder(borderRadius: AppRadii.pill),
          textStyle: body.labelLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.primarySurface,
        side: BorderSide.none,
        shape: const RoundedRectangleBorder(borderRadius: AppRadii.pill),
        labelStyle: body.labelMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: AppColors.textOnBrandSurface,
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.primarySurface,
        indicatorShape: const RoundedRectangleBorder(
          borderRadius: AppRadii.pill,
        ),
        selectedIconTheme: const IconThemeData(color: AppColors.primaryDeep),
        unselectedIconTheme: const IconThemeData(
          color: AppColors.textSecondary,
        ),
        selectedLabelTextStyle: body.labelLarge?.copyWith(
          color: AppColors.primaryDeep,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelTextStyle: body.labelLarge?.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.neutral,
        contentTextStyle: body.bodyMedium?.copyWith(color: Colors.white),
        shape: const RoundedRectangleBorder(borderRadius: AppRadii.pill),
      ),
      listTileTheme: const ListTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: AppRadii.medium),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) => Colors.white),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.primaryDeep
              : AppColors.border,
        ),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.primaryDeep,
        unselectedLabelColor: AppColors.textSecondary,
        indicatorColor: AppColors.primaryDeep,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: AppColors.border,
        labelStyle: body.labelLarge?.copyWith(fontWeight: FontWeight.w700),
        unselectedLabelStyle: body.labelLarge,
      ),
    );
  }
}
