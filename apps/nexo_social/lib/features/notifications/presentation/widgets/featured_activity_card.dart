import 'package:flutter/material.dart';

import '../../../../app/theme/app_tokens.dart';
import '../../../../core/widgets/nexo_icon.dart';
import '../../../../core/widgets/pills.dart';
import '../../../../core/widgets/sticker.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../domain/entities/app_notification.dart';

/// El evento que encabeza el centro de actividad.
///
/// Es la única tarjeta de la pantalla con CTA propio: algo que empieza en
/// minutos deja de servir si se lee mañana, y enterrarlo entre notificaciones
/// lo convierte en una fila más.
///
/// El borde dice en qué estado está, con el mismo vocabulario que el resto de
/// la app: punteado mientras sigue programado en la plancha, holo cuando ya
/// está al aire.
class FeaturedActivityCard extends StatelessWidget {
  const FeaturedActivityCard({
    super.key,
    required this.featured,
    required this.onToggleReminder,
  });

  final FeaturedActivity featured;
  final VoidCallback onToggleReminder;

  /// Cuánto asoman las insignias por encima del borde de la tarjeta.
  static const _badgeOverhang = 10.0;

  bool get _onAir => featured.startsIn.inMinutes <= 0;

  /// "En 45 min" / "En 2 h". La cuenta atrás es el dato que justifica la
  /// tarjeta, así que va en la insignia pegada en la esquina y no escondida
  /// en el cuerpo.
  String get _countdown {
    final minutes = featured.startsIn.inMinutes;
    if (minutes <= 0) return 'Ahora';
    if (minutes < 60) return 'En $minutes min';
    return 'En ${featured.startsIn.inHours} h';
  }

  @override
  Widget build(BuildContext context) {
    final onAir = _onAir;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: _badgeOverhang),
          child: StickerFrame(
            edge: onAir ? StickerEdge.holo : StickerEdge.dashed,
            radius: 22,
            fill: AppColors.surface,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.md,
              ),
              child: _FeaturedBody(
                featured: featured,
                onToggleReminder: onToggleReminder,
              ),
            ),
          ),
        ),
        // Pegadas encima del borde, apenas torcidas, como stickers puestos a
        // mano. Rojo con pulso sólo si ya está pasando: un pulso sobre algo
        // programado afirmaría que ocurre ahora.
        Positioned(
          top: 0,
          left: AppSpacing.md,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              StatusBadge(
                label: _countdown,
                color: onAir ? AppColors.secondary : AppColors.vinylCyan,
                foreground: onAir ? AppColors.onSecondary : AppColors.ink,
                pulse: onAir,
                tilt: -.05,
              ),
              const SizedBox(width: 6),
              StatusBadge(
                label: 'Evento exclusivo',
                color: AppColors.vinylViolet,
                foreground: AppColors.ink,
                tilt: .04,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FeaturedBody extends StatelessWidget {
  const _FeaturedBody({required this.featured, required this.onToggleReminder});

  final FeaturedActivity featured;
  final VoidCallback onToggleReminder;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    const dense = Size(0, AppSizes.buttonHeightDense);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(featured.title, style: text.titleLarge),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            if (featured.participants.isNotEmpty) ...[
              _ParticipantStack(names: featured.participants),
              const SizedBox(width: AppSpacing.sm),
            ],
            Expanded(
              child: Text(
                featured.detail,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: text.bodySmall,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        // A todo el ancho: al lado de los avatares, "Activar recordatorio" no
        // entra a 320 y se cortaba a la mitad de la palabra.
        if (featured.reminderSet)
          OutlinedButton.icon(
            key: const Key('activity-reminder'),
            onPressed: onToggleReminder,
            // La campana rellena es "activo", la de contorno "por activar":
            // el mismo par que la pestaña de Actividad.
            icon: const NexoIcon(NexoGlyph.activity, filled: true, size: 18),
            label: const Text('Recordatorio activo'),
            style: OutlinedButton.styleFrom(
              minimumSize: dense,
              foregroundColor: AppColors.tertiary,
              side: BorderSide(
                color: AppColors.tertiary.withValues(alpha: .5),
                width: 1.6,
              ),
            ),
          )
        else
          FilledButton.icon(
            key: const Key('activity-reminder'),
            onPressed: onToggleReminder,
            icon: const NexoIcon(NexoGlyph.activity, size: 18),
            label: const Text('Activar recordatorio'),
            style: FilledButton.styleFrom(minimumSize: dense),
          ),
      ],
    );
  }
}

/// Avatares superpuestos. Solapados a propósito: ocupan el ancho de uno y
/// medio en vez del de tres, y un aro del color de la tarjeta separa cada
/// sticker del de abajo.
class _ParticipantStack extends StatelessWidget {
  const _ParticipantStack({required this.names});

  final List<String> names;

  static const _maxShown = 3;
  static const _avatar = 28.0;
  static const _gap = 2.0;
  static const _overlap = 18.0;

  @override
  Widget build(BuildContext context) {
    final shown = names.take(_maxShown).toList();
    if (shown.isEmpty) return const SizedBox.shrink();

    const side = _avatar + _gap * 2;
    return SizedBox(
      width: side + _overlap * (shown.length - 1),
      height: side,
      child: Stack(
        children: [
          for (final (index, name) in shown.indexed)
            Positioned(
              left: index * _overlap,
              child: Container(
                padding: const EdgeInsets.all(_gap),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  shape: BoxShape.circle,
                ),
                child: UserAvatar(name: name, size: _avatar),
              ),
            ),
        ],
      ),
    );
  }
}
