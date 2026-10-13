import 'package:flutter/material.dart';

import '../../app/theme/app_tokens.dart';
import '../animations/app_motion.dart';
import 'nexo_icon.dart';

/// Filtro con estado, como la fila "Para ti / Siguiendo / En vivo /
/// Comunidades".
///
/// En reposo es un sticker todavía pegado a la plancha (gris, sin borde). Al
/// elegirlo se despega: blanco con tinta, la misma forma que un CTA. Uno solo
/// para toda la app, porque dos copias del mismo layout se separan.
class FilterPill extends StatelessWidget {
  const FilterPill({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.dotColor,
    this.count,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  /// Punto de color antes de la etiqueta: el rojo de "En vivo".
  final Color? dotColor;

  /// Contador a la derecha, para un filtro que cuantifica lo que muestra.
  final int? count;

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? AppColors.ink : AppColors.textSecondary;
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadii.pill,
          child: AnimatedContainer(
            duration: AppMotion.feedbackDuration,
            curve: Curves.easeOutCubic,
            height: AppSizes.chipHeight,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            decoration: BoxDecoration(
              color: selected ? AppColors.sticker : AppColors.linerHigh,
              borderRadius: AppRadii.pill,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (dotColor != null) ...[
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: dotColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 7),
                ],
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(
                      context,
                    ).textTheme.labelMedium?.copyWith(color: foreground),
                  ),
                ),
                if (count != null) ...[
                  const SizedBox(width: 6),
                  Text(
                    '$count',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: selected
                          ? AppColors.ink.withValues(alpha: .55)
                          : AppColors.textTertiary,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Insignia de estado (EN VIVO, PRO, DESTACADO, VIP), como un sticker chico:
/// vinilo de color con su troquel blanco.
class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.label,
    this.color,
    this.foreground,
    this.icon,
    this.glyph,
    this.pulse = false,
    this.tilt = 0,
  });

  final String label;

  /// El relleno. Por defecto, el color de en vivo del tema.
  final Color? color;

  /// Texto y punto. Por defecto, el que se lee sobre [color].
  final Color? foreground;
  final IconData? icon;

  /// El glifo propio, preferido a [icon] cuando existe.
  final NexoGlyph? glyph;

  /// Radianes. Una insignia pegada encima de otro sticker (la esquina de una
  /// media, el borde de un plan) va apenas torcida, como pegada a mano. Una
  /// insignia dentro de una fila de texto va derecha.
  final double tilt;

  /// Sólo para lo que está pasando ahora. Un pulso sobre un replay afirmaría
  /// que está ocurriendo en este momento.
  final bool pulse;

  @override
  Widget build(BuildContext context) {
    final color = this.color ?? AppColors.secondary;
    final foreground = this.foreground ?? AppColors.on(color);
    final dot = Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(color: foreground, shape: BoxShape.circle),
    );
    final badge = Container(
      padding: const EdgeInsets.all(1.5),
      decoration: BoxDecoration(
        color: AppColors.cut,
        borderRadius: AppRadii.pill,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(color: color, borderRadius: AppRadii.pill),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (pulse)
              PulsingDot(child: dot)
            else if (glyph != null)
              NexoIcon(glyph!, filled: true, size: 11, color: foreground)
            else if (icon != null)
              Icon(icon, size: 11, color: foreground),
            if (pulse || glyph != null || icon != null)
              const SizedBox(width: 4),
            Flexible(
              child: Text(
                label.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: foreground,
                  fontSize: 10,
                  height: 1.1,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
    return tilt == 0 ? badge : Transform.rotate(angle: tilt, child: badge);
  }
}

/// Un punto que late. Aislado en su propia capa: sin el [RepaintBoundary] el
/// repintado que programa cada frame sube al ancestro y vuelve a rasterizar
/// todo lo que comparte esa capa, normalmente una miniatura de video.
class PulsingDot extends StatefulWidget {
  const PulsingDot({super.key, required this.child});

  final Widget child;

  @override
  State<PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 850),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: FadeTransition(
      opacity: Tween<double>(begin: .35, end: 1).animate(_controller),
      child: widget.child,
    ),
  );
}

/// Contador compacto: 2845 → "2.8K".
///
/// Escrito a mano y no con `NumberFormat` porque la app todavía no tiene
/// plumbing de locale, y un separador locale-aware sería el del dispositivo y
/// no el de la app.
String compactCount(int value) {
  if (value < 1000) return '$value';
  if (value < 1000000) {
    final thousands = value / 1000;
    return '${thousands.toStringAsFixed(thousands >= 10 ? 0 : 1)}K';
  }
  final millions = value / 1000000;
  return '${millions.toStringAsFixed(millions >= 10 ? 0 : 1)}M';
}
