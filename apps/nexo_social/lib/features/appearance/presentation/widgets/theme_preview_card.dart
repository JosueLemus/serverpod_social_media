import 'package:flutter/material.dart';

import '../../../../app/theme/app_tokens.dart';
import '../../../../app/theme/nexo_themes.dart';
import '../../../../core/widgets/nexo_icon.dart';

/// Un tema del catálogo, dibujado **con sus propios colores y fuentes**: una
/// miniatura de la app (avatar al aire, media en vivo, CTA y chip) más su
/// nombre. Lo que se elige es cómo se ve, así que la tarjeta tiene que
/// mostrarlo antes de elegirlo, no después.
///
/// Por eso adentro no se usa [AppColors] salvo para el marco de selección:
/// [AppColors] es el tema **activo**, y la miniatura es la de [spec].
class ThemePreviewCard extends StatelessWidget {
  const ThemePreviewCard({
    super.key,
    required this.spec,
    required this.selected,
    required this.onTap,
  });

  final NexoThemeSpec spec;
  final bool selected;
  final VoidCallback onTap;

  /// Alto fijo de la celda, para la grilla de la pantalla.
  static const extent = 252.0;

  @override
  Widget build(BuildContext context) {
    final p = spec.palette;
    final text = Theme.of(context).textTheme;
    return Semantics(
      button: true,
      selected: selected,
      label: 'Tema ${spec.name}',
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          borderRadius: AppRadii.large,
          // El marco es del tema activo: es lo que dice "éste es el tuyo" sobre
          // el suelo en el que está apoyada la grilla.
          border: Border.all(
            color: selected ? AppColors.primary : Colors.transparent,
            width: 2.5,
          ),
        ),
        child: Material(
          color: p.liner,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: const BorderRadius.all(Radius.circular(20)),
            side: BorderSide(color: p.border),
          ),
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _MiniHeader(spec: spec, selected: selected),
                  const SizedBox(height: AppSpacing.xs),
                  Expanded(child: _MiniMedia(palette: p)),
                  const SizedBox(height: AppSpacing.xs),
                  _MiniActions(spec: spec),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    spec.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.titleMedium?.copyWith(
                      fontFamily: spec.displayFont,
                      fontWeight: spec.displayWeight,
                      letterSpacing: spec.displayTracking * .5,
                      color: p.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    spec.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.bodySmall?.copyWith(
                      fontFamily: spec.textFont,
                      color: p.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Avatar al aire con el borde del tema, dos renglones y la marca de elegido.
class _MiniHeader extends StatelessWidget {
  const _MiniHeader({required this.spec, required this.selected});

  final NexoThemeSpec spec;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final p = spec.palette;
    final ring = p.holo.length > 1 && p.holo.first != p.holo.last
        ? SweepGradient(colors: p.holo)
        : null;
    return Row(
      children: [
        Container(
          width: 26,
          height: 26,
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: ring == null ? p.secondary : null,
            gradient: ring,
          ),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: p.vinylViolet,
              border: Border.all(color: p.liner, width: 2),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Bar(color: p.textPrimary, widthFactor: .8),
              const SizedBox(height: 4),
              _Bar(color: p.textSecondary, widthFactor: .5),
            ],
          ),
        ),
        AnimatedScale(
          scale: selected ? 1 : 0,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutBack,
          child: Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: p.primaryDeep,
              shape: BoxShape.circle,
            ),
            child: NexoIcon(
              NexoGlyph.check,
              size: 14,
              filled: true,
              color: p.onPrimaryDeep,
            ),
          ),
        ),
      ],
    );
  }
}

/// La media de un vivo: superficie teñida de marca y su insignia.
class _MiniMedia extends StatelessWidget {
  const _MiniMedia({required this.palette});

  final NexoPalette palette;

  @override
  Widget build(BuildContext context) {
    final p = palette;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Color.lerp(p.linerHigh, p.primaryDeep, .38),
        borderRadius: AppRadii.small,
        border: Border.all(color: p.border),
      ),
      alignment: Alignment.topLeft,
      padding: const EdgeInsets.all(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        decoration: BoxDecoration(
          color: p.secondary,
          borderRadius: const BorderRadius.all(Radius.circular(4)),
        ),
        child: Text(
          'EN VIVO',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            fontSize: 8,
            letterSpacing: .4,
            color: p.onSecondary,
          ),
        ),
      ),
    );
  }
}

/// El CTA tal como lo pinta el tema, un chip en reposo y la paleta en puntos.
class _MiniActions extends StatelessWidget {
  const _MiniActions({required this.spec});

  final NexoThemeSpec spec;

  @override
  Widget build(BuildContext context) {
    final p = spec.palette;
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 22,
            decoration: BoxDecoration(
              color: spec.brandButtons ? p.primaryDeep : p.sticker,
              borderRadius: AppRadii.pill,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Container(
          width: 34,
          height: 22,
          decoration: BoxDecoration(
            color: p.linerHigh,
            borderRadius: AppRadii.pill,
            border: Border.all(color: p.border),
          ),
        ),
        const SizedBox(width: 8),
        for (final c in [p.primary, p.secondary, p.tertiary])
          Padding(
            padding: const EdgeInsets.only(left: 3),
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: c, shape: BoxShape.circle),
            ),
          ),
      ],
    );
  }
}

/// Un renglón de texto falso.
class _Bar extends StatelessWidget {
  const _Bar({required this.color, required this.widthFactor});

  final Color color;
  final double widthFactor;

  @override
  Widget build(BuildContext context) => FractionallySizedBox(
    widthFactor: widthFactor,
    child: Container(
      height: 6,
      decoration: BoxDecoration(
        color: color.withValues(alpha: .85),
        borderRadius: AppRadii.pill,
      ),
    ),
  );
}
