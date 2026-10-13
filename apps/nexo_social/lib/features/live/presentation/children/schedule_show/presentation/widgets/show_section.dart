import 'package:flutter/material.dart';

import '../../../../../../../app/theme/app_tokens.dart';
import '../../../../../../../core/widgets/nexo_icon.dart';

/// Una sección del formulario: título en la voz de sticker y el contenido
/// directo sobre el liner, sin tarjeta alrededor.
class ShowSection extends StatelessWidget {
  const ShowSection({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final Widget child;

  /// Una línea de contexto bajo el título, en el texto del cuerpo.
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: text.titleLarge,
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: AppSpacing.xs),
              trailing!,
            ],
          ],
        ),
        if (subtitle case final subtitle?) ...[
          const SizedBox(height: AppSpacing.xxs),
          Text(subtitle, style: text.bodySmall),
        ],
        const SizedBox(height: AppSpacing.sm),
        child,
      ],
    );
  }
}

/// Un panel liso para lo que necesita un contenedor y no es un sticker: un
/// aviso, un grupo de ajustes.
///
/// Es un [Material] y no una caja pintada: la reacción de un `Switch` o de un
/// `InkWell` se dibuja en el Material más cercano, y con el del Scaffold
/// quedaría debajo del relleno.
class ShowPanel extends StatelessWidget {
  const ShowPanel({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  static const radius = BorderRadius.all(Radius.circular(22));

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.surface,
    borderRadius: radius,
    clipBehavior: Clip.antiAlias,
    child: padding == null ? child : Padding(padding: padding!, child: child),
  );
}

/// Pastilla de pista junto a un título: "Soporta Markdown", "1 de 3 cupos".
/// Gris sobre la plancha, para que no compita con los controles.
class ShowHintPill extends StatelessWidget {
  const ShowHintPill({super.key, required this.label, this.glyph});

  final String label;
  final NexoGlyph? glyph;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 6),
    decoration: BoxDecoration(
      color: AppColors.linerHigh,
      borderRadius: AppRadii.pill,
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (glyph case final glyph?) ...[
          NexoIcon(glyph, size: 13, color: AppColors.textSecondary),
          const SizedBox(width: AppSpacing.xxs),
        ],
        Text(
          label,
          maxLines: 1,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppColors.textSecondary,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    ),
  );
}

/// La decoración de un campo de varias líneas.
///
/// El tema dibuja los campos como pastillas, que es lo correcto para una
/// línea. Con cuatro renglones una pastilla es una cápsula, así que el campo
/// largo toma el radio de superficie y conserva el resto del tema: relleno
/// `linerHigh`, sin borde en reposo y el filete lila en foco.
InputDecoration showMultilineDecoration({required String hintText}) =>
    InputDecoration(
      border: _multilineBorder,
      enabledBorder: _multilineBorder,
      focusedBorder: OutlineInputBorder(
        borderRadius: AppRadii.medium,
        borderSide: BorderSide(color: AppColors.primary, width: 1.6),
      ),
      contentPadding: EdgeInsets.all(AppSpacing.md),
    ).copyWith(hintText: hintText);

const _multilineBorder = OutlineInputBorder(
  borderRadius: AppRadii.medium,
  borderSide: BorderSide.none,
);
