import 'package:flutter/material.dart';

import '../../app/theme/app_tokens.dart';
import 'nexo_icon.dart';
import 'nexo_mascot.dart';
import 'pills.dart';

/// Un artículo disponible sin conexión.
class SavedReading {
  const SavedReading({
    required this.title,
    required this.summary,
    required this.author,
    required this.minutes,
  });

  final String title;
  final String summary;
  final String author;
  final int minutes;
}

/// El modo sin conexión.
///
/// No es un error genérico. Quien perdió la red no necesita que le digan que
/// falló algo (ya lo sabe): necesita saber qué **sí** puede hacer mientras
/// tanto. De ahí que la pantalla ofrezca borradores y lecturas guardadas en
/// vez de sólo un botón de reintentar.
///
/// Pendiente: no hay detección de conectividad todavía, así que esta vista se
/// muestra sólo cuando quien la invoca ya sabe que el fallo fue de red.
class AppOfflineView extends StatelessWidget {
  const AppOfflineView({
    super.key,
    required this.onRetry,
    this.draftCount = 0,
    this.savedReadings = const [],
  });

  final VoidCallback onRetry;
  final int draftCount;
  final List<SavedReading> savedReadings;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.md),
        const _OfflineStrip(),
        const SizedBox(height: AppSpacing.lg),
        const Center(child: MascotIllustration(NexoMascot.offline)),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Sin conexión a Internet',
          textAlign: TextAlign.center,
          style: text.headlineSmall,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Verifica tu red Wi-Fi o datos móviles. Puedes seguir disfrutando de '
          'tus publicaciones guardadas y borradores locales mientras '
          'restablecemos la señal.',
          textAlign: TextAlign.center,
          style: text.bodyMedium?.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.lg),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            key: const Key('offline-retry'),
            onPressed: onRetry,
            child: const Text('Reintentar conexión'),
          ),
        ),
        if (draftCount > 0) ...[
          const SizedBox(height: AppSpacing.xs),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {},
              child: Text('Ver borradores guardados ($draftCount)'),
            ),
          ),
        ],
        if (savedReadings.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Lectura disponible offline',
                  style: text.titleLarge,
                ),
              ),
              Text('${savedReadings.length} historias', style: text.bodySmall),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final reading in savedReadings)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: _SavedReadingCard(reading: reading),
            ),
          const SizedBox(height: AppSpacing.xs),
          Center(
            child: Text('Sin consumo de datos móviles', style: text.bodySmall),
          ),
        ],
      ],
    );
  }
}

/// Dónde está parado el usuario, antes del porqué: modo sin conexión,
/// mostrando lo guardado.
class _OfflineStrip extends StatelessWidget {
  const _OfflineStrip();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: const BoxDecoration(
        color: AppColors.linerHigh,
        borderRadius: AppRadii.pill,
      ),
      child: Row(
        children: [
          const StatusBadge(
            label: 'Offline',
            color: AppColors.warning,
            foreground: AppColors.ink,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Modo sin conexión',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: text.titleSmall,
            ),
          ),
          Flexible(
            child: Text(
              'Contenido guardado',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              style: text.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _SavedReadingCard extends StatelessWidget {
  const _SavedReadingCard({required this.reading});

  final SavedReading reading;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xxs,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const StatusBadge(
                  label: 'Guardado',
                  color: AppColors.vinylGreen,
                  foreground: AppColors.ink,
                ),
                Text(
                  '${reading.minutes} min de lectura',
                  style: text.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              reading.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: text.titleMedium,
            ),
            const SizedBox(height: 2),
            Text(
              reading.summary,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: text.bodySmall,
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Expanded(
                  child: Text(
                    reading.author,
                    style: text.labelMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () {},
                  iconAlignment: IconAlignment.end,
                  icon: const NexoIcon(NexoGlyph.forward, size: 14),
                  label: const Text('Leer ahora'),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    textStyle: text.labelMedium,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
