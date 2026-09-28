import 'package:flutter/material.dart';

import '../../app/theme/app_tokens.dart';
import '../animations/app_motion.dart';

/// Chip de filtro con estado, como la fila "Para ti / Siguiendo / En vivo /
/// Comunidades" del diseño.
///
/// Uno solo para toda la app: el feed y el centro de actividad tenían el mismo
/// layout escrito dos veces, y dos copias se separan.
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

  /// Punto de color antes de la etiqueta — el rojo de "En vivo".
  final Color? dotColor;

  /// Contador a la derecha, para un filtro que cuantifica lo que muestra.
  final int? count;

  @override
  Widget build(BuildContext context) => Semantics(
    selected: selected,
    button: true,
    child: InkWell(
      onTap: onTap,
      borderRadius: AppRadii.pill,
      child: AnimatedContainer(
        duration: AppMotion.feedbackDuration,
        curve: Curves.easeOut,
        height: AppSizes.chipHeight,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryDeep : AppColors.surface,
          borderRadius: AppRadii.pill,
          border: Border.all(
            color: selected ? AppColors.primaryDeep : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (dotColor != null) ...[
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  // Seleccionado, el punto va en blanco: su propio rojo sobre
                  // el azul relleno pierde todo contraste.
                  color: selected ? Colors.white : dotColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ),
            if (count != null) ...[
              const SizedBox(width: 6),
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: selected
                      ? Colors.white70
                      : AppColors.textOnBrandSurface,
                ),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

/// Insignia pequeña de estado: EN VIVO, PRO, DESTACADO, VIP.
class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.label,
    this.color = AppColors.secondary,
    this.foreground = Colors.white,
    this.icon,
    this.pulse = false,
  });

  final String label;
  final Color color;
  final Color foreground;
  final IconData? icon;

  /// Sólo para lo que está pasando ahora. Un pulso sobre un replay afirmaría
  /// que está ocurriendo en este momento.
  final bool pulse;

  @override
  Widget build(BuildContext context) {
    final dot = Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(color: foreground, shape: BoxShape.circle),
    );
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: 4,
      ),
      decoration: BoxDecoration(color: color, borderRadius: AppRadii.pill),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (pulse)
            PulsingDot(child: dot)
          else if (icon != null)
            Icon(icon, size: 11, color: foreground),
          if (pulse || icon != null) const SizedBox(width: 5),
          Flexible(
            child: Text(
              label.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: foreground,
                fontSize: 9.5,
                fontWeight: FontWeight.w800,
                letterSpacing: .6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Un punto que late. Aislado en su propia capa: sin el [RepaintBoundary] el
/// repintado que programa cada frame sube al ancestro y vuelve a rasterizar
/// todo lo que comparte esa capa — normalmente una miniatura de video.
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
