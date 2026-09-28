import 'package:flutter/material.dart';

import '../../../../app/theme/app_tokens.dart';
import '../../../../core/widgets/pills.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../domain/entities/app_notification.dart';

/// El evento que encabeza el centro de actividad.
///
/// Es la única tarjeta de la pantalla con CTA propio: algo que empieza en
/// minutos deja de servir si se lee mañana, y enterrarlo entre notificaciones
/// lo convierte en una fila más.
class FeaturedActivityCard extends StatelessWidget {
  const FeaturedActivityCard({
    super.key,
    required this.featured,
    required this.onToggleReminder,
  });

  final FeaturedActivity featured;
  final VoidCallback onToggleReminder;

  /// "En 45 min" / "En 2 h". La cuenta atrás es el dato que justifica la
  /// tarjeta, así que se muestra en la insignia y no escondida en el cuerpo.
  String get _countdown {
    final minutes = featured.startsIn.inMinutes;
    if (minutes <= 0) return 'Ahora';
    if (minutes < 60) return 'En $minutes min';
    return 'En ${featured.startsIn.inHours} h';
  }

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: AppColors.primarySurface,
      borderRadius: AppRadii.medium,
      border: Border.all(color: AppColors.primarySurfaceDeep),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Wrap: a 320 las dos insignias no entran en una línea y un Row
        // recorta la cuenta atrás, que es el dato que justifica la tarjeta.
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: 6,
          children: [
            const StatusBadge(
              label: 'Evento exclusivo',
              color: AppColors.primaryDeep,
              icon: Icons.auto_awesome,
            ),
            StatusBadge(label: _countdown, pulse: true),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          featured.title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 16),
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(featured.detail, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            _ParticipantStack(names: featured.participants),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: SizedBox(
                height: AppSizes.buttonHeightDense,
                child: featured.reminderSet
                    ? OutlinedButton.icon(
                        key: const Key('activity-reminder'),
                        onPressed: onToggleReminder,
                        icon: const Icon(Icons.check_rounded, size: 17),
                        label: const Text('Recordatorio activo'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(
                            0,
                            AppSizes.buttonHeightDense,
                          ),
                          foregroundColor: AppColors.tertiary,
                        ),
                      )
                    : FilledButton.icon(
                        key: const Key('activity-reminder'),
                        onPressed: onToggleReminder,
                        icon: const Icon(
                          Icons.notifications_active_outlined,
                          size: 17,
                        ),
                        label: const Text('Activar recordatorio'),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(
                            0,
                            AppSizes.buttonHeightDense,
                          ),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

/// Avatares superpuestos. Solapados a propósito: ocupan el ancho de uno y
/// medio en vez del de tres, que es lo que deja espacio para el CTA al lado.
class _ParticipantStack extends StatelessWidget {
  const _ParticipantStack({required this.names});

  final List<String> names;

  static const _maxShown = 3;
  static const _overlap = 18.0;

  @override
  Widget build(BuildContext context) {
    final shown = names.take(_maxShown).toList();
    if (shown.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      width: 28 + _overlap * (shown.length - 1),
      height: 30,
      child: Stack(
        children: [
          for (final (index, name) in shown.indexed)
            Positioned(
              left: index * _overlap,
              child: Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.fromBorderSide(
                    BorderSide(color: AppColors.primarySurface, width: 2),
                  ),
                ),
                child: UserAvatar(name: name, size: 26),
              ),
            ),
        ],
      ),
    );
  }
}
