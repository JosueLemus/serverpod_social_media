import 'package:flutter/material.dart';

import '../../app/theme/app_tokens.dart';

/// Encabezado de sección: título a la izquierda, pista o acción a la derecha.
///
/// Uno solo para toda la app. Las secciones del diseño ("Temas en tendencia /
/// TOCA PARA SEGUIR", "Creadores recomendados / 3 Sugeridos", "Hoy / 3
/// NUEVAS") son la misma fila con distinto contenido, y tres copias del mismo
/// layout se separan.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.hint,
    this.action,
    this.icon,
  });

  final String title;

  /// Texto gris en versalitas a la derecha. Es una pista, no un control: no
  /// recibe gesto, para no prometer un tap que no existe.
  final String? hint;

  /// Un control de verdad, cuando la sección tiene uno. Excluyente con [hint].
  final Widget? action;

  final IconData? icon;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: AppSpacing.lg, bottom: AppSpacing.sm),
    child: Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 6),
        ],
        Expanded(
          child: Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontSize: 17),
          ),
        ),
        if (action != null)
          action!
        else if (hint != null)
          Text(
            hint!.toUpperCase(),
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              letterSpacing: .9,
              color: AppColors.textSecondary,
            ),
          ),
      ],
    ),
  );
}
